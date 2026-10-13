import 'package:intl/intl.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';

/// What the Coach card says, or null when the user trained in the last 2 days
/// (nothing to nudge about). [now] is injectable for tests.
({String title, String message})? coachMessage(
    List<CompletedWorkout> history, DateTime now) {
  if (history.isEmpty) {
    final today = DateFormat('EEEE').format(now);
    return (
      title: 'Ready for your first workout?',
      message: 'Start with $today. Felix will adjust the plan after it.',
    );
  }
  final last = history
      .map((w) => w.finishedAt)
      .reduce((a, b) => a.isAfter(b) ? a : b);
  final days = DateTime(now.year, now.month, now.day)
      .difference(DateTime(last.year, last.month, last.day))
      .inDays;
  if (days < 3) return null;
  return (
    title: 'Welcome back',
    message: 'Your last workout was $days days ago. '
        'A lighter session today gets you back on track.',
  );
}
