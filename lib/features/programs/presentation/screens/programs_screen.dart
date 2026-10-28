import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitrix/core/navigation/circle_reveal.dart';
import 'package:fitrix/core/router/app_router.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/core/time/today_provider.dart';
import 'package:fitrix/core/widgets/app_button.dart';
import 'package:fitrix/core/widgets/coach_card.dart';
import 'package:fitrix/core/widgets/pill_selector.dart';
import 'package:fitrix/core/widgets/screen_title.dart';
import 'package:fitrix/features/plan/presentation/widgets/plan_format.dart';
import 'package:fitrix/features/programs/data/program_store.dart';
import 'package:fitrix/features/profile/presentation/providers/profile_provider.dart';
import 'package:fitrix/features/programs/domain/program_catalog.dart';
import 'package:fitrix/features/programs/domain/program_progress.dart';
import 'package:fitrix/features/programs/presentation/providers/programs_provider.dart';
import 'package:fitrix/features/programs/presentation/widgets/program_widgets.dart';
import 'package:fitrix/features/workouts/presentation/providers/workouts_provider.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

enum _Filter { all, muscle, strength, fatLoss, beginner, atHome }

/// "Programs": the active program, Felix's pick and the catalog with filters.
class ProgramsScreen extends ConsumerStatefulWidget {
  const ProgramsScreen({super.key});

  @override
  ConsumerState<ProgramsScreen> createState() => _ProgramsScreenState();
}

class _ProgramsScreenState extends ConsumerState<ProgramsScreen> {
  _Filter _filter = _Filter.all;

  /// 0 = any, 3, 4, 5 = five or more.
  int _days = 0;

  bool _matches(TrainingProgram p) {
    final byFilter = switch (_filter) {
      _Filter.all => true,
      _Filter.muscle => p.goals.contains('muscle'),
      _Filter.strength => p.goals.contains('strength'),
      _Filter.fatLoss => p.goals.contains('fat_loss'),
      _Filter.beginner => p.level == 'beginner',
      _Filter.atHome => p.atHome,
    };
    final byDays = switch (_days) {
      0 => true,
      5 => p.perWeek >= 5,
      final n => p.perWeek == n,
    };
    return byFilter && byDays;
  }

