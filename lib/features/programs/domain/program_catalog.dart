import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitrix/features/exercises/data/exercise_catalog.dart';
import 'package:fitrix/features/plan/data/week_plan.dart';
import 'package:fitrix/features/progress/domain/progress_math.dart'
    show liftSeries;
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/features/workouts/domain/training_math.dart';

class ProgramExercise {
  final String exercise;
  final int sets;
  final int repsLow;
  final int repsHigh;
  final int rir;

  const ProgramExercise({
    required this.exercise,
    required this.sets,
    required this.repsLow,
    required this.repsHigh,
    required this.rir,
  });

  factory ProgramExercise.fromJson(Map<String, dynamic> j) => ProgramExercise(
        exercise: j['exercise'] as String,
        sets: j['sets'] as int,
        repsLow: j['repsLow'] as int,
        repsHigh: j['repsHigh'] as int,
        rir: j['rir'] as int,
      );
}

class ProgramSession {
  final String name;
  final List<ProgramExercise> exercises;
  final int minutes;

  const ProgramSession({
    required this.name,
    required this.exercises,
    required this.minutes,
  });

  factory ProgramSession.fromJson(Map<String, dynamic> j) => ProgramSession(
        name: j['name'] as String,
        minutes: j['minutes'] as int,
        exercises: [
          for (final e in j['exercises'] as List)
            ProgramExercise.fromJson(e as Map<String, dynamic>),
        ],
      );
}

class TrainingProgram {
  final String id;
  final String name;
  final String author;
  final int weeks;
  final int perWeek;

  /// `beginner`, `intermediate` or `advanced`.
  final String level;

  /// `muscle`, `strength` or `fat_loss`.
  final List<String> goals;
  final bool atHome;
  final String summary;
  final List<ProgramSession> sessions;
  final int? deloadWeek;

  /// "Title: explanation" lines.
  final List<String> progressionRules;

  const TrainingProgram({
    required this.id,
    required this.name,
    required this.author,
    required this.weeks,
    required this.perWeek,
    required this.level,
    required this.goals,
    required this.atHome,
    required this.summary,
    required this.sessions,
    required this.deloadWeek,
    required this.progressionRules,
  });

  factory TrainingProgram.fromJson(Map<String, dynamic> j) => TrainingProgram(
        id: j['id'] as String,
        name: j['name'] as String,
        author: j['author'] as String,
        weeks: j['weeks'] as int,
        perWeek: j['perWeek'] as int,
        level: j['level'] as String,
        goals: [for (final g in j['goals'] as List) g as String],
        atHome: j['atHome'] as bool? ?? false,
        summary: j['summary'] as String,
        deloadWeek: j['deloadWeek'] as int?,
        progressionRules: [
          for (final r in j['progressionRules'] as List) r as String,
        ],
        sessions: [
          for (final s in j['sessions'] as List)
            ProgramSession.fromJson(s as Map<String, dynamic>),
        ],
      );

  /// The session minutes shared by all sessions, or the longest.
  int get sessionMinutes =>
      sessions.fold(0, (m, s) => s.minutes > m ? s.minutes : m);

  /// The program session on the [i]-th training day (0-based), cycling.
  ProgramSession sessionAt(int i) => sessions[i % sessions.length];
}

class ProgramCatalog {
  static const assetPath = 'assets/data/training_programs.json';

  final List<TrainingProgram> programs;
  const ProgramCatalog(this.programs);

  TrainingProgram? byId(String id) {
    for (final p in programs) {
      if (p.id == id) return p;
    }
    return null;
  }

  static ProgramCatalog parse(String raw) => ProgramCatalog([
        for (final p in jsonDecode(raw) as List)
          TrainingProgram.fromJson(p as Map<String, dynamic>),
      ]);

  static Future<ProgramCatalog> load(AssetBundle bundle) async =>
      parse(await bundle.loadString(assetPath));
}

final programCatalogProvider = FutureProvider<ProgramCatalog>(
  (ref) => ProgramCatalog.load(rootBundle),
);

/// Maps the free-text profile goal to `muscle`, `strength` or `fat_loss`.
/// Matching is by lowercase substring: muscle, mass, bulk, size, hypertrophy,
/// gain -> muscle; strength, strong, power -> strength; fat, lose, loss, cut,
/// slim, lean, weight -> fat_loss. Null when nothing matches.
String? programGoalFor(String goal) {
  final g = goal.toLowerCase();
  bool has(List<String> words) => words.any(g.contains);
  if (has(['muscle', 'mass', 'bulk', 'size', 'hypertrophy', 'gain'])) {
    return 'muscle';
  }
  if (has(['strength', 'strong', 'power'])) return 'strength';
  if (has(['fat', 'lose', 'loss', 'cut', 'slim', 'lean', 'weight'])) {
    return 'fat_loss';
  }
  return null;
}

