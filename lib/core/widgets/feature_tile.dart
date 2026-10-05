import 'package:flutter/material.dart';
import 'package:fitrix/core/theme/app_palette.dart';

/// Grey rounded tile with a bold uppercase label and a 3D illustration,
/// used on the Home and My workouts screens.
class FeatureTile extends StatelessWidget {
  final String label;
  final double labelSize;
  final String? imageAsset;

  /// Fraction of the tile occupied by the illustration (anchored right).
  final double imageWidthFactor;
  final Alignment labelAlignment;
  final Alignment imageAlignment;
  final VoidCallback? onTap;

  const FeatureTile({
    super.key,
    required this.label,
    this.labelSize = 16,
    this.imageAsset,
    this.imageWidthFactor = 0.55,
    this.labelAlignment = Alignment.centerLeft,
    this.imageAlignment = Alignment.centerRight,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Material(
      color: palette.tile,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            if (imageAsset != null)
              Positioned.fill(
                child: Align(
                  alignment: imageAlignment,
                  child: FractionallySizedBox(
                    widthFactor: imageWidthFactor,
                    heightFactor: 1,
                    child: Image.asset(imageAsset!, fit: BoxFit.contain),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Align(
                alignment: labelAlignment,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: labelSize,
                    fontWeight: FontWeight.w800,
                    height: 0.95,
                    letterSpacing: 0.2,
                    color: palette.textPrimary,
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
