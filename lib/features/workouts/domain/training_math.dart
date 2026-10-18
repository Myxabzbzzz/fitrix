import 'package:fitrix/core/text/normalize.dart';
import 'package:fitrix/core/time/day_key.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';

/// Estimated one-rep max (Epley). One rep is the weight itself; no reps is 0.
double e1rm(double kg, int reps) {
  if (reps <= 0) return 0;
  if (reps == 1) return kg;
  return kg * (1 + reps / 30);
}

/// Session load in arbitrary units: RPE times whole minutes.
int sessionLoad(int rpe, Duration duration) => rpe * duration.inMinutes;

// The one place that excludes warm-ups.
// History only holds done sets, so records don't need the done check.
bool _isWorking(WorkoutSet s, {bool requireDone = true}) =>
    !s.warmup && (!requireDone || s.done);

/// Total kg lifted in done working sets.
double volumeKg(Iterable<Exercise> exercises) {
  var total = 0.0;
  for (final e in exercises) {
    for (final s in e.sets) {
      if (_isWorking(s)) total += s.kg * s.reps;
    }
  }
  return total;
}

class DailyLoad {
  final DateTime day;
  final int load;
  const DailyLoad(this.day, this.load);
}

enum AcwrBand { low, sweetSpot, risky }

class LoadSummary {
  final double fitness;
  final double fatigue;
  final double? form;
  final double? acwr;
  final AcwrBand? band;
  const LoadSummary({
    required this.fitness,
    required this.fatigue,
    this.form,
    this.acwr,
    this.band,
  });
}

/// Fatigue is the mean daily load over 7 days ending [today], fitness over 42.
/// Days without an entry count as 0; several entries on a day add up.
LoadSummary loadSummary(List<DailyLoad> days, DateTime today) {
  final end = dayOf(today);
  var sum7 = 0;
  var sum42 = 0;
  for (final d in days) {
    final day = DateTime(d.day.year, d.day.month, d.day.day);
    final ago = DateTime.utc(end.year, end.month, end.day)
        .difference(DateTime.utc(day.year, day.month, day.day))
        .inDays;
    if (ago < 0 || ago >= 42) continue;
    sum42 += d.load;
    if (ago < 7) sum7 += d.load;
  }
  final fatigue = sum7 / 7;
  final fitness = sum42 / 42;
  if (fitness == 0) {
    return LoadSummary(fitness: fitness, fatigue: fatigue);
  }
  final acwr = fatigue / fitness;
  return LoadSummary(
    fitness: fitness,
    fatigue: fatigue,
    form: (fitness - fatigue) / fitness,
    acwr: acwr,
    band: acwr < 0.8
        ? AcwrBand.low
        : acwr > 1.3
            ? AcwrBand.risky
            : AcwrBand.sweetSpot,
  );
}

enum RecordKind { e1rm, reps }

class PersonalRecord {
  final String exercise;
  final DateTime date;
  final double value;
  final double previous;
  final RecordKind kind;
  const PersonalRecord({
    required this.exercise,
    required this.date,
    required this.value,
    required this.previous,
    required this.kind,
  });
}

/// Records set in [workout] against everything in [earlier]. An exercise
/// with no earlier history sets no record.
List<PersonalRecord> recordsIn(
  CompletedWorkout workout,
  List<CompletedWorkout> earlier,
) {
  final result = <PersonalRecord>[];
  final seen = <String>{};
  for (final ex in workout.exercises) {
    if (!seen.add(normalizeName(ex.name))) continue;
    final sets = [
      for (final e in workout.exercises)
        if (normalizeName(e.name) == normalizeName(ex.name))
          ...e.sets.where((s) => _isWorking(s, requireDone: false)),
    ];
    if (sets.isEmpty) continue;
    final past = [
      for (final w in earlier)
        for (final e in w.exercises)
          if (normalizeName(e.name) == normalizeName(ex.name))
            ...e.sets.where((s) => _isWorking(s, requireDone: false)),
    ];
    if (past.isEmpty) continue;

    final bodyweight = sets.every((s) => s.kg == 0);
    if (bodyweight) {
      final best = sets.map((s) => s.reps).reduce((a, b) => a > b ? a : b);
      final prev = past.map((s) => s.reps).reduce((a, b) => a > b ? a : b);
      if (best > prev) {
        result.add(PersonalRecord(
          exercise: ex.name,
          date: workout.finishedAt,
          value: best.toDouble(),
          previous: prev.toDouble(),
          kind: RecordKind.reps,
        ));
      }
    } else {
      final pastWeighted = past.where((s) => s.kg > 0);
      if (pastWeighted.isEmpty) continue;
      final best = sets.map((s) => e1rm(s.kg, s.reps)).reduce(_max);
      final prev = pastWeighted.map((s) => e1rm(s.kg, s.reps)).reduce(_max);
      if (best > prev) {
        result.add(PersonalRecord(
          exercise: ex.name,
          date: workout.finishedAt,
          value: best,
          previous: prev,
          kind: RecordKind.e1rm,
        ));
      }
    }
  }
  return result;
}

double _max(double a, double b) => a > b ? a : b;

/// Every record ever set, oldest first.
List<PersonalRecord> allRecords(List<CompletedWorkout> history) {
  final sorted = [...history]
    ..sort((a, b) => a.startedAt.compareTo(b.startedAt));
  return [
    for (var i = 0; i < sorted.length; i++)
      ...recordsIn(sorted[i], sorted.sublist(0, i)),
  ];
}

/// Next session's weight: add 2.5 kg when every set was completed.
double? suggestNextKg(List<WorkoutSet> lastSets) {
  final working = lastSets.where((s) => _isWorking(s, requireDone: false));
  if (working.isEmpty) return null;
  final best = working.map((s) => s.kg).reduce(_max);
  if (best == 0) return null; // bodyweight
  return working.every((s) => s.done) ? best + 2.5 : best;
}

/// Nearest 2.5 kg.
double roundToPlate(double kg) => (kg / 2.5).round() * 2.5;

/// Two warm-up sets for a working weight: about 55% x 10 and 75% x 5,
/// rounded to the plate.
List<({double kg, int reps})> warmupPlan(double workingKg) => [
      (kg: roundToPlate(workingKg * 0.55), reps: 10),
      (kg: roundToPlate(workingKg * 0.75), reps: 5),
    ];

/// The best done working set: highest e1RM; bodyweight sets (0 kg) compare
/// by reps. Null when there is none.
WorkoutSet? bestSet(Iterable<WorkoutSet> sets) {
  WorkoutSet? best;
  for (final s in sets) {
    if (!_isWorking(s)) continue;
    if (best == null) {
      best = s;
      continue;
    }
    final a = e1rm(s.kg, s.reps), b = e1rm(best.kg, best.reps);
    if (a > b || (a == b && s.reps > best.reps)) best = s;
  }
  return best;
}
