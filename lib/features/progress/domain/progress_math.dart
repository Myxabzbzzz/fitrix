import 'dart:math' as math;

import 'package:fitrix/core/text/normalize.dart';
import 'package:fitrix/core/time/day_key.dart';
import 'package:fitrix/features/exercises/data/exercise_catalog.dart';
import 'package:fitrix/features/nutrition/data/nutrition_targets.dart';
import 'package:fitrix/features/plan/data/week_plan.dart' show weekStartOf;
import 'package:fitrix/features/progress/data/body_weight_store.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/features/workouts/domain/training_math.dart';

/// Whole calendar days from [a] to [b] (DST-safe).
int daysBetween(DateTime a, DateTime b) => DateTime.utc(b.year, b.month, b.day)
    .difference(DateTime.utc(a.year, a.month, a.day))
    .inDays;

/// Σ [CompletedWorkout.load] per local day, oldest first.
List<DailyLoad> dailyLoads(List<CompletedWorkout> history) {
  final byDay = <DateTime, int>{};
  for (final w in history) {
    final day = dayOf(w.finishedAt);
    byDay[day] = (byDay[day] ?? 0) + w.load;
  }
  final days = byDay.keys.toList()..sort();
  return [for (final d in days) DailyLoad(d, byDay[d]!)];
}

/// Total load of each Monday-Sunday week, index 0 = the week containing [today],
/// 1 = the week before, and so on.
List<int> weeklyTotals(List<DailyLoad> days, DateTime today, int weeks) {
  final start = weekStartOf(today);
  final totals = List.filled(weeks, 0);
  for (final d in days) {
    final offset = daysBetween(start, d.day);
    if (offset >= 0) {
      if (offset < 7) totals[0] += d.load;
    } else {
      final i = (-offset + 6) ~/ 7;
      if (i < weeks) totals[i] += d.load;
    }
  }
  return totals;
}

/// Average of the four complete weeks before the current one; null when
/// none of them has any load.
double? usualWeeklyLoad(List<DailyLoad> days, DateTime today) {
  final t = weeklyTotals(days, today, 5).skip(1).toList();
  final sum = t.fold<int>(0, (a, b) => a + b);
  return sum == 0 ? null : sum / t.length;
}

/// The next-week aim: the four-week average rounded to 100; null with none.
int? nextWeekAim(List<DailyLoad> days, DateTime today) {
  final usual = usualWeeklyLoad(days, today);
  if (usual == null) return null;
  return (usual / 100).round() * 100;
}

/// Weekly weight change in kg: least-squares slope over the weigh-ins of the
/// last [weeks] weeks, times 7. Null with fewer than 2 weigh-ins or when
/// they span less than 7 days.
double? weeklyTrendKg(List<WeighIn> w, DateTime now, {int weeks = 8}) {
  final from = dayOf(now).subtract(Duration(days: weeks * 7));
  final pts = [
    for (final e in w)
      if (!e.at.isBefore(from) &&
          !e.at.isAfter(now.add(const Duration(days: 1))))
        e,
  ];
  if (pts.length < 2) return null;
  double x(WeighIn e) =>
      e.at.millisecondsSinceEpoch / Duration.millisecondsPerDay;
  final xs = pts.map(x).toList();
  if (xs.reduce(math.max) - xs.reduce(math.min) < 7) return null;
  final mx = xs.reduce((a, b) => a + b) / xs.length;
  final my = pts.map((e) => e.kg).reduce((a, b) => a + b) / pts.length;
  var num = 0.0, den = 0.0;
  for (var i = 0; i < pts.length; i++) {
    num += (xs[i] - mx) * (pts[i].kg - my);
    den += (xs[i] - mx) * (xs[i] - mx);
  }
  return den == 0 ? null : num / den * 7;
}

/// Target weekly weight change per goal, kg.
double targetRateKg(Goal goal) => switch (goal) {
      Goal.loseFat => -0.5,
      Goal.maintain => 0,
      Goal.leanBulk => 0.3,
    };

/// Daily kcal to add (positive) or cut (negative) to bring the trend to the
/// goal's rate, rounded to 10; null when within 0.1 kg/week of it.
int? kcalAdjustment(double trendKgPerWeek, Goal goal) {
  final diff = targetRateKg(goal) - trendKgPerWeek;
  if (diff.abs() < 0.1 - 1e-9) return null;
  // Rounded to 6 places first so 494.99999999999994 counts as 495.
  final kcal = (diff * 7700 / 7 * 1e6).round() / 1e6;
  return (kcal / 10).round() * 10;
}

const strengthLevels = [
  'beginner',
  'novice',
  'intermediate',
  'advanced',
  'elite',
];

// novice, intermediate, advanced, elite as multiples of body weight (male).
const _bands = <String, List<double>>{
  'bench': [0.75, 1.0, 1.5, 2.0],
  'squat': [1.0, 1.5, 2.0, 2.5],
  'deadlift': [1.25, 1.75, 2.5, 3.0],
  'row': [0.6, 0.9, 1.25, 1.6],
  'ohp': [0.5, 0.7, 1.0, 1.3],
};

const femaleFactor = 0.65;

class StrengthInfo {
  /// Index into [strengthLevels].
  final int index;
  final double ratio;

  /// Ratio (x body weight) of the next band, null at the top.
  final double? nextRatio;
  const StrengthInfo(this.index, this.ratio, this.nextRatio);
  String get level => strengthLevels[index];
}

