import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitrix/core/time/today_provider.dart';
import 'package:fitrix/features/running/presentation/run_format.dart';

/// Live "1:43:22" counter since [startedAt], read from the app clock.
///
/// A clock reads the same in every language (no "h m s" units), and it
/// shrinks rather than touching the screen edges at large text sizes.
class ElapsedTimeText extends ConsumerStatefulWidget {
  final DateTime startedAt;
  final TextStyle? style;

  const ElapsedTimeText({super.key, required this.startedAt, this.style});

  @override
  ConsumerState<ElapsedTimeText> createState() => _ElapsedTimeTextState();
}

class _ElapsedTimeTextState extends ConsumerState<ElapsedTimeText> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = ref.watch(clockProvider)();
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        formatClock(now.difference(widget.startedAt)),
        maxLines: 1,
        style: widget.style,
      ),
    );
  }
}
