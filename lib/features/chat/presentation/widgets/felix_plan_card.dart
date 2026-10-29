import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitrix/core/widgets/felix_avatar.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/core/time/today_provider.dart';
import 'package:fitrix/core/widgets/app_button.dart';
import 'package:fitrix/features/chat/data/models/chat_action.dart';
import 'package:fitrix/features/plan/presentation/widgets/plan_format.dart';
import 'package:fitrix/features/workouts/data/felix_templates_store.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

/// The workout plan Felix proposes: a calm card with the sessions and one
/// confident button. After adding it turns into a quiet "Added" row with
/// Open and Undo.
class FelixPlanCard extends ConsumerWidget {
  final WorkoutPlanAction action;
  final bool applied;

  /// Whether Undo is offered once added.
  final bool canUndo;
  final bool busy;
  final VoidCallback onApply;
  final VoidCallback onUndo;
  final VoidCallback onOpen;

  const FelixPlanCard({
    super.key,
    required this.action,
    required this.applied,
    this.canUndo = true,
    required this.busy,
    required this.onApply,
    required this.onUndo,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final today = ref.watch(todayProvider);
    final count = action.templates.length;
    final title = count == 1
        ? action.templates.first.name
        : l10n.felixPlanTitleCount(count);

    // Only the days the plan is really put on get a chip.
    final when = action.scheduleWhen;
    String? chipFor(int i) {
      final d = switch (when) {
        'today' => today,
        'week' =>
          felixDayOf(i < action.days.length ? action.days[i] : null, today),
        _ => null,
      };
      if (d == null) return null;
      return d == today ? l10n.homeToday : weekdayShort(context, d);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const FelixAvatar(size: 24),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(l10n.felixPlanBadge.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.microStrong.copyWith(
                      letterSpacing: 1.2, color: palette.textSecondary)),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(title,
            style: AppText.headingS.copyWith(color: palette.textPrimary)),
        const SizedBox(height: AppSpacing.xs),
        for (final (i, t) in action.templates.indexed) ...[
          Divider(height: 1, thickness: 1, color: palette.border),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.bodyStrong
                              .copyWith(color: palette.textPrimary)),
                      Text(
                          '${l10n.chatActionWorkoutExercises(t.exercises.length)}'
                          '${t.exercises.isEmpty ? '' : ' · ${t.exercises.take(3).map((e) => e.name).join(', ')}'}',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.caption
                              .copyWith(color: palette.textSecondary)),
                    ],
                  ),
                ),
                if (chipFor(i) != null) ...[
                  const SizedBox(width: AppSpacing.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs, vertical: AppSpacing.xxs),
                    decoration: BoxDecoration(
                        color: palette.buttonMuted,
                        borderRadius: AppRadius.fullAll),
                    child: Text(chipFor(i)!,
                        style: AppText.microStrong
                            .copyWith(color: palette.textPrimary)),
                  ),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.xxs),
        if (applied)
          Wrap(
            key: const ValueKey('chat-action-applied'),
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.xs,
            children: [
              Text(l10n.chatActionApplied,
                  style: AppText.captionStrong
                      .copyWith(color: palette.textPrimary)),
              TextButton(onPressed: onOpen, child: Text(l10n.chatActionOpen)),
              if (canUndo)
                TextButton(
                    onPressed: busy ? null : onUndo, child: Text(l10n.undo)),
            ],
          )
        else
          AppButton(
            label: when == 'today'
                ? l10n.felixPlanAddToToday
                : l10n.felixPlanAddToWorkouts,
            size: AppButtonSize.large,
            expand: true,
            onPressed: busy ? null : onApply,
          ),
      ],
    );
  }
}
