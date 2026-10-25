import 'package:flutter/material.dart';

import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';

/// A caption over a number on a summary screen.
class RunFigure extends StatelessWidget {
  const RunFigure({super.key, required this.label, required this.value});

  final String label, value;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 120, maxWidth: 160),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppText.caption.copyWith(color: palette.textSecondary)),
          Text(value,
              style: AppText.headingM.copyWith(
                  color: palette.textPrimary,
                  fontFeatures: const [FontFeature.tabularFigures()])),
        ],
      ),
    );
  }
}
