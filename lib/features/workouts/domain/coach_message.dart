import 'package:intl/intl.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';

/// What the Coach card says, or null when the user trained in the last 2 days
/// (nothing to nudge about). [now] is injectable for tests.
({String title, String message})? coachMessage(
    List<CompletedWorkout> history, DateTime now,
    {String? todayWorkout}) {
  if (history.isEmpty) {
    final today = todayWorkout ?? DateFormat('EEEE').format(now);
    return (
      title: 'Ready for your first workout?',
      message: 'Start with $today. Felix will adjust the plan after it.',
    );
  }
  final last = history
      .map((w) => w.finishedAt)
      .reduce((a, b) => a.isAfter(b) ? a : b);
  // UTC midnights, so a daylight-saving change can't shift the day count.
  final days = DateTime.utc(now.year, now.month, now.day)
      .difference(DateTime.utc(last.year, last.month, last.day))
      .inDays;
  if (days < 3) return null;
  return (
    title: 'Welcome back',
    message: 'Your last workout was $days days ago. '
        'A lighter session today gets you back on track.',
  );
}
