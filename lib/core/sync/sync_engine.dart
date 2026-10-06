import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'package:fitrix/core/sync/remote_store.dart';
import 'package:fitrix/core/sync/sync_local.dart';
import 'package:fitrix/core/sync/sync_merge.dart';
import 'package:fitrix/core/sync/sync_state.dart';
import 'package:fitrix/features/chat/data/models/assistant_topic.dart';
import 'package:fitrix/features/chat/data/models/chat_message.dart';

/// What sync is up to, for an optional indicator.
@immutable
class SyncStatus {
  /// False when nobody is signed in (or Supabase isn't available): the app
  /// is local-only and nothing is synced.
  final bool enabled;
  final bool syncing;

  /// End of the last sync that completed without errors.
  final DateTime? lastSyncedAt;

  /// Local changes not yet on the server.
  final int pending;

  /// Why the last sync failed (it will be retried), or null.
  final String? error;

  const SyncStatus({
    this.enabled = false,
    this.syncing = false,
    this.lastSyncedAt,
    this.pending = 0,
    this.error,
  });

  static const disabled = SyncStatus();
}

/// Keeps local data and the server in step for one signed-in user.
///
/// The app always reads and writes local storage; this runs in the
/// background. Each sync pulls what changed on the server since last time,
/// merges it into local data (see `sync_merge.dart`), then pushes local
/// changes the server doesn't have. Syncs run:
/// - when the engine starts (sign-in, or app start with a session),
/// - [debounce] after a local change,
/// - every [pollInterval] and when the app returns to the foreground,
/// - after a failure, with exponential backoff.
///
/// Unsynced changes are derived from local data and [SyncState], both in
/// local storage, so nothing is lost while offline or if the app is
/// killed: it's pushed by the next successful sync.
class SyncEngine {
  SyncEngine({
    required this.local,
    required this.remote,
    required this.userId,
    this.debounce = const Duration(seconds: 2),
    this.pollInterval = const Duration(minutes: 2),
    this.pullOverlap = const Duration(minutes: 1),
  });

  final SyncLocal local;
  final RemoteStore remote;
  final String userId;
  final Duration debounce;

  /// Current status, updated as syncs run and local changes come in.
  final ValueNotifier<SyncStatus> status =
      ValueNotifier(const SyncStatus(enabled: true));
  final Duration? pollInterval;

  /// Pulls re-read this much before the last seen server time, so rows
  /// committed slightly out of order aren't missed (merging is idempotent).
  final Duration pullOverlap;

  StreamSubscription<void>? _changes;
  Timer? _debounceTimer;
  Timer? _retryTimer;
  Timer? _pollTimer;
  Future<void>? _running;
  bool _again = false;
  bool _disposed = false;
  int _failures = 0;
  DateTime? _lastSyncedAt;
  String? _lastError;
  bool _syncing = false;

  bool get isDisposed => _disposed;

  /// Starts listening for local changes and runs the first sync.
  void start() {
    _changes = local.changes.listen((_) => _schedule());
    final interval = pollInterval;
    if (interval != null) {
      _pollTimer = Timer.periodic(interval, (_) => sync());
    }
    // Not during start(): it's typically called while providers build.
    scheduleMicrotask(sync);
  }

