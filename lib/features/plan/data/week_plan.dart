import 'package:fitrix/features/exercises/data/exercise_catalog.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/features/workouts/data/workout_catalog.dart';

enum Intensity { easy, normal, hard }

enum SessionStatus { planned, done, missed, today }

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Calendar-day arithmetic that is safe across DST changes.
DateTime addDays(DateTime d, int n) => DateTime(d.year, d.month, d.day + n);

/// Monday of the week that contains [d].
DateTime weekStartOf(DateTime d) =>
    DateTime(d.year, d.month, d.day - (d.weekday - DateTime.monday));

bool sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// One session on the week plan.
class PlannedSession {
  final String id;

  /// Date only.
  final DateTime day;
  final Sport sport;
  final String title;
  final String? templateId;
  final int minutes;
  final Intensity intensity;

  PlannedSession({
    required this.id,
    required DateTime day,
    required this.sport,
    required this.title,
    this.templateId,
    required this.minutes,
    required this.intensity,
  }) : day = dateOnly(day);

  PlannedSession copyWith({DateTime? day}) => PlannedSession(
        id: id,
        day: day ?? this.day,
        sport: sport,
        title: title,
        templateId: templateId,
        minutes: minutes,
        intensity: intensity,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'day': '${day.year.toString().padLeft(4, '0')}-'
            '${day.month.toString().padLeft(2, '0')}-'
            '${day.day.toString().padLeft(2, '0')}',
        'sport': sport.name,
        'title': title,
        if (templateId != null) 'templateId': templateId,
        'minutes': minutes,
        'intensity': intensity.name,
      };

  /// Throws on anything malformed; the store skips such entries.
  factory PlannedSession.fromJson(Map<String, dynamic> j) {
    final parts = (j['day'] as String).split('-');
    if (parts.length != 3) throw const FormatException('bad day');
    final day =
        DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    return PlannedSession(
      id: j['id'] as String,
      day: day,
      sport: Sport.values.byName(j['sport'] as String),
      title: j['title'] as String,
      templateId: j['templateId'] as String?,
      minutes: j['minutes'] as int,
      intensity: Intensity.values.byName(j['intensity'] as String),
    );
  }
}

/// The finished workout that fulfils [s]: same day and same template (or
/// the same sport when the session has no template).
CompletedWorkout? completedFor(
    PlannedSession s, List<CompletedWorkout> history) {
  for (final w in history) {
    if (!sameDay(w.finishedAt, s.day)) continue;
    final match = s.templateId != null
        ? w.templateId == s.templateId
        : w.sport == s.sport;
    if (match) return w;
  }
  return null;
}

/// done when [completedFor] finds a workout. Otherwise missed before today,
/// today on today, planned after.
SessionStatus statusOf(
    PlannedSession s, List<CompletedWorkout> history, DateTime now) {
  if (completedFor(s, history) != null) return SessionStatus.done;
  final today = dateOnly(now);
  if (s.day.isBefore(today)) return SessionStatus.missed;
  if (s.day == today) return SessionStatus.today;
  return SessionStatus.planned;
}

/// Lower-body and full-body gym plans are hard, other gym plans from 60 min,
/// football is hard, stretching is easy, everything else is normal.
Intensity intensityOfTemplate(WorkoutTemplate t) {
  final name = t.name.toLowerCase();
  if (name.contains('stretch')) return Intensity.easy;
  switch (t.sport) {
    case Sport.football:
      return Intensity.hard;
    case Sport.gym:
      final focus = t.focus.toLowerCase();
      if (focus.contains('lower') ||
          focus.contains('full body') ||
          name.contains('leg') ||
          name.contains('full body')) {
        return Intensity.hard;
      }
      return t.estimatedDuration.inMinutes >= 60
          ? Intensity.hard
          : Intensity.normal;
    default:
      return Intensity.normal;
  }
}

/// Football, running and skiing load the legs, and so does a plan with an
/// exercise whose primary muscle group is legs or glutes (the catalog's
/// `group`). [templates] defaults to the built-in plans.
bool loadsLegs(PlannedSession s, ExerciseCatalog c,
    {List<WorkoutTemplate>? templates}) {
  switch (s.sport) {
    case Sport.football:
    case Sport.running:
    case Sport.winterSports:
      return true;
    default:
  }
  final id = s.templateId;
  if (id == null) return false;
  for (final t in templates ?? WorkoutCatalog.defaults) {
    if (t.id != id) continue;
    for (final e in t.exercises) {
      final info = c.byName(e.name);
      if (info == null) continue;
      if (info.group == MuscleGroup.legs || info.group == MuscleGroup.glutes) {
        return true;
      }
    }
    return false;
  }
  return false;
}

class PlanSuggestion {
  /// The session to move.
  final String sessionId;

