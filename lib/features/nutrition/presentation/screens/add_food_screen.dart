import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fitrix/core/i18n/catalog_text.dart';
import 'package:fitrix/core/felix/ask_felix.dart';
import 'package:fitrix/core/router/app_router.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/core/time/today_provider.dart';
import 'package:fitrix/core/widgets/pill_selector.dart';
import 'package:fitrix/features/chat/data/models/assistant_topic.dart';
import 'package:fitrix/features/nutrition/data/food_catalog.dart';
import 'package:fitrix/features/nutrition/data/food_log_store.dart';
import 'package:fitrix/features/nutrition/presentation/providers/nutrition_provider.dart';
import 'package:fitrix/features/nutrition/presentation/widgets/nutrition_cards.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

const _allCategories = 'all';
const _categories = [
  _allCategories,
  'uzbek',
  'meat_fish',
  'dairy',
  'fruit',
  'veg',
  'grains',
  'bread',
  'drinks',
  'other',
];

String categoryLabel(AppLocalizations l10n, String c) => switch (c) {
      'uzbek' => l10n.foodCatUzbek,
      'meat_fish' => l10n.foodCatMeatFish,
      'dairy' => l10n.foodCatDairy,
      'fruit' => l10n.foodCatFruit,
      'veg' => l10n.foodCatVeg,
      'grains' => l10n.foodCatGrains,
      'bread' => l10n.foodCatBread,
      'drinks' => l10n.foodCatDrinks,
      'other' => l10n.foodCatOther,
      _ => l10n.foodCatAll,
    };

/// Add food: search the base, pick a slot and category, quick-add the first
/// portion or open the food.
class AddFoodScreen extends ConsumerStatefulWidget {
  final MealSlot slot;
  const AddFoodScreen({super.key, required this.slot});

  @override
  ConsumerState<AddFoodScreen> createState() => _AddFoodScreenState();
}

class _AddFoodScreenState extends ConsumerState<AddFoodScreen> {
  late MealSlot _slot = widget.slot;
  String _category = _allCategories;
  String _query = '';

