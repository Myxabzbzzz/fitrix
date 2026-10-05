import 'package:fitrix/features/workouts/data/models/workout.dart';

/// Starter workout plans shown until the user (or Felix) creates their own.
class WorkoutCatalog {
  WorkoutCatalog._();

  static List<WorkoutSet> _sets(double kg, int reps, {int count = 4}) =>
      List.generate(
        count,
        (_) => WorkoutSet(previousKg: kg, previousReps: reps, kg: kg, reps: reps),
      );

  static final List<WorkoutTemplate> defaults = [
    WorkoutTemplate(
      id: 'gym-chest-biceps',
      sport: Sport.gym,
      name: 'Chest and Biceps',
      focus: 'Upper body',
      estimatedDuration: const Duration(hours: 1, minutes: 43),
      exercises: [
        Exercise(name: 'Biceps curl', sets: _sets(24, 10)),
        Exercise(name: 'Bench press', sets: _sets(80, 10)),
        Exercise(name: 'Incline dumbbell press', sets: _sets(28, 10)),
        Exercise(name: 'Hammer curl', sets: _sets(18, 12, count: 3)),
        Exercise(name: 'Cable fly', sets: _sets(15, 12, count: 3)),
        Exercise(name: 'Push-ups', sets: _sets(0, 20, count: 3)),
        Exercise(name: 'Concentration curl', sets: _sets(12, 12, count: 3)),
      ],
    ),
    WorkoutTemplate(
      id: 'gym-back-triceps',
      sport: Sport.gym,
      name: 'Back and Triceps',
      focus: 'Upper body',
      estimatedDuration: const Duration(hours: 1, minutes: 20),
      exercises: [
        Exercise(name: 'Pull-ups', sets: _sets(0, 8)),
        Exercise(name: 'Barbell row', sets: _sets(60, 10)),
        Exercise(name: 'Triceps pushdown', sets: _sets(25, 12)),
        Exercise(name: 'Skull crushers', sets: _sets(20, 10, count: 3)),
      ],
    ),
    WorkoutTemplate(
      id: 'gym-legs',
      sport: Sport.gym,
      name: 'Legs',
      focus: 'Lower body',
      estimatedDuration: const Duration(hours: 1, minutes: 10),
      exercises: [
        Exercise(name: 'Squat', sets: _sets(90, 8)),
        Exercise(name: 'Romanian deadlift', sets: _sets(70, 10)),
        Exercise(name: 'Leg press', sets: _sets(140, 12)),
        Exercise(name: 'Calf raise', sets: _sets(40, 15, count: 3)),
      ],
    ),
    WorkoutTemplate(
      id: 'fitness-full-body',
      sport: Sport.fitness,
      name: 'Full body',
      focus: 'Full body',
      estimatedDuration: const Duration(minutes: 45),
      exercises: [
        Exercise(name: 'Burpees', sets: _sets(0, 15, count: 3)),
        Exercise(name: 'Kettlebell swing', sets: _sets(16, 20, count: 3)),
        Exercise(name: 'Plank (sec)', sets: _sets(0, 60, count: 3)),
      ],
    ),
  ];
}
