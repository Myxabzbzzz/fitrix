import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:fitrix/core/theme/app_palette.dart';

/// Line chart card from the "My progress" design: grid, Y/X labels,
/// a gradient-filled line and a highlighted last point.
class ProgressChart extends StatelessWidget {
  final String title;
  final List<double> values;
  final List<String> xLabels;
  final double minY;
  final double maxY;
  final int yDivisions;
  final String? footerLeft;
  final String? footerRight;

  const ProgressChart({
    super.key,
    required this.title,
    required this.values,
    required this.xLabels,
    required this.minY,
    required this.maxY,
    this.yDivisions = 4,
    this.footerLeft,
    this.footerRight,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final footerStyle = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      color: palette.textPrimary,
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: palette.chartCard,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 110,
            width: double.infinity,
            child: CustomPaint(
              painter: _ChartPainter(
                values: values,
                xLabels: xLabels,
                minY: minY,
                maxY: maxY,
                yDivisions: yDivisions,
                lineColor: palette.accent,
                gridColor: palette.border,
                labelColor: palette.chartLabel,
              ),
            ),
          ),
          if (footerLeft != null || footerRight != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(footerLeft ?? '', style: footerStyle),
                Text(footerRight ?? '', style: footerStyle),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<double> values;
  final List<String> xLabels;
  final double minY;
  final double maxY;
  final int yDivisions;
  final Color lineColor;
  final Color gridColor;
  final Color labelColor;

  _ChartPainter({
    required this.values,
    required this.xLabels,
    required this.minY,
    required this.maxY,
    required this.yDivisions,
    required this.lineColor,
    required this.gridColor,
    required this.labelColor,
  });

  static const double _leftAxis = 26;
  static const double _bottomAxis = 16;

  TextPainter _label(String text) => TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(fontSize: 10, color: labelColor),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

  String _formatY(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final chart = Rect.fromLTRB(
      _leftAxis,
      6,
      size.width - 6,
      size.height - _bottomAxis,
    );
    double yFor(double v) =>
        chart.bottom - (v - minY) / (maxY - minY) * chart.height;

    // Grid + Y labels
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var i = 0; i <= yDivisions; i++) {
      final value = minY + (maxY - minY) * i / yDivisions;
      final y = yFor(value);
      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), gridPaint);
      final tp = _label(_formatY(value));
      tp.paint(canvas, Offset(0, y - tp.height / 2));
    }

    // X labels
    if (xLabels.isNotEmpty) {
      for (var i = 0; i < xLabels.length; i++) {
        final x = xLabels.length == 1
            ? chart.left
            : chart.left + chart.width * i / (xLabels.length - 1);
        final tp = _label(xLabels[i]);
        final dx = (x - tp.width / 2).clamp(0.0, size.width - tp.width);
        tp.paint(canvas, Offset(dx, chart.bottom + 3));
      }
    }

    // Line + area
    final points = <Offset>[
      for (var i = 0; i < values.length; i++)
        Offset(
          values.length == 1
              ? chart.left
              : chart.left + chart.width * i / (values.length - 1),
          yFor(values[i].clamp(minY, maxY)),
        ),
    ];

    final line = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      line.lineTo(p.dx, p.dy);
    }

    final area = Path.from(line)
      ..lineTo(points.last.dx, chart.bottom)
      ..lineTo(points.first.dx, chart.bottom)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, chart.top),
          Offset(0, chart.bottom),
          [
            lineColor.withValues(alpha: 0.30),
            lineColor.withValues(alpha: 0.05),
          ],
        ),
    );

    canvas.drawPath(
      line,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );

    // Highlighted last point with a soft glow
    final last = points.last;
    canvas.drawCircle(last, 8, Paint()..color = lineColor.withValues(alpha: 0.15));
    canvas.drawCircle(last, 3, Paint()..color = lineColor);
  }

  @override
  bool shouldRepaint(covariant _ChartPainter old) =>
      old.values != values ||
      old.lineColor != lineColor ||
      old.minY != minY ||
      old.maxY != maxY;
}