  void _quickAdd(Food food) {
    final l10n = AppLocalizations.of(context);
    final portion = food.portions.first;
    final now = ref.read(clockProvider)();
    ref.read(foodLogProvider.notifier).add(FoodEntry.fromFood(
          food,
          grams: portion.grams,
          slot: _slot,
          at: now,
          id: newEntryId(now),
        ));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
          content: Text(l10n.nutritionAddedTo(
              ref.read(catalogTextProvider).foodName(food), _slot.name))));
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final catalog = ref.watch(foodCatalogProvider);
    final today = ref.watch(todayProvider);
    ref.watch(foodLogProvider);

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
                        MaterialLocalizations.of(context).closeButtonTooltip,
                    icon: Icon(Icons.close, color: palette.textPrimary),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  Expanded(
                    child: Text(
                      l10n.nutritionAddToSlot(_slot.name),
                      overflow: TextOverflow.ellipsis,
                      style:
                          AppText.headingS.copyWith(color: palette.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                style: AppText.body14.copyWith(color: palette.textPrimary),
                decoration: InputDecoration(
                  hintText: l10n.nutritionSearch,
                  hintStyle:
                      AppText.body14.copyWith(color: palette.textSecondary),
                  prefixIcon: Icon(Icons.search, color: palette.textSecondary),
                  filled: true,
                  fillColor: palette.tile,
                  border: OutlineInputBorder(
                      borderRadius: AppRadius.smAll,
                      borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            PillSelector<MealSlot>(
              items: MealSlot.values,
              selected: _slot,
              labelOf: (s) => slotLabel(l10n, s),
              onSelected: (s) => setState(() => _slot = s),
            ),
            const SizedBox(height: AppSpacing.xs),
            PillSelector<String>(
              items: _categories,
              selected: _category,
              labelOf: (c) => categoryLabel(l10n, c),
              onSelected: (c) => setState(() => _category = c),
            ),
            Expanded(
              child: catalog.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => Center(
                    child: Text(l10n.foodBaseError,
                        style: AppText.body14
                            .copyWith(color: palette.textSecondary))),
                data: (c) => _body(context, c, today),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context, FoodCatalog catalog, DateTime today) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final text = ref.watch(catalogTextProvider);
    final results = catalog.search(_query,
        category: _category == _allCategories ? null : _category,
        nameOf: text.foodName);
    final recent = [
      for (final id
          in ref.watch(foodLogStoreProvider).recentFoodIds(today, days: 7))
        if (catalog.byId(id) != null) catalog.byId(id)!,
    ].take(5).toList();

    Widget header(String title, String? note) => Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.xxs, AppSpacing.md, AppSpacing.xxs, AppSpacing.xs),
          child: Row(
            children: [
              Expanded(
                child: Text(title,
                    style:
                        AppText.headingS.copyWith(color: palette.textPrimary)),
              ),
              if (note != null)
                Flexible(
                  child: Text(note,
                      textAlign: TextAlign.end,
                      style: AppText.caption
                          .copyWith(color: palette.textSecondary)),
                ),
            ],
          ),
        );

    Widget group(List<Food> foods) => NutritionTile(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (final f in foods)
                _FoodRow(
                  food: f,
                  onOpen: () => context.push(AppRouter.foodDetail(f.id, _slot)),
                  onQuickAdd: () => _quickAdd(f),
                )
            ],
          ),
        );

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, 0, AppSpacing.md, AppSpacing.lg),
      children: [
        header(l10n.nutritionResults,
            l10n.nutritionResultsCount('${results.length}')),
        if (results.isEmpty)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(l10n.nutritionNoResults,
                style: AppText.body14.copyWith(color: palette.textSecondary)),
          )
        else
          group(results),
        if (recent.isNotEmpty) ...[
          header(l10n.nutritionRecent, l10n.nutritionRecentNote),
          group(recent),
        ],
        const SizedBox(height: AppSpacing.md),
        InkWell(
          key: const ValueKey('cant-find'),
          borderRadius: AppRadius.smAll,
          onTap: () => askFelix(context, ref,
              topic: AssistantTopic.nutrition,
              draft: l10n.nutritionCantFindDraft),
          child: NutritionTile(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.nutritionCantFind,
                          style: AppText.headingS
                              .copyWith(color: palette.textPrimary)),
                      Text(l10n.nutritionCantFindBody,
                          style: AppText.caption
                              .copyWith(color: palette.textSecondary)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: palette.textSecondary),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FoodRow extends ConsumerWidget {
  final Food food;
  final VoidCallback onOpen;
  final VoidCallback onQuickAdd;
  const _FoodRow(
      {required this.food, required this.onOpen, required this.onQuickAdd});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final text = ref.watch(catalogTextProvider);
    final name = text.foodName(food);
    final p = food.portions.first;
    return InkWell(
      onTap: onOpen,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: palette.buttonMuted, borderRadius: AppRadius.smAll),
              child: Text(name.substring(0, 1).toUpperCase(),
                  style:
                      AppText.headingS.copyWith(color: palette.textSecondary)),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(children: [
                      TextSpan(text: name),
                      if (food.uzbek) ...[
                        const TextSpan(text: '  '),
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.xs,
                                vertical: AppSpacing.xxs / 2),
                            decoration: BoxDecoration(
                                color: palette.accentSoft,
                                borderRadius: AppRadius.fullAll),
                            child: Text('UZ',
                                style: AppText.microStrong
                                    .copyWith(color: palette.accent)),
                          ),
                        ),
                      ],
                    ]),
                    style:
                        AppText.bodyStrong.copyWith(color: palette.textPrimary),
                  ),
                  Text(
                    l10n.nutritionPortionLine(
                      '${text.portion(p.label)} ${p.grams} g',
                      '${food.kcalFor(p.grams)}',
                      '${food.proteinFor(p.grams).round()}',
                    ),
                    style:
                        AppText.caption.copyWith(color: palette.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Semantics(
              button: true,
              label: l10n.nutritionAdd,
              child: GestureDetector(
                key: ValueKey('quick-add-${food.id}'),
                behavior: HitTestBehavior.opaque,
                onTap: onQuickAdd,
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Center(
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                          color: palette.accent, shape: BoxShape.circle),
                      child: Icon(Icons.add, size: 18, color: palette.onAccent),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
