/// Sample progress history used by "My progress" until real workout
/// history is stored.
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

  static const _weeks = ['Sep 1', '8', '15', '22', '29', 'Oct 6', '13', '20'];
  static const _days = ['Sep 1', '2', '3', '4', '5', '6', '7', '8'];

  static const strength = [
    ProgressSeries(
      title: 'Biceps curl',
      values: [60, 61, 65, 65, 70, 70, 75, 80],
      xLabels: _weeks,
      minY: 60,
      maxY: 80,
    ),
    ProgressSeries(
      title: 'Bench press',
      values: [60, 61, 65, 65, 70, 70, 75, 80],
      xLabels: _weeks,
      minY: 60,
      maxY: 80,
    ),
  ];

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
