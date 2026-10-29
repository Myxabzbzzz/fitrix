import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fitrix/core/i18n/catalog_text.dart';
import 'package:fitrix/core/felix/ask_felix.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/core/widgets/title_row.dart';
import 'package:fitrix/core/time/today_provider.dart';
import 'package:fitrix/core/widgets/coach_card.dart';
import 'package:fitrix/core/widgets/pill_selector.dart';
import 'package:fitrix/core/widgets/screen_title.dart';
import 'package:fitrix/features/chat/data/models/assistant_topic.dart';
import 'package:fitrix/features/exercises/data/exercise_catalog.dart';
import 'package:fitrix/features/nutrition/presentation/providers/nutrition_provider.dart';
import 'package:fitrix/features/profile/data/performance_store.dart';
import 'package:fitrix/features/progress/domain/progress_math.dart';
import 'package:fitrix/features/progress/presentation/providers/progress_providers.dart';
import 'package:fitrix/features/progress/presentation/widgets/multi_line_chart.dart';
import 'package:fitrix/features/progress/presentation/widgets/progress_widgets.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/features/workouts/domain/training_math.dart';
import 'package:fitrix/features/workouts/presentation/providers/workouts_provider.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

/// One lift: estimated 1RM over time, strength level, next session and
/// pace. Starts on [name]; the pills switch lifts.
class LiftDetailScreen extends ConsumerStatefulWidget {
  final String name;
  const LiftDetailScreen({super.key, required this.name});

  @override
  ConsumerState<LiftDetailScreen> createState() => _LiftDetailScreenState();
}

class _LiftDetailScreenState extends ConsumerState<LiftDetailScreen> {
  String? _picked;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = AppPalette.of(context);
    final locale = Localizations.localeOf(context).toString();
    final today = ref.watch(todayProvider);
    final history = ref.watch(workoutHistoryProvider);
    final catalog = ref.watch(exerciseCatalogProvider).valueOrNull;
    final lifts = liftsIn(history, catalog);
    final names = ref.watch(catalogTextProvider);
    final female = ref.watch(performanceProfileProvider).sex == Sex.female;
    final weighIns = ref.watch(bodyWeightProvider);
    final bodyKg = weighIns.isNotEmpty
        ? weighIns.last.kg
        : ref.watch(bodyStatsProvider).weightKg;

