import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:fitrix/core/session/session_providers.dart';
import 'package:fitrix/core/sync/local_changes.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/features/workouts/data/workout_catalog.dart';
import 'package:fitrix/features/workouts/data/workout_storage.dart';
import 'package:fitrix/features/workouts/domain/training_math.dart';

final workoutStorageProvider = Provider<WorkoutStorage>(
  (ref) => WorkoutStorage(ref.watch(sharedPreferencesProvider)),
);

/// The user's plans (deleted ones excluded). Changes are synced when signed
/// in, see `SyncEngine`.
final workoutTemplatesProvider =
    StateNotifierProvider<WorkoutTemplatesNotifier, List<WorkoutTemplate>>(
  (ref) => WorkoutTemplatesNotifier(
    ref.watch(workoutStorageProvider),
    onChanged: ref.read(localChangesProvider).notify,
  ),
);

final workoutsForSportProvider =
    Provider.family<List<WorkoutTemplate>, Sport>((ref, sport) {
  return ref
      .watch(workoutTemplatesProvider)
      .where((w) => w.sport == sport)
      .toList();
});

/// Finished workouts, newest first.
final workoutHistoryProvider =
    StateNotifierProvider<WorkoutHistoryNotifier, List<CompletedWorkout>>(
  (ref) => WorkoutHistoryNotifier(
    ref.watch(workoutStorageProvider),
    onChanged: ref.read(localChangesProvider).notify,
  ),
);

/// The finished-but-unsaved workout shown on the "Workout complete" screen.
/// Save writes it to history, Discard clears it.
final pendingCompletedWorkoutProvider =
    StateProvider<CompletedWorkout?>((ref) => null);

final activeWorkoutProvider =
    StateNotifierProvider<ActiveWorkoutNotifier, ActiveWorkout?>(
  (ref) => ActiveWorkoutNotifier(
    ref.watch(workoutStorageProvider),
    ref.read(workoutHistoryProvider.notifier),
  ),
);

/// Whether the active workout sheet is expanded (full table) or collapsed
/// to the mini bar above the tab bar.
final activeWorkoutExpandedProvider = StateProvider<bool>((ref) => false);

class WorkoutTemplatesNotifier extends StateNotifier<List<WorkoutTemplate>> {
  final WorkoutStorage _storage;
  final void Function()? _onChanged;
  final Uuid _uuid = const Uuid();

  WorkoutTemplatesNotifier(this._storage, {void Function()? onChanged})
      : _onChanged = onChanged,
        super(_storage.loadTemplates() ?? WorkoutCatalog.defaults);

  /// User changes: saved and reported for sync.
  @override
  set state(List<WorkoutTemplate> value) {
    super.state = value;
    _storage.saveTemplates(value);
    _onChanged?.call();
  }

  void add(Sport sport, String name) {
    state = [
      ...state,
      WorkoutTemplate(
        id: _uuid.v4(),
        sport: sport,
        name: name,
        focus: sport.label,
        estimatedDuration: const Duration(hours: 1),
        exercises: const [],
        updatedAt: DateTime.now(),
      ),
    ];
  }

  /// Adds ready-made plans (e.g. proposed by Felix) for [sport] in one go.
  void addAll(
      Sport sport, List<({String name, List<Exercise> exercises})> plans) {
    final now = DateTime.now();
    state = [
      ...state,
      for (final plan in plans)
        WorkoutTemplate(
          id: _uuid.v4(),
          sport: sport,
          name: plan.name,
          focus: sport.label,
          estimatedDuration: const Duration(hours: 1),
          exercises: plan.exercises,
          updatedAt: now,
        ),
    ];
  }

  void update(WorkoutTemplate template) {
    final edited = template.copyWith(updatedAt: DateTime.now());
    state = [
      for (final w in state) w.id == template.id ? edited : w,
    ];
  }

  /// Deletes the plan, keeping a tombstone until the deletion is synced.
  void remove(String id) {
    final now = DateTime.now();
    final removed = state.where((w) => w.id == id).toList();
    if (removed.isNotEmpty) {
      _storage.saveDeletedTemplates([
        ..._storage.loadDeletedTemplates().where((t) => t.id != id),
        removed.first.copyWith(updatedAt: now, deletedAt: now),
      ]);
    }
    state = state.where((w) => w.id != id).toList();
  }

