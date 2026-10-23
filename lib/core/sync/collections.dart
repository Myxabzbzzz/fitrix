import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitrix/core/session/session_providers.dart';
import 'package:fitrix/core/sync/synced_collection.dart';
import 'package:fitrix/core/time/day_key.dart';
import 'package:fitrix/features/checkin/data/checkin_models.dart';
import 'package:fitrix/features/checkin/presentation/providers/checkin_provider.dart';
import 'package:fitrix/features/football/data/match_log.dart';
import 'package:fitrix/features/football/data/match_store.dart';
import 'package:fitrix/features/health/data/health_import_store.dart';
import 'package:fitrix/features/nutrition/data/food_log_store.dart';
import 'package:fitrix/features/nutrition/data/nutrition_targets.dart';
import 'package:fitrix/features/nutrition/presentation/providers/nutrition_provider.dart';
import 'package:fitrix/features/plan/data/week_plan.dart';
import 'package:fitrix/features/plan/data/week_plan_store.dart';
import 'package:fitrix/features/plan/presentation/providers/week_plan_provider.dart';
import 'package:fitrix/features/profile/data/performance_store.dart';
import 'package:fitrix/features/programs/data/program_store.dart';
import 'package:fitrix/features/programs/presentation/providers/programs_provider.dart';
import 'package:fitrix/features/progress/data/body_weight_store.dart';
import 'package:fitrix/features/progress/presentation/providers/progress_providers.dart';
import 'package:fitrix/features/running/data/run_store.dart';
import 'package:fitrix/features/running/data/run_track.dart';
import 'package:fitrix/features/workouts/data/deleted_workouts_store.dart';
import 'package:fitrix/features/workouts/data/doc_rpe.dart';
import 'package:fitrix/features/workouts/data/felix_templates_store.dart';
import 'package:fitrix/features/workouts/presentation/providers/workouts_provider.dart';

/// One adapter per synced store. Each reads only what the user saved (never
/// defaults), applies pulled docs through the store without reporting them
/// as local changes or deletions, skips docs it cannot parse, and refreshes
/// the provider the screens watch (when it has been built).
List<SyncedCollection> syncedCollections(Ref ref) => [
      CheckInCollection(ref),
      FoodCollection(ref),
      WaterCollection(ref),
      WeightCollection(ref),
      WeekPlanCollection(ref),
      ProgramCollection(ref),
      PerformanceCollection(ref),
      NutritionSettingsCollection(ref),
      FelixPlansCollection(ref),
      WorkoutDeletedCollection(ref),
      RunCollection(ref),
      MatchCollection(ref),
      HealthImportCollection(ref),
    ];

/// Parses [json] with [parse]; null when it fails.
T? _tryParse<T>(
    Map<String, Object?> json, T Function(Map<String, dynamic>) parse) {
  try {
    return parse(Map<String, dynamic>.from(json));
  } catch (_) {
    return null;
  }
}

Map<String, Object?> _plain(Map<String, Object?> m) =>
    (jsonDecode(jsonEncode(m)) as Map).cast<String, Object?>();

class CheckInCollection extends SyncedCollection {
  CheckInCollection(this._ref);
  final Ref _ref;

  @override
  String get kind => 'checkin';

  @override
  Map<String, Map<String, Object?>> read() => {
        for (final c in _ref.read(checkInStoreProvider).all())
          dayKey(c.at): _plain(c.toJson()),
      };

  @override
  void apply(Map<String, Map<String, Object?>?> docs) {
    final updates = <String, CheckIn?>{};
    for (final e in docs.entries) {
      final data = e.value;
      if (data == null) {
        updates[e.key] = null;
        continue;
      }
      final c = _tryParse(data, CheckIn.fromJson);
      if (c != null && dayKey(c.at) == e.key) updates[e.key] = c;
    }
    if (!_ref.read(checkInStoreProvider).applySynced(updates)) return;
    if (_ref.exists(todayCheckInProvider)) {
      _ref.read(todayCheckInProvider.notifier).refresh();
    }
    _ref.invalidate(checkInHistoryProvider);
  }

