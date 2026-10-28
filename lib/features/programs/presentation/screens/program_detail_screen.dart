import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fitrix/core/felix/ask_felix.dart';
import 'package:fitrix/core/router/app_router.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/core/widgets/app_button.dart';
import 'package:fitrix/core/widgets/coach_card.dart';
import 'package:fitrix/core/widgets/pill_selector.dart';
import 'package:fitrix/core/widgets/screen_title.dart';
import 'package:fitrix/features/chat/data/models/assistant_topic.dart';
import 'package:fitrix/features/plan/data/week_plan.dart';
import 'package:fitrix/features/plan/presentation/providers/week_plan_provider.dart';
import 'package:fitrix/features/plan/presentation/widgets/plan_day_section.dart';
import 'package:fitrix/features/plan/presentation/widgets/plan_format.dart';
import 'package:fitrix/features/programs/domain/program_catalog.dart';
import 'package:fitrix/features/programs/presentation/screens/start_program_sheet.dart';
import 'package:fitrix/features/programs/presentation/widgets/program_widgets.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

/// One program: facts, your week with clashes, the sessions, how you
/// progress and the Start button.
class ProgramDetailScreen extends ConsumerStatefulWidget {
  final String id;
  const ProgramDetailScreen({super.key, required this.id});

  @override
  ConsumerState<ProgramDetailScreen> createState() =>
      _ProgramDetailScreenState();
}