  /// Undoes [remove]: puts [template] back at [index] as a fresh change, so
  /// it also wins over a deletion that already reached the server.
  void restore(WorkoutTemplate template, int index) {
    _storage.saveDeletedTemplates(_storage
        .loadDeletedTemplates()
        .where((t) => t.id != template.id)
        .toList());
    final plans = state.where((w) => w.id != template.id).toList()
      ..insert(
        index.clamp(0, state.length),
        template.copyWith(updatedAt: DateTime.now()),
      );
    state = plans;
  }

  /// Replaces plans and pending deletions with the result of a sync
  /// (not reported back as a local change).
  void applySynced(
    List<WorkoutTemplate> plans,
    List<WorkoutTemplate> tombstones,
  ) {
    super.state = plans;
    _storage.saveTemplates(plans);
    _storage.saveDeletedTemplates(tombstones);
  }
}

class WorkoutHistoryNotifier extends StateNotifier<List<CompletedWorkout>> {
  final WorkoutStorage _storage;
  final void Function()? _onChanged;

  WorkoutHistoryNotifier(this._storage, {void Function()? onChanged})
      : _onChanged = onChanged,
        super(_storage.loadHistory());

  @override
  set state(List<CompletedWorkout> value) {
    super.state = value;
    _storage.saveHistory(value);
    _onChanged?.call();
  }

  void add(CompletedWorkout workout) => state = [workout, ...state];

  /// Replaces history with the result of a sync (newest first; not
  /// reported back as a local change).
  void applySynced(List<CompletedWorkout> history) {
    super.state = history;
    _storage.saveHistory(history);
  }

  /// Most recent session of the given plan, if any.
  CompletedWorkout? lastFor(String templateId) {
    for (final w in state) {
      if (w.templateId == templateId) return w;
    }
    return null;
  }
}

class ActiveWorkoutNotifier extends StateNotifier<ActiveWorkout?> {
  final WorkoutStorage _storage;
  final WorkoutHistoryNotifier _history;

  /// Restores a workout that was in progress when the app was closed.
  ActiveWorkoutNotifier(this._storage, this._history)
      : super(_storage.loadActive());

  @override
  set state(ActiveWorkout? value) {
    super.state = value;
    _storage.saveActive(value);
  }

  /// Starts [template], pre-filling "Previous" (and today's targets) from
  /// the last time this plan was done.
  void start(WorkoutTemplate template) {
    final last = _history.lastFor(template.id);
    state = ActiveWorkout(
      template: template,
      startedAt: DateTime.now(),
      exercises: [
        for (final e in template.exercises) _withPrevious(e, last),
      ],
    );
  }

  /// Ends the workout. It's saved to history if at least one working set was
  /// completed; returns the saved workout, or null when nothing was saved.
  /// [at] is the finish time (defaults to now).
  CompletedWorkout? finish({int? sessionRpe, DateTime? at}) {
    final workout = state;
    if (workout == null) return null;
    CompletedWorkout? saved;
    if (workout.completedSets > 0) {
      saved = CompletedWorkout.from(
        workout,
        at ?? DateTime.now(),
        sessionRpe: sessionRpe,
      );
      _history.add(saved);
    }
    state = null;
    return saved;
  }

  /// Drops the workout without saving it.
  void discard() => state = null;

  void toggleSet(int exerciseIndex, int setIndex) {
    _updateSet(exerciseIndex, setIndex, (s) => s.copyWith(done: !s.done));
  }

  void setKg(int exerciseIndex, int setIndex, double kg) {
    _updateSet(exerciseIndex, setIndex, (s) => s.copyWith(kg: kg));
  }

  void setReps(int exerciseIndex, int setIndex, int reps) {
    _updateSet(exerciseIndex, setIndex, (s) => s.copyWith(reps: reps));
  }

  void addSet(int exerciseIndex) {
    final workout = state;
    if (workout == null) return;
    final exercise = workout.exercises[exerciseIndex];
    final last = exercise.sets.isNotEmpty ? exercise.sets.last : null;
    final newSet = WorkoutSet(
      previousKg: last?.kg ?? 0,
      previousReps: last?.reps ?? 10,
      kg: last?.kg ?? 0,
      reps: last?.reps ?? 10,
    );
    _replaceExercise(
      exerciseIndex,
      exercise.copyWith(sets: [...exercise.sets, newSet]),
    );
  }

  void setRpe(int exerciseIndex, int setIndex, int rpe) {
    _updateSet(exerciseIndex, setIndex, (s) => s.copyWith(rpe: rpe));
  }