  @override
  void clear() {
    _ref.read(checkInStoreProvider).clearAll();
    if (_ref.exists(todayCheckInProvider)) {
      _ref.read(todayCheckInProvider.notifier).refresh();
    }
    _ref.invalidate(checkInHistoryProvider);
    _ref.invalidate(appliedSwapsProvider);
  }
}

void _refreshFoodLog(Ref ref) {
  if (ref.exists(foodLogProvider)) ref.read(foodLogProvider.notifier).refresh();
}

class FoodCollection extends SyncedCollection {
  FoodCollection(this._ref);
  final Ref _ref;

  @override
  String get kind => 'food';

  @override
  Map<String, Map<String, Object?>> read() => {
        for (final e in _ref.read(foodLogStoreProvider).allEntries())
          e.id: _plain(e.toJson()),
      };

  @override
  void apply(Map<String, Map<String, Object?>?> docs) {
    final updates = <String, FoodEntry?>{};
    for (final e in docs.entries) {
      final data = e.value;
      if (data == null) {
        updates[e.key] = null;
        continue;
      }
      final entry = _tryParse(data, FoodEntry.fromJson);
      if (entry != null && entry.id == e.key) updates[e.key] = entry;
    }
    if (_ref.read(foodLogStoreProvider).applySynced(entries: updates)) {
      _refreshFoodLog(_ref);
    }
  }

  @override
  void clear() {
    _ref.read(foodLogStoreProvider).clearEntries();
    _refreshFoodLog(_ref);
  }
}

class WaterCollection extends SyncedCollection {
  WaterCollection(this._ref);
  final Ref _ref;

  @override
  String get kind => 'water';

  @override
  Map<String, Map<String, Object?>> read() => {
        for (final e in _ref.read(foodLogStoreProvider).waterDays().entries)
          e.key: {'ml': e.value},
      };

  @override
  void apply(Map<String, Map<String, Object?>?> docs) {
    final updates = <String, int?>{};
    for (final e in docs.entries) {
      final data = e.value;
      if (data == null) {
        updates[e.key] = null;
        continue;
      }
      final ml = data['ml'];
      if (ml is num) updates[e.key] = ml.round();
    }
    if (_ref.read(foodLogStoreProvider).applySynced(water: updates)) {
      _refreshFoodLog(_ref);
    }
  }

  @override
  void clear() {
    _ref.read(foodLogStoreProvider).clearWater();
    _refreshFoodLog(_ref);
  }
}

class WeightCollection extends SyncedCollection {
  WeightCollection(this._ref);
  final Ref _ref;

  @override
  String get kind => 'weight';

  @override
  Map<String, Map<String, Object?>> read() => {
        for (final w in _ref.read(bodyWeightStoreProvider).all())
          dayKey(w.at): _plain(w.toJson()),
      };

  void _refresh() {
    if (_ref.exists(bodyWeightProvider)) {
      _ref.read(bodyWeightProvider.notifier).refresh();
    }
  }

  @override
  void apply(Map<String, Map<String, Object?>?> docs) {
    final updates = <String, WeighIn?>{};
    for (final e in docs.entries) {
      final data = e.value;
      if (data == null) {
        updates[e.key] = null;
        continue;
      }
      final w = WeighIn.fromJson(data);
      if (w != null && dayKey(w.at) == e.key) updates[e.key] = w;
    }
    if (_ref.read(bodyWeightStoreProvider).applySynced(updates)) _refresh();
  }

  @override
  void clear() {
    _ref.read(bodyWeightStoreProvider).clearAll();
    _refresh();
  }
}

class WeekPlanCollection extends SyncedCollection {
  WeekPlanCollection(this._ref);
  final Ref _ref;

  static const id = 'current';

