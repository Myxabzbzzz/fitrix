import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';

/// One line (or a set of dots) on a [MultiLineChart]. Points are
/// (x in 0..1 across the time span, y in data units).
class ChartSeries {
  final List<Offset> points;
  final Color color;
  final bool dashed;
  final bool dotsOnly;
  final bool ringDots;
  final bool fill;
  final bool endDot;
  const ChartSeries(
    this.points,
    this.color, {
    this.dashed = false,
    this.dotsOnly = false,
    this.ringDots = false,
    this.fill = false,
    this.endDot = false,
  });
}

/// Chart card body for the progress screens: grid, Y labels, X labels and
/// any number of lines, dotted series and an optional shaded band.
class MultiLineChart extends StatelessWidget {
  final List<ChartSeries> series;
  final double minY;
  final double maxY;
  final List<(double, String)> xLabels;

  /// Shaded area between [bandUpper] and [bandLower] (same x values).
  final List<Offset> bandUpper;
  final List<Offset> bandLower;
  final Color? bandColor;
  final double height;

  const MultiLineChart({
    super.key,
    required this.series,
    required this.minY,
    required this.maxY,
    required this.xLabels,
    this.bandUpper = const [],
    this.bandLower = const [],
    this.bandColor,
    this.height = 130,
  });

  /// Axis bounds that put 3 grid steps on whole numbers.
  static (double, double) niceRange(Iterable<double> values) {
    final lo = values.reduce((a, b) => a < b ? a : b);
    final hi = values.reduce((a, b) => a > b ? a : b);
    final pad = ((hi - lo) * 0.1).clamp(1.0, double.infinity);
    final bottom = (lo - pad).floorToDouble();
    final step = ((hi + pad - bottom) / 3).ceilToDouble();
    return (bottom < 0 && lo >= 0 ? 0 : bottom, bottom + step * 3);
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _Painter(
          series: series,
          minY: minY,
          maxY: maxY,
          xLabels: xLabels,
          bandUpper: bandUpper,
          bandLower: bandLower,
          bandColor: bandColor,
          grid: p.border,
          label: p.chartLabel,
          surface: p.chartCard,
        ),
      ),
    );
  }
}

class _Painter extends CustomPainter {
  final List<ChartSeries> series;
  final double minY, maxY;
  final List<(double, String)> xLabels;
  final List<Offset> bandUpper, bandLower;
  final Color? bandColor;
  final Color grid, label, surface;

  _Painter({
    required this.series,
    required this.minY,
    required this.maxY,
    required this.xLabels,
    required this.bandUpper,
    required this.bandLower,
    required this.bandColor,
    required this.grid,
    required this.label,
    required this.surface,
  });

  static const double _left = 30, _bottom = 18;

  TextPainter _text(String s) => TextPainter(
        text: TextSpan(text: s, style: AppText.micro.copyWith(color: label)),
        textDirection: TextDirection.ltr,
      )..layout();

  // Axis ticks of any unit: up to one decimal in the app language.
  String _fmt(double v) => NumberFormat('0.#').format(v);

  @override
  void paint(Canvas canvas, Size size) {
    final area = Rect.fromLTRB(_left, 8, size.width - 8, size.height - _bottom);
    final span = (maxY - minY) == 0 ? 1 : maxY - minY;
    Offset at(Offset pt) => Offset(
          area.left + area.width * pt.dx.clamp(0, 1),
          area.bottom - (pt.dy.clamp(minY, maxY) - minY) / span * area.height,
        );

    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (var i = 0; i <= 3; i++) {
      final v = minY + (maxY - minY) * i / 3;
      final y = at(Offset(0, v)).dy;
      canvas.drawLine(Offset(area.left, y), Offset(area.right, y), gridPaint);
      final tp = _text(_fmt(v));
      tp.paint(canvas, Offset(0, y - tp.height / 2));
    }
    for (final (x, s) in xLabels) {
      final tp = _text(s);
      final cx = area.left + area.width * x;
      tp.paint(
          canvas,
          Offset((cx - tp.width / 2).clamp(0, size.width - tp.width),
              area.bottom + 3));
    }

    if (bandUpper.length >= 2 && bandUpper.length == bandLower.length) {
      final path = Path()
        ..moveTo(at(bandUpper.first).dx, at(bandUpper.first).dy);
      for (final pt in bandUpper.skip(1)) {
        path.lineTo(at(pt).dx, at(pt).dy);
      }
      for (final pt in bandLower.reversed) {
        path.lineTo(at(pt).dx, at(pt).dy);
      }
      path.close();
      canvas.drawPath(
          path, Paint()..color = (bandColor ?? grid).withValues(alpha: 0.25));
    }

    for (final s in series) {
      if (s.points.isEmpty) continue;
      final pts = [for (final pt in s.points) at(pt)];
      if (s.dotsOnly) {
        for (final o in pts) {
          if (s.ringDots) {
            canvas.drawCircle(o, 4, Paint()..color = surface);
            canvas.drawCircle(
                o,
                4,
                Paint()
                  ..color = s.color
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 2);
          } else {
            canvas.drawCircle(o, 2.5, Paint()..color = s.color);
          }
        }
        continue;
      }
      final line = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (final o in pts.skip(1)) {
        line.lineTo(o.dx, o.dy);
      }
      if (s.fill && pts.length > 1) {
        final fillPath = Path.from(line)
          ..lineTo(pts.last.dx, area.bottom)
          ..lineTo(pts.first.dx, area.bottom)
          ..close();
        canvas.drawPath(
          fillPath,
          Paint()
            ..shader = ui.Gradient.linear(
              Offset(0, area.top),
              Offset(0, area.bottom),
              [
                s.color.withValues(alpha: 0.28),
                s.color.withValues(alpha: 0),
              ],
            ),
        );
      }
      final stroke = Paint()
        ..color = s.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round;
      if (s.dashed) {
        for (final m in line.computeMetrics()) {
          var d = 0.0;
          while (d < m.length) {
            canvas.drawPath(m.extractPath(d, d + 5), stroke);
            d += 9;
          }
        }
      } else {
        canvas.drawPath(line, stroke);
      }
      if (s.endDot) {
        canvas.drawCircle(
            pts.last, 7, Paint()..color = s.color.withValues(alpha: 0.22));
        canvas.drawCircle(pts.last, 3.5, Paint()..color = s.color);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _Painter old) =>
      old.series != series ||
      old.minY != minY ||
      old.maxY != maxY ||
      old.grid != grid;
}
