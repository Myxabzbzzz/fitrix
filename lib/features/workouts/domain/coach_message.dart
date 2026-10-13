import 'package:intl/intl.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';

enum CoachMessageKind { firstWorkout, welcomeBack }

/// What the Coach card says, as data the screen turns into localized copy:
/// [kind] picks the text, [days] is the gap since the last workout
/// (welcomeBack), [today] the workout or weekday to start with (firstWorkout).
/// Null when the user trained in the last 2 days (nothing to nudge about).
/// [now] is injectable for tests; [localeName] formats the weekday fallback.
({CoachMessageKind kind, int days, String today})? coachMessage(
    List<CompletedWorkout> history, DateTime now,
    {String? todayWorkout, String? localeName}) {
  if (history.isEmpty) {
    return (
      kind: CoachMessageKind.firstWorkout,
      days: 0,
      today: todayWorkout ?? DateFormat('EEEE', localeName).format(now),
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
  return (kind: CoachMessageKind.welcomeBack, days: days, today: '');
}
