import 'package:fitrix/core/i18n/catalog_text.dart';
import 'package:fitrix/features/exercises/data/exercise_catalog.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/features/workouts/domain/training_math.dart';

/// Working sets per muscle group per week the user is aiming for.
const int kWeeklySetsTarget = 14;

/// Exercises matching the filters. [query] matches the name or an alias,
/// in English or in the app language ([text]).
List<ExerciseInfo> filterExercises(
  Iterable<ExerciseInfo> all, {
  MuscleGroup? group,
  Equipment? equipment,
  String query = '',
  CatalogText? text,
}) {
  final q = query.trim().toLowerCase();
  final t = text ?? CatalogText.english;
  return [
    for (final e in all)
      if ((group == null || e.group == group) &&
          (equipment == null || e.equipment == equipment) &&
          t.exerciseMatches(e, q))
        e,
  ];
}

/// One finished workout's work on one exercise.
class ExerciseSession {
  final DateTime date;
  final List<WorkoutSet> sets;
  const ExerciseSession(this.date, this.sets);

  double get bestE1rm => sets.fold(0.0, (m, s) {
        final v = e1rm(s.kg, s.reps);
        return v > m ? v : m;
      });
}

/// The user's history of one exercise, oldest session first. Warm-ups are
/// left out; sessions with only warm-ups don't count.
List<ExerciseSession> sessionsOf(
  ExerciseInfo info,
  ExerciseCatalog catalog,
  List<CompletedWorkout> history,
) {
  final result = <ExerciseSession>[];
  for (final w in history) {
    final sets = <WorkoutSet>[];
    for (final e in w.exercises) {
      if (catalog.byName(e.name)?.id == info.id) {
        sets.addAll(e.sets.where((s) => !s.warmup));
      }
    }
    if (sets.isNotEmpty) result.add(ExerciseSession(w.finishedAt, sets));
  }
  result.sort((a, b) => a.date.compareTo(b.date));
  return result;
}

/// Best set over all [sessions], or null.
WorkoutSet? bestOf(List<ExerciseSession> sessions) => bestSet(
    [for (final s in sessions) ...s.sets.map((x) => x.copyWith(done: true))]);

/// Rounds half up to one decimal, so 107.25 reads 107.3.
double round1(double v) => (v * 10).round() / 10;

/// Working sets of [group] done in the calendar week starting [weekStart]
/// (Monday), from history.
int weeklySets(
  MuscleGroup group,
  ExerciseCatalog catalog,
  List<CompletedWorkout> history,
  DateTime weekStart,
) {
  final end = DateTime(weekStart.year, weekStart.month, weekStart.day + 7);
  var n = 0;
  for (final w in history) {
    if (w.finishedAt.isBefore(weekStart) || !w.finishedAt.isBefore(end)) {
      continue;
    }
    for (final e in w.exercises) {
      if (catalog.byName(e.name)?.group == group) {
        n += e.sets.where((s) => !s.warmup).length;
      }
    }
  }
  return n;
}