  void _schedule() {
    if (_disposed) return;
    _emit();
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounce, sync);
  }

  /// Runs a sync now, or once more after the one in progress. Completes
  /// when local data and the server agree (or the attempt failed, in which
  /// case a retry is scheduled). Never throws.
  Future<void> sync() {
    if (_disposed) return Future.value();
    final running = _running;
    if (running != null) {
      _again = true;
      return running;
    }
    _debounceTimer?.cancel();
    final run = _loop();
    _running = run;
    return run.whenComplete(() => _running = null);
  }

  /// Repeats while changes came in during a successful run; after a failure
  /// the scheduled retry takes over.
  Future<void> _loop() async {
    bool ok;
    do {
      _again = false;
      ok = await _runOnce();
    } while (ok && _again && !_disposed);
  }

  /// One pull-merge-push round; false if it failed or was abandoned.
  Future<bool> _runOnce() async {
    _retryTimer?.cancel();
    _syncing = true;
    _emit();
    var ok = false;
    try {
      _claimLocalData();
      await _pullPlans();
      await _pullHistory();
      await _pullChat();
      await _pushPlans();
      await _pushHistory();
      await _pushChat();
      _failures = 0;
      _lastError = null;
      _lastSyncedAt = DateTime.now();
      ok = true;
    } on _Disposed {
      return false;
    } catch (e) {
      if (_disposed) return false;
      _failures++;
      _lastError = e.toString();
      final delay = retryDelay(_failures);
      debugPrint('Sync failed (retrying in ${delay.inSeconds}s): $e');
      _retryTimer = Timer(delay, sync);
    }
    _syncing = false;
    _emit();
    return ok;
  }

  /// 5s, 10s, 20s ... capped at 5 minutes.
  static Duration retryDelay(int failures) =>
      Duration(seconds: min(300, 5 * pow(2, min(failures - 1, 6)).toInt()));

  void dispose() {
    _disposed = true;
    _changes?.cancel();
    _debounceTimer?.cancel();
    _retryTimer?.cancel();
    _pollTimer?.cancel();
  }

  // ---------------------------------------------------------------------------
  // Steps. Each one awaits the network once, then (synchronously, so no
  // user change can interleave) re-reads local data, merges and saves.
  // ---------------------------------------------------------------------------

  SyncState _load() => SyncState.load(local.prefs);

  void _save(SyncState state) => state.save(local.prefs);

  /// Called after every network wait: stops if the engine was disposed or
  /// local data no longer belongs to this user (sign-out cleared storage
  /// meanwhile). In that case the engine shuts down for good, so nothing is
  /// written back into the next session; the app creates a new one.
  void _checkDisposed() {
    if (!_disposed && _load().owner != userId) dispose();
    if (_disposed) throw const _Disposed();
  }

  /// Local data made without an account is uploaded to the first account
  /// that signs in; data left from a different account is dropped.
  void _claimLocalData() {
    var state = _load();
    if (state.owner == userId) return;
    if (state.owner != null) {
      local.clear();
      state = SyncState();
    }
    state.owner = userId;
    _save(state);
  }

  DateTime? _since(DateTime? cursor) => cursor?.subtract(pullOverlap);

  static DateTime? _latest(DateTime? cursor, Iterable<DateTime> times) {
    var latest = cursor;
    for (final t in times) {
      if (latest == null || t.isAfter(latest)) latest = t;
    }
    return latest;
  }

  Future<void> _pullPlans() async {
    final cursor = _load().plansCursor;
    final rows = await remote.fetchPlans(userId, since: _since(cursor));
    _checkDisposed();

    final state = _load();
    final merge = mergePlans(
      local: local.plans,
      tombstones: local.tombstones,
      versions: state.plans,
      remote: rows,
      fullPull: cursor == null,
    );
    if (merge.changed) local.applyPlans(merge.plans, merge.tombstones);
    state
      ..plans = merge.versions
      ..plansCursor = _latest(state.plansCursor, rows.map((r) => r.updatedAt));
    _save(state);
  }

  Future<void> _pullHistory() async {
    final cursor = _load().historyCursor;
    final rows = await remote.fetchHistory(userId, since: _since(cursor));
    _checkDisposed();

    final merge = unionById(
      local: local.history,
      remote: rows.map((r) => r.value),
      idOf: (w) => w.id,
      compare: newestFirst,
    );
    if (merge.changed) local.applyHistory(merge.items);
    final state = _load();
    state
      ..history = syncedAfterPull(
        state.history,
        rows.map((r) => r.value.id),
        fullPull: cursor == null,
      )
      ..historyCursor =
          _latest(state.historyCursor, rows.map((r) => r.serverTime));
    _save(state);
  }

  Future<void> _pullChat() async {
    final cursor = _load().chatCursor;
    final rows = await remote.fetchChat(userId, since: _since(cursor));
    _checkDisposed();

    final byTopic = <AssistantTopic, List<ChatMessage>>{};
    for (final row in rows) {
      final topic = _topics[row.value.topic];
      if (topic == null) continue; // a chat this app version doesn't know
      byTopic.putIfAbsent(topic, () => []).add(row.value.message);
    }
    for (final entry in byTopic.entries) {
      final merge = unionById(
        local: local.chat(entry.key),
        remote: entry.value,
        idOf: (m) => m.id,
        compare: (a, b) => a.timestamp.compareTo(b.timestamp),
      );
      if (merge.changed) local.applyChat(entry.key, merge.items);
    }
    final state = _load();
    state
      ..chat = syncedAfterPull(
        state.chat,
        rows.map((r) => r.value.message.id),
        fullPull: cursor == null,
      )
      ..chatCursor = _latest(state.chatCursor, rows.map((r) => r.serverTime));
    _save(state);
  }

  static final _topics = {
    for (final topic in AssistantTopic.all) topic.apiTopic: topic,
  };

  List<RemotePlan> _pendingPlans(SyncState state) {
    final live = local.plans;
    return [
      for (var i = 0; i < live.length; i++)
        if (isPlanDirty(live[i], state.plans)) RemotePlan(live[i], position: i),
      for (final tombstone in local.tombstones) RemotePlan(tombstone),
    ];
  }

  Future<void> _pushPlans() async {
    final pending = _pendingPlans(_load());
    if (pending.isEmpty) return;
    final stored = await remote.upsertPlans(userId, pending);
    _checkDisposed();

    final state = _load();
    final tombstones = local.tombstones;
    final remaining = [...tombstones];
    for (final plan in pending) {
      final serverTime = stored[plan.id];
      if (serverTime == null) continue;
      if (plan.isDeleted) {
        // Done, unless the plan was deleted again meanwhile (can't happen
        // today, plan ids are never reused, but cheap to respect).
        remaining.removeWhere((t) =>
            t.id == plan.id &&
            micros(t.deletedAt) == micros(plan.template.deletedAt));
        state.plans.remove(plan.id);
      } else {
        // If the plan was edited again during the push it stays unsynced.
        state.plans[plan.id] = PlanVersion(
          local: micros(plan.template.updatedAt),
          server: micros(serverTime)!,
        );
      }
    }
    if (remaining.length != tombstones.length) {
      local.applyPlans(local.plans, remaining);
    }
    _save(state);
  }

  Future<void> _pushHistory() async {
    final synced = _load().history;
    final pending = local.history.where((w) => !synced.contains(w.id)).toList();
    if (pending.isEmpty) return;
    final stored = await remote.insertHistory(userId, pending);
    _checkDisposed();

    final state = _load();
    state.history.addAll(stored);
    _save(state);
  }

  List<ChatRecord> _pendingChat(Set<String> synced) => [
        for (final topic in AssistantTopic.all)
          for (final message in local.chat(topic))
            if (!synced.contains(message.id) &&
                !message.isStreaming &&
                !message.isFailed)
              ChatRecord(topic.apiTopic, message),
      ];

  Future<void> _pushChat() async {
    final pending = _pendingChat(_load().chat);
    if (pending.isEmpty) return;
    final stored = await remote.insertChat(userId, pending);
    _checkDisposed();

    final state = _load();
    state.chat.addAll(stored);
    _save(state);
  }

  /// Local changes not on the server yet.
  int pendingCount() {
    final state = _load();
    return _pendingPlans(state).length +
        local.history.where((w) => !state.history.contains(w.id)).length +
        _pendingChat(state.chat).length;
  }

  void _emit() {
    if (_disposed) return;
    status.value = SyncStatus(
      enabled: true,
      syncing: _syncing,
      lastSyncedAt: _lastSyncedAt,
      pending: pendingCount(),
      error: _lastError,
    );
  }
}

class _Disposed implements Exception {
  const _Disposed();
}
