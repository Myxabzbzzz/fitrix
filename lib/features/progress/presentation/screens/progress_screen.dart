import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/core/widgets/pill_selector.dart';
import 'package:fitrix/core/widgets/screen_title.dart';
import 'package:fitrix/core/widgets/sync_refresh.dart';
import 'package:fitrix/features/progress/data/progress_data.dart';
import 'package:fitrix/features/progress/presentation/widgets/progress_chart.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/features/workouts/presentation/providers/workouts_provider.dart';
import 'package:fitrix/features/workouts/presentation/sport_l10n.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

/// "My progress": strength charts and recent sessions from saved workouts,
/// plus body weight and calories (sample data for now), filtered by sport.
class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  Sport _sport = Sport.gym;

  ProgressChart _chart(
    ProgressSeries s, {
    String? title,
    String? left,
    String? right,
    String? delta,
  }) =>
      ProgressChart(
        title: title ?? s.title,
        values: s.values,
        xLabels: s.xLabels,
        minY: s.minY,
        maxY: s.maxY,
        footerLeft: left,
        footerRight: right,
        delta: delta,
      );

  /// "+2.5 kg" style change between the first and last value.
  String _delta(ProgressSeries s) {
    final d = s.values.last - s.values.first;
    return '${d < 0 ? '−' : '+'}${formatKg(d.abs())}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fmt = NumberFormat.decimalPattern(
        Localizations.localeOf(context).toString());
    final palette = AppPalette.of(context);
    final sectionStyle = AppText.headingS.copyWith(color: palette.textPrimary);
    final noteStyle = AppText.caption.copyWith(color: palette.textSecondary);

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
            ScreenTitle(l10n.progressTitle),
            PillSelector<Sport>(
              items: Sport.values,
              selected: _sport,
              labelOf: (s) => s.localizedLabel(l10n),
              onSelected: (s) => setState(() => _sport = s),
            ),
            Expanded(
              child: SyncRefresh(
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(AppSpacing.md,
                      AppSpacing.sm, AppSpacing.md, AppSpacing.lg),
                  children: [
                    Text(l10n.progressStrength, style: sectionStyle),
                    const SizedBox(height: AppSpacing.sm),
                    if (strength.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Text(
                          l10n.progressNoWorkouts(_sport.localizedLabel(l10n).toLowerCase()),
                          style: noteStyle,
                        ),
                      ),
                    for (final series in strength) ...[
                      _chart(
                        series,
                        delta: series.values.length > 1 ? _delta(series) : null,
                        left: series.values.length > 1
                            ? l10n.progressFirst(formatKg(series.values.first))
                            : null,
                        right:
                            l10n.progressLatest(formatKg(series.values.last)),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    if (history.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(l10n.progressRecentWorkouts, style: sectionStyle),
                      const SizedBox(height: AppSpacing.xs),
                      for (final workout in history.take(10))
                        _HistoryTile(workout: workout),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    Text(l10n.progressBody, style: sectionStyle),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(l10n.progressSampleNote, style: noteStyle),
                    const SizedBox(height: AppSpacing.sm),
                    _chart(
                      weight,
                      title: l10n.progressWeightTitle,
                      delta: _delta(weight),
                      left:
                          l10n.progressMonthAgo(formatKg(weight.values.first)),
                      right: l10n.progressCurrent(formatKg(weight.values.last)),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _chart(ProgressData.calories,
                        title: l10n.progressCaloriesTitle),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: _StatTile(
                            label: l10n.progressIntake,
                            value: fmt.format(ProgressData.caloriesIntake),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _StatTile(
                            label: l10n.progressBurn,
                            value: fmt.format(ProgressData.caloriesBurn),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;

  const _StatTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration:
          BoxDecoration(color: palette.tile, borderRadius: AppRadius.smAll),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppText.caption.copyWith(color: palette.textSecondary)),
          Text(value,
              style:
                  AppText.displayMedium.copyWith(color: palette.textPrimary)),
          Text(AppLocalizations.of(context).progressKcalPerDay,
              style: AppText.micro.copyWith(color: palette.textSecondary)),
        ],
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
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: palette.tile,
        borderRadius: AppRadius.smAll,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  workout.name,
                  style:
                      AppText.bodyStrong.copyWith(color: palette.textPrimary),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  DateFormat('EEE, d MMM · HH:mm').format(workout.finishedAt),
                  style: AppText.caption.copyWith(color: palette.textSecondary),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatDuration(workout.duration, withSeconds: false),
                style:
                    AppText.captionStrong.copyWith(color: palette.textPrimary),
              ),
              Text(
                AppLocalizations.of(context)
                    .progressSets(workout.setCount),
                style: AppText.caption.copyWith(color: palette.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