class _ProgramDetailScreenState extends ConsumerState<ProgramDetailScreen> {
  int _session = 0;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final catalog = ref.watch(programCatalogProvider).valueOrNull;
    final p = catalog?.byId(widget.id);
    if (p == null) {
      return Scaffold(
        backgroundColor: palette.background,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ScreenTitle(l10n.programTitle),
              if (catalog != null)
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Text(l10n.programNotFound,
                      style: AppText.bodyRegular
                          .copyWith(color: palette.textSecondary)),
                ),
            ],
          ),
        ),
      );
    }

    final nonGym = ref.watch(upcomingNonGymProvider);
    final weekdays = defaultWeekdays(p, nonGym);
    final clashes = clashingWeekdays(p, nonGym);
    final hardDays = hardNonGymWeekdays(nonGym).toList()..sort();
    final session = p.sessions[_session.clamp(0, p.sessions.length - 1)];

    PlannedSession? other(int weekday) {
      for (final s in nonGym) {
        if (s.day.weekday == weekday) return s;
      }
      return null;
    }

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScreenTitle(l10n.programTitle),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, 0, AppSpacing.md, AppSpacing.lg),
                children: [
                  Text(p.name,
                      style: AppText.displayLarge
                          .copyWith(color: palette.textPrimary)),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(p.author,
                      style: AppText.body14
                          .copyWith(color: palette.textSecondary)),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xxs,
                    children: [
                      ProgramTag(programLevelLabel(l10n, p.level)),
                      ProgramTag(programGoalsText(l10n, p)),
                      if (p.atHome) ProgramTag(l10n.programsAtHome),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      _Fact(
                          l10n.programLength, l10n.programWeeksShort(p.weeks)),
                      const SizedBox(width: AppSpacing.xs),
                      _Fact(l10n.programPerWeekLabel, '${p.perWeek}×'),
                      const SizedBox(width: AppSpacing.xs),
                      _Fact(l10n.programSessionLabel,
                          planDuration(l10n, p.sessionMinutes)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(p.summary,
                      style: AppText.bodyRegular
                          .copyWith(color: palette.textPrimary)),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: Text(l10n.programYourWeek,
                            style: AppText.headingS
                                .copyWith(color: palette.textPrimary)),
                      ),
                      if (clashes.isNotEmpty)
                        Text(l10n.programClashes(clashes.length),
                            key: const Key('program-clashes'),
                            style:
                                AppText.body14.copyWith(color: palette.danger)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var d = 1; d <= 7; d++) ...[
                          if (d > 1) const SizedBox(width: AppSpacing.xxs),
                          Expanded(
                            child: _DayTile(
                              day: weekdayName(context, d),
                              label: weekdays.contains(d)
                                  ? p.sessionAt(weekdays.indexOf(d)).name
                                  : other(d)?.title ?? l10n.programRest,
                              // Other sports show as their icon: their
                              // titles don't fit a seventh of the width.
                              icon: weekdays.contains(d)
                                  ? null
                                  : switch (other(d)) {
                                      final s? => sportIcon(s.sport),
                                      null => null,
                                    },
                              training: weekdays.contains(d),
                              clash: hardDays.contains(d),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: Text(session.name,
                            style: AppText.headingM
                                .copyWith(color: palette.textPrimary)),
                      ),
                      Text(l10n.programWorkoutsCount(p.sessions.length),
                          style: AppText.body14
                              .copyWith(color: palette.textSecondary)),
                    ],
                  ),
                  if (p.sessions.length > 1) ...[
                    const SizedBox(height: AppSpacing.xs),
                    PillSelector<int>(
                      items: [for (var i = 0; i < p.sessions.length; i++) i],
                      selected: _session,
                      labelOf: (i) => p.sessions[i].name,
                      onSelected: (i) => setState(() => _session = i),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
                    decoration: BoxDecoration(
                        color: palette.tile, borderRadius: AppRadius.mdAll),
                    child: Column(
                      children: [
                        for (var i = 0; i < session.exercises.length; i++) ...[
                          if (i > 0) Divider(height: 1, color: palette.border),
                          _ExerciseRow(session.exercises[i]),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(l10n.programHowYouProgress,
                      style: AppText.headingS
                          .copyWith(color: palette.textPrimary)),
                  const SizedBox(height: AppSpacing.xs),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                        color: palette.tile, borderRadius: AppRadius.mdAll),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var i = 0; i < p.progressionRules.length; i++) ...[
                          if (i > 0) const SizedBox(height: AppSpacing.sm),
                          _Rule(p.progressionRules[i]),
                        ],
                      ],
                    ),
                  ),
                  if (clashes.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    KeyedSubtree(
                      key: const Key('program-felix-card'),
                      child: CoachCard(
                        eyebrow: l10n.programFelixEyebrow,
                        title: '',
                        message: l10n.programFelixText(
                          hardDays
                              .map((d) => weekdayFull(context, d))
                              .join(', '),
                          nonGym
                              .where((s) =>
                                  s.intensity == Intensity.hard &&
                                  hardDays.contains(s.day.weekday))
                              .map((s) => s.title)
                              .toSet()
                              .join(', '),
                        ),
                        imageAsset: 'assets/images/felix_robot.png',
                        imageWidth: 56,
                        imageHeight: 80,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
              decoration: BoxDecoration(
                color: palette.background,
                border: Border(top: BorderSide(color: palette.border)),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: l10n.programAskFelix,
                        style: AppButtonStyle.secondary,
                        size: AppButtonSize.large,
                        icon: Icons.chat_bubble_outline,
                        expand: true,
                        onPressed: () => askFelix(context, ref,
                            topic: AssistantTopic.forSport(Sport.gym),
                            draft: l10n.programAskFelixDraft(p.name)),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: AppButton(
                        key: const Key('program-start'),
                        label: l10n.programStart,
                        size: AppButtonSize.large,
                        expand: true,
                        onPressed: () async {
                          final started =
                              await showStartProgramSheet(context, p, weekdays);
                          if (started == true && context.mounted) {
                            context.go(AppRouter.programsActive);
                          }
                        },
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

class _Fact extends StatelessWidget {
  final String label;
  final String value;
  const _Fact(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration:
            BoxDecoration(color: palette.tile, borderRadius: AppRadius.mdAll),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(label,
                  maxLines: 1,
                  style:
                      AppText.caption.copyWith(color: palette.textSecondary)),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value,
                  maxLines: 1,
                  style: AppText.headingM.copyWith(color: palette.textPrimary)),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayTile extends StatelessWidget {
  final String day;
  final String label;

  /// Shown instead of [label] (which becomes its semantics label).
  final IconData? icon;
  final bool training;
  final bool clash;
  const _DayTile(
      {required this.day,
      required this.label,
      this.icon,
      required this.training,
      required this.clash});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final bg = training
        ? palette.pillSelected
        : clash
            ? palette.danger.withValues(alpha: 0.12)
            : palette.tile;
    final fg = training
        ? palette.onPillSelected
        : clash
            ? palette.danger
            : palette.textPrimary;
    final icon = this.icon;
    return Container(
      padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.xs, horizontal: AppSpacing.xxs),
      decoration: BoxDecoration(color: bg, borderRadius: AppRadius.smAll),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(day.toUpperCase(),
                maxLines: 1, style: AppText.microStrong.copyWith(color: fg)),
          ),
          const SizedBox(height: AppSpacing.xxs),
          if (icon != null)
            Tooltip(
              message: label,
              child: Icon(icon,
                  size: AppText.headingS.fontSize,
                  color: fg,
                  semanticLabel: label),
            )
          else
            // One line, shrunk to fit: "Upper 1" never splits mid-word.
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(label,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: AppText.micro.copyWith(color: fg)),
            ),
        ],
      ),
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  final ProgramExercise e;
  const _ExerciseRow(this.e);

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(e.exercise,
                style: AppText.body14.copyWith(color: palette.textPrimary)),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text.rich(
            TextSpan(children: [
              TextSpan(
                  text: setsReps(e),
                  style:
                      AppText.bodyStrong.copyWith(color: palette.textPrimary)),
              TextSpan(
                  text: ' ${l10n.programRir(e.rir)}',
                  style:
                      AppText.caption.copyWith(color: palette.textSecondary)),
            ]),
          ),
        ],
      ),
    );
  }
}

class _Rule extends StatelessWidget {
  final String rule;
  const _Rule(this.rule);

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final i = rule.indexOf(': ');
    final title = i < 0 ? rule : rule.substring(0, i);
    final body = i < 0 ? '' : rule.substring(i + 2);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: AppText.bodyStrong.copyWith(color: palette.textPrimary)),
        if (body.isNotEmpty)
          Text(body,
              style:
                  AppText.bodyRegular.copyWith(color: palette.textSecondary)),
      ],
    );
  }
}
