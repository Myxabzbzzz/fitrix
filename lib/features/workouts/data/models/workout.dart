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

  WorkoutSet copyWith({
    double? previousKg,
    int? previousReps,
    double? kg,
    int? reps,
    bool? done,
  }) =>
      WorkoutSet(
        previousKg: previousKg ?? this.previousKg,
        previousReps: previousReps ?? this.previousReps,
        kg: kg ?? this.kg,
        reps: reps ?? this.reps,
        done: done ?? this.done,
      );

  Map<String, dynamic> toJson() => {
        'previousKg': previousKg,
        'previousReps': previousReps,
        'kg': kg,
        'reps': reps,
        'done': done,
      };

  factory WorkoutSet.fromJson(Map<String, dynamic> json) => WorkoutSet(
        previousKg: (json['previousKg'] as num).toDouble(),
        previousReps: json['previousReps'] as int,
        kg: (json['kg'] as num).toDouble(),
        reps: json['reps'] as int,
        done: json['done'] as bool? ?? false,
      );
}

class Exercise {
  final String name;
  final List<WorkoutSet> sets;

  const Exercise({required this.name, required this.sets});

  Exercise copyWith({String? name, List<WorkoutSet>? sets}) =>
      Exercise(name: name ?? this.name, sets: sets ?? this.sets);

  Map<String, dynamic> toJson() => {
        'name': name,
        'sets': [for (final s in sets) s.toJson()],
      };

  factory Exercise.fromJson(Map<String, dynamic> json) => Exercise(
        name: json['name'] as String,
        sets: [
          for (final s in json['sets'] as List)
            WorkoutSet.fromJson(s as Map<String, dynamic>),
        ],
      );
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

  Map<String, dynamic> toJson() => {
        'id': id,
        'sport': sport.name,
        'name': name,
        'focus': focus,
        'estimatedMinutes': estimatedDuration.inMinutes,
        'exercises': [for (final e in exercises) e.toJson()],
      };

  factory WorkoutTemplate.fromJson(Map<String, dynamic> json) =>
      WorkoutTemplate(
        id: json['id'] as String,
        sport: Sport.fromName(json['sport'] as String),
        name: json['name'] as String,
        focus: json['focus'] as String,
        estimatedDuration: Duration(minutes: json['estimatedMinutes'] as int),
        exercises: [
          for (final e in json['exercises'] as List)
            Exercise.fromJson(e as Map<String, dynamic>),
        ],
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

  Map<String, dynamic> toJson() => {
        'template': template.toJson(),
        'startedAt': startedAt.toIso8601String(),
        'exercises': [for (final e in exercises) e.toJson()],
      };

  factory ActiveWorkout.fromJson(Map<String, dynamic> json) => ActiveWorkout(
        template: WorkoutTemplate.fromJson(
          json['template'] as Map<String, dynamic>,
        ),
        startedAt: DateTime.parse(json['startedAt'] as String),
        exercises: [
          for (final e in json['exercises'] as List)
            Exercise.fromJson(e as Map<String, dynamic>),
        ],
      );
}

/// A finished workout kept in history. Only completed sets are stored.
class CompletedWorkout {
  final String templateId;
  final String name;
  final Sport sport;
  final DateTime startedAt;
  final DateTime finishedAt;
  final List<Exercise> exercises;

  const CompletedWorkout({
    required this.templateId,
    required this.name,
    required this.sport,
    required this.startedAt,
    required this.finishedAt,
    required this.exercises,
  });

  factory CompletedWorkout.from(ActiveWorkout workout, DateTime finishedAt) {
    return CompletedWorkout(
      templateId: workout.template.id,
      name: workout.template.name,
      sport: workout.template.sport,
      startedAt: workout.startedAt,
      finishedAt: finishedAt,
      exercises: [
        for (final e in workout.exercises)
          if (e.sets.any((s) => s.done))
            e.copyWith(sets: e.sets.where((s) => s.done).toList()),
      ],
    );
  }

  Duration get duration => finishedAt.difference(startedAt);

  int get setCount => exercises.fold(0, (sum, e) => sum + e.sets.length);

  Map<String, dynamic> toJson() => {
        'templateId': templateId,
        'name': name,
        'sport': sport.name,
        'startedAt': startedAt.toIso8601String(),
        'finishedAt': finishedAt.toIso8601String(),
        'exercises': [for (final e in exercises) e.toJson()],
      };

  factory CompletedWorkout.fromJson(Map<String, dynamic> json) =>
      CompletedWorkout(
        templateId: json['templateId'] as String,
        name: json['name'] as String,
        sport: Sport.fromName(json['sport'] as String),
        startedAt: DateTime.parse(json['startedAt'] as String),
        finishedAt: DateTime.parse(json['finishedAt'] as String),
        exercises: [
          for (final e in json['exercises'] as List)
            Exercise.fromJson(e as Map<String, dynamic>),
        ],
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
