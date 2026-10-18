import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fitrix/core/animation/motion.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/core/widgets/app_button.dart';
import 'package:fitrix/features/nutrition/data/food_catalog.dart';
import 'package:fitrix/features/nutrition/data/food_log_store.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

String slotLabel(AppLocalizations l10n, MealSlot slot) => switch (slot) {
      MealSlot.breakfast => l10n.nutritionBreakfast,
      MealSlot.lunch => l10n.nutritionLunch,
      MealSlot.dinner => l10n.nutritionDinner,
      MealSlot.snack => l10n.nutritionSnack,
    };

/// A rounded tile that holds a section of the screen.
class NutritionTile extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const NutritionTile(
      {super.key,
      required this.child,
      this.padding = const EdgeInsets.all(AppSpacing.md)});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Container(
      width: double.infinity,
      padding: padding,
      decoration:
          BoxDecoration(color: palette.tile, borderRadius: AppRadius.smAll),
      child: child,
    );
  }
}

/// Calories ring: [fraction] of the target eaten. The arc grows to its
/// value (instantly with reduced motion).
class CalorieRing extends StatelessWidget {
  final int eaten;
  final int target;
  const CalorieRing({super.key, required this.eaten, required this.target});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final fmt =
        NumberFormat.decimalPattern(Localizations.localeOf(context).toString());
    final fraction = target <= 0 ? 0.0 : eaten / target;
    return SizedBox(
      key: const ValueKey('calorie-ring'),
      width: 132,
      height: 132,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: fraction),
        duration: Motion.of(context, Motion.slow),
        curve: Motion.curve,
        builder: (context, f, _) => Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              painter: RingPainter(
                fraction: f,
                track: palette.buttonMuted,
                arc: eaten > target ? palette.warning : palette.accent,
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        fmt.format(eaten),
                        key: const ValueKey('nutrition-eaten'),
                        style: AppText.displayMedium
                            .copyWith(color: palette.textPrimary),
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        l10n.nutritionOfGoal(fmt.format(target)),
                        style: AppText.micro
                            .copyWith(color: palette.textSecondary),
                      ),
                    ),
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

class RingPainter extends CustomPainter {
  final double fraction;
  final Color track;
  final Color arc;

  RingPainter({required this.fraction, required this.track, required this.arc});

  static const double _stroke = 12;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(_stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, math.pi * 2, false, paint..color = track);
    final f = fraction.clamp(0.0, 1.0);
    if (f > 0) {
      canvas.drawArc(
          rect, -math.pi / 2, math.pi * 2 * f, false, paint..color = arc);
    }
  }

  @override
  bool shouldRepaint(RingPainter old) =>
      old.fraction != fraction || old.track != track || old.arc != arc;
}

/// One macro: name, "eaten / target g" and a bar (warning colour when over).
class MacroColumn extends StatelessWidget {
  final String label;
  final double eaten;
  final int target;
  const MacroColumn(
      {super.key,
      required this.label,
      required this.eaten,
      required this.target});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final fmt =
        NumberFormat.decimalPattern(Localizations.localeOf(context).toString());
    final over = eaten > target;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.bodyStrong.copyWith(color: palette.textPrimary)),
        const SizedBox(height: AppSpacing.xxs),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            l10n.nutritionGramsOf(
                fmt.format(eaten.round()), fmt.format(target)),
            style: AppText.caption.copyWith(color: palette.textSecondary),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: AppRadius.fullAll,
          child: TweenAnimationBuilder<double>(
            tween: Tween(
                end: target <= 0 ? 0.0 : (eaten / target).clamp(0.0, 1.0)),
            duration: Motion.of(context, Motion.slow),
            curve: Motion.curve,
            builder: (context, v, _) => LinearProgressIndicator(
              value: v,
              minHeight: 6,
              color: over ? palette.warning : palette.accent,
              backgroundColor: palette.buttonMuted,
            ),
          ),
        ),
      ],
    );
  }
}

/// A glass that fills with the water drunk today.
class WaterGlass extends StatelessWidget {
  final double fraction;
  const WaterGlass({super.key, required this.fraction});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Container(
      width: 40,
      height: 48,
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.bottomCenter,
      decoration: BoxDecoration(
          color: palette.buttonMuted, borderRadius: AppRadius.smAll),
      child: FractionallySizedBox(
        heightFactor: fraction.clamp(0.0, 1.0),
        widthFactor: 1,
        child: ColoredBox(color: palette.accent),
      ),
    );
  }
}

