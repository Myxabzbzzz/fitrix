import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Text that wraps between words but never inside one: when the longest
/// word is wider than the available width (a big title or a narrow tile at
/// a large text size), the font shrinks just enough for that word to fit
/// instead of breaking it ("Восстановлен / ие").
class WordFitText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final int? maxLines;
  final TextAlign? textAlign;

  const WordFitText(
    this.text, {
    super.key,
    required this.style,
    this.maxLines,
    this.textAlign,
  });

  /// [style] scaled so that every word of [text] fits in [maxWidth].
  static TextStyle fitted(
      BuildContext context, String text, TextStyle style, double maxWidth) {
    if (!maxWidth.isFinite || maxWidth <= 0) return style;
    final base = DefaultTextStyle.of(context).style.merge(style);
    final fontSize = base.fontSize;
    if (fontSize == null) return style;
    final painter = TextPainter(
      textDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    );
    double widestAt(double size) {
      var widest = 0.0;
      for (final word in text.split(RegExp(r'\s+'))) {
        if (word.isEmpty) continue;
        painter
          ..text = TextSpan(text: word, style: base.copyWith(fontSize: size))
          ..layout();
        widest = math.max(widest, painter.width);
      }
      return widest;
    }

    final widest = widestAt(fontSize);
    if (widest <= maxWidth) {
      painter.dispose();
      return style;
    }
    // Proportional first, then nudge down: letter spacing doesn't shrink
    // with the font, so the proportional guess can be a hair too wide.
    var size = (fontSize * maxWidth / widest * 10).floorToDouble() / 10;
    for (var i = 0; i < 8 && size > 1 && widestAt(size) > maxWidth; i++) {
      size -= 0.5;
    }
    painter.dispose();
    return style.copyWith(fontSize: size);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Text(
        text,
        maxLines: maxLines,
        textAlign: textAlign,
        overflow: maxLines == null ? null : TextOverflow.ellipsis,
        style: fitted(context, text, style, constraints.maxWidth),
      ),
    );
  }
}
