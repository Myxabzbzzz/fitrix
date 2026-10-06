import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/widgets/pill_selector.dart';
import 'package:fitrix/core/widgets/screen_title.dart';
import 'package:fitrix/features/progress/data/progress_data.dart';
import 'package:fitrix/features/progress/presentation/widgets/progress_chart.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/features/workouts/presentation/providers/workouts_provider.dart';

/// "My progress": strength charts and recent sessions from saved workouts,
/// plus body weight and calories (sample data for now), filtered by sport.
class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  Sport _sport = Sport.gym;

  ProgressChart _chart(ProgressSeries s, {String? left, String? right}) =>
      ProgressChart(
        title: s.title,
        values: s.values,
        xLabels: s.xLabels,
        minY: s.minY,
        maxY: s.maxY,
        footerLeft: left,
        footerRight: right,
      );

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final sectionStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: palette.textPrimary,
    );
    final noteStyle = TextStyle(fontSize: 13, color: palette.textSecondary);

    final history = ref
        .watch(workoutHistoryProvider)
        .where((w) => w.sport == _sport)
        .toList();
    final strength = ProgressData.strengthFrom(history, _sport);
    const weight = ProgressData.weight;

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ScreenTitle('My progress'),
            PillSelector<Sport>(
              items: Sport.values,
              selected: _sport,
              labelOf: (s) => s.label,
              onSelected: (s) => setState(() => _sport = s),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(28, 20, 28, 24),
                children: [
                  Text('Strength', style: sectionStyle),
                  const SizedBox(height: 12),
                  if (strength.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'No ${_sport.label.toLowerCase()} workouts yet. '
                        'Finish one with at least one set checked off and '
                        'your progress will show up here.',
                        style: noteStyle,
                      ),
                    ),
                  for (final series in strength) ...[
                    _chart(
                      series,
                      left: 'Latest: ${formatKg(series.values.last)}',
                      right: series.values.length > 1
                          ? 'First: ${formatKg(series.values.first)}'
                          : null,
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (history.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text('Recent workouts', style: sectionStyle),
                    const SizedBox(height: 8),
                    for (final workout in history.take(10))
                      _HistoryTile(workout: workout),
                  ],
                  const SizedBox(height: 20),
                  Text('Body', style: sectionStyle),
                  const SizedBox(height: 4),
                  Text('Sample data — tracking is coming soon.', style: noteStyle),
                  const SizedBox(height: 12),
                  _chart(
                    weight,
                    left: 'Current: ${formatKg(weight.values.last)}',
                    right: 'One month ago: ${formatKg(weight.values.first)}',
                  ),
                  const SizedBox(height: 20),
                  _chart(
                    ProgressData.calories,
                    left: 'Intake: ${ProgressData.caloriesIntake}',
                    right: 'Burn: ${ProgressData.caloriesBurn}',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final CompletedWorkout workout;

  const _HistoryTile({required this.workout});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: palette.tile,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  workout.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('EEE, d MMM · HH:mm').format(workout.finishedAt),
                  style: TextStyle(fontSize: 12, color: palette.textSecondary),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatDuration(workout.duration, withSeconds: false),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: palette.textPrimary,
                ),
              ),
              Text(
                '${workout.setCount} sets',
                style: TextStyle(fontSize: 12, color: palette.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
