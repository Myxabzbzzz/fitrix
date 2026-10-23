import 'package:uuid/uuid.dart';

import 'package:fitrix/core/time/day_key.dart';
import 'package:fitrix/features/football/data/match_log.dart';
import 'package:fitrix/features/health/data/health_source.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';

/// Time asleep for the night that ended on [today]: the asleep segments that
/// end in (yesterday 18:00, today 12:00], overlaps merged. Null if none.
Duration? sleepLastNight(List<SleepSegment> s, DateTime today) {
  final from = DateTime(today.year, today.month, today.day - 1, 18);
  final to = DateTime(today.year, today.month, today.day, 12);
  final spans = [
    for (final x in s)
      if (x.asleep &&
          x.to.isAfter(from) &&
          !x.to.isAfter(to) &&
          x.to.isAfter(x.from))
        x,
  ]..sort((a, b) => a.from.compareTo(b.from));
  if (spans.isEmpty) return null;
  var total = Duration.zero;
  var curFrom = spans.first.from;
  var curTo = spans.first.to;
  for (final x in spans.skip(1)) {
    if (x.from.isAfter(curTo)) {
      total += curTo.difference(curFrom);
      curFrom = x.from;
      curTo = x.to;
    } else if (x.to.isAfter(curTo)) {
      curTo = x.to;
    }
  }
  total += curTo.difference(curFrom);
  return total;
}

/// Mean of the previous (up to 28) days before [today], keyed by `dayKey`.
/// Needs at least 5 values, else null.
double? baseline(Map<String, double> byDayKey, DateTime today) {
  final values = <double>[];
  for (var i = 1; i <= 28; i++) {
    final v =
        byDayKey[dayKey(DateTime(today.year, today.month, today.day - i))];
    if (v != null) values.add(v);
  }
  if (values.length < 5) return null;
  return values.reduce((a, b) => a + b) / values.length;
}

/// Readiness delta for resting heart rate against its baseline.
int restingHrDelta(double today, double baseline) {
  final d = today - baseline;
  if (d >= 8) return -10;
  if (d >= 5) return -6;
  return 0;
}

/// Readiness delta for HRV against its baseline (same kind on both sides).
int hrvDelta(double today, double baseline) {
  if (baseline <= 0) return 0;
  final pct = (today - baseline) / baseline;
  if (pct <= -0.2) return -10;
  if (pct <= -0.1) return -6;
  if (pct >= 0.1) return 3;
  return 0;
}

class HealthSignals {
  const HealthSignals({
    this.restingHr,
    this.restingHrBaseline,
    this.hrv,
    this.hrvBaseline,
    this.hrvKind,
    this.stepsToday,
    this.steps7dAvg,
  });

  final double? restingHr, restingHrBaseline, hrv, hrvBaseline;
  final HrvKind? hrvKind;
  final int? stepsToday, steps7dAvg;
}

Sport sportForActivity(String activity) => switch (activity) {
      'RUNNING' || 'RUNNING_TREADMILL' => Sport.running,
      'BIKING' || 'BIKING_STATIONARY' => Sport.cycling,
      'SOCCER' => Sport.football,
      'DOWNHILL_SKIING' ||
      'CROSS_COUNTRY_SKIING' ||
      'SKIING' ||
      'SNOWBOARDING' ||
      'SKATING' ||
      'ICE_SKATING' =>
        Sport.winterSports,
      'TRADITIONAL_STRENGTH_TRAINING' ||
      'FUNCTIONAL_STRENGTH_TRAINING' ||
      'STRENGTH_TRAINING' ||
      'WEIGHTLIFTING' =>
        Sport.gym,
      _ => Sport.fitness,
    };

/// Fixed forever: changing it would re-import every workout as a new one.
const healthImportNamespace = '7b1d4c52-3e8a-4f6b-9a0d-5c2e8f1b6a37';

String importedWorkoutId(HealthPlatform p, String healthUuid) =>
    const Uuid().v5(healthImportNamespace, '${p.name}:$healthUuid');

/// Whether [imported] (read from Health) and [own] are the same session.
/// Same sport and either they overlap by more than half of [imported]'s
/// duration, or [own] is a football log (its times are made up: only the
/// day and the minutes are real) on the same calendar day with 50-150 % of
/// [imported]'s minutes.
bool sameSession(CompletedWorkout imported, CompletedWorkout own) {
  if (imported.sport != own.sport) return false;
  final dur = imported.duration;
  if (dur <= Duration.zero) return false;
  final start = own.startedAt.isAfter(imported.startedAt)
      ? own.startedAt
      : imported.startedAt;
  final end = own.finishedAt.isBefore(imported.finishedAt)
      ? own.finishedAt
      : imported.finishedAt;
  if (end.difference(start) * 2 > dur) return true;
  if (own.templateId != footballLogTemplateId) return false;
  if (dayOf(own.startedAt.toLocal()) != dayOf(imported.startedAt.toLocal())) {
    return false;
  }
  final ratio = own.duration.inSeconds / dur.inSeconds;
  return ratio >= 0.5 && ratio <= 1.5;
}