  WeekPlanStore get _store => _ref.read(weekPlanStoreProvider);

  @override
  String get kind => 'week_plan';

  @override
  Map<String, Map<String, Object?>> read() {
    if (!_store.isSaved) return {};
    return {
      id: {
        'sessions': [for (final s in _store.all()) _plain(s.toJson())],
        'dismissed': _store.dismissed().toList(),
      },
    };
  }

  void _refresh() {
    if (_ref.exists(weekPlanProvider)) {
      _ref.read(weekPlanProvider.notifier).refresh();
    }
    if (_ref.exists(dismissedSuggestionsProvider)) {
      _ref.read(dismissedSuggestionsProvider.notifier).refresh();
    }
  }

  @override
  void apply(Map<String, Map<String, Object?>?> docs) {
    if (!docs.containsKey(id)) return;
    final data = docs[id];
    if (data == null) return clear();
    final list = data['sessions'];
    if (list is! List) return;
    final sessions = <PlannedSession>[];
    for (final e in list) {
      if (e is! Map) continue;
      final s = _tryParse(e.cast<String, Object?>(), PlannedSession.fromJson);
      if (s != null) sessions.add(s);
    }
    final d = data['dismissed'];
    final dismissed = {
      if (d is List)
        for (final e in d)
          if (e is String) e,
    };
    _store.applySynced(sessions, dismissed);
    _refresh();
  }

  @override
  void clear() {
    _store.clearAll();
    _refresh();
  }
}

class ProgramCollection extends SyncedCollection {
  ProgramCollection(this._ref);
  final Ref _ref;

  static const id = 'active';

  @override
  String get kind => 'program';

  @override
  Map<String, Map<String, Object?>> read() {
    final p = _ref.read(programStoreProvider).load();
    return p == null ? {} : {id: _plain(p.toJson())};
  }

  void _refresh() {
    if (_ref.exists(activeProgramProvider)) {
      _ref.read(activeProgramProvider.notifier).refresh();
    }
  }

  @override
  void apply(Map<String, Map<String, Object?>?> docs) {
    if (!docs.containsKey(id)) return;
    final data = docs[id];
    final store = _ref.read(programStoreProvider);
    if (data == null) {
      store.clear();
    } else {
      final p = _tryParse(data, ActiveProgram.fromJson);
      if (p == null) return;
      store.save(p);
    }
    _refresh();
  }

  @override
  void clear() {
    _ref.read(programStoreProvider).clear();
    _refresh();
  }
}

Map<String, dynamic>? _storedJson(SharedPreferences prefs, String key) {
  final raw = prefs.getString(key);
  if (raw == null) return null;
  try {
    final v = jsonDecode(raw);
    if (v is Map<String, dynamic>) return v;
  } catch (_) {}
  return null;
}

class PerformanceCollection extends SyncedCollection {
  PerformanceCollection(this._ref);
  final Ref _ref;

  static const id = 'profile';

  SharedPreferences get _prefs => _ref.read(sharedPreferencesProvider);

  @override
  String get kind => 'performance';

  @override
  Map<String, Map<String, Object?>> read() {
    final j = _storedJson(_prefs, performanceProfileKey);
    if (j == null) return {};
    return {id: _plain(PerformanceProfile.fromJson(j).toJson())};
  }

  void _set(PerformanceProfile p) {
    if (_ref.exists(performanceProfileProvider)) {
      _ref.read(performanceProfileProvider.notifier).applySynced(p);
    } else {
      _prefs.setString(performanceProfileKey, jsonEncode(p.toJson()));
    }
  }

  @override
  void apply(Map<String, Map<String, Object?>?> docs) {
    if (!docs.containsKey(id)) return;
    final data = docs[id];
    if (data == null) return clear();
    final p = _tryParse(data, PerformanceProfile.fromJson);
    if (p != null) _set(p);
  }

