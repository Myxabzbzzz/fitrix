import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:fitrix/features/workouts/domain/training_math.dart';

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

  /// How hard the set felt, 1-10. Optional.
  final int? rpe;

  /// Warm-up sets are logged but never count as volume or records.
  final bool warmup;

  /// When the set was ticked off, while the workout is in progress. Used to
  /// end a forgotten workout at a sensible time (see [finishTimeFor]); not
  /// kept in history.
  final DateTime? doneAt;

  const WorkoutSet({
    required this.previousKg,
    required this.previousReps,
    required this.kg,
    required this.reps,
    this.done = false,
    this.rpe,
    this.warmup = false,
    this.doneAt,
  });

  WorkoutSet copyWith({
    double? previousKg,
    int? previousReps,
    double? kg,
    int? reps,
    bool? done,
    int? rpe,
    bool? warmup,
    DateTime? doneAt,
    bool clearDoneAt = false,
  }) =>
      WorkoutSet(
        previousKg: previousKg ?? this.previousKg,
        previousReps: previousReps ?? this.previousReps,
        kg: kg ?? this.kg,
        reps: reps ?? this.reps,
        done: done ?? this.done,
        rpe: rpe ?? this.rpe,
        warmup: warmup ?? this.warmup,
        doneAt: clearDoneAt ? null : doneAt ?? this.doneAt,
      );

  Map<String, dynamic> toJson() => {
        'previousKg': previousKg,
        'previousReps': previousReps,
        'kg': kg,
        'reps': reps,
        'done': done,
        if (rpe != null) 'rpe': rpe,
        if (warmup) 'warmup': true,
        if (doneAt != null) 'doneAt': doneAt!.toIso8601String(),
      };

  factory WorkoutSet.fromJson(Map<String, dynamic> json) => WorkoutSet(
        previousKg: (json['previousKg'] as num).toDouble(),
        previousReps: json['previousReps'] as int,
        kg: (json['kg'] as num).toDouble(),
        reps: json['reps'] as int,
        done: json['done'] as bool? ?? false,
        rpe: (json['rpe'] as num?)?.toInt(),
        warmup: json['warmup'] as bool? ?? false,
        doneAt: _parseDate(json['doneAt']),
      );
}

class Exercise {
  final String name;
  final List<WorkoutSet> sets;

  /// Rest between sets for this exercise, in seconds. Optional.
  final int? restSeconds;
  final String? note;

  const Exercise({
    required this.name,
    required this.sets,
    this.restSeconds,
    this.note,
  });

  Exercise copyWith({
    String? name,
    List<WorkoutSet>? sets,
    int? restSeconds,
    String? note,
    bool clearNote = false,
  }) =>
      Exercise(
        name: name ?? this.name,
        sets: sets ?? this.sets,
        restSeconds: restSeconds ?? this.restSeconds,
        note: clearNote ? null : note ?? this.note,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'sets': [for (final s in sets) s.toJson()],
        if (restSeconds != null) 'restSeconds': restSeconds,
        if (note != null) 'note': note,
      };

