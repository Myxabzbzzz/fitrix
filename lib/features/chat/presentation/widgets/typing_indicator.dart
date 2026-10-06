import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Three bouncing dots shown while Felix is preparing a reply.
class TypingIndicator extends StatefulWidget {
  final Color color;

  const TypingIndicator({super.key, required this.color});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Felix is typing',
      child: SizedBox(
        height: 18,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < 3; i++) _dot(i),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dot(int index) {
    // Each dot rises in turn, offset by a third of the cycle.
    final phase = (_controller.value - index / 3) % 1.0;
    final lift = math.sin(phase * math.pi * 2).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Transform.translate(
        offset: Offset(0, -4 * lift),
        child: Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: 0.4 + 0.6 * lift),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
