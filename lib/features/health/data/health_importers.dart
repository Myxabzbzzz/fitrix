import 'dart:convert';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fitrix/core/session/session_providers.dart';
import 'package:fitrix/features/language/presentation/providers/language_provider.dart';
import 'package:fitrix/core/time/day_key.dart';
import 'package:fitrix/features/health/data/health_import_store.dart';
import 'package:fitrix/features/health/data/health_source.dart';
import 'package:fitrix/features/health/domain/health_math.dart';
import 'package:fitrix/features/health/presentation/providers/health_providers.dart';
import 'package:fitrix/features/progress/data/body_weight_store.dart';
import 'package:fitrix/features/progress/presentation/providers/progress_providers.dart';
import 'package:fitrix/features/running/data/run_store.dart';
import 'package:fitrix/features/running/data/run_track.dart';
import 'package:fitrix/features/workouts/data/deleted_workouts_store.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/features/workouts/presentation/providers/workouts_provider.dart';
import 'package:fitrix/features/workouts/presentation/sport_l10n.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

/// Workouts recorded by other apps and watches become completed workouts,
/// once: the id is derived from the Health record id.
class WorkoutImporter implements HealthImporter {
  WorkoutImporter(this._ref);

  final Ref _ref;

  @override
  Future<void> run(HealthSource s, DateTime from, DateTime to,
      bool Function() mayWrite) async {
    final records = await s.workouts(from, to);
    if (!mayWrite()) return;
    final platform = s.platform;
    final l10n =
        lookupAppLocalizations(Locale(_ref.read(selectedLanguageProvider)));
    final seen = <String>{};
    for (final r in records) {
      if (!mayWrite()) return;
      if (r.sourceId == fitrixHealthSourceId) continue;
      if (!r.to.isAfter(r.from)) continue;
      final id = importedWorkoutId(platform, r.uuid);
      if (!seen.add(id)) continue;
      if (_ref.read(deletedWorkoutsStoreProvider).deletedAt(id) != null) {
        continue;
      }
      final history = _ref.read(workoutHistoryProvider);
      if (history.any((w) => w.id == id)) continue;
      final sport = sportForActivity(r.activity);
      final workout = CompletedWorkout(
        id: id,
        templateId: healthImportTemplateId,
        name: sport.localizedLabel(l10n),
        sport: sport,
        startedAt: r.from,
        finishedAt: r.to,
        exercises: const [],
      );
      // Logged in FITRIX, already imported from another source, or earlier
      // in this read: the same session once is enough.
      if (history.any((w) => sameSession(workout, w))) continue;

      final meters = (r.meters ?? 0) > 0 ? r.meters : null;
      final kcal = (r.kcal ?? 0) > 0 ? r.kcal : null;
      final avgHr = await _avgHr(s, r.from, r.to);
      if (!mayWrite()) return;

      _ref.read(healthImportsProvider.notifier).put(
            id,
            HealthImport(
              source: r.sourceName,
              healthUuid: r.uuid,
              meters: meters,
              avgHr: avgHr,
              kcal: kcal,
            ),
          );
      if (sport == Sport.running) {
        final d = r.to.difference(r.from);
        _ref.read(runsProvider.notifier).put(
              id,
              RunDetails(
                startedAt: r.from,
                moving: d,
                elapsed: d,
                pauses: 0,
                meters: meters ?? 0,
                splits: const [],
                route: const [],
                templateId: healthImportTemplateId,
              ),
            );
      }
      _ref.read(workoutHistoryProvider.notifier).addImported(workout);
    }
  }

  /// Mean of the heart-rate samples inside [from, to], rounded.
  static Future<int?> _avgHr(HealthSource s, DateTime from, DateTime to) async {
    try {
      final inside = [
        for (final x in await s.heartRate(from, to))
          if (!x.to.isBefore(from) && !x.to.isAfter(to)) x.value,
      ];
      if (inside.isEmpty) return null;
      return (inside.reduce((a, b) => a + b) / inside.length).round();
    } catch (_) {
      return null;
    }
  }
}

/// Weigh-ins from smart scales (anything not written by FITRIX).
class WeightImporter implements HealthImporter {
  WeightImporter(this._ref);

  final Ref _ref;

  @override
  Future<void> run(HealthSource s, DateTime from, DateTime to,
      bool Function() mayWrite) async {
    final samples = await s.weightKg(from, to);
    final latest = <String, HealthSample>{};
    for (final x in samples) {
      if (x.sourceId == fitrixHealthSourceId) continue;
      if (x.value < BodyWeightStore.minKg || x.value > BodyWeightStore.maxKg) {
        continue;
      }
      final k = dayKey(x.to);
      final cur = latest[k];
      if (cur == null || x.to.isAfter(cur.to)) latest[k] = x;
    }
    if (latest.isEmpty || !mayWrite()) return;
    final list = latest.values.toList()..sort((a, b) => a.to.compareTo(b.to));
    await _ref.read(bodyWeightProvider.notifier).importWeighIns([
      for (final x in list) WeighIn(at: x.to, kg: x.value),
    ]);
    await _remember(latest.keys);
  }

  /// Prefs: day keys that got an imported weigh-in, newest 60.
  static const importedKey = 'health_weight_imported_v1';
  static const keepDays = 60;

  Future<void> _remember(Iterable<String> days) async {
    final prefs = _ref.read(sharedPreferencesProvider);
    var all = <String>{...days};
    try {
      final raw = prefs.getString(importedKey);
      if (raw != null) all.addAll((jsonDecode(raw) as List).cast<String>());
    } catch (_) {}
    final sorted = all.toList()..sort();
    final kept = sorted.length > keepDays
        ? sorted.sublist(sorted.length - keepDays)
        : sorted;
    await prefs.setString(importedKey, jsonEncode(kept));
  }
}
