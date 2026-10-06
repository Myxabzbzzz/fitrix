import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitrix/core/constants/app_constants.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';

/// Persists workout plans, the workout in progress and workout history on
/// the device. Reads are synchronous (prefs are preloaded in `main()`);
/// writes update the in-memory cache immediately and hit disk async.
class WorkoutStorage {
  final SharedPreferences _prefs;

  WorkoutStorage(this._prefs);

  /// Saved plans, or null if the user hasn't changed the defaults yet.
  List<WorkoutTemplate>? loadTemplates() => _readList(
        AppConstants.keyWorkoutTemplates,
        WorkoutTemplate.fromJson,
      );

  void saveTemplates(List<WorkoutTemplate> templates) => _write(
        AppConstants.keyWorkoutTemplates,
        [for (final t in templates) t.toJson()],
      );

  /// Deleted plans (with `deletedAt` set) whose deletion hasn't been synced
  /// yet, so other devices can learn about it.
  List<WorkoutTemplate> loadDeletedTemplates() =>
      _readList(keyDeletedTemplates, WorkoutTemplate.fromJson) ?? const [];

  void saveDeletedTemplates(List<WorkoutTemplate> tombstones) {
    if (tombstones.isEmpty) {
      _prefs.remove(keyDeletedTemplates);
    } else {
      _write(keyDeletedTemplates, [for (final t in tombstones) t.toJson()]);
    }
  }

  static const keyDeletedTemplates = 'workout_templates_deleted';

  ActiveWorkout? loadActive() {
    final raw = _prefs.getString(AppConstants.keyActiveWorkout);
    if (raw == null) return null;
    try {
      return ActiveWorkout.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Discarding unreadable active workout: $e');
      return null;
    }
  }

  void saveActive(ActiveWorkout? workout) {
    if (workout == null) {
      _prefs.remove(AppConstants.keyActiveWorkout);
    } else {
      _write(AppConstants.keyActiveWorkout, workout.toJson());
    }
  }

  List<CompletedWorkout> loadHistory() =>
      _readList(AppConstants.keyWorkoutHistory, CompletedWorkout.fromJson) ??
      const [];

  void saveHistory(List<CompletedWorkout> history) => _write(
        AppConstants.keyWorkoutHistory,
        [for (final w in history) w.toJson()],
      );

  List<T>? _readList<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    try {
      return [
        for (final item in jsonDecode(raw) as List)
          fromJson(item as Map<String, dynamic>),
      ];
    } catch (e) {
      debugPrint('Discarding unreadable $key: $e');
      return null;
    }
  }

  void _write(String key, Object json) {
    _prefs.setString(key, jsonEncode(json));
  }
}
