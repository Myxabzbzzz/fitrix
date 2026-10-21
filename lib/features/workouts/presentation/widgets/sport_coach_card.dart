import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
        statusOf(s, allHistory, today) != SessionStatus.done);
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
        todayWorkout: coachPlan?.name, localeName: localeName);
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
          CoachMessageKind.firstWorkout =>
            l10n.gymCoachFirstMessage(coach.today),
          CoachMessageKind.welcomeBack => l10n.gymCoachBackMessage(coach.days),
        },
        imageAsset: 'assets/images/felix_avatar.png',
        primaryLabel: suggested == null ? null : l10n.gymStart,
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
