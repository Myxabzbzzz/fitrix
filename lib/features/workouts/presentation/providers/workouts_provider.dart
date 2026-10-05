import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/features/workouts/data/workout_catalog.dart';

final workoutTemplatesProvider =
    StateNotifierProvider<WorkoutTemplatesNotifier, List<WorkoutTemplate>>(
  (ref) => WorkoutTemplatesNotifier(),
);

final workoutsForSportProvider =
    Provider.family<List<WorkoutTemplate>, Sport>((ref, sport) {
  return ref
      .watch(workoutTemplatesProvider)
      .where((w) => w.sport == sport)
      .toList();
});

final activeWorkoutProvider =
    StateNotifierProvider<ActiveWorkoutNotifier, ActiveWorkout?>(
  (ref) => ActiveWorkoutNotifier(),
);

/// Whether the active workout sheet is expanded (full table) or collapsed
/// to the mini bar above the tab bar.
final activeWorkoutExpandedProvider = StateProvider<bool>((ref) => false);

class WorkoutTemplatesNotifier extends StateNotifier<List<WorkoutTemplate>> {
  final Uuid _uuid = const Uuid();

  WorkoutTemplatesNotifier() : super(WorkoutCatalog.defaults);

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
      ),
    ];
  }

  void update(WorkoutTemplate template) {
    state = [
      for (final w in state) w.id == template.id ? template : w,
    ];
  }

  void remove(String id) {
    state = state.where((w) => w.id != id).toList();
  }
}

class ActiveWorkoutNotifier extends StateNotifier<ActiveWorkout?> {
  ActiveWorkoutNotifier() : super(null);

  void start(WorkoutTemplate template) {
    state = ActiveWorkout(
      template: template,
      startedAt: DateTime.now(),
      exercises: template.exercises,
    );
  }

  void finish() => state = null;

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
