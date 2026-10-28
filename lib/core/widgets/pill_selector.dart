import 'package:flutter/material.dart';
import 'package:fitrix/core/animation/motion.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';

/// Horizontally scrolling row of pills (Gym / Fitness / Cycling / ...).
///
/// The first pill sits on the page's 16 pt content edge and the row scrolls
/// out to the screen edge. Inside a list that already has a 16 pt side
/// padding, pass that padding as [bleed] so the row still reaches the screen
/// edges instead of being cut off flat at the padding.
class PillSelector<T> extends StatelessWidget {
  final List<T> items;
  final T selected;
  final String Function(T) labelOf;
  final ValueChanged<T> onSelected;
  final double bleed;

  const PillSelector({
    super.key,
    required this.items,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
    this.bleed = 0,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    final list = SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.xs),
        itemBuilder: (context, index) {
          final item = items[index];
          final isSelected = item == selected;
          return GestureDetector(
            onTap: () => onSelected(item),
            child: AnimatedContainer(
              duration: Motion.of(context, Motion.fast),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? palette.pillSelected : palette.background,
                borderRadius: AppRadius.fullAll,
                border: isSelected ? null : Border.all(color: palette.border),
              ),
              child: Text(
                labelOf(item),
                style: AppText.body14.copyWith(
                  color:
                      isSelected ? palette.onPillSelected : palette.textPrimary,
                ),
              ),
            ),
          );
        },
      ),
    );
    if (bleed == 0) return list;
    return LayoutBuilder(
      builder: (context, box) => SizedBox(
        height: 32,
        width: box.maxWidth,
        child: OverflowBox(
          minWidth: box.maxWidth + 2 * bleed,
          maxWidth: box.maxWidth + 2 * bleed,
          child: list,
        ),
      ),
    );
  }
}