  String _filterLabel(AppLocalizations l10n, _Filter f) => switch (f) {
        _Filter.all => l10n.programsFilterAll,
        _Filter.muscle => l10n.programsGoalMuscle,
        _Filter.strength => l10n.programsGoalStrength,
        _Filter.fatLoss => l10n.programsGoalFatLoss,
        _Filter.beginner => l10n.programsLevelBeginner,
        _Filter.atHome => l10n.programsAtHome,
      };

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final catalog = ref.watch(programCatalogProvider).valueOrNull;
    final info = ref.watch(activeProgramInfoProvider);
    final profile = ref.watch(profileProvider).valueOrNull;
    final programs = catalog?.programs ?? const <TrainingProgram>[];
    final goal = profile?.goal ?? '';
    final experience = profile?.experience ?? '';
    final picked = pickProgram(programs, goal, experience);
    // Without a goal or experience to match, the first program is only a
    // place to start, not a pick.
    final fit = picked == null ? null : programFit(picked, goal, experience);
    final shown = [
      for (final p in programs)
        if (_matches(p)) p
    ];

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScreenTitle(l10n.programsTitle),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.lg),
                children: [
                  if (info != null) ...[
                    _ActiveCard(
                        key: const Key('programs-active-card'),
                        active: info.active,
                        program: info.program),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  if (picked != null) ...[
                    KeyedSubtree(
                      key: const Key('programs-picked'),
                      child: CoachCard(
                        eyebrow: fit == ProgramFit.none
                            ? l10n.programsStartEyebrow
                            : l10n.programsPickedEyebrow,
                        title: '',
                        message: (switch (fit!) {
                          ProgramFit.goalAndLevel => l10n.programsPickedText,
                          ProgramFit.goal => l10n.programsPickedGoalText,
                          ProgramFit.level => l10n.programsPickedLevelText,
                          ProgramFit.none => l10n.programsStartText,
                        })(picked.name, picked.perWeek,
                            programLevelLabel(l10n, picked.level)),
                        imageAsset: 'assets/images/felix_robot.png',
                        imageWidth: 56,
                        imageHeight: 80,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  PillSelector<_Filter>(
                    bleed: AppSpacing.md,
                    items: _Filter.values,
                    selected: _filter,
                    labelOf: (f) => _filterLabel(l10n, f),
                    onSelected: (f) => setState(() => _filter = f),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: Text(l10n.programsDaysAWeek,
                            style: AppText.headingS
                                .copyWith(color: palette.textPrimary)),
                      ),
                      Text(l10n.programsCount(shown.length),
                          style: AppText.body14
                              .copyWith(color: palette.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      for (final d in const [0, 3, 4, 5]) ...[
                        if (d != 0) const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: _DaysSegment(
                            key: Key('programs-days-$d'),
                            label: d == 0
                                ? l10n.programsAny
                                : d == 5
                                    ? '5+'
                                    : '$d',
                            selected: _days == d,
                            onTap: () => setState(() => _days = d),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (catalog != null && shown.isEmpty)
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                      child: Text(l10n.programsEmptyFilter,
                          textAlign: TextAlign.center,
                          style: AppText.bodyRegular
                              .copyWith(color: palette.textSecondary)),
                    ),
                  for (final p in shown) ...[
                    _ProgramCard(
                        program: p,
                        felixPick:
                            p.id == picked?.id && fit != ProgramFit.none),
                    const SizedBox(height: AppSpacing.sm),
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

class _DaysSegment extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _DaysSegment(
      {super.key,
      required this.label,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? palette.pillSelected : palette.tile,
            borderRadius: AppRadius.smAll,
          ),
          child: Text(label,
              style: AppText.headingS.copyWith(
                  color:
                      selected ? palette.onPillSelected : palette.textPrimary)),
        ),
      ),
    );
  }
}

class _ActiveCard extends ConsumerWidget {
  final ActiveProgram active;
  final TrainingProgram program;
  const _ActiveCard({super.key, required this.active, required this.program});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final today = ref.watch(todayProvider);
    final history = ref.watch(workoutHistoryProvider);
    final slots = programSlots(program, active, history);
    final stats = programStats(slots, today, history, active.start);
    final week = programWeek(active, program, today);
    final next = nextSlot(slots, today);
    final onDark = palette.onPillSelected;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
          color: palette.pillSelected, borderRadius: AppRadius.mdAll),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.sm,
            children: [
              Text(l10n.programsActiveEyebrow.toUpperCase(),
                  style: AppText.captionStrong
                      .copyWith(color: onDark.withValues(alpha: 0.7))),
              Text(l10n.programsWeekOf(week, program.weeks),
                  style: AppText.body14
                      .copyWith(color: onDark.withValues(alpha: 0.7))),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(program.name.toUpperCase(),
              style: AppText.displayMedium.copyWith(color: onDark)),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            next == null
                ? l10n.programsNoneLeft
                : l10n.programsNext(
                    next.session.title,
                    weekdayFull(context, next.session.day.weekday),
                    planDuration(l10n, next.session.minutes)),
            style:
                AppText.body14.copyWith(color: onDark.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: AppSpacing.sm),
          WeekDots(
            weeks: program.weeks,
            current: week,
            deloadWeek: program.deloadWeek,
            doneColor: onDark,
            doneText: palette.pillSelected,
            upcomingColor: onDark.withValues(alpha: 0.18),
            upcomingText: onDark.withValues(alpha: 0.7),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Text(l10n.programsDoneOf(stats.done, stats.planned),
                    style: AppText.body14
                        .copyWith(color: onDark.withValues(alpha: 0.7))),
              ),
              const SizedBox(width: AppSpacing.xs),
              Builder(
                builder: (btnContext) => AppButton(
                  label: l10n.programsOpen,
                  size: AppButtonSize.small,
                  onPressed: () =>
                      openWithReveal(btnContext, AppRouter.programsActive),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgramCard extends StatelessWidget {
  final TrainingProgram program;
  final bool felixPick;
  const _ProgramCard({required this.program, required this.felixPick});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    return Builder(
      builder: (cardContext) => Semantics(
        button: true,
        child: GestureDetector(
          key: Key('programs-card-${program.id}'),
          behavior: HitTestBehavior.opaque,
          onTap: () =>
              openWithReveal(cardContext, AppRouter.program(program.id)),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
                color: palette.tile, borderRadius: AppRadius.mdAll),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(program.name.toUpperCase(),
                              style: AppText.displayMedium
                                  .copyWith(color: palette.textPrimary)),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(program.author,
                              style: AppText.body14
                                  .copyWith(color: palette.textSecondary)),
                        ],
                      ),
                    ),
                    if (felixPick)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs,
                            vertical: AppSpacing.xxs),
                        decoration: BoxDecoration(
                            color: palette.accentSoft,
                            borderRadius: AppRadius.fullAll),
                        child: Text(l10n.programsFelixPick,
                            style: AppText.captionStrong
                                .copyWith(color: palette.accent)),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xxs,
                  children: [
                    ProgramTag(l10n.programsPerWeek(program.perWeek)),
                    ProgramTag(programLevelLabel(l10n, program.level)),
                    ProgramTag(programGoalsText(l10n, program)),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(program.summary,
                    style: AppText.bodyRegular
                        .copyWith(color: palette.textPrimary)),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                          l10n.programsWeeksMin(
                              program.weeks, program.sessionMinutes),
                          style: AppText.body14
                              .copyWith(color: palette.textSecondary)),
                    ),
                    Text('${l10n.programsDetails} ›',
                        style:
                            AppText.bodyStrong.copyWith(color: palette.accent)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