  factory Exercise.fromJson(Map<String, dynamic> json) => Exercise(
        name: json['name'] as String,
        sets: [
          for (final s in json['sets'] as List)
            WorkoutSet.fromJson(s as Map<String, dynamic>),
        ],
        restSeconds: (json['restSeconds'] as num?)?.toInt(),
        note: json['note'] as String?,
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

  /// When the plan was last changed: by the user on this device, or the
  /// server's time for a version that came from sync. Null for built-in
  /// plans nobody edited and for plans saved before sync existed; those
  /// lose to any synced version.
  final DateTime? updatedAt;

  /// Set only on deleted plans, kept as tombstones until the deletion has
  /// reached the server (see `WorkoutStorage.loadDeletedTemplates`).
  final DateTime? deletedAt;

  const WorkoutTemplate({
    required this.id,
    required this.sport,
    required this.name,
    required this.focus,
    required this.estimatedDuration,
    required this.exercises,
    this.updatedAt,
    this.deletedAt,
  });

  WorkoutTemplate copyWith({
    String? name,
    List<Exercise>? exercises,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) =>
      WorkoutTemplate(
        id: id,
        sport: sport,
        name: name ?? this.name,
        focus: focus,
        estimatedDuration: estimatedDuration,
        exercises: exercises ?? this.exercises,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt ?? this.deletedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'sport': sport.name,
        'name': name,
        'focus': focus,
        'estimatedMinutes': estimatedDuration.inMinutes,
        'exercises': [for (final e in exercises) e.toJson()],
        if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
        if (deletedAt != null) 'deletedAt': deletedAt!.toIso8601String(),
      };

  /// Reads plans saved by any app version; older ones have no timestamps.
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
        updatedAt: _parseDate(json['updatedAt']),
        deletedAt: _parseDate(json['deletedAt']),
      );
}

DateTime? _parseDate(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;

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

  /// Working sets ticked off; warm-ups don't count.
  int get completedSets => exercises.fold(
      0, (sum, e) => sum + e.sets.where((s) => s.done && !s.warmup).length);

  /// Working sets; warm-ups don't count.
  int get totalSets => exercises.fold(
      0, (sum, e) => sum + e.sets.where((s) => !s.warmup).length);

  ActiveWorkout copyWith({List<Exercise>? exercises, DateTime? startedAt}) =>
      ActiveWorkout(
        template: template,
        startedAt: startedAt ?? this.startedAt,
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

/// When a workout finished at [now] counts as finished. A workout left
/// running (its last ticked set more than 30 min before [now]) ends 15 min
/// after that set. Without set times (a workout saved by an older version)
/// it lasts at most 4 h.
DateTime finishTimeFor(ActiveWorkout workout, DateTime now) {
  DateTime? last;
  for (final e in workout.exercises) {
    for (final s in e.sets) {
      final at = s.doneAt;
      if (s.done && at != null && (last == null || at.isAfter(last))) {
        last = at;
      }
    }
  }
  if (last != null) {
    return now.difference(last) > const Duration(minutes: 30)
        ? last.add(const Duration(minutes: 15))
        : now;
  }
  final cap = workout.startedAt.add(const Duration(hours: 4));
  return now.isAfter(cap) ? cap : now;
}

/// A finished workout kept in history. Only completed sets are stored.
class CompletedWorkout {
  /// Unique id (a UUID), used to sync history between devices.
  final String id;
  final String templateId;
  final String name;
  final Sport sport;
  final DateTime startedAt;
  final DateTime finishedAt;
  final List<Exercise> exercises;

  /// How hard the whole session felt, 1-10. Local only: never sent to the
  /// server, and kept when a server copy of the workout is merged in.
  final int? sessionRpe;

  /// Without an [id] (history saved before sync existed) one is derived
  /// from the workout itself, so it's the same every time it's loaded.
  CompletedWorkout({
    String? id,
    required this.templateId,
    required this.name,
    required this.sport,
    required this.startedAt,
    required this.finishedAt,
    required this.exercises,
    this.sessionRpe,
  }) : id = id ?? legacyId(templateId, startedAt, finishedAt);

  /// Deterministic UUID (v5) for a workout stored without an id.
  static String legacyId(
    String templateId,
    DateTime startedAt,
    DateTime finishedAt,
  ) =>
      const Uuid().v5(
        _legacyNamespace,
        '$templateId|${startedAt.toIso8601String()}|'
        '${finishedAt.toIso8601String()}',
      );

  static const _legacyNamespace = '0c3a8f1e-5d0b-4c47-9a57-3f2b9d1c6e21';

  factory CompletedWorkout.from(
    ActiveWorkout workout,
    DateTime finishedAt, {
    int? sessionRpe,
  }) {
    return CompletedWorkout(
      id: const Uuid().v4(),
      templateId: workout.template.id,
      name: workout.template.name,
      sport: workout.template.sport,
      startedAt: workout.startedAt,
      finishedAt: finishedAt,
      exercises: [
        for (final e in workout.exercises)
          if (e.sets.any((s) => s.done))
            e.copyWith(sets: [
              for (final s in e.sets)
                if (s.done) s.copyWith(clearDoneAt: true),
            ]),
      ],
      sessionRpe: sessionRpe,
    );
  }

  CompletedWorkout copyWith({int? sessionRpe, List<Exercise>? exercises}) =>
      CompletedWorkout(
        id: id,
        templateId: templateId,
        name: name,
        sport: sport,
        startedAt: startedAt,
        finishedAt: finishedAt,
        exercises: exercises ?? this.exercises,
        sessionRpe: sessionRpe ?? this.sessionRpe,
      );

  /// Session load; assumes RPE 6 when the user didn't rate the session.
  int get load => sessionLoad(sessionRpe ?? 6, duration);

  bool get loadEstimated => sessionRpe == null;

  Duration get duration => finishedAt.difference(startedAt);

  /// Working sets only; warm-ups don't count.
  int get setCount => exercises.fold(
      0, (sum, e) => sum + e.sets.where((s) => !s.warmup).length);

  Map<String, dynamic> toJson() => {
        'id': id,
        'templateId': templateId,
        'name': name,
        'sport': sport.name,
        'startedAt': startedAt.toIso8601String(),
        'finishedAt': finishedAt.toIso8601String(),
        'exercises': [for (final e in exercises) e.toJson()],
        if (sessionRpe != null) 'sessionRpe': sessionRpe,
      };

  factory CompletedWorkout.fromJson(Map<String, dynamic> json) =>
      CompletedWorkout(
        id: json['id'] as String?,
        templateId: json['templateId'] as String,
        name: json['name'] as String,
        sport: Sport.fromName(json['sport'] as String),
        startedAt: DateTime.parse(json['startedAt'] as String),
        finishedAt: DateTime.parse(json['finishedAt'] as String),
        exercises: [
          for (final e in json['exercises'] as List)
            Exercise.fromJson(e as Map<String, dynamic>),
        ],
        sessionRpe: (json['sessionRpe'] as num?)?.toInt(),
      );
}

/// Formats a weight without a trailing ".0", with the app language's
/// decimal mark ("72,5" in Russian, "72.5" in English): FitrixApp keeps
/// `Intl.defaultLocale` on the app language.
String formatKg(double kg) => NumberFormat('0.#').format(kg);

/// One decimal, always shown ("110,0"), in the app language's format.
String formatOneDecimal(double v) => NumberFormat('0.0').format(v);
