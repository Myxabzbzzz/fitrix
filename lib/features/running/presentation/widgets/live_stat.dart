import 'package:flutter/material.dart';

import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';

/// A caption over a big number, centred; the number shrinks to fit.
class LiveStat extends StatelessWidget {
  const LiveStat({
    super.key,
    required this.label,
    required this.value,
    required this.size,
    required this.valueKey,
  });

  final String label, value;
  final double size;
  final Key valueKey;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Column(
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppText.caption.copyWith(color: palette.textSecondary),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            key: valueKey,
            style: AppText.displayLarge.copyWith(
              fontSize: size,
              color: palette.textPrimary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}
