import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fitrix/core/router/app_router.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/core/widgets/app_button.dart';
import 'package:fitrix/features/chat/data/models/chat_action.dart';
import 'package:fitrix/features/chat/data/models/chat_message.dart';
import 'package:fitrix/features/chat/presentation/chat_action_apply.dart';
import 'package:fitrix/features/chat/presentation/widgets/chat_bubble.dart';
import 'package:fitrix/features/profile/data/models/profile_row.dart';
import 'package:fitrix/features/profile/presentation/providers/profile_provider.dart';
import 'package:fitrix/features/workouts/presentation/sport_l10n.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

/// Confirmation card under a Felix reply that proposes a change. Nothing is
/// applied until the user taps the button; afterwards it shows "Added".
class ChatActionCard extends ConsumerStatefulWidget {
  final ChatMessage message;

  /// Called after the action was applied, to remember it on the message.
  final VoidCallback onApplied;

  const ChatActionCard({
    super.key,
    required this.message,
    required this.onApplied,
  });

  @override
  ConsumerState<ChatActionCard> createState() => _ChatActionCardState();
}

class _ChatActionCardState extends ConsumerState<ChatActionCard> {
  bool _busy = false;

  Future<void> _apply(ChatAction action) async {
    if (_busy || widget.message.actionApplied) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final router = GoRouter.maybeOf(context);
    final l10n = AppLocalizations.of(context);
    await applyChatAction(ref, action);
    widget.onApplied();
    if (action is WorkoutPlanAction) {
      final sport = action.sport;
      messenger?.showSnackBar(SnackBar(
        content: Text(l10n.chatActionWorkoutsAdded(sport.localizedLabel(l10n))),
        action: router == null
            ? null
            : SnackBarAction(
                label: l10n.chatActionOpen,
                onPressed: () => router.go(AppRouter.sportWorkouts(sport)),
              ),
      ));
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final action = widget.message.action;
    if (action == null) return const SizedBox.shrink();
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final applied = widget.message.actionApplied;

    String title;
    List<String> lines = const [];
    var canApply = true;
    switch (action) {
      case WeightAction():
        final current = weightKgOf(ref.watch(profileProvider).valueOrNull);
        final result = action.resultFrom(current);
        if (result == null) {
          title = l10n.chatActionWeightUnknown(_signed(action.kg));
          canApply = false;
        } else if (current == null) {
          title = l10n.chatActionWeightSet(formatProfileNumber(result));
        } else {
          title = l10n.chatActionWeightChange(
              formatProfileNumber(current), formatProfileNumber(result));
        }
      case WorkoutPlanAction():
        title = l10n.chatActionWorkoutTitle(
            action.templates.length, action.sport.localizedLabel(l10n));
        lines = [
          for (final t in action.templates)
            '${t.name} · ${l10n.chatActionWorkoutExercises(t.exercises.length)}',
        ];
      case MealPlanAction():
        title = l10n.chatActionMealTitle;
        lines = [
          for (final m in action.meals)
            '${m.name} · ${l10n.nutritionKcal('${m.kcal}')}',
          l10n.chatActionMealTotal('${action.totalKcal}'),
        ];
    }

    return Padding(
      // Lines up with the bubble: avatar column (24) + gap.
      padding: const EdgeInsets.only(
          left: 24 + AppSpacing.xs, bottom: AppSpacing.md),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          key: const ValueKey('chat-action-card'),
          constraints: const BoxConstraints(maxWidth: ChatBubble.maxWidth),
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: palette.tile,
            borderRadius: AppRadius.smAll,
            border: Border.all(color: palette.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title,
                  style:
                      AppText.bodyStrong.copyWith(color: palette.textPrimary)),
              for (final line in lines)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xxs),
                  child: Text(line,
                      style: AppText.caption
                          .copyWith(color: palette.textSecondary)),
                ),
              if (applied) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(l10n.chatActionApplied,
                    key: const ValueKey('chat-action-applied'),
                    style: AppText.captionStrong
                        .copyWith(color: palette.textPrimary)),
              ] else if (canApply) ...[
                const SizedBox(height: AppSpacing.xs),
                AppButton(
                  label: l10n.chatActionConfirm,
                  size: AppButtonSize.small,
                  onPressed: _busy ? null : () => _apply(action),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String _signed(double kg) =>
      '${kg > 0 ? '+' : ''}${formatProfileNumber(kg)}';
}
