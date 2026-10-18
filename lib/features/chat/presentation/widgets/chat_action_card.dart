import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fitrix/core/router/app_router.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/core/widgets/app_button.dart';
import 'package:fitrix/features/chat/data/models/chat_action.dart';
import 'package:fitrix/features/chat/data/models/chat_message.dart';
import 'package:fitrix/features/chat/presentation/chat_action_apply.dart';
import 'package:fitrix/features/chat/presentation/widgets/chat_bubble.dart';
import 'package:fitrix/core/time/today_provider.dart';
import 'package:fitrix/features/nutrition/data/food_catalog.dart';
import 'package:fitrix/features/nutrition/domain/food_match.dart';
import 'package:fitrix/features/nutrition/presentation/widgets/nutrition_cards.dart'
    show slotLabel;
import 'package:fitrix/features/profile/presentation/providers/profile_provider.dart';
import 'package:fitrix/features/workouts/presentation/sport_l10n.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

/// Confirmation card under a Felix reply that proposes a change. Nothing is
/// applied until the user taps the button; afterwards it shows "Added".
class ChatActionCard extends ConsumerStatefulWidget {
  final ChatMessage message;

  /// Called after the action was applied, with what it changed, to remember
  /// it on the message.
  final ValueChanged<Map<String, num>> onApplied;

  /// Called after the user undid a weight or food action.
  final VoidCallback? onUndone;

  const ChatActionCard({
    super.key,
    required this.message,
    required this.onApplied,
    this.onUndone,
  });

  @override
  ConsumerState<ChatActionCard> createState() => _ChatActionCardState();
}

class _ChatActionCardState extends ConsumerState<ChatActionCard> {
  bool _busy = false;
  MealSlot? _slot;

  Future<void> _undo(ChatAction action) async {
    final result = widget.message.appliedResult;
    if (_busy || result == null) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final l10n = AppLocalizations.of(context);
    try {
      await undoChatAction(ref, action, result);
      widget.onUndone?.call();
    } catch (_) {
      messenger?.showSnackBar(SnackBar(content: Text(l10n.chatActionError)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _apply(ChatAction action) async {
    if (_busy || widget.message.actionApplied) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final router = GoRouter.maybeOf(context);
    final l10n = AppLocalizations.of(context);
    try {
      final result = await applyChatAction(ref, action, slot: _slot);
      if (result == null) {
        messenger?.showSnackBar(SnackBar(content: Text(l10n.chatActionError)));
        return;
      }
      widget.onApplied(result);
      if (action is WorkoutPlanAction) {
        final sport = action.sport;
        messenger?.showSnackBar(SnackBar(
          content:
              Text(l10n.chatActionWorkoutsAdded(sport.localizedLabel(l10n))),
          action: router == null
              ? null
              : SnackBarAction(
                  label: l10n.chatActionOpen,
                  onPressed: () => router.go(AppRouter.sportWorkouts(sport)),
                ),
        ));
      }
    } catch (_) {
      messenger?.showSnackBar(SnackBar(content: Text(l10n.chatActionError)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final action = widget.message.action;
    if (action == null) return const SizedBox.shrink();
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final applied = widget.message.actionApplied;

    final fmt =
        NumberFormat('#,##0.#', Localizations.localeOf(context).toString());
    String n(num v) => fmt.format(v);

    String? title;
    List<String> lines = const [];
    var canApply = true;
    var loading = false;
    var needsWeight = false;
    Widget? foodBody;
    MealSlot? foodSlot;
    var foodKcal = 0;
    switch (action) {
      case WeightAction():
        final result = widget.message.appliedResult;
        if (applied) {
          // Frozen at apply time, so it doesn't change with the profile.
          final to = result?['to'];
          final from = result?['from'];
          if (to != null) {
            title = from == null
                ? l10n.chatActionWeightDoneSet(n(to))
                : l10n.chatActionWeightDone(n(from), n(to));
          }
          break;
        }
        final profile = ref.watch(profileProvider);
        final current = weightKgOf(profile.valueOrNull);
        final next = action.resultFrom(current);
        if (profile.valueOrNull == null) {
          loading = profile.isLoading;
          title = loading ? null : l10n.chatActionNoProfile;
          canApply = false;
        } else if (next == null) {
          title = l10n.chatActionWeightSetFirst;
          canApply = false;
          needsWeight = true;
        } else if (current == null) {
          title = l10n.chatActionWeightSet(n(next));
        } else {
          title = l10n.chatActionWeightChange(n(current), n(next));
        }
      case WorkoutPlanAction():
        title = l10n.chatActionWorkoutTitle(
            action.templates.length, action.sport.localizedLabel(l10n));
        lines = [
          for (final t in action.templates)
            '${t.name} · ${l10n.chatActionWorkoutExercises(t.exercises.length)}',
        ];
      case FoodLogAction():
        final result = widget.message.appliedResult;
        final now = ref.read(clockProvider)();
        final slot = applied && result?['slot'] != null
            ? MealSlot.values[result!['slot']!.toInt().clamp(0, 3)]
            : _slot ?? action.slot ?? slotForTime(now);
        final catalog = ref.watch(foodCatalogProvider);
        final foods = [
          for (final i in action.items)
            catalog.valueOrNull == null
                ? null
                : matchFood(i.name, catalog.valueOrNull!),
        ];
        final entries = [
          for (final (i, item) in action.items.indexed)
            entryFor(item, foods[i], slot, now, id: 'preview'),
        ];
        final kcal = entries.fold(0, (sum, e) => sum + e.kcal);
        final protein = entries.fold(0.0, (sum, e) => sum + e.protein);
        loading = catalog.isLoading;
        canApply = catalog.hasValue;
        foodSlot = slot;
        foodKcal = kcal;
        foodBody = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final e in entries)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xxs),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        e.estimate ? l10n.chatFoodEstimateName(e.name) : e.name,
                        style: AppText.caption
                            .copyWith(color: palette.textPrimary)),
                    Text(l10n.chatFoodItemMeta(n(e.grams), n(e.kcal)),
                        style: AppText.caption
                            .copyWith(color: palette.textSecondary)),
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.xs),
            Text(l10n.chatFoodTotal(n(kcal), n(protein.round())),
                style:
                    AppText.captionStrong.copyWith(color: palette.textPrimary)),
            if (entries.any((e) => e.estimate))
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xxs),
                child: Text(l10n.chatFoodEstimateNote,
                    style:
                        AppText.caption.copyWith(color: palette.textSecondary)),
              ),
          ],
        );
      case MealPlanAction():
        title = l10n.chatActionMealTitle;
        lines = [
          for (final m in action.meals)
            '${m.name} · ${l10n.nutritionKcal(n(m.kcal))}',
          l10n.chatActionMealTotal(n(action.totalKcal)),
        ];
    }

