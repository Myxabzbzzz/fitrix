import 'package:flutter/material.dart';
import 'package:fitrix/core/animation/motion.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/core/widgets/word_fit_text.dart';

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

  /// The narrowest the illustration gets to make room for a long label.
  static const double _minImageFactor = 0.3;

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
        borderRadius: AppRadius.smAll,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          onHighlightChanged: widget.onTap == null ? null : _setPressed,
          child: LayoutBuilder(
            builder: (context, box) => imageAsset == null
                ? _label(context, palette)
                : widget.imageWidthFactor >= 1
                    ? _stacked(context, palette, imageAsset)
                    : _sideBySide(context, palette, imageAsset, box),
          ),
        ),
      ),
    );
  }

  TextStyle _style(AppPalette palette) => AppText.displayMedium.copyWith(
        fontSize: widget.labelSize,
        height: 0.95,
        letterSpacing: 0.2,
        color: palette.textPrimary,
      );

  Widget _label(BuildContext context, AppPalette palette,
          {EdgeInsets padding = const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm)}) =>
      Padding(
        padding: padding,
        child: Align(
          alignment: widget.labelAlignment,
          child: WordFitText(widget.label, style: _style(palette)),
        ),
      );

  /// Label on the left, illustration on the right, never overlapping: the
  /// illustration gives up width (down to [_minImageFactor] of the tile) for
  /// a long label, and past that the label shrinks.
  Widget _sideBySide(BuildContext context, AppPalette palette,
      String imageAsset, BoxConstraints box) {
    final w = box.maxWidth;
    final style = _style(palette);
    final painter = TextPainter(
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    );
    var widest = 0.0;
    for (final word in widget.label.split(RegExp(r'\s+'))) {
      painter
        ..text = TextSpan(text: word, style: style)
        ..layout();
      if (painter.width > widest) widest = painter.width;
    }
    painter.dispose();
    final labelNeeds = AppSpacing.md + widest + AppSpacing.xs;
    final imageWidth = (w - labelNeeds)
        .clamp(w * FeatureTile._minImageFactor, w * widget.imageWidthFactor)
        .toDouble();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: _label(context, palette,
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.sm, AppSpacing.xs, AppSpacing.sm)),
        ),
        SizedBox(
          width: imageWidth,
          child: Align(
            alignment: widget.imageAlignment,
            child: Image.asset(imageAsset, fit: BoxFit.contain),
          ),
        ),
      ],
    );
  }

  /// Illustration filling the tile with the label underneath it.
  Widget _stacked(
          BuildContext context, AppPalette palette, String imageAsset) =>
      Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          children: [
            Expanded(
              child: Image.asset(imageAsset, fit: BoxFit.contain),
            ),
            const SizedBox(height: AppSpacing.xs),
            WordFitText(widget.label,
                textAlign: TextAlign.center, style: _style(palette)),
          ],
        ),
      );
}
