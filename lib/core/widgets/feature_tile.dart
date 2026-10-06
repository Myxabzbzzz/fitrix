import 'package:flutter/material.dart';
import 'package:fitrix/core/animation/motion.dart';
import 'package:fitrix/core/theme/app_palette.dart';

/// Grey rounded tile with a bold uppercase label and a 3D illustration,
/// used on the Home and My workouts screens. Shrinks slightly while pressed.
class FeatureTile extends StatefulWidget {
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

  static const double pressedScale = 0.97;

  @override
  State<FeatureTile> createState() => _FeatureTileState();
}

class _FeatureTileState extends State<FeatureTile> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final imageAsset = widget.imageAsset;

    return AnimatedScale(
      scale: _pressed ? FeatureTile.pressedScale : 1,
      duration: Motion.of(context, Motion.press),
      curve: Motion.curve,
      child: Material(
        color: palette.tile,
        borderRadius: BorderRadius.circular(8),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          onHighlightChanged: widget.onTap == null ? null : _setPressed,
          child: Stack(
            children: [
              if (imageAsset != null)
                Positioned.fill(
                  child: Align(
                    alignment: widget.imageAlignment,
                    child: FractionallySizedBox(
                      widthFactor: widget.imageWidthFactor,
                      heightFactor: 1,
                      child: Image.asset(imageAsset, fit: BoxFit.contain),
                    ),
                  ),
                ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Align(
                  alignment: widget.labelAlignment,
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: widget.labelSize,
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
      ),
    );
  }
}
