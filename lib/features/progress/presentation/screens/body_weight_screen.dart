import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fitrix/core/widgets/sheet_safe_area.dart';
import 'package:fitrix/core/felix/ask_felix.dart';
import 'package:fitrix/core/router/app_router.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/core/time/today_provider.dart';
import 'package:fitrix/core/widgets/app_button.dart';
import 'package:fitrix/core/widgets/coach_card.dart';
import 'package:fitrix/core/widgets/screen_title.dart';
import 'package:fitrix/features/chat/data/models/assistant_topic.dart';
import 'package:fitrix/features/nutrition/data/nutrition_targets.dart';
import 'package:fitrix/features/nutrition/presentation/providers/nutrition_provider.dart';
import 'package:fitrix/features/progress/data/body_weight_store.dart';
import 'package:fitrix/features/progress/domain/progress_math.dart';
import 'package:fitrix/features/progress/presentation/providers/progress_providers.dart';
import 'package:fitrix/features/progress/presentation/widgets/multi_line_chart.dart';
import 'package:fitrix/features/progress/presentation/widgets/progress_widgets.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

/// Weekly kg change range that counts as on track, per goal.
({double lo, double hi}) _goalRange(Goal g) => switch (g) {
      Goal.loseFat => (lo: -0.7, hi: -0.3),
      Goal.maintain => (lo: -0.2, hi: 0.2),
      Goal.leanBulk => (lo: 0.2, hi: 0.4),
    };

/// Body weight: latest, weekly trend, chart, goal check and weigh-ins.
class BodyWeightScreen extends ConsumerStatefulWidget {
  const BodyWeightScreen({super.key});

  @override
  ConsumerState<BodyWeightScreen> createState() => _BodyWeightScreenState();
}

class _BodyWeightScreenState extends ConsumerState<BodyWeightScreen> {
  int _weeks = 8;

