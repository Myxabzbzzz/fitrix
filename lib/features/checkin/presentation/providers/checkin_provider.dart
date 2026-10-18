import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitrix/core/session/session_providers.dart';
import 'package:fitrix/core/time/today_provider.dart';
import 'package:fitrix/features/checkin/data/checkin_models.dart';
import 'package:fitrix/features/checkin/data/checkin_store.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/features/workouts/presentation/providers/workouts_provider.dart';

final checkInStoreProvider = Provider<CheckInStore>((ref) => CheckInStore(
      ref.watch(sharedPreferencesProvider),
      now: ref.watch(clockProvider),
    ));

class TodayCheckInNotifier extends StateNotifier<CheckIn?> {
  final CheckInStore _store;
  TodayCheckInNotifier(this._store) : super(_store.today());

  /// Re-reads the store (e.g. the day changed while the app stayed open).
  void refresh() => state = _store.today();

  Future<void> save(CheckIn c) async {
    await _store.save(c);
    // A new check-in starts the day's plan adjustment from scratch.
    await _store.saveSwaps(const []);
    state = _store.today();
  }
}

final todayCheckInProvider =
    StateNotifierProvider<TodayCheckInNotifier, CheckIn?>(
  (ref) {
    // A new day rebuilds this, so yesterday's check-in is gone.
    ref.watch(todayProvider);
    return TodayCheckInNotifier(ref.watch(checkInStoreProvider));
  },
);

/// Check-ins of the last 7 days, oldest first.
final checkInHistoryProvider = Provider<List<CheckIn>>((ref) {
  ref.watch(todayProvider);
  ref.watch(todayCheckInProvider);
  return ref.watch(checkInStoreProvider).lastDays(7);
});

/// Hard days in the 7 days up to now.
final hardDaysProvider = Provider<int>((ref) {
  ref.watch(todayProvider);
  return hardDaysLast7(
      ref.watch(workoutHistoryProvider), ref.read(clockProvider)());
});

/// Readiness of today's check-in, null before it.
final todayReadinessProvider = Provider<Readiness?>((ref) {
  final c = ref.watch(todayCheckInProvider);
  if (c == null) return null;
  return readiness(c, hardDaysLast7: ref.watch(hardDaysProvider));
});

/// Today's planned gym session. Until the week plan exists this is the
/// first gym template. The single place to repoint when it does.
final todaysGymTemplateProvider = Provider<WorkoutTemplate?>((ref) {
  for (final t in ref.watch(workoutTemplatesProvider)) {
    if (t.sport == Sport.gym) return t;
  }
  return null;
});

/// Swaps applied to today's session (date-scoped, stored with the check-in).
class AppliedSwapsNotifier extends StateNotifier<List<Swap>> {
  final CheckInStore _store;
  AppliedSwapsNotifier(this._store) : super(_store.swaps());

  Future<void> apply(List<Swap> swaps) async {
    state = swaps;
    await _store.saveSwaps(swaps);
  }

  Future<void> undo() => apply(const []);
}

final appliedSwapsProvider =
    StateNotifierProvider<AppliedSwapsNotifier, List<Swap>>((ref) {
  // A new check-in or a new day resets the swaps; follow them.
  ref.watch(todayProvider);
  ref.watch(todayCheckInProvider);
  return AppliedSwapsNotifier(ref.watch(checkInStoreProvider));
});
