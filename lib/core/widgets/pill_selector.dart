import 'package:flutter/material.dart';
import 'package:fitrix/core/animation/motion.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';

/// Horizontally scrolling row of pills (Gym / Fitness / Cycling / ...).
///
/// The first pill sits on the page's 16 pt content edge and the row scrolls
/// out to the screen edge, so it must be placed full width: in a list with
/// a side margin use [withPageGutter] instead of the list's own padding.
class PillSelector<T> extends StatelessWidget {
  final List<T> items;
  final T selected;
  final String Function(T) labelOf;
  final ValueChanged<T> onSelected;

  const PillSelector({
    super.key,
    required this.items,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
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
    return list;
  }
}

/// Children of a list whose rows sit on the 16 pt page margin while its
/// pill rows run edge to edge: pads every child except the [PillSelector]s.
/// Use with a list that has no horizontal padding of its own.
List<Widget> withPageGutter(List<Widget> children) => [
      for (final c in children)
        c is PillSelector
            ? c
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: c),
    ];