/// Maps the free-text experience to a program level: advanced / expert /
/// pro / 5+ -> advanced; intermediate / some / 1-3 -> intermediate;
/// beginner / new / never / first / just -> beginner. Null otherwise.
String? programLevelFor(String experience) {
  final e = experience.toLowerCase();
  bool has(List<String> words) => words.any(e.contains);
  if (has(['advanced', 'expert', 'pro', '5+'])) return 'advanced';
  if (has(['intermediate', 'some', '1-3', '1–3', 'moderate'])) {
    return 'intermediate';
  }
  if (has(['beginner', 'new', 'never', 'first', 'just', 'start'])) {
    return 'beginner';
  }
  return null;
}

/// How well a program matches the profile's goal and experience.
enum ProgramFit { goalAndLevel, goal, level, none }

ProgramFit programFit(TrainingProgram p, String goal, String experience) {
  final g = programGoalFor(goal);
  final l = programLevelFor(experience);
  final goalOk = g != null && p.goals.contains(g);
  final levelOk = l != null && p.level == l;
  if (goalOk && levelOk) return ProgramFit.goalAndLevel;
  if (goalOk) return ProgramFit.goal;
  if (levelOk) return ProgramFit.level;
  return ProgramFit.none;
}

/// The first program that matches the goal and the level; failing that the
/// first matching the goal, then the level; failing that the first program
/// ([programFit] then says [ProgramFit.none]).
TrainingProgram? pickProgram(
    List<TrainingProgram> programs, String goal, String experience) {
  if (programs.isEmpty) return null;
  final g = programGoalFor(goal);
  final l = programLevelFor(experience);
  TrainingProgram? first(bool Function(TrainingProgram) t) {
    for (final p in programs) {
      if (t(p)) return p;
    }
    return null;
  }

  bool goalOk(TrainingProgram p) => g != null && p.goals.contains(g);
  bool levelOk(TrainingProgram p) => l != null && p.level == l;
  return first((p) => goalOk(p) && levelOk(p)) ??
      first(goalOk) ??
      first(levelOk) ??
      programs.first;
}

const _presets = <int, List<int>>{
  1: [1],
  2: [1, 4],
  3: [1, 3, 5],
  4: [1, 2, 4, 5],
  5: [1, 2, 3, 5, 6],
  6: [1, 2, 3, 4, 5, 6],
  7: [1, 2, 3, 4, 5, 6, 7],
};

List<List<int>> _combos(List<int> pool, int k) {
  final out = <List<int>>[];
  void go(int from, List<int> cur) {
    if (cur.length == k) {
      out.add([...cur]);
      return;
    }
    for (var i = from; i < pool.length; i++) {
      cur.add(pool[i]);
      go(i + 1, cur);
      cur.removeLast();
    }
  }

  go(0, []);
  return out;
}

/// Weekdays (1 = Monday) with a hard non-gym session in [plan].
Set<int> hardNonGymWeekdays(List<PlannedSession> plan) => {
      for (final s in plan)
        if (s.sport != Sport.gym && s.intensity == Intensity.hard)
          s.day.weekday,
    };

/// The default training days with no plan at all.
List<int> naiveWeekdays(TrainingProgram p) =>
    List.of(_presets[p.perWeek.clamp(1, 7)]!);

/// [p.perWeek] weekdays (1 = Monday). Starts from the usual spread (3 ->
/// Mon Wed Fri, 4 -> Mon Tue Thu Fri ...) and avoids days with a hard
/// non-gym session in [nonGymPlan] and the days right before and after it
/// (legs recover on both sides), choosing the
/// closest spread of the remaining days. When too few days are free the
/// day-before days are used first, then the hard days themselves.
List<int> defaultWeekdays(TrainingProgram p, List<PlannedSession> nonGymPlan) {
  final k = p.perWeek.clamp(1, 7);
  final preset = _presets[k]!;
  final hard = hardNonGymWeekdays(nonGymPlan);
  if (hard.isEmpty) return List.of(preset);
  final before = {for (final d in hard) d == 1 ? 7 : d - 1};
  final after = {for (final d in hard) d == 7 ? 1 : d + 1};
  bool blocked(int d) =>
      hard.contains(d) || before.contains(d) || after.contains(d);
  final free = [
    for (var d = 1; d <= 7; d++)
      if (!blocked(d)) d
  ];
  if (free.length < k) {
    // Not enough clear days: use the days next to a hard day first (the
    // day after before the day before), then the hard days themselves.
    final extra = [
      for (var d = 1; d <= 7; d++)
        if (!hard.contains(d) && after.contains(d)) d,
      for (var d = 1; d <= 7; d++)
        if (!hard.contains(d) && !after.contains(d) && before.contains(d)) d,
      for (var d = 1; d <= 7; d++)
        if (hard.contains(d)) d,
    ];
    for (final d in extra) {
      if (free.length >= k) break;
      free.add(d);
    }
    free.sort();
  }
  if (free.length == k) return free;

  (int, int, int, List<int>) score(List<int> c) {
    var dist = 0;
    for (var i = 0; i < k; i++) {
      dist += (c[i] - preset[i]).abs();
    }
    var minGap = 7, sq = 0;
    for (var i = 0; i < k; i++) {
      final next = i == k - 1 ? c[0] + 7 : c[i + 1];
      final gap = next - c[i];
      if (gap < minGap) minGap = gap;
      sq += gap * gap;
    }
    return (dist, -minGap, sq, c);
  }

  int cmp((int, int, int, List<int>) a, (int, int, int, List<int>) b) {
    for (final r in [
      a.$1.compareTo(b.$1),
      a.$2.compareTo(b.$2),
      a.$3.compareTo(b.$3)
    ]) {
      if (r != 0) return r;
    }
    for (var i = 0; i < k; i++) {
      final r = a.$4[i].compareTo(b.$4[i]);
      if (r != 0) return r;
    }
    return 0;
  }

  List<int>? best;
  for (final c in _combos(free, k)) {
    if (best == null || cmp(score(c), score(best)) < 0) best = c;
  }
  return best!;
}

