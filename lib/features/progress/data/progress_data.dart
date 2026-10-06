import 'dart:math' as math;
import 'package:intl/intl.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';

class ProgressSeries {
  final String title;
  final List<double> values;
  final List<String> xLabels;
  final double minY;
  final double maxY;

  const ProgressSeries({
    required this.title,
    required this.values,
    required this.xLabels,
    required this.minY,
    required this.maxY,
  });
}

class ProgressData {
  ProgressData._();

  /// Sessions shown per strength chart.
  static const int maxSessions = 8;

  /// One chart per exercise from finished workouts of [sport]: the best
  /// completed weight of each session, oldest to newest. Bodyweight
  /// exercises (all sets at 0 kg) chart max reps instead.
  static List<ProgressSeries> strengthFrom(
    List<CompletedWorkout> history,
    Sport sport,
  ) {
    final sessions = history.where((w) => w.sport == sport).toList()
      ..sort((a, b) => a.finishedAt.compareTo(b.finishedAt));

    final points = <String, List<({DateTime date, double kg, int reps})>>{};
    for (final workout in sessions) {
      for (final exercise in workout.exercises) {
        if (exercise.sets.isEmpty) continue;
        points.putIfAbsent(exercise.name, () => []).add((
          date: workout.finishedAt,
          kg: exercise.sets.map((s) => s.kg).reduce(math.max),
          reps: exercise.sets.map((s) => s.reps).reduce(math.max),
        ));
      }
    }

    final dateFormat = DateFormat('d MMM');
    return [
      for (final entry in points.entries)
        () {
          final recent = entry.value.length > maxSessions
              ? entry.value.sublist(entry.value.length - maxSessions)
              : entry.value;
          final bodyweight = recent.every((p) => p.kg == 0);
          final values = [
            for (final p in recent) bodyweight ? p.reps.toDouble() : p.kg,
          ];
          final (minY, maxY) = _range(values);
          return ProgressSeries(
            title: bodyweight ? '${entry.key} (reps)' : '${entry.key} (kg)',
            values: values,
            xLabels: [for (final p in recent) dateFormat.format(p.date)],
            minY: minY,
            maxY: maxY,
          );
        }(),
    ];
  }

  /// Y axis bounds with a little headroom, never a zero-height range, and
  /// sized so the chart's 4 grid lines land on whole numbers.
  static (double, double) _range(List<double> values) {
    const divisions = 4;
    final lo = values.reduce(math.min);
    final hi = values.reduce(math.max);
    final pad = math.max((hi - lo) * 0.1, 1.0);
    final bottom = math.max(0.0, (lo - pad).floorToDouble());
    final step = ((hi + pad - bottom) / divisions).ceilToDouble();
    return (bottom, bottom + step * divisions);
  }

  // Sample data for body weight and calories, until those are tracked.

  static const _days = ['Sep 1', '2', '3', '4', '5', '6', '7', '8'];

  static const weight = ProgressSeries(
    title: 'My weight (kg)',
    values: [70, 70.5, 72, 72, 75, 75, 77.5, 80],
    xLabels: _days,
    minY: 60,
    maxY: 80,
  );

  static const caloriesIntake = 2000;
  static const caloriesBurn = 1800;

  /// Net calories (intake − burn) per day.
  static const calories = ProgressSeries(
    title: 'Calories: intake vs burn',
    values: [-200, -180, -100, -100, 0, 0, 100, 200],
    xLabels: _days,
    minY: -200,
    maxY: 200,
  );
}
