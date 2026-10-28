import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:fitrix/core/animation/motion.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/core/widgets/word_fit_text.dart';

/// Grey rounded tile with a bold uppercase label and a 3D illustration,
/// used on the Home and My workouts screens. Shrinks slightly while pressed.
///
/// The illustration keeps its size; the label lives in the room left of it
/// (or, for a full-tile illustration, under it). Screens pick one label
/// size per row with [fittedLabelSize] so neighbouring tiles match.
class FeatureTile extends StatefulWidget {
  final String label;
  final double labelSize;
  final String? imageAsset;

  /// Drawn large on the right when the tile has no [imageAsset] (sports
  /// without 3D art), so every tile in a list carries a picture.
  final IconData? icon;

  /// Fraction of the tile occupied by the illustration (anchored right).
  /// 1 means the illustration fills the tile and the label goes under it.
  final double imageWidthFactor;

  /// Width / height of the illustration file.
  final double imageAspect;

  /// Transparent margin on the illustration's left (or bottom, for a
  /// full-tile one), as a fraction of its painted width (height).
  final double artInset;

  final Alignment labelAlignment;
  final Alignment imageAlignment;
  final VoidCallback? onTap;

  const FeatureTile({
    super.key,
    required this.label,
    this.labelSize = 16,
    this.imageAsset,
    this.icon,
    this.imageWidthFactor = 0.55,
    this.imageAspect = 1.5,
    this.artInset = 0.2,
    this.labelAlignment = Alignment.centerLeft,
    this.imageAlignment = Alignment.centerRight,
    this.onTap,
  });

  static const double pressedScale = 0.97;

  /// Size of [icon] in a tile [tileHeight] tall.
  static double iconSize(double tileHeight) => tileHeight * 0.55;

  static TextStyle labelStyle(double size) => AppText.displayMedium
      .copyWith(fontSize: size, height: 0.95, letterSpacing: 0.2);

  /// Room for the label in a tile of [tile] size: (width, height).
  static Size labelArea(Size tile,
      {required double imageWidthFactor,
      double imageAspect = 1.5,
      double artInset = 0.2,
      bool hasImage = true,
      bool hasIcon = false}) {
    const padH = AppSpacing.md, padV = AppSpacing.sm;
    if (!hasImage) {
      final iconRoom = hasIcon ? iconSize(tile.height) + AppSpacing.md : 0;
      return Size(tile.width - 2 * padH - iconRoom, tile.height - 2 * padV);
    }
    if (imageWidthFactor >= 1) {
      // Full-tile art, painted "contain" and centred: the label goes in
      // its transparent bottom margin.
      final ph = math.min(tile.height, tile.width / imageAspect);
      final below = (tile.height - ph) / 2 + ph * artInset;
      return Size(tile.width - 2 * AppSpacing.sm, below - AppSpacing.xxs);
    }
    final boxW = tile.width * imageWidthFactor;
    final pw = math.min(boxW, tile.height * imageAspect);
    final artLeft = tile.width - boxW + (boxW - pw) / 2 + pw * artInset;
    return Size(artLeft - padH - AppSpacing.xs, tile.height - 2 * padV);
  }

  /// The largest size up to [size] at which [label] fits [area] without
  /// breaking a word: each word on one line, all lines within the height.
  static double fittedLabelSize(
      BuildContext context, String label, double size, Size area) {
    final scaler = MediaQuery.textScalerOf(context);
    final words = label.split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    final painter = TextPainter(textDirection: TextDirection.ltr);
    double widest(double s) {
      var w = 0.0;
      for (final word in words) {
        painter
          ..text = TextSpan(text: word, style: labelStyle(s))
          ..textScaler = scaler
          ..layout();
        w = math.max(w, painter.width);
      }
      return w;
    }

    double tall(double s) {
      painter
        ..text = TextSpan(text: label, style: labelStyle(s))
        ..textScaler = scaler
        ..layout(maxWidth: math.max(area.width, 1));
      return painter.height;
    }

    var s = size;
    while (s > 8 && (widest(s) > area.width || tall(s) > area.height)) {
      s -= 0.5;
    }
    painter.dispose();
    return s;
  }

  /// One label size for a row of tiles: the smallest of their fitted sizes.
  static double rowLabelSize(BuildContext context,
      List<({String label, double size, Size area})> tiles) {
    var s = double.infinity;
    for (final t in tiles) {
      s = math.min(s, fittedLabelSize(context, t.label, t.size, t.area));
    }
    return s;
  }

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
    final fullArt = widget.imageWidthFactor >= 1;

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
          child: LayoutBuilder(builder: (context, box) {
            final area = FeatureTile.labelArea(box.biggest,
                imageWidthFactor: widget.imageWidthFactor,
                imageAspect: widget.imageAspect,
                artInset: widget.artInset,
                hasImage: imageAsset != null,
                hasIcon: widget.icon != null);
            final label = SizedBox(
              width: area.width,
              child: WordFitText(
                widget.label,
                textAlign: fullArt ? TextAlign.center : TextAlign.start,
                style: FeatureTile.labelStyle(widget.labelSize)
                    .copyWith(color: palette.textPrimary),
              ),
            );
            return Stack(
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
                if (imageAsset == null && widget.icon != null)
                  Positioned(
                    right: AppSpacing.lg,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Icon(
                        widget.icon,
                        key: const ValueKey('feature-tile-icon'),
                        size: FeatureTile.iconSize(box.maxHeight),
                        color: palette.textSecondary,
                      ),
                    ),
                  ),
                if (fullArt)
                  Positioned(
                    left: AppSpacing.sm,
                    right: AppSpacing.sm,
                    bottom: AppSpacing.xxs,
                    child: Center(child: label),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                    child: Align(
                      alignment: widget.labelAlignment,
                      child: label,
                    ),
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
