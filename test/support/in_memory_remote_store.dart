import 'dart:async';
import 'dart:io';

import 'package:fitrix/core/sync/remote_store.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';

/// [RemoteStore] in memory, behaving like the Supabase tables: per-user
/// rows, server-assigned timestamps, idempotent inserts. Set [online] to
/// false to simulate no network.
class InMemoryRemoteStore implements RemoteStore {
  bool online = true;

  /// Requests made (successful or not).
  int requests = 0;

  final _plans = <String, Map<String, RemotePlan>>{};
  final _history = <String, Map<String, RemoteRow<CompletedWorkout>>>{};
  final _chat = <String, Map<String, RemoteRow<ChatRecord>>>{};

  DateTime _last = DateTime.utc(2000);

  /// Strictly increasing server clock.
  DateTime _now() {
    var now = DateTime.now().toUtc();
    if (!now.isAfter(_last)) now = _last.add(const Duration(microseconds: 1));
    return _last = now;
  }

  void _request() {
    requests++;
    if (!online) throw const SocketException('Network is unreachable');
  }

  /// Server rows, for assertions.
  List<RemotePlan> plansOf(String userId) =>
      (_plans[userId] ?? {}).values.toList();
  List<CompletedWorkout> historyOf(String userId) =>
      [for (final r in (_history[userId] ?? {}).values) r.value];
  List<ChatRecord> chatOf(String userId) =>
      [for (final r in (_chat[userId] ?? {}).values) r.value];

  /// Simulates another device writing a plan directly.
  void putPlan(String userId, WorkoutTemplate plan, {int position = 0}) {
    (_plans[userId] ??= {})[plan.id] =
        RemotePlan(plan.copyWith(updatedAt: _now()), position: position);
  }

  static List<T> _since<T>(
    Iterable<T> rows,
    DateTime Function(T) time,
    DateTime? since,
  ) =>
      rows.where((r) => since == null || time(r).isAfter(since)).toList()
        ..sort((a, b) => time(a).compareTo(time(b)));

  /// While set, plan fetches wait for it (a slow network).
  Completer<void>? hold;

  @override
  Future<List<RemotePlan>> fetchPlans(String userId, {DateTime? since}) async {
    await hold?.future;
    _request();
    return _since(plansOf(userId), (p) => p.updatedAt, since);
  }

  @override
  Future<Map<String, DateTime>> upsertPlans(
    String userId,
    List<RemotePlan> plans,
  ) async {
    _request();
    final table = _plans[userId] ??= {};
    final result = <String, DateTime>{};
    for (final plan in plans) {
      final now = _now();
      // Like the table: updated_at is the server's, deleted_at as sent.
      table[plan.id] = RemotePlan(
        WorkoutTemplate(
          id: plan.id,
          sport: plan.template.sport,
          name: plan.template.name,
          focus: plan.template.focus,
          estimatedDuration: plan.template.estimatedDuration,
          exercises: plan.template.exercises,
          updatedAt: now,
          deletedAt: plan.template.deletedAt,
        ),
        position: plan.position,
      );
      result[plan.id] = now;
    }
    return result;
  }

  @override
  Future<List<RemoteRow<CompletedWorkout>>> fetchHistory(
    String userId, {
    DateTime? since,
  }) async {
    _request();
    return _since(
      (_history[userId] ?? {}).values,
      (r) => r.serverTime,
      since,
    );
  }

  @override
  Future<Set<String>> insertHistory(
    String userId,
    List<CompletedWorkout> workouts,
  ) async {
    _request();
    final table = _history[userId] ??= {};
    for (final w in workouts) {
      table.putIfAbsent(w.id, () => RemoteRow(w, _now()));
    }
    return {for (final w in workouts) w.id};
  }

  @override
  Future<List<RemoteRow<ChatRecord>>> fetchChat(
    String userId, {
    DateTime? since,
  }) async {
    _request();
    return _since((_chat[userId] ?? {}).values, (r) => r.serverTime, since);
  }

  @override
  Future<Set<String>> insertChat(
    String userId,
    List<ChatRecord> messages,
  ) async {
    _request();
    final table = _chat[userId] ??= {};
    for (final r in messages) {
      table.putIfAbsent(r.message.id, () => RemoteRow(r, _now()));
    }
    return {for (final r in messages) r.message.id};
  }
}
