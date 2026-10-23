import 'package:fitrix/core/time/day_key.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fitrix/core/felix/ask_felix.dart';
import 'package:fitrix/core/router/app_router.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/core/time/today_provider.dart';
import 'package:fitrix/core/widgets/coach_card.dart';
import 'package:fitrix/core/widgets/pill_selector.dart';
import 'package:fitrix/core/widgets/screen_title.dart';
import 'package:fitrix/core/widgets/sync_refresh.dart';
import 'package:fitrix/features/chat/data/models/assistant_topic.dart';
import 'package:fitrix/features/exercises/data/exercise_catalog.dart';
import 'package:fitrix/features/health/presentation/providers/health_providers.dart';
import 'package:fitrix/features/progress/domain/progress_math.dart';
import 'package:fitrix/features/progress/presentation/providers/progress_providers.dart';
import 'package:fitrix/features/progress/presentation/widgets/progress_widgets.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/features/workouts/domain/training_math.dart';
import 'package:fitrix/features/workouts/presentation/providers/workouts_provider.dart';
import 'package:fitrix/features/workouts/presentation/sport_l10n.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

/// "My progress": this week's training load, fitness / fatigue / form,
/// records and links to the detail screens. All from saved workouts.
class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  /// Null is "Overall".
  Sport? _sport;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = AppPalette.of(context);
    final locale = Localizations.localeOf(context).toString();
    final fmt = NumberFormat.decimalPattern(locale);
    final today = ref.watch(todayProvider);
    final all = ref.watch(workoutHistoryProvider);
    final weighIns = ref.watch(bodyWeightProvider);
    final stepsWeek = ref.watch(stepsLast7Provider);

    final present = [
      for (final s in Sport.values)
        if (all.any((w) => w.sport == s)) s,
    ];
    final sport = present.contains(_sport) ? _sport : null;
    final history =
        sport == null ? all : all.where((w) => w.sport == sport).toList();

    final days = dailyLoads(history);
    final summary = loadSummary(days, today);
    final start = weekStart(today);
    final weekTotal = weeklyTotals(days, today, 1).first;
    final usual = usualWeeklyLoad(days, today);
    final weekDays = List.generate(7, (_) => <Sport, int>{});
    for (var i = 0; i < 7; i++) {
      final day = DateTime(start.year, start.month, start.day + i);
      for (final w in history) {
        if (dayOf(w.finishedAt) == day) {
          weekDays[i][w.sport] = (weekDays[i][w.sport] ?? 0) + w.load;
        }
      }
    }
    final usedSports = {for (final d in weekDays) ...d.keys};
    final estimated = history.any(
        (w) => w.loadEstimated && daysBetween(w.finishedAt, today).abs() < 42);

    final records = [
      for (final r in recordEntries(all))
        if (sport == null || r.sport == sport) r,
    ];
    final recordsThisWeek =
        records.where((r) => !r.record.date.isBefore(start)).length;
    final catalog = ref.watch(exerciseCatalogProvider).valueOrNull;
    final lifts = liftsIn(history, catalog);
    final latestWeight = weighIns.isEmpty ? null : weighIns.last.kg;

    final form = summary.form;
    final formInfo = form == null ? null : formLabel(l10n, p, form);
    final band = summary.band;
    final acwr = summary.acwr;

    Widget gap([double h = AppSpacing.sm]) => SizedBox(height: h);

    return Scaffold(
      backgroundColor: p.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScreenTitle(l10n.progressTitle),
            if (all.isNotEmpty)
              PillSelector<Sport?>(
                items: [null, ...present],
                selected: sport,
                labelOf: (s) =>
                    s == null ? l10n.progressOverall : s.localizedLabel(l10n),
                onSelected: (s) => setState(() => _sport = s),
              ),
            Expanded(
              child: SyncRefresh(
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(AppSpacing.md,
                      AppSpacing.sm, AppSpacing.md, AppSpacing.lg),
                  children: [
                    if (all.isEmpty) ...[
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(vertical: AppSpacing.md),
                        child: Text(l10n.progressEmpty,
                            style: AppText.headingS
                                .copyWith(color: p.textSecondary)),
                      ),
                    ] else ...[
                      ProgressCard(
                        onTap: () => context.push(AppRouter.progressLoad),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(l10n.progressLoadThisWeek,
                                      style: AppText.headingS
                                          .copyWith(color: p.textPrimary)),
                                ),
                                Flexible(
                                  child: Text(l10n.progressLoadNote,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppText.caption
                                          .copyWith(color: p.textSecondary)),
                                ),
                              ],
                            ),
                            gap(AppSpacing.xs),
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.end,
                              spacing: AppSpacing.xs,
                              children: [
                                Text(fmt.format(weekTotal),
                                    key: const ValueKey('week-load'),
                                    style: AppText.displayLarge
                                        .copyWith(color: p.textPrimary)),
                                Text(
                                  usual == null
                                      ? l10n.progressAu
                                      : '${l10n.progressAu} · ${l10n.progressPercentOfUsual((weekTotal / usual * 100).round())}',
                                  style: AppText.caption
                                      .copyWith(color: p.textSecondary),
                                ),
                              ],
                            ),
                            gap(),
                            LoadBarChart(weekStartDay: start, days: weekDays),
                            gap(AppSpacing.xs),
                            Wrap(
                              spacing: AppSpacing.sm,
                              children: [
                                for (final s in Sport.values)
                                  if (usedSports.contains(s))
                                    LegendDot(
                                        color: sportColor(p, s),
                                        label: s.localizedLabel(l10n)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      gap(),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: StatTile(
                              label: l10n.progressFitness,
                              value: fmt.format(summary.fitness.round()),
                              valueKey: const ValueKey('fitness-value'),
                              note: l10n.progress42Day,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: StatTile(
                              label: l10n.progressFatigue,
                              value: fmt.format(summary.fatigue.round()),
                              valueKey: const ValueKey('fatigue-value'),
                              note: l10n.progress7Day,
                            ),
                          ),
                        ],
                      ),
                      gap(),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: StatTile(
                              label: l10n.progressForm,
                              value: form == null ? '—' : signedPercent(form),
                              valueKey: const ValueKey('form-value'),
                              valueColor: formInfo?.color,
                              note: formInfo?.text ?? '',
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: StatTile(
                              label: l10n.progressRecords,
                              value: fmt.format(recordsThisWeek),
                              valueColor: p.accent,
                              note: l10n.progressRecordsThisWeek,
                            ),
                          ),
                        ],
                      ),
                      if (estimated) ...[
                        gap(AppSpacing.xs),
                        Text(l10n.progressEstimated,
                            key: const ValueKey('estimated-note'),
                            style: AppText.caption
                                .copyWith(color: p.textSecondary)),
                      ],
                      if (band != null && acwr != null) ...[
                        gap(),
                        ProgressCard(
                          onTap: () => context.push(AppRouter.progressLoad),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(l10n.progressBalance,
                                        style: AppText.headingS
                                            .copyWith(color: p.textPrimary)),
                                  ),
                                  Flexible(
                                    child: Text(
                                      '${NumberFormat('0.00', locale).format(acwr)} · ${switch (band) {
                                        AcwrBand.low => l10n.progressBandLow,
                                        AcwrBand.sweetSpot =>
                                          l10n.progressBandSweet,
                                        AcwrBand.risky =>
                                          l10n.progressBandRisky,
                                      }}',
                                      overflow: TextOverflow.ellipsis,
                                      style: AppText.bodyStrong.copyWith(
                                          color: band == AcwrBand.sweetSpot
                                              ? p.success
                                              : p.warning),
                                    ),
                                  ),
                                ],
                              ),
                              gap(AppSpacing.xs),
                              BalanceBar(acwr: acwr),
                              gap(AppSpacing.xxs),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  for (final t in [
                                    l10n.progressBalanceLow,
                                    l10n.progressBalanceSweet,
                                    l10n.progressBalanceRisky,
                                  ])
                                    Flexible(
                                      child: Text(t,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppText.micro.copyWith(
                                              color: p.textSecondary)),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        gap(),
                        CoachCard(
                          eyebrow: l10n.progressFelixInsight,
                          title: '',
                          message: switch (band) {
                            AcwrBand.low => l10n.progressInsightLow,
                            AcwrBand.sweetSpot => l10n.progressInsightSweet,
                            AcwrBand.risky => l10n.progressInsightRisky,
                          },
                          imageAsset: 'assets/images/felix_robot.png',
                          imageWidth: 56,
                          imageHeight: 80,
                          onAsk: () => askFelix(
                            context,
                            ref,
                            topic: sport == null
                                ? AssistantTopic.app
                                : AssistantTopic.forSport(sport),
                            draft: l10n.progressAskDraft(
                              '${fmt.format(weekTotal)} ${l10n.progressAu}',
                              NumberFormat('0.00', locale).format(acwr),
                              switch (band) {
                                AcwrBand.low => l10n.progressBalanceLow,
                                AcwrBand.sweetSpot => l10n.progressBalanceSweet,
                                AcwrBand.risky => l10n.progressBalanceRisky,
                              },
                            ),
                          ),
                        ),
                      ],
                    ],
                    if (stepsWeek != null) ...[
                      gap(),
                      ProgressCard(
                        key: const ValueKey('steps-week'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.healthSteps,
                                style: AppText.headingS
                                    .copyWith(color: p.textPrimary)),
                            if (stepsWeek.average != null) ...[
                              gap(AppSpacing.xxs),
                              Text(l10n.healthStepsDailyAvg(stepsWeek.average!),
                                  key: const ValueKey('steps-avg'),
                                  style: AppText.caption
                                      .copyWith(color: p.textSecondary)),
                            ],
                            gap(),
                            StepsBarChart(week: stepsWeek),
                          ],
                        ),
                      ),
                    ],
                    gap(AppSpacing.md),
                    ProgressCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          LinkRow(
                            icon: Icons.emoji_events_outlined,
                            title: l10n.progressRecords,
                            value: fmt.format(records.length),
                            onTap: () =>
                                context.push(AppRouter.progressRecords),
                          ),
                          LinkRow(
                            icon: Icons.fitness_center,
                            title: l10n.progressLiftsE1rm,
                            value: fmt.format(lifts.length),
                            onTap: () => context.push(lifts.isEmpty
                                ? AppRouter.progressLift('-')
                                : AppRouter.progressLift(lifts.first.name)),
                          ),
                          LinkRow(
                            icon: Icons.monitor_weight_outlined,
                            title: l10n.progressBodyWeight,
                            value: latestWeight == null
                                ? '—'
                                : kgText(context, latestWeight),
                            onTap: () => context.push(AppRouter.progressWeight),
                          ),
                        ],
                      ),
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