  /// Adds two warm-up sets (about 55% and 75% of the first working set's
  /// weight) at the top. Does nothing for bodyweight work or when the
  /// exercise already has warm-ups.
  void addWarmupSets(int exerciseIndex) {
    final workout = state;
    if (workout == null) return;
    final exercise = workout.exercises[exerciseIndex];
    if (exercise.sets.any((s) => s.warmup)) return;
    final working = exercise.sets.where((s) => !s.warmup);
    if (working.isEmpty || working.first.kg <= 0) return;
    _replaceExercise(
      exerciseIndex,
      exercise.copyWith(sets: [
        for (final w in warmupPlan(working.first.kg))
          WorkoutSet(
            previousKg: 0,
            previousReps: 0,
            kg: w.kg,
            reps: w.reps,
            warmup: true,
          ),
        ...exercise.sets,
      ]),
    );
  }

  void removeExercise(int index) {
    final workout = state;
    if (workout == null) return;
    state =
        workout.copyWith(exercises: [...workout.exercises]..removeAt(index));
  }

  /// Moves the exercise at [from] so it ends up at index [to].
  void moveExercise(int from, int to) {
    final workout = state;
    if (workout == null || from == to) return;
    final list = [...workout.exercises];
    if (to < 0 || to >= list.length) return;
    list.insert(to, list.removeAt(from));
    state = workout.copyWith(exercises: list);
  }

  /// Swaps the exercise for [name], keeping the number of working sets and
  /// reps; weights and ticks start over, "Previous" comes from history.
  void replaceExercise(int index, String name) {
    final workout = state;
    if (workout == null) return;
    final old = workout.exercises[index];
    final fresh = Exercise(
      name: name,
      restSeconds: old.restSeconds,
      sets: [
        for (final s in old.sets.where((s) => !s.warmup))
          WorkoutSet(previousKg: 0, previousReps: 0, kg: 0, reps: s.reps),
      ],
    );
    _replaceExercise(index, _withHistory(fresh));
  }

  /// Appends exercises (3 x 10 each); "Previous" comes from history.
  void addExercises(List<String> names) {
    final workout = state;
    if (workout == null || names.isEmpty) return;
    state = workout.copyWith(exercises: [
      ...workout.exercises,
      for (final name in names)
        _withHistory(Exercise(name: name, sets: [
          for (var i = 0; i < 3; i++)
            const WorkoutSet(previousKg: 0, previousReps: 0, kg: 0, reps: 10),
        ])),
    ]);
  }

  /// An empty note removes it.
  void setNote(int exerciseIndex, String note) {
    final workout = state;
    if (workout == null) return;
    final exercise = workout.exercises[exerciseIndex];
    final text = note.trim();
    _replaceExercise(
      exerciseIndex,
      text.isEmpty
          ? exercise.copyWith(clearNote: true)
          : exercise.copyWith(note: text),
    );
  }

  void setRest(int exerciseIndex, int seconds) {
    final workout = state;
    if (workout == null) return;
    _replaceExercise(
      exerciseIndex,
      workout.exercises[exerciseIndex].copyWith(restSeconds: seconds),
    );
  }

  /// Fills "Previous" and weights from the last session that had [exercise].
  Exercise _withHistory(Exercise exercise) {
    for (final w in _history.state) {
      if (w.exercises
          .any((e) => e.name.toLowerCase() == exercise.name.toLowerCase())) {
        return _withPrevious(exercise, w);
      }
    }
    return exercise;
  }

  static Exercise _withPrevious(Exercise exercise, CompletedWorkout? last) {
    if (last == null) return exercise;
    Exercise? previous;
    for (final e in last.exercises) {
      if (e.name.toLowerCase() == exercise.name.toLowerCase()) previous = e;
    }
    if (previous == null) return exercise;
    final before = previous.sets.where((s) => !s.warmup).toList();

    return exercise.copyWith(
      sets: [
        for (var i = 0; i < exercise.sets.length; i++)
          if (i < before.length)
            exercise.sets[i].copyWith(
              previousKg: before[i].kg,
              previousReps: before[i].reps,
              kg: before[i].kg,
              reps: before[i].reps,
            )
          else
            exercise.sets[i],
      ],
    );
  }

  void _updateSet(
    int exerciseIndex,
    int setIndex,
    WorkoutSet Function(WorkoutSet) update,
  ) {
    final workout = state;
    if (workout == null) return;
    final exercise = workout.exercises[exerciseIndex];
    final sets = [...exercise.sets];
    sets[setIndex] = update(sets[setIndex]);
    _replaceExercise(exerciseIndex, exercise.copyWith(sets: sets));
  }

  void _replaceExercise(int index, Exercise exercise) {
    final workout = state!;
    final exercises = [...workout.exercises];
    exercises[index] = exercise;
    state = workout.copyWith(exercises: exercises);
  }
}
