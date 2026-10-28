import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:fitrix/core/animation/motion.dart';
import 'package:fitrix/core/theme/app_palette.dart';

/// Circular progress ring for a readiness score (0-100). Without a [score]
/// only the track is drawn.
class ReadinessRing extends StatelessWidget {
  final int? score;
  final double size;
  final double strokeWidth;
  final Widget? child;

  const ReadinessRing({
    super.key,
    required this.score,
    required this.size,
    this.strokeWidth = 8,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return SizedBox(
      width: size,
      height: size,
      // The fill sweeps in from zero, and to a new score when it changes.
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: (score ?? 0) / 100),
        duration: Motion.of(context, Motion.slow),
        curve: Motion.curve,
        child: Center(child: child),
        builder: (context, fraction, child) => CustomPaint(
          painter: _RingPainter(
            fraction: fraction,
            track: palette.buttonMuted,
            fill: palette.accent,
            strokeWidth: strokeWidth,
          ),
          child: child,
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double fraction;
  final Color track;
  final Color fill;
  final double strokeWidth;

  _RingPainter({
    required this.fraction,
    required this.track,
    required this.fill,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final arcRect = rect.deflate(strokeWidth / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(arcRect, 0, math.pi * 2, false, paint..color = track);
    if (fraction > 0) {
      canvas.drawArc(arcRect, -math.pi / 2, math.pi * 2 * fraction, false,
          paint..color = fill);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.fraction != fraction ||
      old.track != track ||
      old.fill != fill ||
      old.strokeWidth != strokeWidth;
}
