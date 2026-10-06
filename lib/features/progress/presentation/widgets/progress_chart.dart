import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fitrix/core/animation/motion.dart';
import 'package:fitrix/core/theme/app_palette.dart';

/// Line chart card from the "My progress" design: grid, Y/X labels,
/// a gradient-filled line and a highlighted last point. The line and area
/// draw in from the left when the chart first appears (and when its data
/// changes).
class ProgressChart extends StatefulWidget {
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
  State<ProgressChart> createState() => _ProgressChartState();
}

class _ProgressChartState extends State<ProgressChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drawIn = AnimationController(
    vsync: this,
    duration: Motion.slow,
  );
  late final Animation<double> _progress =
      CurvedAnimation(parent: _drawIn, curve: Motion.curve);

  VoidCallback? _cancelPending;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.reduced(context)) {
      _cancelPending?.call();
      _drawIn.value = 1;
    } else if (_cancelPending == null && _drawIn.isDismissed) {
      // First appearance: draw in once the page transition is done.
      _cancelPending = afterRouteEntrance(context, _start);
    }
  }

  @override
  void didUpdateWidget(ProgressChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.values, widget.values)) _start();
  }

  void _start() {
    if (!mounted) return;
    if (Motion.reduced(context)) {
      _drawIn.value = 1;
    } else {
      _drawIn.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _cancelPending?.call();
    _drawIn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final footerLeft = widget.footerLeft;
    final footerRight = widget.footerRight;
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
            widget.title,
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
                progress: _progress,
                values: widget.values,
                xLabels: widget.xLabels,
                minY: widget.minY,
                maxY: widget.maxY,
                yDivisions: widget.yDivisions,
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
                Flexible(
                  child: Text(
                    footerLeft ?? '',
                    style: footerStyle,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    footerRight ?? '',
                    style: footerStyle,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  /// 0..1: how much of the line/area is drawn (left to right). Repaints
  /// without rebuilding the card.
  final Animation<double> progress;
  final List<double> values;
  final List<String> xLabels;
  final double minY;
  final double maxY;
  final int yDivisions;
  final Color lineColor;
  final Color gridColor;
  final Color labelColor;

  _ChartPainter({
    required this.progress,
    required this.values,
    required this.xLabels,
    required this.minY,
    required this.maxY,
    required this.yDivisions,
    required this.lineColor,
    required this.gridColor,
    required this.labelColor,
  }) : super(repaint: progress);

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

    // Draw-in: reveal the line and area left to right.
    final t = progress.value;
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(
      0,
      0,
      chart.left + (chart.width + 8) * t,
      size.height,
    ));

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

    canvas.restore();

    // Highlighted last point with a soft glow, popping in as the line
    // reaches it.
    final dot = ((t - 0.85) / 0.15).clamp(0.0, 1.0);
    if (dot > 0) {
      final last = points.last;
      canvas.drawCircle(
        last,
        8 * dot,
        Paint()..color = lineColor.withValues(alpha: 0.15),
      );
      canvas.drawCircle(last, 3 * dot, Paint()..color = lineColor);
    }
  }

  @override
  bool shouldRepaint(covariant _ChartPainter old) =>
      old.progress != progress ||
      old.values != values ||
      old.lineColor != lineColor ||
      old.minY != minY ||
      old.maxY != maxY;
}
