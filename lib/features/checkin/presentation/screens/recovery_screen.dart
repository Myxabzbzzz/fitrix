import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fitrix/core/felix/ask_felix.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/time/today_provider.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/core/widgets/app_button.dart';
import 'package:fitrix/core/widgets/ask_felix_link.dart';
import 'package:fitrix/core/widgets/screen_title.dart';
import 'package:fitrix/core/widgets/section_header.dart';
import 'package:fitrix/features/checkin/data/checkin_models.dart';
import 'package:fitrix/features/checkin/data/checkin_store.dart';
import 'package:fitrix/features/checkin/presentation/providers/checkin_provider.dart';
import 'package:fitrix/features/checkin/presentation/widgets/checkin_sheet.dart';
import 'package:fitrix/features/checkin/presentation/widgets/checkin_text.dart';
import 'package:fitrix/features/checkin/presentation/widgets/readiness_ring.dart';
import 'package:fitrix/features/chat/data/models/assistant_topic.dart';
import 'package:fitrix/features/exercises/data/exercise_catalog.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/features/workouts/presentation/providers/workouts_provider.dart';
import 'package:fitrix/features/workouts/presentation/start_workout.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

/// Today's recovery: score ring, what shaped it, the adjusted plan and the
/// last 7 days.
class RecoveryScreen extends ConsumerWidget {
  const RecoveryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final checkIn = ref.watch(todayCheckInProvider);
    final r = ref.watch(todayReadinessProvider);

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            ScreenTitle(l10n.recoveryTitle),
            Expanded(
              child: checkIn == null || r == null
                  ? _Empty(l10n: l10n)
                  : _Content(checkIn: checkIn, readiness: r),
            ),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final AppLocalizations l10n;
  const _Empty({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(l10n.recoveryNoCheckin,
              textAlign: TextAlign.center,
              style: AppText.headingM.copyWith(color: palette.textPrimary)),
          const SizedBox(height: AppSpacing.xs),
          Text(l10n.recoveryNoCheckinBody,
              textAlign: TextAlign.center,
              style:
                  AppText.bodyRegular.copyWith(color: palette.textSecondary)),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: l10n.checkinCardAction,
            onPressed: () => showCheckInSheet(context),
          ),
        ],
      ),
    );
  }
}

class _Content extends ConsumerWidget {
  final CheckIn checkIn;
  final Readiness readiness;
  const _Content({required this.checkIn, required this.readiness});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final hardDays = ref.watch(hardDaysProvider);

    final template = ref.watch(todaysGymTemplateProvider);
    final catalog = ref.watch(exerciseCatalogProvider).valueOrNull;
    final applied = ref.watch(appliedSwapsProvider);
    final suggested = template == null || catalog == null
        ? const <Swap>[]
        : sparingSwaps(template, checkIn.sore, catalog);
    final shown = applied.isNotEmpty ? applied : suggested;

