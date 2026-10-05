import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';

/// Live "1h 43m 22s" counter since [startedAt].
class ElapsedTimeText extends StatefulWidget {
  final DateTime startedAt;
  final TextStyle? style;

  const ElapsedTimeText({super.key, required this.startedAt, this.style});

  @override
  State<ElapsedTimeText> createState() => _ElapsedTimeTextState();
}

class _ElapsedTimeTextState extends State<ElapsedTimeText> {
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
    return Text(
      formatDuration(DateTime.now().difference(widget.startedAt)),
      style: widget.style,
    );
  }
}
