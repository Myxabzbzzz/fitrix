import 'package:flutter/material.dart';
import 'package:fitrix/core/theme/app_palette.dart';

/// FITRIX wordmark as drawn in the design: the two "I"s and the "F" are
/// highlighted with the brand accent ("FI" + "TR" + "I" + "X").
class FitrixLogo extends StatelessWidget {
  final double fontSize;

  const FitrixLogo({super.key, this.fontSize = 24});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final base = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
      color: palette.textPrimary,
    );
    final accent = base.copyWith(color: palette.accent);

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: 'FI', style: accent),
          TextSpan(text: 'TR', style: base),
          TextSpan(text: 'I', style: accent),
          TextSpan(text: 'X', style: base),
        ],
      ),
    );
  }
}
