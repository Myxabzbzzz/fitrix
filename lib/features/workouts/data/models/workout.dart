/// Sports shown on "My workouts" and as pills on the sport / progress screens.
enum Sport {
  gym('Gym', 'GYM', 'assets/images/sport_gym.png'),
  fitness('Fitness', 'FITNESS', 'assets/images/sport_fitness.png'),
  cycling('Cycling', 'CYCLING', 'assets/images/sport_cycling.png'),
  running('Running', 'RUNNING', null),
  football('Football', 'FOOTBALL', null),
  winterSports('Winter sports', 'WINTER\nSPORTS', null);

  final String label;
  final String tileLabel;
  final String? imageAsset;

  const Sport(this.label, this.tileLabel, this.imageAsset);

  static Sport fromName(String name) =>
      Sport.values.firstWhere((s) => s.name == name, orElse: () => Sport.gym);
}

/// A single set: what was done last time and what is done now.
class WorkoutSet {
  final double previousKg;
  final int previousReps;
  final double kg;
  final int reps;
  final bool done;

  const WorkoutSet({
    required this.previousKg,
    required this.previousReps,
    required this.kg,
    required this.reps,
    this.done = false,
  });

  WorkoutSet copyWith({double? kg, int? reps, bool? done}) => WorkoutSet(
        previousKg: previousKg,
        previousReps: previousReps,
        kg: kg ?? this.kg,
        reps: reps ?? this.reps,
        done: done ?? this.done,
      );
}

class Exercise {
  final String name;
  final List<WorkoutSet> sets;

  const Exercise({required this.name, required this.sets});

  Exercise copyWith({String? name, List<WorkoutSet>? sets}) =>
      Exercise(name: name ?? this.name, sets: sets ?? this.sets);
}

/// A saved workout plan, e.g. "Chest and Biceps".
class WorkoutTemplate {
  final String id;
  final Sport sport;
  final String name;
  final String focus;
  final Duration estimatedDuration;
  final List<Exercise> exercises;

  const WorkoutTemplate({
    required this.id,
    required this.sport,
    required this.name,
    required this.focus,
    required this.estimatedDuration,
    required this.exercises,
  });

  WorkoutTemplate copyWith({String? name, List<Exercise>? exercises}) =>
      WorkoutTemplate(
        id: id,
        sport: sport,
        name: name ?? this.name,
        focus: focus,
        estimatedDuration: estimatedDuration,
        exercises: exercises ?? this.exercises,
      );
}

/// A workout in progress, started from a [WorkoutTemplate].
class ActiveWorkout {
  final WorkoutTemplate template;
  final DateTime startedAt;
  final List<Exercise> exercises;

  const ActiveWorkout({
    required this.template,
    required this.startedAt,
    required this.exercises,
  });

  int get completedSets =>
      exercises.fold(0, (sum, e) => sum + e.sets.where((s) => s.done).length);

  int get totalSets => exercises.fold(0, (sum, e) => sum + e.sets.length);

  ActiveWorkout copyWith({List<Exercise>? exercises}) => ActiveWorkout(
        template: template,
        startedAt: startedAt,
        exercises: exercises ?? this.exercises,
      );
}

/// Formats a duration like the design does: "1h 43m 22s" / "1h 43m".
String formatDuration(Duration d, {bool withSeconds = true}) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  final s = d.inSeconds.remainder(60);
  final parts = <String>[
    if (h > 0) '${h}h',
    if (h > 0 || m > 0 || !withSeconds) '${m}m',
    if (withSeconds) '${s}s',
  ];
  return parts.join(' ');
}

/// Formats a weight without a trailing ".0".
String formatKg(double kg) =>
    kg == kg.roundToDouble() ? kg.toInt().toString() : kg.toStringAsFixed(1);
