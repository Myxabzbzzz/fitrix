import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitrix/core/i18n/catalog_text.dart';
import 'package:fitrix/core/felix/ask_felix.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/core/time/today_provider.dart';
import 'package:fitrix/core/widgets/coach_card.dart';
import 'package:fitrix/features/chat/data/models/assistant_topic.dart';
import 'package:fitrix/features/plan/data/week_plan.dart';
import 'package:fitrix/features/plan/presentation/providers/week_plan_provider.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/features/workouts/domain/coach_message.dart';
import 'package:fitrix/features/workouts/presentation/providers/workouts_provider.dart';
import 'package:fitrix/features/workouts/presentation/sport_l10n.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

/// The Felix coach card of a sport's workouts page: a message about the
/// sport's plan and an "Ask Felix" button that opens that sport's trainer
/// chat. Nothing when there is no message. [onStart] runs the plan the
/// card suggests.
class SportCoachCard extends ConsumerWidget {
  const SportCoachCard({super.key, required this.sport, required this.onStart});

  final Sport sport;
  final void Function(WorkoutTemplate) onStart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final workouts = ref.watch(workoutsForSportProvider(sport));
    final allHistory = ref.watch(workoutHistoryProvider);
    final history = allHistory.where((w) => w.sport == sport).toList();
    final today = ref.watch(todayProvider);
    final plan = ref.watch(weekPlanProvider);
    final localeName = Localizations.localeOf(context).toString();
    bool openToday(WorkoutTemplate t) => plan.any((s) =>
        s.templateId == t.id &&
        s.day == today &&
        statusOf(s, allHistory, today, plan: plan) != SessionStatus.done);
    // Today's session, else the next planned one; the first plan only while
    // this sport isn't planned.
    final sportPlanned = planInUse([
      for (final s in plan)
        if (s.sport == sport) s
    ], today);
    WorkoutTemplate? coachPlan = workouts.where(openToday).firstOrNull;
    if (coachPlan == null) {
      final next = nextSessionAfter(plan, today,
          where: (s) => workouts.any((t) => t.id == s.templateId));
      coachPlan = next == null
          ? null
          : workouts.firstWhere((t) => t.id == next.templateId);
    }
    if (coachPlan == null && !sportPlanned) coachPlan = workouts.firstOrNull;
    final coach = coachMessage(history, today,
        todayWorkout: coachPlan == null
            ? null
            : ref.watch(catalogTextProvider).templateName(coachPlan),
        localeName: localeName);
    if (coach == null) return const SizedBox.shrink();
    final suggested = coachPlan;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: CoachCard(
        eyebrow: l10n.gymCoachEyebrow(sport.localizedLabel(l10n)),
        title: switch (coach.kind) {
          CoachMessageKind.firstWorkout => l10n.gymCoachFirstTitle,
          CoachMessageKind.welcomeBack => l10n.gymCoachBackTitle,
        },
        message: switch (coach.kind) {
          // Without a plan there is no workout to name (the slot would
          // get a weekday).
          CoachMessageKind.firstWorkout =>
            _firstMessage(l10n, sport, suggested == null ? null : coach.today),
          CoachMessageKind.welcomeBack => l10n.gymCoachBackMessage(coach.days),
        },
        imageAsset: 'assets/images/felix_avatar.png',
        primaryLabel: suggested == null ? null : sport.actionLabel(l10n),
        onPrimary: suggested == null ? null : () => onStart(suggested),
        secondaryLabel: l10n.gymAskFelix,
        onSecondary: () => askFelix(
          context,
          ref,
          topic: AssistantTopic.forSport(sport),
          draft: switch (coach.kind) {
            CoachMessageKind.firstWorkout =>
              l10n.gymAskFirstDraft(sport.localizedLabel(l10n)),
            CoachMessageKind.welcomeBack => l10n.gymAskBackDraft(coach.days),
          },
        ),
      ),
    );
  }
}

/// The first-run message: what Felix does with this sport's records. With
/// [workout], it starts with that plan.
String _firstMessage(AppLocalizations l10n, Sport sport, String? workout) =>
    switch (sport) {
      Sport.gym => workout == null
          ? l10n.coachFirstMessageNoPlan
          : l10n.gymCoachFirstMessage(workout),
      Sport.running => workout == null
          ? l10n.coachFirstRunningNoPlan
          : l10n.coachFirstRunning(workout),
      Sport.cycling => workout == null
          ? l10n.coachFirstCyclingNoPlan
          : l10n.coachFirstCycling(workout),
      Sport.football => workout == null
          ? l10n.coachFirstFootballNoPlan
          : l10n.coachFirstFootball(workout),
      Sport.winterSports => workout == null
          ? l10n.coachFirstSkiingNoPlan
          : l10n.coachFirstSkiing(workout),
      Sport.fitness => workout == null
          ? l10n.coachFirstMessageNoPlan
          : l10n.coachFirstMessageSport(workout),
    };