/// Training days of the default week that [nonGymPlan] pushes off: preset
/// days that are, or come the day before, a hard non-gym day.
List<int> clashingWeekdays(TrainingProgram p, List<PlannedSession> nonGymPlan) {
  final hard = hardNonGymWeekdays(nonGymPlan);
  return [
    for (final d in naiveWeekdays(p))
      if (hard.contains(d) || hard.contains(d == 7 ? 1 : d + 1)) d
  ];
}

/// Id prefix of the plan sessions that belong to program [programId].
String programSessionPrefix(String programId) => 'prog-$programId-';

/// All sessions of the program: [p.weeks] x [p.perWeek], on the first
/// [weekdays] (1 = Monday) at or after [start], cycling through the program
/// sessions. Any 7 consecutive days hold exactly `perWeek` of them. The
/// plan session id is `prog-<id>-<yyyymmdd of start>-<n>`.
List<PlannedSession> scheduleProgram(TrainingProgram p, DateTime start,
    List<int> weekdays, Map<String, String> templateIds,
    {Intensity Function(ProgramSession)? intensityOf}) {
  final days = weekdays.toSet();
  final total = p.weeks * p.perWeek;
  if (days.isEmpty || total == 0) return const [];
  final s0 = dateOnly(start);
  final tag = '${s0.year.toString().padLeft(4, '0')}'
      '${s0.month.toString().padLeft(2, '0')}'
      '${s0.day.toString().padLeft(2, '0')}';
  final out = <PlannedSession>[];
  for (var d = s0; out.length < total; d = addDays(d, 1)) {
    if (!days.contains(d.weekday)) continue;
    final session = p.sessionAt(out.length);
    out.add(PlannedSession(
      id: '${programSessionPrefix(p.id)}$tag-${out.length}',
      day: d,
      sport: Sport.gym,
      title: session.name,
      templateId: templateIds[session.name],
      minutes: session.minutes,
      intensity: intensityOf != null
          ? intensityOf(session)
          : (session.minutes >= 60 ? Intensity.hard : Intensity.normal),
    ));
  }
  return out;
}

/// Working kg for [reps] reps at 2 reps in reserve, from the best e1RM of
/// the last five sessions of [exercise] in [history]:
/// e1rm / (1 + (reps + 2) / 30), rounded to the plate. Aliases merge when
/// a [catalog] is given. Null without weighted history.
double? startKg(String exercise, List<CompletedWorkout> history, int reps,
    {ExerciseCatalog? catalog}) {
  final series = liftSeries(history, exercise, catalog);
  if (series.isEmpty) return null;
  final recent = series.sublist(series.length > 5 ? series.length - 5 : 0);
  final best = recent.map((p) => p.e1rm).reduce((a, b) => a > b ? a : b);
  final kg = workingKg(best, reps);
  return kg > 0 ? kg : null;
}

/// Working kg for [reps] reps at 2 reps in reserve from an e1RM, rounded to
/// the plate.
double workingKg(double e1rm, int reps) =>
    roundToPlate(e1rm / (1 + (reps + 2) / 30));

/// The exercises of [p] that get a start weight / progress row: barbell
/// compounds (catalog), each once, in program order, at most [max].
List<ProgramExercise> mainLifts(TrainingProgram p, ExerciseCatalog? catalog,
    {int max = 4}) {
  final seen = <String>{};
  final out = <ProgramExercise>[];
  for (final s in p.sessions) {
    for (final e in s.exercises) {
      final info = catalog?.byName(e.exercise);
      if (info == null || !info.compound) continue;
      if (info.equipment != Equipment.barbell) continue;
      if (!seen.add(info.id)) continue;
      out.add(e);
      if (out.length >= max) return out;
    }
  }
  return out;
}

/// True for lower-body lifts (they progress 5 kg, upper lifts 2.5 kg).
bool isLowerLift(String exercise, ExerciseCatalog? catalog) {
  final g = catalog?.byName(exercise)?.group;
  return g == MuscleGroup.legs || g == MuscleGroup.glutes;
}