  @override
  void clear() {
    _prefs.remove(performanceProfileKey);
    if (_ref.exists(performanceProfileProvider)) {
      _ref
          .read(performanceProfileProvider.notifier)
          .applySynced(PerformanceProfile.empty);
      _prefs.remove(performanceProfileKey);
    }
  }
}

class NutritionSettingsCollection extends SyncedCollection {
  NutritionSettingsCollection(this._ref);
  final Ref _ref;

  static const id = 'settings';

  SharedPreferences get _prefs => _ref.read(sharedPreferencesProvider);

  @override
  String get kind => 'nutrition_settings';

  @override
  Map<String, Map<String, Object?>> read() {
    final j = _storedJson(_prefs, NutritionSettings.key);
    if (j == null) return {};
    return {id: _plain(NutritionSettings.fromJson(j).toJson())};
  }

  @override
  void apply(Map<String, Map<String, Object?>?> docs) {
    if (!docs.containsKey(id)) return;
    final data = docs[id];
    if (data == null) return clear();
    final s = _tryParse(data, NutritionSettings.fromJson);
    if (s == null) return;
    if (_ref.exists(nutritionSettingsProvider)) {
      _ref.read(nutritionSettingsProvider.notifier).applySynced(s);
    } else {
      s.write(_prefs);
    }
  }

  @override
  void clear() {
    _prefs.remove(NutritionSettings.key);
    if (_ref.exists(nutritionSettingsProvider)) {
      _ref
          .read(nutritionSettingsProvider.notifier)
          .applySynced(const NutritionSettings());
      _prefs.remove(NutritionSettings.key);
    }
  }
}

class FelixPlansCollection extends SyncedCollection {
  FelixPlansCollection(this._ref);
  final Ref _ref;

  static const id = 'state';

  SharedPreferences get _prefs => _ref.read(sharedPreferencesProvider);

  @override
  String get kind => 'felix_plans';

  @override
  Map<String, Map<String, Object?>> read() {
    const ids = FelixTemplateIdsNotifier.key;
    const batches = FelixTemplateIdsNotifier.batchesKey;
    if (!_prefs.containsKey(ids) && !_prefs.containsKey(batches)) return {};
    return {
      id: {
        'ids': _prefs.getStringList(ids) ?? <String>[],
        'batches': _storedJson(_prefs, batches) ?? <String, Object?>{},
      },
    };
  }

  @override
  void apply(Map<String, Map<String, Object?>?> docs) {
    if (!docs.containsKey(id)) return;
    final data = docs[id];
    if (data == null) return clear();
    final ids = data['ids'];
    final batches = data['batches'];
    if (ids is! List || batches is! Map) return;
    final idList = [for (final e in ids) '$e'];
    final batchMap = batches.map((k, v) => MapEntry('$k', v));
    if (_ref.exists(felixTemplateIdsProvider)) {
      _ref
          .read(felixTemplateIdsProvider.notifier)
          .applySynced(idList, batchMap);
    } else {
      _prefs.setStringList(FelixTemplateIdsNotifier.key, idList);
      _prefs.setString(
          FelixTemplateIdsNotifier.batchesKey, jsonEncode(batchMap));
    }
  }

  @override
  void clear() {
    if (_ref.exists(felixTemplateIdsProvider)) {
      _ref
          .read(felixTemplateIdsProvider.notifier)
          .applySynced(const [], const {});
    }
    _prefs.remove(FelixTemplateIdsNotifier.key);
    _prefs.remove(FelixTemplateIdsNotifier.batchesKey);
  }
}

/// Finished workouts the user deleted (doc id = workout id). A deletion is
/// never undone, so the docs are only ever added.
class WorkoutDeletedCollection extends SyncedCollection {
  WorkoutDeletedCollection(this._ref);
  final Ref _ref;

  DeletedWorkoutsStore get _store => _ref.read(deletedWorkoutsStoreProvider);

  @override
  String get kind => 'workout_deleted';

