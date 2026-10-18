import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fitrix/core/text/normalize.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

/// Tonnes with one decimal in the user's number format: "4.1".
String formatTonnes(BuildContext context, double kg) =>
    NumberFormat('#,##0.0', Localizations.localeOf(context).toString())
        .format(kg / 1000);

bool _sameName(String a, String b) => normalizeName(a) == normalizeName(b);

/// "72.5 × 8" for a set, "BW × 8" for a bodyweight one.
String formatSetLoad(BuildContext context, WorkoutSet s) {
  final kg = s.kg > 0
      ? formatKg(s.kg)
      : AppLocalizations.of(context).workoutBodyweight;
  return '$kg × ${s.reps}';
}

/// The most recent finished workout's sets of [name], or null.
List<WorkoutSet>? lastSetsOf(List<CompletedWorkout> history, String name) {
  for (final w in history) {
    for (final e in w.exercises) {
      if (_sameName(e.name, name)) return e.sets;
    }
  }
  return null;
}
