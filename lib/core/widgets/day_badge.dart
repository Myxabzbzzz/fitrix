import 'package:flutter/material.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';

/// Small pill with the weekday; a play triangle when [today], else a dot.
class DayBadge extends StatelessWidget {
  final String label;
  final bool today;

  const DayBadge({super.key, required this.label, this.today = false});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final color = palette.textPrimary;
    return Container(
      height: 16,
      padding: const EdgeInsets.only(left: 6, right: AppSpacing.xxs),
      decoration:
          BoxDecoration(color: palette.badge, borderRadius: AppRadius.fullAll),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          today
              ? Icon(Icons.play_arrow_rounded, size: 8, color: color)
              : SizedBox(
                  width: 4,
                  height: 4,
                  child: DecoratedBox(
                    decoration:
                        BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                ),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            label.toUpperCase(),
            maxLines: 1,
            style: AppText.microStrong
                .copyWith(fontSize: 9, height: 1, color: color),
          ),
        ],
      ),
    );
  }
}