  void _openSheet() {
    showModalBottomSheet<void>(
      useRootNavigator: true,
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _WeightSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = AppPalette.of(context);
    final locale = Localizations.localeOf(context).toString();
    final now = ref.watch(clockProvider)();
    final today = ref.watch(todayProvider);
    final all = ref.watch(bodyWeightProvider);
    final goal = ref.watch(nutritionSettingsProvider).goal;
    final unit = l10n.unitKg;

    final trend = weeklyTrendKg(all, now);
    final range = _goalRange(goal);
    // One decision from the goal band drives both the headline colour and
    // the off-track card.
    final onTrack =
        trend != null && trend >= range.lo - 1e-9 && trend <= range.hi + 1e-9;
    final adj = trend == null || onTrack ? null : kcalAdjustment(trend, goal);
    final goalText = switch (goal) {
      Goal.loseFat => l10n.bodyGoalLoseFat(unit),
      Goal.maintain => l10n.bodyGoalMaintain(unit),
      Goal.leanBulk => l10n.bodyGoalLeanBulk(unit),
    };
    final goalName = switch (goal) {
      Goal.loseFat => l10n.bodyGoalNameLoseFat,
      Goal.maintain => l10n.bodyGoalNameMaintain,
      Goal.leanBulk => l10n.bodyGoalNameLeanBulk,
    };

    // Chart window.
    final from = DateTime(today.year, today.month, today.day - _weeks * 7);
    final windowDays = _weeks * 7;
    final inWindow = [
      for (final w in all)
        if (!w.at.isBefore(from)) w
    ];
    double xOf(DateTime d) =>
        (daysBetween(from, d) / windowDays).clamp(0.0, 1.0);
    final windowTrend = weeklyTrendKg(all, now, weeks: _weeks);

    final series = <ChartSeries>[];
    var bandU = <Offset>[], bandL = <Offset>[];
    var minY = 0.0, maxY = 3.0;
    if (inWindow.isNotEmpty) {
      final ys = [for (final w in inWindow) w.kg];
      if (windowTrend != null) {
        final perDay = windowTrend / 7;
        final mx = inWindow
                .map((w) => daysBetween(from, w.at))
                .reduce((a, b) => a + b) /
            inWindow.length;
        final my = ys.reduce((a, b) => a + b) / ys.length;
        double fit(double day) => my + perDay * (day - mx);
        final d0 = daysBetween(from, inWindow.first.at).toDouble();
        final d1 = daysBetween(from, inWindow.last.at).toDouble();
        series.add(ChartSeries([
          Offset(d0 / windowDays, fit(d0)),
          Offset(d1 / windowDays, fit(d1))
        ], p.textPrimary, endDot: true));
        ys.addAll([fit(d0), fit(d1)]);
        final base = fit(d0);
        double at(double day, double perWeek) =>
            base + perWeek / 7 * (day - d0);
        bandU = [
          Offset(d0 / windowDays, base),
          Offset(d1 / windowDays, at(d1, range.hi)),
        ];
        bandL = [
          Offset(d0 / windowDays, base),
          Offset(d1 / windowDays, at(d1, range.lo)),
        ];
        ys.addAll([at(d1, range.hi), at(d1, range.lo)]);
      }
      series.add(ChartSeries(
          [for (final w in inWindow) Offset(xOf(w.at), w.kg)], p.chartLabel,
          dotsOnly: true));
      (minY, maxY) = MultiLineChart.niceRange(ys);
    }
    final dateFmt = DateFormat('d MMM', locale);
    final xLabels = <(double, String)>[
      (0.0, dateFmt.format(from)),
      (
        0.5,
        dateFmt
            .format(DateTime(from.year, from.month, from.day + windowDays ~/ 2))
      ),
      (1.0, l10n.bodyToday),
    ];

    String signed(double v) => v.abs() < 0.05
        ? '0.0'
        : '${v > 0 ? '+' : '−'}${NumberFormat('0.0', locale).format(v.abs())}';

    final latest = all.isEmpty ? null : all.last;
    final listed = all.reversed.take(20).toList();

    return Scaffold(
      backgroundColor: p.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScreenTitle(l10n.progressBodyWeight),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, 0, AppSpacing.md, AppSpacing.lg),
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.end,
                    spacing: AppSpacing.xs,
                    children: [
                      Text(latest == null ? '—' : kgText(context, latest.kg),
                          key: const ValueKey('weight-latest'),
                          style: AppText.displayLarge
                              .copyWith(color: p.textPrimary)),
                      if (trend != null)
                        Text(l10n.bodyPerWeek('${signed(trend)} $unit'),
                            style: AppText.captionStrong.copyWith(
                                color: onTrack ? p.success : p.warning)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                      trend == null
                          ? l10n.bodyTrendNone(goalText)
                          : l10n.bodyTrendLine(goalText, 8),
                      style: AppText.caption.copyWith(color: p.textSecondary)),
                  const SizedBox(height: AppSpacing.sm),
                  Segmented<int>(
                    items: const [8, 26, 52],
                    selected: _weeks,
                    labelOf: (w) => switch (w) {
                      8 => l10n.bodyRange8,
                      26 => l10n.bodyRange26,
                      _ => l10n.bodyRange52,
                    },
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
                          series: series,
                          bandUpper: bandU,
                          bandLower: bandL,
                          bandColor: p.success,
                          height: 150,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        if (all.isEmpty)
                          Text(l10n.bodyEmpty,
                              style: AppText.caption
                                  .copyWith(color: p.textSecondary)),
                        Wrap(spacing: AppSpacing.sm, children: [
                          LegendDot(
                              color: p.textPrimary,
                              label: l10n.bodyLegendTrend),
                          LegendDot(
                              color: p.chartLabel,
                              label: l10n.bodyLegendWeighIns),
                          LegendDot(
                              color: p.success, label: l10n.bodyLegendGoal),
                        ]),
                      ],
                    ),
                  ),
                  if (adj != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    CoachCard(
                      eyebrow: l10n.bodyOffTrack(goalName),
                      title: '',
                      message:
                          adj > 0 ? l10n.bodyAdd(adj) : l10n.bodyCut(adj.abs()),
                      imageAsset: 'assets/images/felix_robot.png',
                      imageWidth: 56,
                      imageHeight: 80,
                      primaryLabel: l10n.bodyUpdateTargets,
                      onPrimary: () => context.push(AppRouter.nutritionTargets),
                      onAsk: () => askFelix(
                        context,
                        ref,
                        topic: AssistantTopic.nutrition,
                        draft: l10n.bodyAskDraft(
                          kgText(context, latest!.kg),
                          '${signed(trend!)} $unit',
                          goalText,
                        ),
                      ),
                    ),
                  ],
                  if (listed.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Text(l10n.bodyWeighIns,
                            style: AppText.headingS
                                .copyWith(color: p.textPrimary)),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(l10n.bodyWeighInsNote,
                              textAlign: TextAlign.end,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.caption
                                  .copyWith(color: p.textSecondary)),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    ProgressCard(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                      child: Column(
                        children: [
                          for (var i = 0; i < listed.length; i++)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.xs),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(kgText(context, listed[i].kg),
                                            style: AppText.bodyStrong.copyWith(
                                                color: p.textPrimary)),
                                        Text(
                                            DateFormat('EEE d MMM', locale)
                                                .format(listed[i].at),
                                            style: AppText.caption.copyWith(
                                                color: p.textSecondary)),
                                      ],
                                    ),
                                  ),
                                  if (i + 1 < all.length)
                                    Text(
                                        signed(listed[i].kg -
                                            all[all.length - 2 - i].kg),
                                        style: AppText.body14
                                            .copyWith(color: p.textSecondary)),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.md),
              child: AppButton(
                label: l10n.bodyLog,
                icon: Icons.add,
                size: AppButtonSize.large,
                expand: true,
                onPressed: _openSheet,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeightSheet extends ConsumerStatefulWidget {
  const _WeightSheet();

  @override
  ConsumerState<_WeightSheet> createState() => _WeightSheetState();
}

class _WeightSheetState extends ConsumerState<_WeightSheet> {
  late final TextEditingController _controller;
  bool _invalid = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final all = ref.read(bodyWeightProvider);
    _controller = TextEditingController(
        // The app language's decimal mark; _save reads either mark.
        text: all.isEmpty ? '' : formatKg(all.last.kg));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final kg = double.tryParse(_controller.text.trim().replaceAll(',', '.'));
    if (kg == null ||
        kg < BodyWeightStore.minKg ||
        kg > BodyWeightStore.maxKg) {
      setState(() => _invalid = true);
      return;
    }
    _saving = true;
    final now = ref.read(clockProvider)();
    await ref
        .read(bodyWeightProvider.notifier)
        .log(WeighIn(at: now, kg: (kg * 10).round() / 10));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = AppPalette.of(context);
    return SheetSafeArea(
        child: Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.bodySheetTitle,
                style: AppText.headingM.copyWith(color: p.textPrimary)),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              key: const ValueKey('weight-field'),
              controller: _controller,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: l10n.profileFieldWeightKg,
                errorText: _invalid ? l10n.bodyWeightRange : null,
                errorMaxLines: 2,
              ),
              onChanged: (_) {
                if (_invalid) setState(() => _invalid = false);
              },
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              key: const ValueKey('weight-save'),
              label: l10n.bodySave,
              size: AppButtonSize.large,
              expand: true,
              onPressed: _save,
            ),
          ],
        ),
      ),
    ));
  }
}
