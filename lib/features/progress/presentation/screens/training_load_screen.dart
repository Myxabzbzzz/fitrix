import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/core/widgets/title_row.dart';
import 'package:fitrix/core/time/today_provider.dart';
import 'package:fitrix/core/widgets/coach_card.dart';
import 'package:fitrix/core/widgets/screen_title.dart';
import 'package:fitrix/features/plan/data/week_plan.dart' show weekStartOf;
import 'package:fitrix/features/progress/domain/progress_math.dart';
import 'package:fitrix/features/progress/presentation/widgets/multi_line_chart.dart';
import 'package:fitrix/features/progress/presentation/widgets/progress_widgets.dart';
import 'package:fitrix/features/workouts/domain/training_math.dart';
import 'package:fitrix/features/workouts/presentation/providers/workouts_provider.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

/// Fitness and fatigue over 4, 12 or 16 weeks, what they mean, load by
/// week and the aim for next week.
class TrainingLoadScreen extends ConsumerStatefulWidget {
  const TrainingLoadScreen({super.key});

  @override
  ConsumerState<TrainingLoadScreen> createState() => _TrainingLoadScreenState();
}

class _TrainingLoadScreenState extends ConsumerState<TrainingLoadScreen> {
  int _weeks = 12;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = AppPalette.of(context);
    final locale = Localizations.localeOf(context).toString();
    final fmt = NumberFormat.decimalPattern(locale);
    final today = ref.watch(todayProvider);
    final history = ref.watch(workoutHistoryProvider);
    final days = dailyLoads(history);
    final summary = loadSummary(days, today);

    // Fitness and fatigue for every day of the window.
    final n = _weeks * 7;
    final fitness = <Offset>[], fatigue = <Offset>[];
    for (var i = 0; i < n; i++) {
      final day = DateTime(today.year, today.month, today.day - (n - 1 - i));
      final s = loadSummary(days, day);
      final x = i / (n - 1);
      fitness.add(Offset(x, s.fitness));
      fatigue.add(Offset(x, s.fatigue));
    }
    final hasLoad = days.isNotEmpty;
    // Until there is enough history the curves would show fatigue far above
    // fitness; the numbers below say "collecting", so the chart is bare too.
    final showLines = hasLoad && summary.hasForm;
    final (minY, maxY) = showLines
        ? MultiLineChart.niceRange([...fitness, ...fatigue].map((o) => o.dy))
        : (0.0, 3.0);
    final dateFmt = DateFormat('d MMM', locale);
    final xLabels = <(double, String)>[
      for (final f in [0.0, 1 / 3, 2 / 3])
        (
          f,
          dateFmt.format(DateTime(today.year, today.month,
              today.day - ((1 - f) * (n - 1)).round())),
        ),
      (1.0, l10n.bodyToday),
    ];

    final totals = weeklyTotals(days, today, _weeks);
    final previous = totals.skip(1).where((t) => t > 0).toList();
    final avg = previous.isEmpty
        ? null
        : previous.fold<int>(0, (a, b) => a + b) / previous.length;
    final maxTotal = totals.fold<int>(1, (a, b) => a > b ? a : b);
    final start = weekStartOf(today);
    final aim = nextWeekAim(days, today);
    final form = summary.form;

    Widget explain(Color swatch, String title, String body) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                    color: swatch.withValues(alpha: 0.25),
                    borderRadius: AppRadius.smAll),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style:
                            AppText.bodyStrong.copyWith(color: p.textPrimary)),
                    Text(body,
                        style:
                            AppText.caption.copyWith(color: p.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
        );

    return Scaffold(
      backgroundColor: p.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScreenTitle(l10n.loadTitle),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, 0, AppSpacing.md, AppSpacing.lg),
                children: [
                  Text(l10n.loadSubtitle(l10n.loadAllSports),
                      style: AppText.caption.copyWith(color: p.textSecondary)),
                  const SizedBox(height: AppSpacing.sm),
                  Segmented<int>(
                    items: const [4, 12, 16],
                    selected: _weeks,
                    labelOf: (w) => l10n.loadWeeks(w),
                    onSelected: (w) => setState(() => _weeks = w),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ProgressCard(
                    chart: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MultiLineChart(
                          minY: minY,
                          maxY: maxY,
                          xLabels: xLabels,
                          height: 150,
                          series: showLines
                              ? [
                                  ChartSeries(fatigue, p.warning, dashed: true),
                                  ChartSeries(fitness, p.accent, endDot: true),
                                ]
                              : const [],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        if (!hasLoad)
                          Text(l10n.loadChartEmpty,
                              style: AppText.caption
                                  .copyWith(color: p.textSecondary)),
                        Wrap(spacing: AppSpacing.sm, children: [
                          LegendDot(
                              color: p.accent, label: l10n.progressFitness),
                          LegendDot(
                              color: p.warning, label: l10n.progressFatigue),
                        ]),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ProgressCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!summary.hasForm && hasLoad)
                          Padding(
                            key: const ValueKey('load-collecting'),
                            padding:
                                const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: Text(
                                l10n.progressCollecting(summary.daysToForm),
                                style: AppText.bodyStrong
                                    .copyWith(color: p.textSecondary)),
                          ),
                        explain(
                            p.accent,
                            '${l10n.progressFitness} · ${summary.hasForm ? fmt.format(summary.fitness.round()) : '—'}',
                            l10n.loadFitnessExplain),
                        explain(
                            p.warning,
                            '${l10n.progressFatigue} · ${summary.hasForm ? fmt.format(summary.fatigue.round()) : '—'}',
                            l10n.loadFatigueExplain),
                        explain(
                            p.success,
                            '${l10n.progressForm} · ${form == null ? '—' : signedPercent(form)}',
                            l10n.loadFormExplain),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TitleRow(
                    title: Text(l10n.loadByWeek,
                        style: AppText.headingS.copyWith(color: p.textPrimary)),
                    trailing: avg == null
                        ? null
                        : Text(l10n.loadAvg(fmt.format(avg.round())),
                            overflow: TextOverflow.ellipsis,
                            style: AppText.caption
                                .copyWith(color: p.textSecondary)),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  ProgressCard(
                    child: Column(
                      children: [
                        for (var i = 0; i < totals.length; i++)
                          Padding(
                            padding: EdgeInsets.only(
                                bottom:
                                    i == totals.length - 1 ? 0 : AppSpacing.xs),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 56,
                                  child: Text(
                                    i == 0
                                        ? l10n.loadThisWeek
                                        : dateFmt.format(DateTime(start.year,
                                            start.month, start.day - 7 * i)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppText.caption
                                        .copyWith(color: p.textSecondary),
                                  ),
                                ),
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: AppRadius.fullAll,
                                    child: LinearProgressIndicator(
                                      value: totals[i] / maxTotal,
                                      minHeight: 8,
                                      color: p.accent,
                                      backgroundColor: p.border,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 56,
                                  child: Text(fmt.format(totals[i]),
                                      textAlign: TextAlign.end,
                                      maxLines: 1,
                                      style: AppText.captionStrong
                                          .copyWith(color: p.textPrimary)),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (aim != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    CoachCard(
                      eyebrow: l10n.loadNextWeek,
                      title: '',
                      message: l10n.loadAim(fmt.format(aim)),
                      imageAsset: 'assets/images/felix_robot.png',
                      imageWidth: 56,
                      imageHeight: 80,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
