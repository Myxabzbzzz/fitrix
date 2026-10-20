import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fitrix/core/felix/ask_felix.dart';
import 'package:fitrix/core/router/app_router.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/core/time/today_provider.dart';
import 'package:fitrix/core/widgets/app_button.dart';
import 'package:fitrix/core/widgets/coach_card.dart';
import 'package:fitrix/core/widgets/screen_title.dart';
import 'package:fitrix/features/chat/data/models/assistant_topic.dart';
import 'package:fitrix/features/nutrition/data/dinner_idea.dart';
import 'package:fitrix/features/nutrition/data/food_catalog.dart';
import 'package:fitrix/features/nutrition/data/food_log_store.dart';
import 'package:fitrix/features/nutrition/data/micronutrients.dart';
import 'package:fitrix/features/nutrition/presentation/providers/nutrition_provider.dart';
import 'package:fitrix/features/nutrition/presentation/widgets/nutrition_cards.dart';
import 'package:fitrix/features/profile/data/performance_store.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

/// "My nutrition": today's calories, macros, water, meals, the lowest
/// micronutrients and a dinner idea when protein is behind.
class NutritionScreen extends ConsumerStatefulWidget {
  const NutritionScreen({super.key});

  @override
  ConsumerState<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends ConsumerState<NutritionScreen> {
  int _ideaIndex = 0;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final today = ref.watch(todayProvider);
    final now = ref.watch(clockProvider)();
    final entries = ref.watch(todayEntriesProvider);
    final targets = ref.watch(targetsProvider);
    final training = ref.watch(trainingDayProvider);
    final burned = ref.watch(burnedKcalProvider);
    final water = ref.watch(todayWaterProvider);

    final eaten = entries.fold<int>(0, (s, e) => s + e.kcal);
    final protein = entries.fold<double>(0, (s, e) => s + e.protein);
    final carbs = entries.fold<double>(0, (s, e) => s + e.carbs);
    final fat = entries.fold<double>(0, (s, e) => s + e.fat);
    final dateText = DateFormat('EEE d MMM', locale).format(today);
    final liters = NumberFormat('0.0', locale);

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScreenTitle(
              l10n.nutritionTitle,
              trailing: IconButton(
                tooltip: l10n.nutritionSearch,
                icon: Icon(Icons.search, color: palette.textPrimary),
                onPressed: () =>
                    context.push(AppRouter.addFood(MealSlot.forTime(now))),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.lg),
                children: [
                  NutritionTile(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                    child: Column(
                      children: [
                        Text(l10n.nutritionToday,
                            style: AppText.bodyStrong
                                .copyWith(color: palette.textPrimary)),
                        Text(
                          training
                              ? l10n.nutritionDateTraining(dateText)
                              : dateText,
                          textAlign: TextAlign.center,
                          style: AppText.caption
                              .copyWith(color: palette.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (targets == null)
                    _CompleteProfileCard(
                        onTap: () => context.push(AppRouter.editProfile))
                  else ...[
                    NutritionTile(
                      child: Row(
                        children: [
                          CalorieRing(eaten: eaten, target: targets.kcal),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: _RingSide(
                              left: targets.kcal - eaten,
                              burned: burned,
                              onHow: () =>
                                  context.push(AppRouter.nutritionTargets),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    NutritionTile(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(l10n.nutritionMacros,
                                    style: AppText.headingS
                                        .copyWith(color: palette.textPrimary)),
                              ),
                              Flexible(
                                child: Text(
                                  l10n.nutritionProteinPerKg(
                                      NumberFormat('0.0', locale).format(ref
                                          .watch(nutritionSettingsProvider)
                                          .proteinPerKg)),
                                  style: AppText.caption
                                      .copyWith(color: palette.textSecondary),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                  child: MacroColumn(
                                      label: l10n.nutritionProtein,
                                      eaten: protein,
                                      target: targets.protein)),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                  child: MacroColumn(
                                      label: l10n.nutritionCarbs,
                                      eaten: carbs,
                                      target: targets.carbs)),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                  child: MacroColumn(
                                      label: l10n.nutritionFat,
                                      eaten: fat,
                                      target: targets.fat)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  NutritionTile(
                    child: Row(
                      children: [
                        WaterGlass(
                            fraction: targets == null || targets.waterMl <= 0
                                ? 0
                                : water / targets.waterMl),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                targets == null
                                    ? l10n.nutritionWaterNoTarget(
                                        liters.format(water / 1000))
                                    : l10n.nutritionWaterTitle(
                                        liters.format(water / 1000),
                                        liters.format(targets.waterMl / 1000)),
                                style: AppText.bodyStrong
                                    .copyWith(color: palette.textPrimary),
                              ),
                              if (training)
                                Text(l10n.nutritionWaterWorkout,
                                    style: AppText.caption.copyWith(
                                        color: palette.textSecondary)),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            for (final ml in const [250, 500]) ...[
                              AppButton(
                                key: ValueKey('water-$ml'),
                                label: l10n.nutritionAddMl('$ml'),
                                style: AppButtonStyle.secondary,
                                onPressed: () => ref
                                    .read(foodLogProvider.notifier)
                                    .addWater(today, ml),
                              ),
                              if (ml == 250)
                                const SizedBox(height: AppSpacing.xs),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: Text(l10n.nutritionMeals,
                            style: AppText.headingS
                                .copyWith(color: palette.textPrimary)),
                      ),
                      Text(
                        l10n.nutritionMealsLogged(
                            '${{for (final e in entries) e.slot}.length}'),
                        style: AppText.caption
                            .copyWith(color: palette.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  for (final slot in MealSlot.values) ...[
                    MealSlotCard(
                      slot: slot,
                      entries: [
                        for (final e in entries)
                          if (e.slot == slot) e,
                      ],
                      onAdd: () => context.push(AppRouter.addFood(slot)),
                      onRemove: (e) =>
                          ref.read(foodLogProvider.notifier).remove(e.id),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                  ],
                  ..._lowToday(context, entries),
                  ..._dinnerIdea(context, now, targets?.kcal, targets?.protein,
                      eaten, protein),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The 3 lowest micronutrients today, when there is something logged and
  /// the targets are known.
  List<Widget> _lowToday(BuildContext context, List<FoodEntry> entries) {
    final sex = ref.watch(performanceProfileProvider).sex;
    final age = ref.watch(bodyStatsProvider).age;
    if (entries.isEmpty || sex == null || age == null) return const [];
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final targets = microTargets(sex, age);
    final totals = {for (final k in microKeys) k: 0.0};
    for (final e in entries) {
      for (final k in microKeys) {
        totals[k] = totals[k]! + (e.micros[k] ?? 0);
      }
    }
    final ranked = [
      for (final k in microKeys)
        if (k != 'sodium_mg') (key: k, pct: totals[k]! / targets[k]! * 100),
    ]..sort((a, b) => a.pct.compareTo(b.pct));
    return [
      const SizedBox(height: AppSpacing.sm),
      Row(
        children: [
          Expanded(
            child: Text(l10n.nutritionLowToday,
                style: AppText.headingS.copyWith(color: palette.textPrimary)),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => context.push(AppRouter.nutritionMicros),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Align(
                widthFactor: 1,
                child: Text(l10n.nutritionAllMicros('${microKeys.length}'),
                    style: AppText.body14.copyWith(color: palette.accent)),
              ),
            ),
          ),
        ],
      ),
      Wrap(
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs,
        children: [
          for (final r in ranked.take(3))
            Semantics(
              button: true,
              child: GestureDetector(
                key: const ValueKey('low-micro-chip'),
                behavior: HitTestBehavior.opaque,
                onTap: () => context.push(AppRouter.nutritionMicros),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                      color: palette.tile, borderRadius: AppRadius.fullAll),
                  child: Text.rich(TextSpan(children: [
                    TextSpan(
                        text: microName(l10n, r.key),
                        style: AppText.captionStrong
                            .copyWith(color: palette.textPrimary)),
                    TextSpan(
                        text: '  ${r.pct.round()}%',
                        style: AppText.captionStrong.copyWith(
                            color: r.pct < 60
                                ? palette.warning
                                : palette.success)),
                  ])),
                ),
              ),
            ),
        ],
      ),
    ];
  }

  List<Widget> _dinnerIdea(BuildContext context, DateTime now, int? kcal,
      int? proteinTarget, int eaten, double protein) {
    if (kcal == null || proteinTarget == null || now.hour < 15) {
      return const [];
    }
    final gap = proteinTarget - protein;
    final catalog = ref.watch(foodCatalogProvider).valueOrNull;
    if (gap < 30 || catalog == null) return const [];
    final ideas = dinnerIdeas(catalog, kcal - eaten);
    if (ideas.isEmpty) return const [];
    final l10n = AppLocalizations.of(context);
    final idea = ideas[_ideaIndex % ideas.length];
    final grams = idea.portion.grams;
    return [
      const SizedBox(height: AppSpacing.md),
      KeyedSubtree(
        key: const ValueKey('dinner-idea'),
        child: CoachCard(
          eyebrow: l10n.nutritionDinnerIdea,
          title: '',
          message: l10n.nutritionIdeaMessage(
            '${gap.round()}',
            idea.food.name,
            '${idea.portion.label} $grams g',
            '${idea.food.proteinFor(grams).round()}',
          ),
          imageAsset: 'assets/images/felix_avatar.png',
          imageWidth: 56,
          imageHeight: 80,
          primaryLabel: l10n.nutritionAddToDinner,
          onPrimary: () {
            ref.read(foodLogProvider.notifier).add(FoodEntry.fromFood(
                  idea.food,
                  grams: grams,
                  slot: MealSlot.dinner,
                  at: now,
                  id: newEntryId(now),
                ));
          },
          secondaryLabel: ideas.length > 1 ? l10n.nutritionOtherIdea : null,
          onSecondary: () => setState(() => _ideaIndex++),
          onAsk: () => askFelix(
            context,
            ref,
            topic: AssistantTopic.nutrition,
            draft: l10n.nutritionAskDraft(
              NumberFormat.decimalPattern(
                      Localizations.localeOf(context).toString())
                  .format(math.max(0, kcal - eaten)),
              '${gap.round()}',
            ),
          ),
        ),
      ),
    ];
  }
}

class _RingSide extends StatelessWidget {
  static const _onTargetKcal = 50;

  final int left;
  final int burned;
  final VoidCallback onHow;
  const _RingSide(
      {required this.left, required this.burned, required this.onHow});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final fmt =
        NumberFormat.decimalPattern(Localizations.localeOf(context).toString());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l10n.nutritionLeftToday,
            style: AppText.caption.copyWith(color: palette.textSecondary)),
        Text(
          // Within ±50 kcal counts as on target; past it says how far over.
          left.abs() <= _onTargetKcal
              ? l10n.nutritionGoalReached
              : left > 0
                  ? l10n.nutritionKcal(fmt.format(left))
                  : l10n.nutritionKcalOver(fmt.format(-left)),
          style: AppText.headingM.copyWith(color: palette.textPrimary),
        ),
        if (burned > 0) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(l10n.nutritionBurned,
              style: AppText.caption.copyWith(color: palette.textSecondary)),
          Text(l10n.nutritionBurnedValue(fmt.format(burned)),
              style: AppText.headingS.copyWith(color: palette.textPrimary)),
        ],
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onHow,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(l10n.nutritionHowSet,
                  style: AppText.body14.copyWith(color: palette.accent)),
            ),
          ),
        ),
      ],
    );
  }
}

class _CompleteProfileCard extends StatelessWidget {
  final VoidCallback onTap;
  const _CompleteProfileCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    return InkWell(
      key: const ValueKey('nutrition-complete-profile'),
      borderRadius: AppRadius.smAll,
      onTap: onTap,
      child: NutritionTile(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.nutritionCompleteTitle,
                      style: AppText.headingS
                          .copyWith(color: palette.textPrimary)),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(l10n.nutritionCompleteBody,
                      style: AppText.caption
                          .copyWith(color: palette.textSecondary)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: palette.textSecondary),
          ],
        ),
      ),
    );
  }
}