  /// The other hard leg session it follows.
  final String otherSessionId;
  final DateTime from;
  final DateTime to;
  final String reason;

  const PlanSuggestion({
    required this.sessionId,
    required this.otherSessionId,
    required this.from,
    required this.to,
    this.reason = 'legs_recovery',
  });
}

bool _hardOn(List<PlannedSession> week, DateTime day) =>
    week.any((s) => s.intensity == Intensity.hard && sameDay(s.day, day));

/// Two hard leg-loading sessions on consecutive days: move the later gym
/// one to the first following day with no hard session and at least 48 h
/// after the other leg session. Only the later session has to be today or
/// later and not done ([isDone]); the other may be yesterday.
PlanSuggestion? suggestPlanChange(
    List<PlannedSession> week, DateTime today, ExerciseCatalog c,
    {List<WorkoutTemplate>? templates, bool Function(PlannedSession)? isDone}) {
  final from = dateOnly(today);
  final hardLegs = [
    for (final s in week)
      if (s.intensity == Intensity.hard &&
          loadsLegs(s, c, templates: templates))
        s,
  ]..sort((a, b) => a.day.compareTo(b.day));
  for (final later in hardLegs) {
    if (later.sport != Sport.gym || later.day.isBefore(from)) continue;
    if (isDone != null && isDone(later)) continue;
    for (final other in hardLegs) {
      if (other.id == later.id || addDays(other.day, 1) != later.day) continue;
      for (var n = 1; n <= 7; n++) {
        final cand = addDays(later.day, n);
        if (cand.isBefore(addDays(other.day, 2))) continue;
        if (_hardOn(week, cand)) continue;
        return PlanSuggestion(
          sessionId: later.id,
          otherSessionId: other.id,
          from: later.day,
          to: cand,
        );
      }
    }
  }
  return null;
}

/// Hard sessions today and in the two days after it.
int hardInNext3Days(List<PlannedSession> week, DateTime today) {
  final start = dateOnly(today);
  final end = addDays(start, 2);
  return week
      .where((s) =>
          s.intensity == Intensity.hard &&
          !s.day.isBefore(start) &&
          !s.day.isAfter(end))
      .length;
}

/// Whether a session of [i] on [day] makes three or more hard days in a row.
bool wouldBeThirdHardDayInARow(
    List<PlannedSession> week, DateTime day, Intensity i) {
  if (i != Intensity.hard) return false;
  final d = dateOnly(day);
  var run = 1;
  for (var n = 1; _hardOn(week, addDays(d, -n)); n++) {
    run++;
  }
  for (var n = 1; _hardOn(week, addDays(d, n)); n++) {
    run++;
  }
  return run >= 3;
}

/// What today holds on the week plan.
enum TodayKind {
  /// A session today is still open ([TodayPlan.session]).
  session,

  /// Nothing planned today.
  rest,

  /// Today's sessions are all done.
  done,

  /// The plan has nothing this week or later: screens fall back to the
  /// user's first plan.
  unplanned,
}

class TodayPlan {
  final TodayKind kind;

  /// Today's first open session, for [TodayKind.session].
  final PlannedSession? session;

  /// The first session after today (earliest day, then plan order).
  final PlannedSession? next;

  const TodayPlan(this.kind, {this.session, this.next});
}

/// Whether the plan is in use: it has a session this week (Mon-Sun) or
/// later.
bool planInUse(List<PlannedSession> plan, DateTime today) {
  final monday = weekStartOf(today);
  return plan.any((s) => !s.day.isBefore(monday));
}

/// The first session of [plan] after [today] that passes [where], earliest
/// day first (plan order within a day).
PlannedSession? nextSessionAfter(List<PlannedSession> plan, DateTime today,
    {bool Function(PlannedSession)? where}) {
  final day = dateOnly(today);
  PlannedSession? next;
  for (final s in plan) {
    if (!s.day.isAfter(day) || (where != null && !where(s))) continue;
    if (next == null || s.day.isBefore(next.day)) next = s;
  }
  return next;
}

/// Today on the plan: its open session, or a rest / done day with the next
/// session; [TodayKind.unplanned] when the plan is not in use.
TodayPlan todayPlanOf(
    List<PlannedSession> plan, List<CompletedWorkout> history, DateTime today) {
  final day = dateOnly(today);
  if (!planInUse(plan, day)) return const TodayPlan(TodayKind.unplanned);
  final todays = [
    for (final s in plan)
      if (s.day == day) s
  ];
  for (final s in todays) {
    if (statusOf(s, history, day) != SessionStatus.done) {
      return TodayPlan(TodayKind.session, session: s);
    }
  }
  return TodayPlan(todays.isEmpty ? TodayKind.rest : TodayKind.done,
      next: nextSessionAfter(plan, day));
}
