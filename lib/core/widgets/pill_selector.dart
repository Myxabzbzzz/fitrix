import 'package:flutter/material.dart';
import 'package:fitrix/core/theme/app_palette.dart';

/// Horizontally scrolling row of pills (Gym / Fitness / Cycling / ...).
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

    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = items[index];
          final isSelected = item == selected;
          return GestureDetector(
            onTap: () => onSelected(item),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? palette.pillSelected : palette.background,
                borderRadius: BorderRadius.circular(20),
                border: isSelected ? null : Border.all(color: palette.border),
              ),
              child: Text(
                labelOf(item),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? palette.onPillSelected : palette.textPrimary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
