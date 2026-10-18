import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitrix/core/session/session_providers.dart';
import 'package:fitrix/core/time/today_provider.dart';
import 'package:fitrix/features/plan/data/week_plan.dart';
import 'package:fitrix/features/plan/data/week_plan_store.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/features/workouts/presentation/providers/workouts_provider.dart';

final weekPlanStoreProvider = Provider<WeekPlanStore>(
    (ref) => WeekPlanStore(ref.watch(sharedPreferencesProvider)));

class WeekPlanNotifier extends StateNotifier<List<PlannedSession>> {
  final WeekPlanStore _store;
  final DateTime Function() _now;

  WeekPlanNotifier(this._store, this._now) : super(_store.all());

  Future<void> _set(List<PlannedSession> v) {
    state = v;
    return _store.save(v);
  }

  Future<void> add(PlannedSession s) => _set([...state, s]);

  Future<void> addAll(List<PlannedSession> s) => _set([...state, ...s]);

  Future<void> remove(String id) => _set([
        for (final s in state)
          if (s.id != id) s
      ]);

  Future<void> move(String id, DateTime day) => _set([
        for (final s in state) s.id == id ? s.copyWith(day: day) : s,
      ]);

  /// Removes every session for which [test] is true.
  Future<void> removeWhere(bool Function(PlannedSession) test) => _set([
        for (final s in state)
          if (!test(s)) s
      ]);

  /// Swaps today's and later gym sessions for [sessions] (used when Felix
  /// builds a plan). Past sessions and other sports stay, and so do sessions
  /// that [isDone] reports as done (a gym session finished today).
  Future<void> replaceFutureGym(List<PlannedSession> sessions,
      {bool Function(PlannedSession)? isDone}) {
    final today = dateOnly(_now());
    return _set([
      for (final s in state)
        if (s.sport != Sport.gym ||
            s.day.isBefore(today) ||
            (isDone != null && isDone(s)))
          s,
      ...sessions,
    ]);
  }
}

final weekPlanProvider =
    StateNotifierProvider<WeekPlanNotifier, List<PlannedSession>>((ref) {
  return WeekPlanNotifier(
      ref.watch(weekPlanStoreProvider), ref.read(clockProvider));
});

/// Suggestions the user kept, as "sessionId@monday" keys.
class DismissedSuggestionsNotifier extends StateNotifier<Set<String>> {
  final WeekPlanStore _store;
  DismissedSuggestionsNotifier(this._store) : super(_store.dismissed());

  static String keyFor(String sessionId, DateTime today) {
    final m = weekStartOf(today);
    return '$sessionId@${m.year}-${m.month}-${m.day}';
  }

  Future<void> dismiss(String sessionId, DateTime today) {
    state = {...state, keyFor(sessionId, today)};
    return _store.saveDismissed(state);
  }
}

final dismissedSuggestionsProvider =
    StateNotifierProvider<DismissedSuggestionsNotifier, Set<String>>(
  (ref) => DismissedSuggestionsNotifier(ref.watch(weekPlanStoreProvider)),
);

/// Today's sessions that are not done yet, in plan order.
final todaysOpenSessionsProvider = Provider<List<PlannedSession>>((ref) {
  final today = ref.watch(todayProvider);
  final history = ref.watch(workoutHistoryProvider);
  return [
    for (final s in ref.watch(weekPlanProvider))
      if (s.day == today && statusOf(s, history, today) != SessionStatus.done)
        s,
  ];
});
