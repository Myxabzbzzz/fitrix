import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fitrix/features/football/data/match_store.dart';
import 'package:fitrix/features/health/data/health_import_store.dart';
import 'package:fitrix/features/running/data/run_store.dart';
import 'package:fitrix/features/workouts/presentation/providers/workouts_provider.dart';

/// Session RPE rated on a detail document (run, match or Health import), by workout id.
List<Map<String, int>> _rpeSources(Ref ref) => [
      {
        for (final e in ref.read(runsProvider).entries)
          if (e.value.rpe != null) e.key: e.value.rpe!,
      },
      {
        for (final e in ref.read(matchesProvider).entries)
          if (e.value.rpe != null) e.key: e.value.rpe!,
      },
      {
        for (final e in ref.read(healthImportsProvider).entries)
          if (e.value.rpe != null) e.key: e.value.rpe!,
      },
    ];

/// Copies the RPE of run (and match) docs onto the matching workouts in
/// history when it differs. Session RPE is otherwise local-only, so this is
/// how a rating reaches another device. Not reported as a local change.
void applyDocRpe(Ref ref) {
  final rpes = <String, int>{
    for (final source in _rpeSources(ref)) ...source,
  };
  if (rpes.isEmpty) return;
  final history = ref.read(workoutHistoryProvider);
  var changed = false;
  final updated = [
    for (final w in history)
      if (rpes[w.id] != null && rpes[w.id] != w.sessionRpe)
        () {
          changed = true;
          return w.copyWith(sessionRpe: rpes[w.id]);
        }()
      else
        w,
  ];
  if (changed) {
    ref.read(workoutHistoryProvider.notifier).applySynced(updated);
  }
}
