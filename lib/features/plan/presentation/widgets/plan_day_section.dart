import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitrix/features/workouts/presentation/sport_l10n.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/core/widgets/app_button.dart';
import 'package:fitrix/features/plan/data/week_plan.dart';
import 'package:fitrix/features/plan/presentation/widgets/plan_format.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/features/workouts/presentation/start_workout.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

class PlanDaySection extends ConsumerWidget {
  final DateTime day;
  final DateTime today;
  final List<PlannedSession> sessions;
  final List<CompletedWorkout> history;
  final List<WorkoutTemplate> templates;

  const PlanDaySection({
    super.key,
    required this.day,
    required this.today,
    required this.sessions,
    required this.history,
    required this.templates,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final isToday = day == today;
    final statuses = [for (final s in sessions) statusOf(s, history, today)];
    final label = weekdayAndDate(context, day);
    final String? trailing;
    if (sessions.isEmpty) {
      trailing = null;
    } else if (statuses.every((s) => s == SessionStatus.done)) {
      trailing = l10n.planDoneCount(sessions.length);
    } else if (statuses.contains(SessionStatus.missed)) {
      trailing = l10n.planMissedHeader;
    } else {
      trailing = l10n.planPlannedCount(sessions.length);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                isToday ? l10n.planTodayDay(label) : label,
                style: AppText.headingS.copyWith(
                    color: isToday ? palette.accent : palette.textPrimary),
              ),
            ),
            if (trailing != null)
              Text(trailing,
                  style:
                      AppText.caption.copyWith(color: palette.textSecondary)),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        if (sessions.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              borderRadius: AppRadius.smAll,
              border: Border.all(color: palette.border),
            ),
            child: Row(
              children: [
                Icon(Icons.dark_mode_outlined,
                    size: 20, color: palette.textSecondary),
                const SizedBox(width: AppSpacing.sm),
                Text(l10n.planRestDay,
                    style:
                        AppText.body14.copyWith(color: palette.textSecondary)),
              ],
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
                color: palette.tile, borderRadius: AppRadius.smAll),
            child: Column(
              children: [
                for (var i = 0; i < sessions.length; i++) ...[
                  if (i > 0) Divider(height: 1, color: palette.border),
                  _SessionRow(
                    session: sessions[i],
                    status: statuses[i],
                    history: history,
                    templates: templates,
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _SessionRow extends ConsumerWidget {
  final PlannedSession session;
  final SessionStatus status;
  final List<CompletedWorkout> history;
  final List<WorkoutTemplate> templates;

  const _SessionRow({
    required this.session,
    required this.status,
    required this.history,
    required this.templates,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final s = session;
    final template = templates.where((t) => t.id == s.templateId).firstOrNull;

    final String meta;
    if (status == SessionStatus.done) {
      final w = completedFor(s, history)!;
      final d =
          planDuration(l10n, w.finishedAt.difference(w.startedAt).inMinutes);
      meta = w.sessionRpe == null ? d : l10n.planDoneMeta(d, w.sessionRpe!);
    } else if (template != null) {
      meta = l10n.planExercisesMeta(
          template.exercises.length, planDuration(l10n, s.minutes));
    } else {
      meta = planDuration(l10n, s.minutes);
    }

    Widget trailing;
    switch (status) {
      case SessionStatus.done:
        trailing = Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
              color: palette.pillSelected, shape: BoxShape.circle),
          child: Icon(Icons.check, size: 16, color: palette.onPillSelected),
        );
      case SessionStatus.missed:
        trailing = PlanChip(
          label: l10n.planMissed,
          background: palette.danger.withValues(alpha: 0.12),
          foreground: palette.danger,
        );
      case SessionStatus.today when template != null:
        trailing = AppButton(
          key: Key('plan-start-${s.id}'),
          label: template.sport.actionLabel(l10n),
          size: AppButtonSize.small,
          onPressed: () => startWorkout(context, ref, template),
        );
      default:
        trailing = PlanChip.intensity(context, s.intensity);
    }

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: palette.accentSoft, borderRadius: AppRadius.smAll),
            child: Icon(_icon(s.sport), size: 20, color: palette.accent),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style:
                        AppText.headingS.copyWith(color: palette.textPrimary)),
                Text(meta,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style:
                        AppText.caption.copyWith(color: palette.textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          trailing,
        ],
      ),
    );
  }

  IconData _icon(Sport sport) => switch (sport) {
        Sport.gym => Icons.fitness_center,
        Sport.fitness => Icons.self_improvement,
        Sport.cycling => Icons.directions_bike,
        Sport.running => Icons.directions_run,
        Sport.football => Icons.sports_soccer,
        Sport.winterSports => Icons.downhill_skiing,
      };
}
