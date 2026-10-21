import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fitrix/core/router/app_router.dart';
import 'package:fitrix/core/felix/ask_felix.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/core/widgets/coach_card.dart';
import 'package:fitrix/core/time/today_provider.dart';
import 'package:fitrix/features/chat/data/models/assistant_topic.dart';
import 'package:fitrix/features/workouts/domain/coach_message.dart';
import 'package:fitrix/core/widgets/pill_selector.dart';
import 'package:fitrix/core/widgets/screen_title.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/features/workouts/presentation/providers/workouts_provider.dart';
import 'package:fitrix/features/plan/data/week_plan.dart';
import 'package:fitrix/features/plan/presentation/providers/week_plan_provider.dart';
import 'package:fitrix/features/workouts/presentation/start_workout.dart';
import 'package:fitrix/core/widgets/sync_refresh.dart';
import 'package:fitrix/features/workouts/presentation/widgets/workouts_grid.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';
import 'package:fitrix/features/workouts/presentation/sport_l10n.dart';

/// Workouts of one sport ("Gym"): the sport's plans, marked with the day
/// the week plan has them on.
class SportWorkoutsScreen extends ConsumerStatefulWidget {
  final Sport sport;

  const SportWorkoutsScreen({super.key, required this.sport});

  @override
  ConsumerState<SportWorkoutsScreen> createState() =>
      _SportWorkoutsScreenState();
}

class _SportWorkoutsScreenState extends ConsumerState<SportWorkoutsScreen> {
  late Sport _sport = widget.sport;

  Future<void> _start(WorkoutTemplate template) =>
      startWorkout(context, ref, template);

  /// Opens this sport's Felix trainer chat (the Felix tab) with a question
  /// about what the coach card says, ready to send.
  void _askFelix(({CoachMessageKind kind, int days, String today}) coach) {
    final l10n = AppLocalizations.of(context);
    askFelix(
      context,
      ref,
      topic: AssistantTopic.forSport(_sport),
      draft: switch (coach.kind) {
        CoachMessageKind.firstWorkout =>
          l10n.gymAskFirstDraft(_sport.localizedLabel(l10n)),
        CoachMessageKind.welcomeBack => l10n.gymAskBackDraft(coach.days),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final workouts = ref.watch(workoutsForSportProvider(_sport));
    final history = ref
        .watch(workoutHistoryProvider)
        .where((w) => w.sport == _sport)
        .toList();
    final today = ref.watch(todayProvider);
    final plan = ref.watch(weekPlanProvider);
    final allHistory = ref.watch(workoutHistoryProvider);
    final localeName = Localizations.localeOf(context).toString();
    bool openToday(WorkoutTemplate t) => plan.any((s) =>
        s.templateId == t.id &&
        s.day == today &&
        statusOf(s, allHistory, today) != SessionStatus.done);
    // The coach card follows the same rule: today's session, else the next
    // planned one; the first plan only while this sport isn't planned.
    final sportPlanned = planInUse([
      for (final s in plan)
        if (s.sport == _sport) s
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

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScreenTitle(_sport.localizedLabel(l10n)),
            PillSelector<Sport>(
              items: Sport.values,
              selected: _sport,
              labelOf: (s) => s.localizedLabel(l10n),
              onSelected: (s) => s == Sport.running
                  ? context.pushReplacement(AppRouter.sportWorkouts(s))
                  : setState(() => _sport = s),
            ),
            Expanded(
              child: SyncRefresh(
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    WorkoutsGrid(
                      sport: _sport,
                      actionLabel: l10n.gymStart,
                      onAction: _start,
                    ),
                    if (coach != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      CoachCard(
                        eyebrow:
                            l10n.gymCoachEyebrow(_sport.localizedLabel(l10n)),
                        title: switch (coach.kind) {
                          CoachMessageKind.firstWorkout =>
                            l10n.gymCoachFirstTitle,
                          CoachMessageKind.welcomeBack =>
                            l10n.gymCoachBackTitle,
                        },
                        message: switch (coach.kind) {
                          CoachMessageKind.firstWorkout =>
                            l10n.gymCoachFirstMessage(coach.today),
                          CoachMessageKind.welcomeBack =>
                            l10n.gymCoachBackMessage(coach.days),
                        },
                        imageAsset: 'assets/images/felix_avatar.png',
                        primaryLabel: coachPlan == null ? null : l10n.gymStart,
                        onPrimary:
                            coachPlan == null ? null : () => _start(coachPlan!),
                        secondaryLabel: l10n.gymAskFelix,
                        onSecondary: () => _askFelix(coach),
                      ),
                    ],
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