  @override
  Map<String, Map<String, Object?>> read() => {
        for (final id in _store.ids())
          id: {
            'deletedAt': (_store.deletedAt(id) ?? DateTime.now())
                .toUtc()
                .toIso8601String(),
          },
      };

  @override
  void apply(Map<String, Map<String, Object?>?> docs) {
    final gone = <String>{};
    for (final e in docs.entries) {
      if (e.value == null) continue;
      final at = DateTime.tryParse('${e.value!['deletedAt']}');
      _store.add(e.key, at ?? DateTime.now());
      gone.add(e.key);
    }
    final notifier = _ref.read(workoutHistoryProvider.notifier);
    final history = _ref.read(workoutHistoryProvider);
    if (history.any((w) => gone.contains(w.id))) {
      notifier.applySynced([
        for (final w in history)
          if (!gone.contains(w.id)) w,
      ]);
    }
  }

  @override
  void clear() => _store.clear();
}

/// Run details (doc id = workout id). A pulled run's RPE is copied onto its
/// workout, since the RPE itself is not stored with the synced workout.
class RunCollection extends SyncedCollection {
  RunCollection(this._ref);
  final Ref _ref;

  @override
  String get kind => 'run';

  @override
  Map<String, Map<String, Object?>> read() => {
        for (final e in _ref.read(runStoreProvider).all().entries)
          e.key: _plain(e.value.toJson()),
      };

  @override
  void apply(Map<String, Map<String, Object?>?> docs) {
    final updates = <String, RunDetails?>{};
    for (final e in docs.entries) {
      final data = e.value;
      if (data == null) {
        updates[e.key] = null;
        continue;
      }
      try {
        updates[e.key] = RunDetails.fromJson(data);
      } catch (_) {}
    }
    if (updates.isEmpty) return;
    _ref.read(runsProvider.notifier).applySynced(updates);
    applyDocRpe(_ref);
  }

  @override
  void clear() => _ref.read(runsProvider.notifier).clear();
}

/// Football logs (doc id = workout id). A pulled log's RPE is copied onto
/// its workout, like a run's.
class MatchCollection extends SyncedCollection {
  MatchCollection(this._ref);
  final Ref _ref;

  @override
  String get kind => 'match';

  @override
  Map<String, Map<String, Object?>> read() => {
        for (final e in _ref.read(matchStoreProvider).all().entries)
          e.key: _plain(e.value.toJson()),
      };

  @override
  void apply(Map<String, Map<String, Object?>?> docs) {
    final updates = <String, MatchLog?>{};
    for (final e in docs.entries) {
      final data = e.value;
      if (data == null) {
        updates[e.key] = null;
        continue;
      }
      try {
        updates[e.key] = MatchLog.fromJson(data);
      } catch (_) {}
    }
    if (updates.isEmpty) return;
    _ref.read(matchesProvider.notifier).applySynced(updates);
    applyDocRpe(_ref);
  }

  @override
  void clear() => _ref.read(matchesProvider.notifier).clear();
}

/// Details of workouts imported from Health (doc id = workout id).
class HealthImportCollection extends SyncedCollection {
  HealthImportCollection(this._ref);
  final Ref _ref;

  @override
  String get kind => 'health_import';

  @override
  Map<String, Map<String, Object?>> read() => {
        for (final e in _ref.read(healthImportStoreProvider).all().entries)
          e.key: _plain(e.value.toJson()),
      };

  @override
  void apply(Map<String, Map<String, Object?>?> docs) {
    final updates = <String, HealthImport?>{};
    for (final e in docs.entries) {
      final data = e.value;
      if (data == null) {
        updates[e.key] = null;
        continue;
      }
      final d = _tryParse(data, (j) => HealthImport.fromJson(j));
      if (d != null) updates[e.key] = d;
    }
    if (updates.isEmpty) return;
    _ref.read(healthImportsProvider.notifier).applySynced(updates);
  }

  @override
  void clear() => _ref.read(healthImportsProvider.notifier).clear();
}
