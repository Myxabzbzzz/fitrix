import 'package:fitrix/features/exercises/data/exercise_catalog.dart';
import 'package:fitrix/features/plan/data/week_plan.dart';
import 'package:fitrix/features/programs/data/program_store.dart';
import 'package:fitrix/features/programs/domain/program_catalog.dart';
import 'package:fitrix/features/progress/domain/progress_math.dart'
    show canonicalLift, liftSeries;
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/features/workouts/domain/training_math.dart';

/// One scheduled program session and the workout that fulfilled it.
class ProgramSlot {
  final PlannedSession session;
  final CompletedWorkout? done;
  const ProgramSlot(this.session, this.done);

  bool get isDone => done != null;

  /// Done on its day or earlier.
  bool get onTime =>
      done != null && !dateOnly(done!.finishedAt).isAfter(session.day);
}

/// The schedule of [active] with each slot matched to a workout: workouts of
/// the slot's template since the start are matched to that template's slots
/// in order.
List<ProgramSlot> programSlots(
    TrainingProgram p, ActiveProgram active, List<CompletedWorkout> history) {
  final sessions = scheduleProgram(
      p, active.start, active.weekdays, active.sessionTemplateIds);
  final byTemplate = <String, List<CompletedWorkout>>{};
  for (final w in history) {
    if (dateOnly(w.finishedAt).isBefore(active.start)) continue;
    byTemplate.putIfAbsent(w.templateId, () => []).add(w);
  }
  for (final l in byTemplate.values) {
    l.sort((a, b) => a.finishedAt.compareTo(b.finishedAt));
  }
  final used = <String, int>{};
  return [
    for (final s in sessions)
      ProgramSlot(s, () {
        final id = s.templateId;
        if (id == null) return null;
        final list = byTemplate[id] ?? const [];
        final i = used[id] ?? 0;
        if (i >= list.length) return null;
        used[id] = i + 1;
        return list[i];
      }()),
  ];
}

/// 1-based program week of [today], clamped to 1..weeks.
int programWeek(ActiveProgram a, TrainingProgram p, DateTime today) {
  final days = DateTime.utc(today.year, today.month, today.day)
      .difference(DateTime.utc(a.start.year, a.start.month, a.start.day))
      .inDays;
  return (days ~/ 7 + 1).clamp(1, p.weeks);
}

/// Last day of the program: the day before the first day of week weeks+1.
DateTime programEnd(ActiveProgram a, TrainingProgram p) =>
    addDays(a.start, p.weeks * 7 - 1);

class ProgramStats {
  /// Sessions due up to and including today, and how many of them are done.
  final int planned;
  final int done;

  /// Done on the day or earlier, among the sessions due before today plus the
  /// done ones. Null when nothing is due yet.
  final int? onTimePercent;
  final int records;
  const ProgramStats(this.planned, this.done, this.onTimePercent, this.records);
}

ProgramStats programStats(List<ProgramSlot> slots, DateTime today,
    List<CompletedWorkout> history, DateTime start) {
  final t = dateOnly(today);
  final due = [
    for (final s in slots)
      if (!s.session.day.isAfter(t)) s
  ];
  final done = due.where((s) => s.isDone).length;
  final judged = [
    for (final s in due)
      if (s.isDone || s.session.day.isBefore(t)) s
  ];
  final onTime = judged.where((s) => s.onTime).length;
  final records = allRecords(history)
      .where((r) => !dateOnly(r.date).isBefore(start))
      .length;
  return ProgramStats(due.length, done,
      judged.isEmpty ? null : (onTime * 100 / judged.length).round(), records);
}

/// The slots in the Monday-Sunday week of [today].
List<ProgramSlot> slotsThisWeek(List<ProgramSlot> slots, DateTime today) {
  final from = weekStartOf(today);
  final to = addDays(from, 6);
  return [
    for (final s in slots)
      if (!s.session.day.isBefore(from) && !s.session.day.isAfter(to)) s
  ];
}

/// The next session that is not done, today or later.
ProgramSlot? nextSlot(List<ProgramSlot> slots, DateTime today) {
  final t = dateOnly(today);
  for (final s in slots) {
    if (!s.isDone && !s.session.day.isBefore(t)) return s;
  }
  return null;
}

class LiftProgress {
  final String exercise;
  final ProgramExercise target;
  final double? start;
  final double? now;
  final double? goal;
  const LiftProgress(
      this.exercise, this.target, this.start, this.now, this.goal);

  /// 0..1 from start to goal.
  double get fraction {
    if (start == null || now == null || goal == null || goal! <= start!) {
      return 0;
    }
    return ((now! - start!) / (goal! - start!)).clamp(0.0, 1.0);
  }
}

/// Start: from the history before the program began, else the first logged
/// working set after it. Now: the best recent e1RM as working kg at the top
/// of the rep range ([startKg] over the whole history). Goal: start + 2.5 kg
/// (upper) or 5 kg (lower) per two full weeks of the program.
List<LiftProgress> liftProgress(TrainingProgram p, ActiveProgram a,
    List<CompletedWorkout> history, ExerciseCatalog? catalog) {
  final before = [
    for (final w in history)
      if (dateOnly(w.finishedAt).isBefore(a.start)) w
  ];
  return [
    for (final e in mainLifts(p, catalog))
      () {
        var start = startKg(e.exercise, before, e.repsHigh, catalog: catalog);
        if (start == null) {
          final after = liftSeries(history, e.exercise, catalog)
              .where((x) => !dateOnly(x.date).isBefore(a.start));
          if (after.isNotEmpty) start = after.first.kg;
        }
        final now = startKg(e.exercise, history, e.repsHigh, catalog: catalog);
        final step = isLowerLift(e.exercise, catalog) ? 5.0 : 2.5;
        return LiftProgress(e.exercise, e, start, now,
            start == null ? null : start + step * (p.weeks ~/ 2));
      }(),
  ];
}

class NextIncrease {
  final String exercise;
  final int sets;
  final int reps;
  final double nextKg;
  const NextIncrease(this.exercise, this.sets, this.reps, this.nextKg);
}

/// The first main lift whose last two sessions since the start hit every
/// set at the top of the rep range. Next weight: last weight + 2.5 kg
/// (upper) or 5 kg (lower).
NextIncrease? nextIncrease(TrainingProgram p, ActiveProgram a,
    List<CompletedWorkout> history, ExerciseCatalog? catalog) {
  final recent = [
    for (final w in history)
      if (!dateOnly(w.finishedAt).isBefore(a.start)) w
  ]..sort((x, y) => y.finishedAt.compareTo(x.finishedAt));
  for (final e in mainLifts(p, catalog)) {
    final key = canonicalLift(e.exercise, catalog).key;
    final sessions = <List<WorkoutSet>>[];
    for (final w in recent) {
      final sets = [
        for (final x in w.exercises)
          if (canonicalLift(x.name, catalog).key == key)
            ...x.sets.where((s) => s.done && !s.warmup && s.kg > 0),
      ];
      if (sets.isNotEmpty) sessions.add(sets);
      if (sessions.length == 2) break;
    }
    if (sessions.length < 2) continue;
    final hit = sessions.every((sets) =>
        sets.length >= e.sets && sets.every((s) => s.reps >= e.repsHigh));
    if (!hit) continue;
    final last =
        sessions.first.map((s) => s.kg).reduce((a, b) => a > b ? a : b);
    final step = isLowerLift(e.exercise, catalog) ? 5.0 : 2.5;
    return NextIncrease(e.exercise, e.sets, e.repsHigh, last + step);
  }
  return null;
}
