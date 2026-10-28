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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: AppText.caption.copyWith(color: palette.textSecondary)),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(value,
              maxLines: 1,
              style: AppText.headingM.copyWith(
                  color: palette.textPrimary,
                  fontFeatures: const [FontFeature.tabularFigures()])),
        ),
      ],
    );
  }
}

/// [RunFigure]s in two equal columns: the second column starts at the same
/// x on every row, and an odd last figure keeps its column.
class RunFigureGrid extends StatelessWidget {
  const RunFigureGrid(
      {super.key, required this.children, this.runSpacing = AppSpacing.md});

  final List<Widget> children;
  final double runSpacing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < children.length; i += 2) ...[
          if (i > 0) SizedBox(height: runSpacing),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: children[i]),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                  child: i + 1 < children.length
                      ? children[i + 1]
                      : const SizedBox.shrink()),
            ],
          ),
        ],
      ],
    );
  }
}