    return Padding(
      // Lines up with the bubble: avatar column (24) + gap.
      padding: const EdgeInsets.only(
          left: ChatBubble.avatarSize + AppSpacing.xs, bottom: AppSpacing.md),
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
              if (loading)
                const SizedBox(
                  key: ValueKey('chat-action-loading'),
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              if (foodSlot != null)
                _FoodHeader(
                  slot: foodSlot,
                  fixed: applied,
                  onPick: (s) => setState(() => _slot = s),
                ),
              if (foodBody != null) foodBody,
              if (title != null)
                Text(title,
                    style: AppText.bodyStrong
                        .copyWith(color: palette.textPrimary)),
              for (final line in lines)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xxs),
                  child: Text(line,
                      style: AppText.caption
                          .copyWith(color: palette.textSecondary)),
                ),
              if (applied) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                    foodSlot != null
                        ? l10n.chatFoodAdded(slotLabel(l10n, foodSlot))
                        : l10n.chatActionApplied,
                    key: const ValueKey('chat-action-applied'),
                    style: AppText.captionStrong
                        .copyWith(color: palette.textPrimary)),
                if (action is WeightAction || action is FoodLogAction)
                  Wrap(
                    spacing: AppSpacing.xs,
                    children: [
                      TextButton(
                        onPressed: _busy ? null : () => _undo(action),
                        child: Text(l10n.undo),
                      ),
                      if (action is FoodLogAction)
                        TextButton(
                          onPressed: () => GoRouter.maybeOf(context)
                              ?.go(AppRouter.nutrition),
                          child: Text(l10n.chatActionOpen),
                        ),
                    ],
                  ),
              ] else if (needsWeight) ...[
                const SizedBox(height: AppSpacing.xs),
                AppButton(
                  label: l10n.chatActionSetWeight,
                  size: AppButtonSize.large,
                  onPressed: () =>
                      GoRouter.maybeOf(context)?.push(AppRouter.editProfile),
                ),
              ] else if (canApply) ...[
                const SizedBox(height: AppSpacing.xs),
                AppButton(
                  label: foodSlot != null
                      ? l10n.chatFoodAdd(n(foodKcal))
                      : l10n.chatActionConfirm,
                  // Large is 48 px tall: a comfortable tap target.
                  size: AppButtonSize.large,
                  onPressed: _busy ? null : () => _apply(action),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// "Log to Lunch" with a menu to pick another slot. Fixed once added.
class _FoodHeader extends StatelessWidget {
  final MealSlot slot;
  final bool fixed;
  final ValueChanged<MealSlot> onPick;

  const _FoodHeader(
      {required this.slot, required this.fixed, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final label = Text(l10n.chatFoodLogTo(slotLabel(l10n, slot)),
        style: AppText.bodyStrong.copyWith(color: palette.textPrimary));
    if (fixed) return label;
    return PopupMenuButton<MealSlot>(
      key: const ValueKey('food-slot-picker'),
      tooltip: '',
      padding: EdgeInsets.zero,
      onSelected: onPick,
      itemBuilder: (context) => [
        for (final s in MealSlot.values)
          PopupMenuItem(value: s, child: Text(slotLabel(l10n, s))),
      ],
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: label),
            const SizedBox(width: AppSpacing.xxs),
            Icon(Icons.expand_more, size: 20, color: palette.textSecondary),
          ],
        ),
      ),
    );
  }
}
