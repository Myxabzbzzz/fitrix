import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/core/time/today_provider.dart';
import 'package:fitrix/core/widgets/app_button.dart';
import 'package:fitrix/core/widgets/pill_selector.dart';
import 'package:fitrix/features/nutrition/data/food_catalog.dart';
import 'package:fitrix/features/nutrition/data/food_log_store.dart';
import 'package:fitrix/features/nutrition/data/micronutrients.dart';
import 'package:fitrix/features/nutrition/presentation/providers/nutrition_provider.dart';
import 'package:fitrix/features/nutrition/presentation/widgets/nutrition_cards.dart';
import 'package:fitrix/features/profile/data/performance_store.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

/// One food: numbers for the chosen portion, how it fits the day and what
/// it is rich in.
class FoodDetailScreen extends ConsumerStatefulWidget {
  final String id;
  final MealSlot slot;
  const FoodDetailScreen({super.key, required this.id, required this.slot});

  @override
  ConsumerState<FoodDetailScreen> createState() => _FoodDetailScreenState();
}

class _FoodDetailScreenState extends ConsumerState<FoodDetailScreen> {
  int? _grams;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final catalog = ref.watch(foodCatalogProvider);

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xxs, AppSpacing.xs, AppSpacing.md, AppSpacing.xs),
              child: Row(
                children: [
                  IconButton(
                    tooltip:
                        MaterialLocalizations.of(context).backButtonTooltip,
                    icon: Icon(Icons.arrow_back_ios_new,
                        size: 20, color: palette.textPrimary),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  Expanded(
                    child: Text(l10n.nutritionFood,
                        style: AppText.headingS
                            .copyWith(color: palette.textPrimary)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: catalog.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => Center(child: Text(l10n.foodBaseError)),
                data: (c) {
                  final food = c.byId(widget.id);
                  if (food == null) {
                    return Center(
                        child: Text(l10n.foodNotFound,
                            style: AppText.body14
                                .copyWith(color: palette.textSecondary)));
                  }
                  return _content(context, food);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content(BuildContext context, Food food) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final fmt = NumberFormat.decimalPattern(locale);
    final one = NumberFormat('0.0', locale);
    final grams = _grams ?? food.portions.first.grams;
    final kcal = food.kcalFor(grams);
    final protein = food.proteinFor(grams);
    final carbs = food.carbsFor(grams);
    final fat = food.fatFor(grams);

    final targets = ref.watch(targetsProvider);
    final entries = ref.watch(todayEntriesProvider);
    final eatenKcal = entries.fold<int>(0, (s, e) => s + e.kcal);
    final eatenProtein = entries.fold<double>(0, (s, e) => s + e.protein);
    final eatenFat = entries.fold<double>(0, (s, e) => s + e.fat);
    final fatAfter = eatenFat + fat;
    final fatOver = targets != null && fatAfter > targets.fat;

    // Portion pills: the food's own portions plus 100 g.
    final labels = <int, String>{
      for (final p in food.portions) p.grams: p.label,
    };
    labels.putIfAbsent(100, () => l10n.nutritionGrams('100'));

    final sex = ref.watch(performanceProfileProvider).sex;
    final age = ref.watch(bodyStatsProvider).age;
    final rich = <({String key, double pct, double amount})>[];
    if (sex != null && age != null) {
      final t = microTargets(sex, age);
      final m = food.microsFor(grams);
      for (final k in microKeys) {
        if (k == 'sodium_mg') continue;
        final pct = (m[k] ?? 0) / t[k]! * 100;
        if (pct > 0) rich.add((key: k, pct: pct, amount: m[k] ?? 0));
      }
      rich.sort((a, b) => b.pct.compareTo(a.pct));
    }

    Widget tag(String text) => Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs, vertical: AppSpacing.xxs),
          decoration: BoxDecoration(
              color: palette.tile, borderRadius: AppRadius.fullAll),
          child: Text(text.toUpperCase(),
              style: AppText.microStrong.copyWith(color: palette.textPrimary)),
        );

    Widget stat(String label, String value, {bool warn = false}) => Expanded(
          child: NutritionTile(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        AppText.caption.copyWith(color: palette.textSecondary)),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(value,
                      style: AppText.headingM.copyWith(
                          color: warn ? palette.warning : palette.textPrimary)),
                ),
              ],
            ),
          ),
        );

    Widget stepper(IconData icon, String key, int delta) => Semantics(
          button: true,
          child: GestureDetector(
            key: ValueKey(key),
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(
                () => _grams = (grams + delta).clamp(10, 2000).toInt()),
            child: SizedBox(
              width: 44,
              height: 44,
              child: Center(
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                      color: palette.buttonMuted, shape: BoxShape.circle),
                  child: Icon(icon, size: 18, color: palette.textPrimary),
                ),
              ),
            ),
          ),
        );

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
            children: [
              Text(food.name,
                  style: AppText.headingL.copyWith(color: palette.textPrimary)),
              if (food.localName != null)
                Text(food.localName!,
                    style:
                        AppText.caption.copyWith(color: palette.textSecondary)),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  if (food.uzbek) tag(l10n.foodCatUzbek),
                  if (food.estimate) tag(l10n.foodRecipeEstimate),
                  tag(l10n.foodPer100(fmt.format(food.kcal.round()))),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: Text(l10n.foodPortion,
                        style: AppText.headingS
                            .copyWith(color: palette.textPrimary)),
                  ),
                  stepper(Icons.remove, 'grams-minus', -10),
                  Text(l10n.nutritionGrams('$grams'),
                      style: AppText.bodyStrong
                          .copyWith(color: palette.textPrimary)),
                  stepper(Icons.add, 'grams-plus', 10),
                ],
              ),
              PillSelector<int>(
                items: labels.keys.toList(),
                selected: grams,
                labelOf: (g) => labels[g]!,
                onSelected: (g) => setState(() => _grams = g),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  stat(l10n.foodKcal, fmt.format(kcal)),
                  const SizedBox(width: AppSpacing.xs),
                  stat(l10n.nutritionProtein, one.format(protein)),
                  const SizedBox(width: AppSpacing.xs),
                  stat(l10n.nutritionCarbs, one.format(carbs)),
                  const SizedBox(width: AppSpacing.xs),
                  stat(l10n.nutritionFat, one.format(fat), warn: fatOver),
                ],
              ),
              if (targets != null) ...[
                const SizedBox(height: AppSpacing.md),
                NutritionTile(
                  child: _FitsDay(
                    name: food.name,
                    eaten: eatenKcal,
                    adding: kcal,
                    target: targets.kcal,
                    warning: [
                      if (fatOver)
                        l10n.foodFatWould(fmt.format(fatAfter.round()),
                            fmt.format(targets.fat)),
                      if (targets.protein - eatenProtein - protein > 0)
                        l10n.foodProteinBehind(fmt.format(
                            (targets.protein - eatenProtein - protein)
                                .round())),
                    ],
                    fatOver: fatOver,
                  ),
                ),
              ],
              if (rich.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: Text(l10n.foodRichIn,
                          style: AppText.headingS
                              .copyWith(color: palette.textPrimary)),
                    ),
                    Flexible(
                      child: Text(l10n.foodPctOfTarget,
                          textAlign: TextAlign.end,
                          style: AppText.caption
                              .copyWith(color: palette.textSecondary)),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                NutritionTile(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                  child: Column(
                    children: [
                      for (final r in rich.take(5))
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.xs),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(microName(l10n, r.key),
                                        style: AppText.bodyStrong.copyWith(
                                            color: palette.textPrimary)),
                                  ),
                                  Text(
                                    '${microAmount(r.key, r.amount, locale)} '
                                    '${microUnitLabel(r.key)} · ${r.pct.round()}%',
                                    style: AppText.caption
                                        .copyWith(color: palette.textSecondary),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.xxs),
                              ClipRRect(
                                borderRadius: AppRadius.fullAll,
                                child: LinearProgressIndicator(
                                  value: (r.pct / 100).clamp(0.0, 1.0),
                                  minHeight: 6,
                                  color: palette.accent,
                                  backgroundColor: palette.buttonMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.md),
          child: AppButton(
            label:
                l10n.nutritionAddToSlotKcal(widget.slot.name, fmt.format(kcal)),
            size: AppButtonSize.large,
            expand: true,
            onPressed: () {
              final now = ref.read(clockProvider)();
              ref.read(foodLogProvider.notifier).add(FoodEntry.fromFood(
                    food,
                    grams: grams,
                    slot: widget.slot,
                    at: now,
                    id: newEntryId(now),
                  ));
              Navigator.of(context).maybePop();
            },
          ),
        ),
      ],
    );
  }
}