    Widget page(List<Widget> children) => Scaffold(
          backgroundColor: p.background,
          body: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ScreenTitle(l10n.liftTitle),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, AppSpacing.lg),
                    children: withPageGutter(children),
                  ),
                ),
              ],
            ),
          ),
        );

    if (lifts.isEmpty) {
      return page([
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.md),
          child: Text(l10n.liftNone,
              style: AppText.headingS.copyWith(color: p.textSecondary)),
        ),
      ]);
    }

    final wanted = canonicalLift(_picked ?? widget.name, catalog).key;
    final current = lifts.firstWhere(
        (l) => canonicalLift(l.name, catalog).key == wanted,
        orElse: () => lifts.first);
    final series = liftSeries(history, current.name, catalog);
    final best = series.reduce((a, b) => b.e1rm > a.e1rm ? b : a);
    final first = series.first;
    final dateFmt = DateFormat('d MMM', locale);
    final num1 = NumberFormat('0.#', locale);

    // Chart.
    final t0 = first.date, t1 = series.last.date;
    final span = daysBetween(t0, t1);
    double xOf(LiftPoint pt) =>
        span == 0 ? 0.5 : daysBetween(t0, pt.date) / span;
    final (minY, maxY) = MultiLineChart.niceRange([
      for (final s in series) ...[s.e1rm, s.kg]
    ]);
    final monthFmt = DateFormat('MMM', locale);
    final xLabels = <(double, String)>[];
    if (span == 0) {
      xLabels.add((0.5, monthFmt.format(t0)));
    } else {
      for (final f in [0.0, 1 / 3, 2 / 3, 1.0]) {
        final d = DateTime(t0.year, t0.month, t0.day + (span * f).round());
        final label = monthFmt.format(d);
        if (xLabels.isEmpty || xLabels.last.$2 != label) {
          xLabels.add((f, label));
        }
      }
    }

    final change = series.length > 1 && first.e1rm > 0
        ? (best.e1rm - first.e1rm) / first.e1rm * 100
        : null;

    // Strength level.
    final key = liftKeyFor(current.name, catalog);
    final info = key == null || bodyKg == null
        ? null
        : strengthInfo(key, best.e1rm, bodyKg, female: female);

    // Pace.
    final slope = liftWeeklySlope(series, today);
    String? pace;
    if (slope != null) {
      if (slope >= 0.2) {
        final rate = '+${num1.format(slope)} ${l10n.unitKg}';
        final next = info?.nextRatio;
        final weeks = next == null || bodyKg == null
            ? null
            : (next * bodyKg - best.e1rm) / slope;
        if (weeks != null && weeks > 0 && weeks <= 52) {
          final date = DateTime(
              today.year, today.month, today.day + (weeks * 7).round());
          pace = l10n.liftPaceTo(
              DateFormat('MMMM', locale).format(date), rate, num1.format(next));
        } else {
          pace = l10n.liftPaceUp(rate);
        }
      } else {
        pace = l10n.liftPaceFlat;
      }
    }

    Widget cell(String text, {bool strong = false, bool end = false}) =>
        Expanded(
          child: Text(text,
              textAlign: end ? TextAlign.end : TextAlign.start,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: (strong ? AppText.bodyStrong : AppText.caption)
                  .copyWith(color: strong ? p.textPrimary : p.textSecondary)),
        );
    Widget plan(String name, int pct, String reps) => Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xs),
          child: Row(children: [
            Expanded(
                flex: 2,
                child: Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.bodyStrong.copyWith(color: p.textPrimary))),
            cell('$pct%', end: true),
            Expanded(
              flex: 2,
              child: Text(kgText(context, roundToPlate(best.e1rm * pct / 100)),
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.bodyStrong.copyWith(color: p.textPrimary)),
            ),
            cell(reps, strong: true, end: true),
          ]),
        );

    return page([
      PillSelector<String>(
        items: [for (final l in lifts) l.name],
        selected: current.name,
        labelOf: names.exercise,
        onSelected: (n) => setState(() => _picked = n),
      ),
      const SizedBox(height: AppSpacing.sm),
      Text(l10n.liftEstimated,
          style: AppText.caption.copyWith(color: p.textSecondary)),
      const SizedBox(height: AppSpacing.xxs),
      Wrap(
        crossAxisAlignment: WrapCrossAlignment.end,
        spacing: AppSpacing.xs,
        children: [
          Text(kgText(context, double.parse(best.e1rm.toStringAsFixed(1))),
              key: const ValueKey('lift-e1rm'),
              style: AppText.displayLarge.copyWith(color: p.textPrimary)),
          if (change != null)
            Text(
                '${change >= 0 ? '+' : '−'}${NumberFormat('0.0', locale).format(change.abs())}%',
                style: AppText.captionStrong
                    .copyWith(color: change >= 0 ? p.success : p.warning)),
        ],
      ),
      const SizedBox(height: AppSpacing.xxs),
      Text(
        change != null
            ? l10n.liftSince(dateFmt.format(best.date), num1.format(best.kg),
                '${best.reps}', dateFmt.format(first.date))
            : l10n.liftBestSet(dateFmt.format(best.date), num1.format(best.kg),
                '${best.reps}'),
        style: AppText.caption.copyWith(color: p.textSecondary),
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
              series: [
                ChartSeries(
                    [for (final s in series) Offset(xOf(s), s.e1rm)], p.accent,
                    fill: true, endDot: true),
                ChartSeries([
                  for (final s in series) Offset(xOf(s), s.kg)
                ], p.textPrimary, dotsOnly: true, ringDots: true),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(spacing: AppSpacing.sm, children: [
              LegendDot(color: p.accent, label: l10n.liftChartE1rm),
              LegendDot(
                  color: p.textPrimary, label: l10n.liftChartTop, ring: true),
            ]),
          ],
        ),
      ),
      if (key != null) ...[
        const SizedBox(height: AppSpacing.sm),
        ProgressCard(
          child: info == null
              ? Text(l10n.liftNeedWeight,
                  style: AppText.caption.copyWith(color: p.textSecondary))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TitleRow(
                      title: Text(l10n.liftStrengthLevel,
                          style:
                              AppText.headingS.copyWith(color: p.textPrimary)),
                      trailing: Text(strengthLevelLabel(l10n, info.level),
                          key: const ValueKey('strength-level'),
                          overflow: TextOverflow.ellipsis,
                          style: AppText.bodyStrong.copyWith(color: p.accent)),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(children: [
                      for (var i = 0; i < strengthLevels.length; i++) ...[
                        if (i > 0) const SizedBox(width: AppSpacing.xxs),
                        Expanded(
                          child: Container(
                            height: 6,
                            decoration: BoxDecoration(
                                color: i <= info.index ? p.accent : p.border,
                                borderRadius: AppRadius.fullAll),
                          ),
                        ),
                      ],
                    ]),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      spacing: AppSpacing.sm,
                      children: [
                        Text(
                            l10n.liftRatio(NumberFormat('0.00', locale)
                                .format(info.ratio)),
                            style: AppText.caption
                                .copyWith(color: p.textSecondary)),
                        Text(
                            info.nextRatio == null
                                ? l10n.liftTopBand
                                : l10n.liftNextBand(
                                    kgText(
                                        context,
                                        (info.nextRatio! * bodyKg!)
                                            .roundToDouble()),
                                    strengthLevelLabel(
                                        l10n, strengthLevels[info.index + 1]),
                                    NumberFormat('0.##', locale)
                                        .format(info.nextRatio)),
                            style: AppText.caption
                                .copyWith(color: p.textSecondary)),
                      ],
                    ),
                  ],
                ),
        ),
      ],
      const SizedBox(height: AppSpacing.md),
      TitleRow(
        title: Text(l10n.liftNextSession,
            style: AppText.headingS.copyWith(color: p.textPrimary)),
        trailing: Text(l10n.liftReserve,
            overflow: TextOverflow.ellipsis,
            style: AppText.caption.copyWith(color: p.textSecondary)),
      ),
      const SizedBox(height: AppSpacing.xs),
      ProgressCard(
        child: Column(
          children: [
            Row(children: [
              Expanded(
                  flex: 2,
                  child: Text(l10n.liftColSet.toUpperCase(),
                      maxLines: 1,
                      style: AppText.micro.copyWith(color: p.textSecondary))),
              Expanded(
                  child: Text(l10n.liftCol1rm,
                      textAlign: TextAlign.end,
                      maxLines: 1,
                      style: AppText.micro.copyWith(color: p.textSecondary))),
              Expanded(
                  flex: 2,
                  child: Text(l10n.liftColLoad.toUpperCase(),
                      textAlign: TextAlign.end,
                      maxLines: 1,
                      style: AppText.micro.copyWith(color: p.textSecondary))),
              Expanded(
                  child: Text(l10n.liftColReps.toUpperCase(),
                      textAlign: TextAlign.end,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.micro.copyWith(color: p.textSecondary))),
            ]),
            plan(l10n.liftTopSet, 85, '6'),
            plan(l10n.liftBackOff, 75, '8–9'),
            plan(l10n.liftVolume, 70, '10'),
          ],
        ),
      ),
      if (pace != null) ...[
        const SizedBox(height: AppSpacing.sm),
        CoachCard(
          eyebrow: l10n.liftFelix,
          title: '',
          message: pace,
          imageAsset: 'assets/images/felix_robot.png',
          imageWidth: 56,
          imageHeight: 80,
          onAsk: () => askFelix(
            context,
            ref,
            topic: AssistantTopic.forSport(Sport.gym),
            draft: l10n.liftAskDraft(names.exercise(current.name),
                kgText(context, double.parse(best.e1rm.toStringAsFixed(1)))),
          ),
        ),
      ],
    ]);
  }
}
