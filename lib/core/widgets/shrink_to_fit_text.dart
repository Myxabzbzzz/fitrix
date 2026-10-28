import 'package:flutter/widgets.dart';
import 'package:fitrix/core/widgets/word_fit_text.dart';

/// One line of text that shrinks a little to fit, but never below
/// [minScale] of its size: past that it wraps onto up to [maxLines] lines
/// at full size instead of getting unreadably small (or ending in "…").
class ShrinkToFitText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final TextAlign? textAlign;
  final double minScale;
  final int maxLines;

  const ShrinkToFitText(
    this.text, {
    super.key,
    required this.style,
    this.textAlign,
    this.minScale = 0.8,
    this.maxLines = 2,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final base = DefaultTextStyle.of(context).style.merge(style);
      final fontSize = base.fontSize;
      final painter = TextPainter(
        textDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
        textScaler: MediaQuery.textScalerOf(context),
        maxLines: 1,
      );
      double widthAt(double size) {
        painter
          ..text = TextSpan(text: text, style: base.copyWith(fontSize: size))
          ..layout();
        return painter.width;
      }

      Widget oneLine(TextStyle s) => Text(text,
          maxLines: 1, softWrap: false, textAlign: textAlign, style: s);

      try {
        if (fontSize == null || !box.maxWidth.isFinite) return oneLine(style);
        final full = widthAt(fontSize);
        if (full <= box.maxWidth) return oneLine(style);
        var size = (fontSize * box.maxWidth / full * 10).floorToDouble() / 10;
        // Letter spacing doesn't scale with the font: nudge down to fit.
        for (var i = 0; i < 6 && widthAt(size) > box.maxWidth; i++) {
          size -= 0.25;
        }
        if (size >= fontSize * minScale) {
          return oneLine(style.copyWith(fontSize: size));
        }
        // Wrap at full size, shrinking only a word too wide for a line, and
        // never below the floor. A single word still too wide at the floor
        // stays on one line and ends in "…" rather than breaking mid-word.
        final floor = fontSize * minScale;
        final wordFit = WordFitText.fitted(context, text, style, box.maxWidth);
        final wordSize = wordFit.fontSize ?? fontSize;
        if (wordSize >= floor) {
          return Text(text,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              textAlign: textAlign,
              style: wordFit);
        }
        return Text(text,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            textAlign: textAlign,
            style: style.copyWith(fontSize: floor));
      } finally {
        painter.dispose();
      }
    });
  }
}