class _FitsDay extends StatelessWidget {
  final String name;
  final int eaten;
  final int adding;
  final int target;
  final List<String> warning;
  final bool fatOver;
  const _FitsDay({
    required this.name,
    required this.eaten,
    required this.adding,
    required this.target,
    required this.warning,
    required this.fatOver,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final fmt =
        NumberFormat.decimalPattern(Localizations.localeOf(context).toString());
    final total = target <= 0 ? 1 : target;
    final eatenFlex = (eaten / total).clamp(0.0, 1.0);
    final addFlex = (adding / total).clamp(0.0, 1.0 - eatenFlex);
    final leftAfter = target - eaten - adding;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(l10n.foodFitsDay,
                  style: AppText.headingS.copyWith(color: palette.textPrimary)),
            ),
            Flexible(
              child: Text(
                leftAfter >= 0
                    ? l10n.foodKcalLeftAfter(fmt.format(leftAfter))
                    : l10n.foodKcalOver(fmt.format(-leftAfter)),
                textAlign: TextAlign.end,
                style: AppText.bodyStrong.copyWith(
                    color:
                        leftAfter >= 0 ? palette.textPrimary : palette.warning),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: AppRadius.fullAll,
          child: SizedBox(
            height: 8,
            child: Row(
              children: [
                if (eatenFlex > 0)
                  Expanded(
                      flex: (eatenFlex * 1000).round(),
                      child: ColoredBox(color: palette.textPrimary)),
                if (addFlex > 0)
                  Expanded(
                      flex: (addFlex * 1000).round(),
                      child: ColoredBox(color: palette.accent)),
                Expanded(
                    flex: ((1 - eatenFlex - addFlex) * 1000)
                        .round()
                        .clamp(1, 1000),
                    child: ColoredBox(color: palette.buttonMuted)),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: AppSpacing.xs,
          children: [
            Text(l10n.foodEaten(fmt.format(eaten)),
                style: AppText.caption.copyWith(color: palette.textSecondary)),
            Text(l10n.foodPlus(name, fmt.format(adding)),
                style: AppText.caption.copyWith(color: palette.accent)),
            Text(l10n.foodTarget(fmt.format(target)),
                style: AppText.caption.copyWith(color: palette.textSecondary)),
          ],
        ),
        if (warning.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(warning.join(' '),
              key: fatOver ? const ValueKey('fat-warning') : null,
              style: AppText.caption.copyWith(color: palette.textPrimary)),
        ],
      ],
    );
  }
}
