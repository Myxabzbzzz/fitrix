import 'package:flutter/material.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/widgets/pill_selector.dart';
import 'package:fitrix/core/widgets/screen_title.dart';
import 'package:fitrix/features/progress/data/progress_data.dart';
import 'package:fitrix/features/progress/presentation/widgets/progress_chart.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';

/// "My progress": strength charts per exercise, body weight and
/// calories intake vs burn, filtered by sport.
class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
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
                  if (_sport == Sport.gym) ...[
                    Text('Strength', style: sectionStyle),
                    const SizedBox(height: 12),
                    for (final series in ProgressData.strength) ...[
                      _chart(series),
                      const SizedBox(height: 12),
                    ],
                  ] else
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        'No ${_sport.label.toLowerCase()} sessions tracked yet. '
                        'Start a workout to see your progress here.',
                        style: TextStyle(color: palette.textSecondary),
                      ),
                    ),
                  const SizedBox(height: 8),
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
