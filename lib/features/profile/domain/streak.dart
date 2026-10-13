/// Consecutive local calendar days with a finished workout, ending today or
/// yesterday. 0 when the latest workout is older than yesterday.
int currentStreak(List<DateTime> finishedDays, DateTime today) {
  int dayNumber(DateTime d) =>
      DateTime.utc(d.year, d.month, d.day).millisecondsSinceEpoch ~/
      Duration.millisecondsPerDay;

  final days = {for (final d in finishedDays) dayNumber(d.toLocal())};
  final todayNumber = dayNumber(today);
  var cursor = days.contains(todayNumber) ? todayNumber : todayNumber - 1;
  var streak = 0;
  while (days.contains(cursor)) {
    streak++;
    cursor--;
  }
  return streak;
}