/// One meal slot: name, total, an add button and the logged entries.
class MealSlotCard extends StatelessWidget {
  final MealSlot slot;
  final List<FoodEntry> entries;
  final VoidCallback onAdd;
  final ValueChanged<FoodEntry> onRemove;

  const MealSlotCard({
    super.key,
    required this.slot,
    required this.entries,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final fmt =
        NumberFormat.decimalPattern(Localizations.localeOf(context).toString());
    final total = entries.fold<int>(0, (s, e) => s + e.kcal);
    return NutritionTile(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(slotLabel(l10n, slot),
                        style: AppText.bodyStrong
                            .copyWith(color: palette.textPrimary)),
                    if (entries.isEmpty)
                      Text(l10n.nutritionNotLogged,
                          style: AppText.caption
                              .copyWith(color: palette.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              if (entries.isEmpty)
                AppButton(
                  label: l10n.nutritionAdd,
                  icon: Icons.add,
                  size: AppButtonSize.small,
                  onPressed: onAdd,
                )
              else ...[
                Text(l10n.nutritionKcal(fmt.format(total)),
                    style: AppText.bodyStrong
                        .copyWith(color: palette.textPrimary)),
                IconButton(
                  key: ValueKey('add-${slot.name}'),
                  tooltip: l10n.nutritionAdd,
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.add, size: 20, color: palette.accent),
                  onPressed: onAdd,
                ),
              ],
            ],
          ),
          for (final e in entries)
            Row(
              children: [
                Expanded(
                  child: Text(e.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.caption
                          .copyWith(color: palette.textSecondary)),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(l10n.nutritionKcal(fmt.format(e.kcal)),
                    style:
                        AppText.caption.copyWith(color: palette.textSecondary)),
                IconButton(
                  key: ValueKey('remove-${e.id}'),
                  tooltip: l10n.nutritionRemove,
                  visualDensity: VisualDensity.compact,
                  icon:
                      Icon(Icons.close, size: 16, color: palette.textSecondary),
                  onPressed: () => onRemove(e),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

String microName(AppLocalizations l10n, String key) => switch (key) {
      'vitD_mcg' => l10n.microVitD,
      'calcium_mg' => l10n.microCalcium,
      'magnesium_mg' => l10n.microMagnesium,
      'iron_mg' => l10n.microIron,
      'zinc_mg' => l10n.microZinc,
      'potassium_mg' => l10n.microPotassium,
      'sodium_mg' => l10n.microSodium,
      'b12_mcg' => l10n.microB12,
      'selenium_mcg' => l10n.microSelenium,
      'vitE_mg' => l10n.microVitE,
      'vitC_mg' => l10n.microVitC,
      'vitA_mcg' => l10n.microVitA,
      _ => key,
    };

/// Where a micronutrient comes from; shown when it runs low (or, for
/// sodium, high).
String microHint(AppLocalizations l10n, String key) => switch (key) {
      'vitD_mcg' => l10n.microHintVitD,
      'calcium_mg' => l10n.microHintCalcium,
      'magnesium_mg' => l10n.microHintMagnesium,
      'iron_mg' => l10n.microHintIron,
      'zinc_mg' => l10n.microHintZinc,
      'potassium_mg' => l10n.microHintPotassium,
      'sodium_mg' => l10n.microHintSodium,
      'b12_mcg' => l10n.microHintB12,
      'selenium_mcg' => l10n.microHintSelenium,
      'vitE_mg' => l10n.microHintVitE,
      'vitC_mg' => l10n.microHintVitC,
      'vitA_mcg' => l10n.microHintVitA,
      _ => '',
    };

/// "2.3 / 15 mcg" style amount. Potassium and sodium are shown in grams.
String microAmount(String key, double value, String locale) {
  final grams = key == 'potassium_mg' || key == 'sodium_mg';
  if (grams) return NumberFormat('0.0', locale).format(value / 1000);
  return value < 10
      ? NumberFormat('0.0', locale).format(value)
      : NumberFormat.decimalPattern(locale).format(value.round());
}

String microUnitLabel(String key) {
  if (key == 'potassium_mg' || key == 'sodium_mg') return 'g';
  return key.endsWith('_mcg') ? 'mcg' : 'mg';
}
