import 'package:fitrix/core/time/day_key.dart';
import 'package:fitrix/features/exercises/data/exercise_catalog.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';

enum SleepQuality { poor, ok, good }

enum Soreness { none, light, medium, strong }

/// Energy: low / ok / high. Stress: low / ok (medium) / high.
enum Level3 { low, ok, high }

enum BodyArea { legs, back, chest, arms, shoulders }

enum ReadinessLabel { ready, trainLight, rest }

/// One morning check-in.
class CheckIn {
  final DateTime at;
  final Duration sleep;
  final SleepQuality quality;
  final Soreness soreness;
  final Set<BodyArea> sore;
  final Level3 energy;
  final Level3 stress;

  const CheckIn({
    required this.at,
    required this.sleep,
    required this.quality,
    required this.soreness,
    required this.sore,
    required this.energy,
    required this.stress,
  });

  Map<String, dynamic> toJson() => {
        'at': at.toIso8601String(),
        'sleepMinutes': sleep.inMinutes,
        'quality': quality.name,
        'soreness': soreness.name,
        'sore': [for (final a in sore) a.name],
        'energy': energy.name,
        'stress': stress.name,
      };

  static T _enum<T extends Enum>(List<T> values, Object? name, T fallback) {
    for (final v in values) {
      if (v.name == name) return v;
    }
    return fallback;
  }

  factory CheckIn.fromJson(Map<String, dynamic> j) => CheckIn(
        at: DateTime.parse(j['at'] as String),
        sleep: Duration(minutes: (j['sleepMinutes'] as num).toInt()),
        quality: _enum(SleepQuality.values, j['quality'], SleepQuality.ok),
        soreness: _enum(Soreness.values, j['soreness'], Soreness.none),
        sore: {
          for (final a in (j['sore'] as List? ?? const []))
            _enum(BodyArea.values, a, BodyArea.legs),
        },
        energy: _enum(Level3.values, j['energy'], Level3.ok),
        stress: _enum(Level3.values, j['stress'], Level3.ok),
      );
}

typedef ReadinessFactor = ({String factor, int delta});

class Readiness {
  final int score;

  /// In order: sleep, soreness, energy, stress, load.
  final List<ReadinessFactor> factors;
  final ReadinessLabel label;

  const Readiness(this.score, this.factors, this.label);
}

/// Factor keys used in [Readiness.factors].
abstract final class ReadinessFactorKey {
  static const sleep = 'sleep',
      soreness = 'soreness',
      energy = 'energy',
      stress = 'stress',
      load = 'load';
}

Readiness readiness(CheckIn c, {required int hardDaysLast7}) {
  final hours = c.sleep.inMinutes / 60;
  final sleepDelta = switch (c.quality) {
        SleepQuality.poor => -10,
        SleepQuality.ok => 0,
        SleepQuality.good => 5,
      } +
      ((hours - 7) * 6).round().clamp(-12, 6);
  final sorenessDelta = switch (c.soreness) {
    Soreness.none => 0,
    Soreness.light => -4,
    Soreness.medium => -12,
    Soreness.strong => -20,
  };
  final energyDelta = switch (c.energy) {
    Level3.low => -8,
    Level3.ok => 0,
    Level3.high => 4,
  };
  final stressDelta = switch (c.stress) {
    Level3.low => 3,
    Level3.ok => 0,
    Level3.high => -8,
  };
  final loadDelta = hardDaysLast7 <= 2
      ? 0
      : hardDaysLast7 == 3
          ? -3
          : hardDaysLast7 == 4
              ? -5
              : -10;
  final factors = <ReadinessFactor>[
    (factor: ReadinessFactorKey.sleep, delta: sleepDelta),
    (factor: ReadinessFactorKey.soreness, delta: sorenessDelta),
    (factor: ReadinessFactorKey.energy, delta: energyDelta),
    (factor: ReadinessFactorKey.stress, delta: stressDelta),
    (factor: ReadinessFactorKey.load, delta: loadDelta),
  ];
  final score =
      (80 + factors.fold<int>(0, (s, f) => s + f.delta)).clamp(0, 100);
  final label = score >= 70
      ? ReadinessLabel.ready
      : score >= 50
          ? ReadinessLabel.trainLight
          : ReadinessLabel.rest;
  return Readiness(score, factors, label);
}

/// Calendar days (in the 7 days up to and including [now]) with at least
/// one finished workout whose session RPE is 7 or more. A workout without
/// an RPE is not a hard day.
int hardDaysLast7(List<CompletedWorkout> history, DateTime now) {
  final today = dayOf(now);
  final from = today.subtract(const Duration(days: 6));
  final days = <DateTime>{};
  for (final w in history) {
    final d = dayOf(w.finishedAt);
    if (d.isBefore(from) || d.isAfter(today)) continue;
    if ((w.sessionRpe ?? 0) >= 7) days.add(d);
  }
  return days.length;
}

/// Exercises of [today] that load a sore area, each with a similar exercise
/// that loads none of the sore areas.
List<({String from, String to})> sparingSwaps(
  WorkoutTemplate today,
  Set<BodyArea> sore,
  ExerciseCatalog catalog,
) {
  if (sore.isEmpty) return const [];
  final soreNames = {for (final a in sore) a.name};
  final inPlan = {for (final e in today.exercises) e.name.toLowerCase()};
  final swaps = <({String from, String to})>[];
  final used = <String>{};
  for (final e in today.exercises) {
    final info = catalog.byName(e.name);
    if (info == null || !info.loads.any(soreNames.contains)) continue;
    for (final c in catalog.similarTo(info)) {
      if (c.loads.isEmpty || c.loads.any(soreNames.contains)) continue;
      final key = c.name.toLowerCase();
      if (inPlan.contains(key) || used.contains(key)) continue;
      used.add(key);
      swaps.add((from: e.name, to: c.name));
      break;
    }
  }
  return swaps;
}

/// [template] with the [swaps] applied (sets are kept). The template itself
/// is not changed.
WorkoutTemplate applySwaps(
  WorkoutTemplate template,
  List<({String from, String to})> swaps,
) {
  if (swaps.isEmpty) return template;
  return template.copyWith(exercises: [
    for (final e in template.exercises)
      swaps.any((s) => s.from == e.name)
          ? e.copyWith(name: swaps.firstWhere((s) => s.from == e.name).to)
          : e,
  ]);
}