    final startButton = template == null
        ? null
        : AppButton(
            label: l10n.recoveryStartWorkout,
            expand: true,
            onPressed: () => startWorkout(context, ref, template),
          );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, 0, AppSpacing.md, AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.recoverySubtitle(DateFormat.Hm(locale).format(checkIn.at)),
            style: AppText.bodyRegular.copyWith(color: palette.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: ReadinessRing(
              score: readiness.score,
              size: 180,
              strokeWidth: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${readiness.score}%',
                      style: AppText.headingXL
                          .copyWith(color: palette.textPrimary)),
                  Text(l10n.recoveryRecovered,
                      style: AppText.caption
                          .copyWith(color: palette.textSecondary)),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(l10n.readinessLabel(readiness.label),
              textAlign: TextAlign.center,
              style: AppText.headingM.copyWith(color: palette.textPrimary)),
          Text(l10n.recoveryHint(readiness, checkIn),
              textAlign: TextAlign.center,
              style:
                  AppText.bodyRegular.copyWith(color: palette.textSecondary)),
          Center(
            child: AskFelixLink(
              onTap: () => askFelix(
                context,
                ref,
                topic:
                    AssistantTopic.all.firstWhere((t) => t.sport == Sport.gym),
                draft: l10n.recoveryAskDraft(
                  readiness.score,
                  l10n.readinessLabel(readiness.label),
                  l10n.sleepText(checkIn.sleep),
                  [
                    l10n.sorenessName(checkIn.soreness).toLowerCase(),
                    if (checkIn.sore.isNotEmpty)
                      '(${l10n.areasText(checkIn.sore)})',
                  ].join(' '),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SectionHeader(l10n.recoveryShaped),
          const SizedBox(height: AppSpacing.xs),
          Container(
            decoration: BoxDecoration(
                color: palette.tile, borderRadius: AppRadius.smAll),
            child: Column(
              children: [
                for (var i = 0; i < readiness.factors.length; i++) ...[
                  if (i > 0)
                    Divider(height: 1, thickness: 1, color: palette.background),
                  _FactorRow(
                    icon: _icons[i],
                    title: _title(l10n, readiness.factors[i].factor, hardDays),
                    subtitle:
                        _subtitle(l10n, readiness.factors[i].factor, hardDays),
                    delta: readiness.factors[i].delta,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (shown.isNotEmpty && template != null)
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                  color: palette.tile, borderRadius: AppRadius.smAll),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.recoveryPlanTitle.toUpperCase(),
                      style:
                          AppText.microStrong.copyWith(color: palette.accent)),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    _planText(l10n, template.name, shown, applied.isNotEmpty),
                    style: AppText.bodyRegular
                        .copyWith(color: palette.textPrimary),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(child: startButton!),
                      const SizedBox(width: AppSpacing.xs),
                      AppButton(
                        label: applied.isNotEmpty
                            ? l10n.recoveryUndo
                            : l10n.recoveryApplySwaps,
                        style: AppButtonStyle.secondary,
                        onPressed: () {
                          final n = ref.read(appliedSwapsProvider.notifier);
                          applied.isNotEmpty ? n.undo() : n.apply(suggested);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            )
          else if (startButton != null)
            startButton,
          const SizedBox(height: AppSpacing.lg),
          _Last7(now: ref.watch(todayProvider)),
        ],
      ),
    );
  }

  static const _icons = [
    Icons.bed_outlined,
    Icons.healing_outlined,
    Icons.battery_5_bar_outlined,
    Icons.cloud_outlined,
    Icons.bolt_outlined,
  ];

  String _title(AppLocalizations l10n, String factor, int hardDays) {
    switch (factor) {
      case ReadinessFactorKey.sleep:
        return l10n.factorSleep(l10n.sleepText(checkIn.sleep));
      case ReadinessFactorKey.soreness:
        return l10n
            .factorSoreness(l10n.sorenessName(checkIn.soreness).toLowerCase());
      case ReadinessFactorKey.energy:
        return l10n.factorEnergy(l10n.energyName(checkIn.energy).toLowerCase());
      case ReadinessFactorKey.stress:
        return l10n.factorStress(l10n.stressName(checkIn.stress).toLowerCase());
      default:
        return l10n.factorLoad;
    }
  }

  String? _subtitle(AppLocalizations l10n, String factor, int hardDays) {
    switch (factor) {
      case ReadinessFactorKey.sleep:
        return l10n.factorSleepQuality(l10n.qualityName(checkIn.quality));
      case ReadinessFactorKey.soreness:
        return checkIn.sore.isEmpty ? null : l10n.areasText(checkIn.sore);
      case ReadinessFactorKey.load:
        return l10n.factorLoadSub(hardDays);
      default:
        return null;
    }
  }

  String _planText(
      AppLocalizations l10n, String plan, List<Swap> swaps, bool applied) {
    final swapsText = swaps.map((s) => '${s.from} → ${s.to}').join(', ');
    final areas = l10n.areasText(checkIn.sore);
    return applied
        ? l10n.recoveryPlanApplied(plan, swapsText, areas)
        : l10n.recoveryPlanSuggested(plan, swapsText, areas);
  }
}

class _FactorRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final int delta;

  const _FactorRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.delta,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final color = delta > 0
        ? palette.accent
        : delta < 0
            ? palette.danger
            : palette.textSecondary;
    final sign = delta > 0
        ? '+'
        : delta < 0
            ? '−'
            : '';
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
                color: palette.buttonMuted, borderRadius: AppRadius.smAll),
            child: Icon(icon, size: 20, color: palette.textPrimary),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppText.bodyStrong
                        .copyWith(color: palette.textPrimary)),
                if (subtitle != null)
                  Text(subtitle!,
                      style: AppText.caption
                          .copyWith(color: palette.textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text('$sign${delta.abs()}',
              style: AppText.headingS.copyWith(color: color)),
        ],
      ),
    );
  }
}

class _Last7 extends ConsumerWidget {
  final DateTime now;
  const _Last7({required this.now});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final history = ref.watch(workoutHistoryProvider);
    final checkIns = ref.watch(checkInHistoryProvider);

    final today = DateTime(now.year, now.month, now.day);
    final days = [
      for (var i = 6; i >= 0; i--) today.subtract(Duration(days: i)),
    ];
    int? scoreFor(DateTime day) {
      for (final c in checkIns) {
        if (DateTime(c.at.year, c.at.month, c.at.day) == day) {
          return readiness(c, hardDaysLast7: hardDaysLast7(history, c.at))
              .score;
        }
      }
      return null;
    }

    final scores = [for (final d in days) scoreFor(d)];
    final present = scores.whereType<int>().toList();
    final avg = present.isEmpty
        ? null
        : (present.reduce((a, b) => a + b) / present.length).round();
    const barArea = 96.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(l10n.recoveryLast7,
            actionLabel: avg == null ? null : l10n.recoveryAvg(avg)),
        const SizedBox(height: AppSpacing.xs),
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration:
              BoxDecoration(color: palette.tile, borderRadius: AppRadius.smAll),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < days.length; i++)
                Expanded(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
                    child: Column(
                      children: [
                        SizedBox(
                          height: barArea + 20,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(scores[i]?.toString() ?? '–',
                                  style: AppText.captionStrong
                                      .copyWith(color: palette.textPrimary)),
                              const SizedBox(height: AppSpacing.xxs),
                              if (scores[i] != null)
                                Container(
                                  height: barArea * scores[i]! / 100,
                                  decoration: BoxDecoration(
                                    color: i == days.length - 1
                                        ? palette.accent
                                        : palette.buttonMuted,
                                    borderRadius:
                                        BorderRadius.circular(AppSpacing.xxs),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(DateFormat.E(locale).format(days[i]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.caption
                                .copyWith(color: palette.textSecondary)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
