import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitrix/core/session/session_providers.dart';
import 'package:fitrix/core/sync/doc_deletions.dart';
import 'package:fitrix/core/sync/local_changes.dart';
import 'package:fitrix/core/time/today_provider.dart';
import 'package:fitrix/features/nutrition/data/food_log_store.dart';
import 'package:fitrix/features/nutrition/data/nutrition_targets.dart';
import 'package:fitrix/features/plan/presentation/providers/week_plan_provider.dart';
import 'package:fitrix/features/profile/data/models/profile_row.dart';
import 'package:fitrix/features/profile/data/performance_store.dart';
import 'package:fitrix/features/profile/presentation/providers/profile_provider.dart';
import 'package:fitrix/features/workouts/presentation/providers/workouts_provider.dart';

final foodLogStoreProvider = Provider<FoodLogStore>(
  (ref) => FoodLogStore(
    ref.watch(sharedPreferencesProvider),
    now: ref.watch(clockProvider),
  ),
);

/// The food log. The state is a revision number that changes on every
/// write; read the data through the providers below.
class FoodLogNotifier extends StateNotifier<int> {
  final FoodLogStore _store;
  final void Function()? _onChanged;
  final void Function(String id)? _onRemoved;

  FoodLogNotifier(this._store,
      {void Function()? onChanged, void Function(String id)? onRemoved})
      : _onChanged = onChanged,
        _onRemoved = onRemoved,
        super(0);

  FoodLogStore get store => _store;

  /// The log changed outside the user's hands (sync): screens re-read it.
  void refresh() => state++;

  Future<void> add(FoodEntry e) async {
    final saved = _store.add(e);
    state++;
    _onChanged?.call();
    await saved;
  }

  Future<void> remove(String id) async {
    final existed = _store.hasEntry(id);
    final saved = _store.remove(id);
    state++;
    if (existed) _onRemoved?.call(id);
    _onChanged?.call();
    await saved;
  }

  Future<void> addWater(DateTime day, int ml) async {
    final saved = _store.addWater(day, ml);
    state++;
    _onChanged?.call();
    await saved;
  }

  /// Makes [entries] the whole food log of [day] (a Felix meal plan).
  Future<void> replaceDay(DateTime day, List<FoodEntry> entries) async {
    final keep = {for (final e in entries) e.id};
    final removed = [
      for (final e in _store.day(day))
        if (!keep.contains(e.id)) e.id,
    ];
    final saved = _store.replaceDay(day, entries);
    state++;
    for (final id in removed) {
      _onRemoved?.call(id);
    }
    _onChanged?.call();
    await saved;
  }
}

final foodLogProvider = StateNotifierProvider<FoodLogNotifier, int>(
  (ref) => FoodLogNotifier(
    ref.watch(foodLogStoreProvider),
    onChanged: ref.read(localChangesProvider).notify,
    onRemoved: (id) => recordDocDeleted(ref, 'food', id),
  ),
);

/// What was logged today, oldest first.
final todayEntriesProvider = Provider<List<FoodEntry>>((ref) {
  ref.watch(foodLogProvider);
  final today = ref.watch(todayProvider);
  return ref.watch(foodLogStoreProvider).day(today);
});

final todayWaterProvider = Provider<int>((ref) {
  ref.watch(foodLogProvider);
  final today = ref.watch(todayProvider);
  return ref.watch(foodLogStoreProvider).waterMl(today);
});

class NutritionSettingsNotifier extends StateNotifier<NutritionSettings> {
  final SharedPreferences _prefs;
  final void Function()? _onChanged;
  NutritionSettingsNotifier(this._prefs, {void Function()? onChanged})
      : _onChanged = onChanged,
        super(NutritionSettings.read(_prefs));

  Future<void> save(NutritionSettings s) {
    state = s;
    _onChanged?.call();
    return s.write(_prefs);
  }

  /// Settings pulled from the cloud (not a user change).
  void applySynced(NutritionSettings s) {
    state = s;
    s.write(_prefs);
  }
}

final nutritionSettingsProvider =
    StateNotifierProvider<NutritionSettingsNotifier, NutritionSettings>(
  (ref) => NutritionSettingsNotifier(
    ref.watch(sharedPreferencesProvider),
    onChanged: ref.read(localChangesProvider).notify,
  ),
);

/// Age, weight and height from the profile; null where missing.
typedef BodyStats = ({int? age, double? weightKg, double? heightCm});

final bodyStatsProvider = Provider<BodyStats>((ref) {
  final p = ref.watch(profileProvider).valueOrNull;
  if (p == null) return (age: null, weightKg: null, heightCm: null);
  final age = parseProfileNumber(p.age);
  return (
    age: age?.round(),
    weightKg: parseProfileNumber(p.weight),
    heightCm: parseProfileNumber(p.height),
  );
});

/// Average weekly training hours over the last 4 weeks, or 3 h (estimated)
/// when there is no workout in that time.
final trainingHoursProvider = Provider<({double hours, bool estimated})>((ref) {
  final today = ref.watch(todayProvider);
  final from = DateTime(today.year, today.month, today.day - 28);
  final to = DateTime(today.year, today.month, today.day + 1);
  var minutes = 0;
  for (final w in ref.watch(workoutHistoryProvider)) {
    if (!w.finishedAt.isBefore(from) && w.finishedAt.isBefore(to)) {
      minutes += w.duration.inMinutes;
    }
  }
  if (minutes <= 0) return (hours: 3.0, estimated: true);
  return (hours: minutes / 60 / 4, estimated: false);
});

/// A workout is done or planned today.
final trainingDayProvider = Provider<bool>((ref) {
  final today = ref.watch(todayProvider);
  bool isToday(DateTime d) =>
      d.year == today.year && d.month == today.month && d.day == today.day;
  return ref.watch(workoutHistoryProvider).any((w) => isToday(w.finishedAt)) ||
      ref.watch(weekPlanProvider).any((s) => isToday(s.day));
});

/// Calories burned in today's workouts: load x 0.9. Zero without workouts.
final burnedKcalProvider = Provider<int>((ref) {
  final today = ref.watch(todayProvider);
  var load = 0;
  for (final w in ref.watch(workoutHistoryProvider)) {
    final d = w.finishedAt;
    if (d.year == today.year && d.month == today.month && d.day == today.day) {
      load += w.load;
    }
  }
  return (load * 0.9).round();
});

/// Today's targets, or null while sex, age, weight or height is missing.
final targetsProvider = Provider<Targets?>((ref) {
  final body = ref.watch(bodyStatsProvider);
  final settings = ref.watch(nutritionSettingsProvider);
  return targetsFor(
    sex: ref.watch(performanceProfileProvider).sex,
    age: body.age,
    weightKg: body.weightKg,
    heightCm: body.heightCm,
    trainingHoursPerWeek: ref.watch(trainingHoursProvider).hours,
    goal: settings.goal,
    proteinPerKg: settings.proteinPerKg,
    fatPerKg: settings.fatPerKg,
    trainingDay: ref.watch(trainingDayProvider),
  );
});