/// Strength level of [e1rm] for [lift] (bench, squat, deadlift, row, ohp).
/// Bands are for men; women's are 0.65 of them. Null for an unknown lift or
/// no body weight.
StrengthInfo? strengthInfo(String lift, double e1rm, double bodyKg,
    {bool female = false}) {
  final bands = _bands[lift];
  if (bands == null || bodyKg <= 0) return null;
  final f = female ? femaleFactor : 1.0;
  final ratio = e1rm / bodyKg;
  var index = 0;
  for (final b in bands) {
    if (ratio >= b * f) index++;
  }
  return StrengthInfo(
      index, ratio, index < bands.length ? bands[index] * f : null);
}

/// Catalog ids of the five barbell lifts that have strength standards.
const _strengthLiftIds = {
  'bench-press': 'bench',
  'back-squat': 'squat',
  'deadlift': 'deadlift',
  'barbell-row': 'row',
  'overhead-press': 'ohp',
};

/// The lift key ([_bands]) an exercise counts as, or null. Resolved through
/// the catalog so aliases work and machine / dumbbell / front variants get
/// no barbell standard. Null without a catalog.
String? liftKeyFor(String exercise, ExerciseCatalog? catalog) =>
    _strengthLiftIds[catalog?.byName(exercise)?.id];

/// A record with the sport of the workout it was set in.
class RecordEntry {
  final PersonalRecord record;
  final Sport sport;
  const RecordEntry(this.record, this.sport);
}

/// Every record ever set (against all earlier workouts, any sport), oldest
/// first.
List<RecordEntry> recordEntries(List<CompletedWorkout> history) {
  final sorted = [...history]
    ..sort((a, b) => a.startedAt.compareTo(b.startedAt));
  return [
    for (var i = 0; i < sorted.length; i++)
      for (final r in recordsIn(sorted[i], sorted.sublist(0, i)))
        RecordEntry(r, sorted[i].sport),
  ];
}

/// Longest run of consecutive Monday-Sunday weeks with at least one record.
int bestRecordStreak(List<RecordEntry> records) {
  final weeks = {
    for (final r in records)
      daysBetween(DateTime(2000, 1, 1), weekStartOf(r.record.date)) ~/ 7,
  }.toList()
    ..sort();
  var best = 0, run = 0;
  int? prev;
  for (final w in weeks) {
    run = prev != null && w == prev + 1 ? run + 1 : 1;
    best = math.max(best, run);
    prev = w;
  }
  return best;
}

/// One lift's sessions: the best estimated 1RM of each workout.
class LiftPoint {
  final DateTime date;
  final double e1rm;
  final double kg;
  final int reps;
  const LiftPoint(this.date, this.e1rm, this.kg, this.reps);
}

/// Identity of an exercise: its catalog id and name when [raw] resolves
/// (names and aliases), else the lowercased name.
({String key, String name}) canonicalLift(
    String raw, ExerciseCatalog? catalog) {
  final info = catalog?.byName(raw);
  return info != null
      ? (key: info.id, name: info.name)
      : (key: normalizeName(raw), name: raw.trim());
}

/// Exercises with weighted working sets in [history], most trained first,
/// as (display name, sessions). Aliases of one catalog entry are one lift.
List<({String name, int sessions})> liftsIn(
    List<CompletedWorkout> history, ExerciseCatalog? catalog) {
  final names = <String, String>{};
  final counts = <String, int>{};
  for (final w in history) {
    final seen = <String>{};
    for (final e in w.exercises) {
      final has = e.sets.any((s) => !s.warmup && s.kg > 0 && s.reps > 0);
      if (!has) continue;
      final id = canonicalLift(e.name, catalog);
      names.putIfAbsent(id.key, () => id.name);
      if (seen.add(id.key)) counts[id.key] = (counts[id.key] ?? 0) + 1;
    }
  }
  final keys = counts.keys.toList()
    ..sort((a, b) => counts[b]!.compareTo(counts[a]!));
  return [for (final k in keys) (name: names[k]!, sessions: counts[k]!)];
}

/// Sessions of [exercise], oldest first.
List<LiftPoint> liftSeries(
    List<CompletedWorkout> history, String exercise, ExerciseCatalog? catalog) {
  final k = canonicalLift(exercise, catalog).key;
  final out = <LiftPoint>[];
  for (final w in history) {
    WorkoutSet? best;
    for (final e in w.exercises) {
      if (canonicalLift(e.name, catalog).key != k) continue;
      for (final s in e.sets) {
        if (s.warmup || s.kg <= 0 || s.reps <= 0) continue;
        if (best == null || e1rm(s.kg, s.reps) > e1rm(best.kg, best.reps)) {
          best = s;
        }
      }
    }
    if (best != null) {
      out.add(LiftPoint(
          w.finishedAt, e1rm(best.kg, best.reps), best.kg, best.reps));
    }
  }
  out.sort((a, b) => a.date.compareTo(b.date));
  return out;
}

/// Weekly e1RM change in kg over the last 90 days (least squares), null when
/// fewer than 2 sessions spanning at least 7 days.
double? liftWeeklySlope(List<LiftPoint> points, DateTime today) {
  final from = dayOf(today).subtract(const Duration(days: 90));
  final p = [
    for (final e in points)
      if (!e.date.isBefore(from)) e
  ];
  if (p.length < 2) return null;
  final xs = [for (final e in p) daysBetween(from, e.date).toDouble()];
  if (xs.last - xs.first < 7) return null;
  final mx = xs.reduce((a, b) => a + b) / xs.length;
  final my = p.map((e) => e.e1rm).reduce((a, b) => a + b) / p.length;
  var n = 0.0, d = 0.0;
  for (var i = 0; i < p.length; i++) {
    n += (xs[i] - mx) * (p[i].e1rm - my);
    d += (xs[i] - mx) * (xs[i] - mx);
  }
  return d == 0 ? null : n / d * 7;
}
