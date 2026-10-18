import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'package:fitrix/core/sync/doc_merge.dart';
import 'package:fitrix/core/sync/remote_store.dart';
import 'package:fitrix/core/sync/sync_local.dart';
import 'package:fitrix/core/sync/sync_merge.dart';
import 'package:fitrix/core/sync/sync_state.dart';
import 'package:fitrix/core/sync/synced_collection.dart';
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
      // Channels are independent: one failing must not starve the others.
      // _Disposed aborts everything; any other error is kept, the rest run.
      Object? failure;
      for (final step in <Future<void> Function()>[
        () async {
          await _pullPlans();
          await _pushPlans();
        },
        () async {
          await _pullHistory();
          await _pushHistory();
        },
        () async {
          await _pullChat();
          await _pushChat();
        },
        () async {
          await _pullDocs();
          await _pushDocs();
        },
      ]) {
        try {
          await step();
        } on _Disposed {
          rethrow;
        } catch (e) {
          if (_disposed) return false;
          failure ??= e;
        }
      }
      if (failure != null) throw failure;
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
    // Local-only data is claimed by this account: deletions made before
    // signing in must not delete the account's cloud data.
    if (state.owner == null) state.docTombstones.clear();
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

  // --- Documents -------------------------------------------------------------

  static String _key(String kind, String id) => '$kind/$id';

  /// Ids of [kind] in state keys ('kind/id' -> id).
  static Map<String, V> _forKind<V>(Map<String, V> map, String kind) {
    final prefix = '$kind/';
    return {
      for (final e in map.entries)
        if (e.key.startsWith(prefix)) e.key.substring(prefix.length): e.value,
    };
  }

  List<SyncedCollection> get _collections => local.collections;

  Future<void> _pullDocs() async {
    final kinds = [for (final c in _collections) c.kind];
    if (kinds.isEmpty) return;
    // One request: since the oldest cursor, or everything when some kind
    // has none yet.
    final cursors = _load().docsCursors;
    DateTime? oldest;
    var fullFetch = false;
    for (final kind in kinds) {
      final c = cursors[kind];
      if (c == null) {
        fullFetch = true;
      } else if (oldest == null || c.isBefore(oldest)) {
        oldest = c;
      }
    }
    final rows = await remote.fetchDocs(
      userId,
      since: fullFetch ? null : _since(oldest),
    );
    _checkDisposed();

    final state = _load();
    final seen = rows.map((r) => r.updatedAt);
    for (final collection in _collections) {
      final kind = collection.kind;
      final cursor = state.docsCursors[kind];
      final mine = [
        for (final r in rows)
          if (r.kind == kind) r
      ];
      try {
        final tombstones = _forKind(state.docTombstones, kind).keys.toSet();
        final merge = mergeDocs(
          local: collection.read(),
          agreed: _forKind(state.docs, kind),
          tombstones: tombstones,
          remote: mine,
          fullPull: cursor == null,
        );
        if (merge.apply.isNotEmpty) collection.apply(merge.apply);
        // What the store now holds is what was agreed (it may reorder,
        // normalise or skip a doc).
        final after = merge.apply.isEmpty ? null : collection.read();
        final agreed = {...merge.agreed};
        if (after != null) {
          for (final id in merge.apply.keys) {
            final stored = after[id];
            if (stored == null) {
              agreed.remove(id);
            } else {
              agreed[id] = docHash(stored);
            }
          }
        }
        state.docs.removeWhere((k, _) => k.startsWith('$kind/'));
        for (final e in agreed.entries) {
          state.docs[_key(kind, e.key)] = e.value;
        }
        // The request started at or before every kind's cursor, so it saw
        // everything up to its newest row, whatever the kind. With no rows
        // at all a kind without a cursor starts at the epoch.
        final newest = _latest(cursor, seen) ??
            (fullFetch
                ? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true)
                : null);
        if (newest != null) state.docsCursors[kind] = newest;
      } catch (e) {
        // A broken collection must not stop the rest; its cursor stays so
        // its rows are fetched again.
        debugPrint('Sync: could not merge $kind documents: $e');
      }
    }
    // Rows of kinds without a collection are ignored and advance nothing.
    _save(state);
  }

  /// Unsynced docs (changed ones, recreated ones and deletions), with the
  /// hash pushed for each live doc and the tombstones they were built from.
  ({
    List<RemoteDoc> docs,
    Map<String, String> hashes,
    Map<String, int> tombstones,
  }) _pendingDocs(SyncState state) {
    final epoch = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    final docs = <RemoteDoc>[];
    final hashes = <String, String>{};
    for (final collection in _collections) {
      final kind = collection.kind;
      final live = collection.read();
      for (final e in live.entries) {
        final key = _key(kind, e.key);
        final hash = docHash(e.value);
        // A tombstone on a live doc: deleted, then created again.
        if (hash == state.docs[key] && !state.docTombstones.containsKey(key)) {
          continue;
        }
        hashes[key] = hash;
        docs.add(RemoteDoc(
            kind: kind, docId: e.key, data: e.value, updatedAt: epoch));
      }
      for (final key in state.docTombstones.keys) {
        if (!key.startsWith('$kind/')) continue;
        final id = key.substring(kind.length + 1);
        if (live.containsKey(id)) continue;
        docs.add(
            RemoteDoc(kind: kind, docId: id, data: null, updatedAt: epoch));
      }
    }
    final pushed = {for (final d in docs) d.key};
    return (
      docs: docs,
      hashes: hashes,
      tombstones: {
        for (final e in state.docTombstones.entries)
          if (pushed.contains(e.key)) e.key: e.value,
      },
    );
  }

  Future<void> _pushDocs() async {
    final pending = _pendingDocs(_load());
    if (pending.docs.isNotEmpty) {
      final stored = await remote.upsertDocs(userId, pending.docs);
      _checkDisposed();

      final state = _load();
      for (final doc in pending.docs) {
        final key = doc.key;
        if (!stored.containsKey(key)) continue;
        // A tombstone made during the push (a delete, or another one after
        // a recreate) is not the one pushed: it stays.
        final unchanged = state.docTombstones[key] == pending.tombstones[key];
        if (doc.isDeleted) {
          if (unchanged) {
            state.docTombstones.remove(key);
            state.docs.remove(key);
          }
        } else {
          // The hash that was pushed, not the current one: a doc edited
          // during the push stays dirty.
          state.docs[key] = pending.hashes[key]!;
          if (unchanged) state.docTombstones.remove(key);
        }
      }
      _save(state);
    }
    _pruneDocs();
  }

  /// Forgets agreed hashes of docs that are gone locally without a
  /// deletion (pruned by their store). That never deletes them on the
  /// server.
  void _pruneDocs() {
    final state = _load();
    final before = state.docs.length;
    for (final collection in _collections) {
      final kind = collection.kind;
      final live = collection.read();
      state.docs.removeWhere((key, _) =>
          key.startsWith('$kind/') &&
          !live.containsKey(key.substring(kind.length + 1)) &&
          !state.docTombstones.containsKey(key));
    }
    if (state.docs.length != before) _save(state);
  }

  /// Local changes not on the server yet.
  int pendingCount() {
    final state = _load();
    return _pendingDocs(state).docs.length +
        _pendingPlans(state).length +
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
