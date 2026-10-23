import 'package:fitrix/core/time/day_key.dart';
import 'package:fitrix/features/checkin/data/checkin_models.dart';
import 'package:fitrix/features/chat/data/models/assistant_topic.dart';
import 'package:fitrix/features/football/data/match_log.dart';
import 'package:fitrix/features/health/data/health_import_store.dart';
import 'package:fitrix/features/health/data/health_source.dart';
import 'package:fitrix/features/health/domain/health_math.dart';
import 'package:fitrix/features/nutrition/data/food_log_store.dart';
import 'package:fitrix/features/nutrition/data/nutrition_targets.dart';
import 'package:fitrix/features/plan/data/week_plan.dart';
import 'package:fitrix/features/progress/data/body_weight_store.dart';
import 'package:fitrix/features/progress/domain/progress_math.dart';
import 'package:fitrix/features/running/data/run_track.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/features/workouts/domain/training_math.dart';

/// What Felix knows about the user's day for one chat topic. Every field
/// except [today] is null when it is unknown or not relevant for the topic;
/// [toJson] is the `context` object of the chat request.
class FelixSnapshot {
  final DateTime today;
  final TodayKind? todayKind;
  final PlannedSession? todaySession;
  final PlannedSession? next;
  final Readiness? readiness;
  final double? sleepHours;
  final CompletedWorkout? lastWorkout;

  /// Run or football details of [lastWorkout], when it has them.
  final RunDetails? lastRun;
  final MatchLog? lastMatch;

  /// Apple Health / Health Connect details of [lastWorkout], when imported.
  final HealthImport? lastImport;

  /// Health values; only given to the recovery topic (also without a
  /// check-in: then `readiness` holds only them).
  final HealthSignals? health;
  final int? load7;
  final double? acwr;
  final AcwrBand? band;
  final int? hardDays7;
  final ({int kcal, double protein, double carbs, double fat})? eaten;
  final int? waterMl;
  final Targets? targets;
  final double? weightKg;
  final double? weightChange8w;

  const FelixSnapshot({
    required this.today,
    this.todayKind,
    this.todaySession,
    this.next,
    this.readiness,
    this.sleepHours,
    this.lastWorkout,
    this.lastRun,
    this.lastMatch,
    this.lastImport,
    this.health,
    this.load7,
    this.acwr,
    this.band,
    this.hardDays7,
    this.eaten,
    this.waterMl,
    this.targets,
    this.weightKg,
    this.weightChange8w,
  });

  static const _weekdays = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];

  static double _round1(double v) => (v * 10).round() / 10;

  /// `distanceKm` and `paceSecPerKm` of a run, within what the backend takes.
  static Map<String, Object> _runJson(RunDetails run) {
    final km = run.meters / 1000;
    final pace = km <= 0 ? 0 : (run.moving.inMilliseconds / 1000 / km).round();
    return {
      if (run.meters > 0 && km <= 500) 'distanceKm': (km * 100).round() / 100,
      if (run.meters >= 50 && pace >= 120 && pace <= 1800) 'paceSecPerKm': pace,
    };
  }

  /// Pace of [meters] covered in [moving], same limits as [_runJson].
  static Map<String, Object> _importDistanceJson(double meters, Duration d) =>
      _runJson(RunDetails(
          startedAt: DateTime(2000),
          moving: d,
          elapsed: d,
          pauses: 0,
          meters: meters,
          splits: const [],
          route: const []));

  static Map<String, Object> _healthJson(HealthSignals h) {
    final rhr = h.restingHr;
    final rhrBase = h.restingHrBaseline;
    final hrv = h.hrv;
    final hrvBase = h.hrvBaseline;
    final hasKind = h.hrvKind != null;
    final steps = h.stepsToday;
    final avg = h.steps7dAvg;
    return {
      if (rhr != null && rhr >= 25 && rhr <= 220) 'restingHr': rhr.round(),
      if (rhrBase != null && rhrBase >= 25 && rhrBase <= 220)
        'restingHrBaseline': _round1(rhrBase),
      if (hasKind && hrv != null && hrv >= 1 && hrv <= 300) 'hrv': hrv.round(),
      if (hasKind && hrvBase != null && hrvBase >= 1 && hrvBase <= 300)
        'hrvBaseline': _round1(hrvBase),
      if (hasKind && (hrv != null || hrvBase != null))
        'hrvKind': h.hrvKind == HrvKind.sdnn ? 'sdnn' : 'rmssd',
      if (steps != null && steps >= 0 && steps <= 100000) 'stepsToday': steps,
      if (avg != null && avg >= 0 && avg <= 100000) 'steps7dAvg': avg,
    };
  }

  static Map<String, Object>? _matchJson(MatchLog m) {
    if (m.minutes < 1) return null;
    final isMatch = m.type == FootballType.match;
    final rpe = m.rpe;
    final format = m.format;
    final goalsFor = m.goalsFor;
    final goalsAgainst = m.goalsAgainst;
    return {
      'type': m.type.name,
      if (isMatch && format != null && footballFormats.contains(format))
        'format': format,
      'minutes': m.minutes.clamp(1, 200),
      if (rpe != null && rpe >= 1 && rpe <= 10) 'rpe': rpe,
      if (isMatch && goalsFor != null && goalsFor >= 0 && goalsFor <= 50)
        'goalsFor': goalsFor,
      if (isMatch &&
          goalsAgainst != null &&
          goalsAgainst >= 0 &&
          goalsAgainst <= 50)
        'goalsAgainst': goalsAgainst,
    };
  }

  Map<String, Object> toJson() {
    final session = todaySession;
    final lastWorkout = this.lastWorkout;
    final lastRun = this.lastRun;
    final lastMatch = this.lastMatch;
    final lastImport = this.lastImport;
    final health = this.health;
    final match = lastMatch == null ? null : _matchJson(lastMatch);
    final next = this.next;
    final readiness = this.readiness;
    final eaten = this.eaten;
    final targets = this.targets;
    final weightKg = this.weightKg;
    final load7 = this.load7;
    final sleepHours = this.sleepHours;
    final acwr = this.acwr;
    final band = this.band;
    final hardDays7 = this.hardDays7;
    final waterMl = this.waterMl;
    final weightChange8w = this.weightChange8w;
    final todayKind = this.todayKind;
    // Without a check-in the health values still go, without a score.
    final healthOnly = readiness == null && health != null
        ? _healthJson(health)
        : const <String, Object>{};
    return {
      'date': dayKey(today),
      'weekday': _weekdays[today.weekday - 1],
      if (todayKind != null)
        'today': {
          'status': todayKind.name,
          if (session != null) ...{
            'sport': session.sport.name,
            'title': session.title,
            'minutes': session.minutes,
          },
        },
      if (next != null)
        'next': {
          'date': dayKey(next.day),
          'sport': next.sport.name,
          'title': next.title,
        },
      if (readiness != null)
        'readiness': {
          'score': readiness.score,
          'label': readiness.label.name,
          if (sleepHours != null) 'sleepHours': _round1(sleepHours),
          if (health != null) ..._healthJson(health),
          if (readiness.factors.isNotEmpty)
            'factors': [
              for (final f in readiness.factors)
                {'factor': f.factor, 'delta': f.delta},
            ],
        }
      else if (healthOnly.isNotEmpty)
        'readiness': healthOnly,
      if (lastWorkout != null)
        'lastWorkout': {
          'date': dayKey(lastWorkout.finishedAt),
          'sport': lastWorkout.sport.name,
          'name': lastWorkout.name,
          if (lastWorkout.duration.inMinutes > 0)
            'minutes': lastWorkout.duration.inMinutes,
          if (lastRun != null)
            ..._runJson(lastRun)
          else if (lastImport?.meters != null)
            ..._importDistanceJson(lastImport!.meters!, lastWorkout.duration),
          if (lastImport != null) ...{
            if (lastImport.source.isNotEmpty && lastImport.source.length <= 40)
              'source': lastImport.source,
            if (lastImport.avgHr != null &&
                lastImport.avgHr! >= 30 &&
                lastImport.avgHr! <= 230)
              'avgHr': lastImport.avgHr!,
          },
          if (match != null) 'match': match,
        },
      if (load7 != null)
        'load': {
          'last7': load7,
          if (acwr != null) 'acwr': (acwr * 100).round() / 100,
          if (band != null) 'band': band.name,
          if (hardDays7 != null) 'hardDays7': hardDays7,
        },
      if (eaten != null || waterMl != null)
        'food': {
          'kcal': eaten?.kcal ?? 0,
          'protein': _round1(eaten?.protein ?? 0),
          'carbs': _round1(eaten?.carbs ?? 0),
          'fat': _round1(eaten?.fat ?? 0),
          if (waterMl != null) 'waterMl': waterMl,
        },
      if (targets != null)
        'targets': {
          'kcal': targets.kcal,
          'protein': targets.protein,
          'carbs': targets.carbs,
          'fat': targets.fat,
          'waterMl': targets.waterMl,
        },
      if (weightKg != null)
        'weight': {
          'kg': _round1(weightKg),
          if (weightChange8w != null) 'change8wKg': _round1(weightChange8w),
        },
    };
  }
}

/// Builds what Felix gets to see for [topic] on [today] from the user's
/// data; see the topic table in the Felix hub plan for who sees what.
FelixSnapshot buildFelixSnapshot({
  required AssistantTopic topic,
  required DateTime today,
  List<PlannedSession> plan = const [],
  List<CompletedWorkout> history = const [],
  Readiness? readiness,
  double? sleepHours,
  int hardDays7 = 0,
  List<FoodEntry> entries = const [],
  int waterMl = 0,
  Targets? targets,
  List<WeighIn> weighIns = const [],
  Map<String, RunDetails> runs = const {},
  Map<String, MatchLog> matches = const {},
  HealthSignals? health,
  Map<String, HealthImport> imports = const {},
}) {
  final day = dayOf(today);
  final sport = topic.sport;
  final isNutrition = topic == AssistantTopic.nutrition;
  final isRecovery = topic == AssistantTopic.recovery;

  final todayPlan = todayPlanOf(plan, history, day);
  final next = isNutrition
      ? null
      : nextSessionAfter(plan, day,
          where: sport == null ? null : (s) => s.sport == sport);

  final ofTopic = sport == null
      ? history
      : [
          for (final w in history)
            if (w.sport == sport) w
        ];

  CompletedWorkout? lastWorkout;
  if (!isNutrition) {
    for (final w in ofTopic) {
      if (lastWorkout == null || w.finishedAt.isAfter(lastWorkout.finishedAt)) {
        lastWorkout = w;
      }
    }
  }

  int? load7;
  LoadSummary? summary;
  if (!isNutrition && ofTopic.isNotEmpty) {
    final days = dailyLoads(ofTopic);
    summary = loadSummary(days, day);
    load7 = 0;
    for (final d in days) {
      final ago = daysBetween(d.day, day);
      if (ago >= 0 && ago < 7) load7 = load7! + d.load;
    }
  }

  ({int kcal, double protein, double carbs, double fat})? eaten;
  if (isNutrition && entries.isNotEmpty) {
    eaten = (
      kcal: entries.fold(0, (s, e) => s + e.kcal),
      protein: entries.fold(0.0, (s, e) => s + e.protein),
      carbs: entries.fold(0.0, (s, e) => s + e.carbs),
      fat: entries.fold(0.0, (s, e) => s + e.fat),
    );
  }

  double? weightKg;
  double? weightChange;
  if (isNutrition && weighIns.isNotEmpty) {
    final sorted = [...weighIns]..sort((a, b) => a.at.compareTo(b.at));
    final latest = sorted.last;
    weightKg = latest.kg;
    final from = sorted.firstWhere(
      (w) => daysBetween(w.at, day) <= 56,
      orElse: () => latest,
    );
    if (!identical(from, latest)) weightChange = latest.kg - from.kg;
  }

  return FelixSnapshot(
    today: day,
    todayKind: todayPlan.kind,
    todaySession: todayPlan.session,
    next: next,
    readiness: isNutrition || readiness == null
        ? null
        : isRecovery
            ? readiness
            : Readiness(readiness.score, const [], readiness.label),
    sleepHours: isRecovery ? sleepHours : null,
    lastWorkout: lastWorkout,
    lastRun: lastWorkout == null ? null : runs[lastWorkout.id],
    lastMatch: lastWorkout == null ? null : matches[lastWorkout.id],
    lastImport: lastWorkout == null ? null : imports[lastWorkout.id],
    health: isRecovery ? health : null,
    load7: load7,
    acwr: isRecovery ? summary?.acwr : null,
    band: summary?.band,
    hardDays7: isRecovery && load7 != null ? hardDays7 : null,
    eaten: eaten,
    waterMl: isNutrition && waterMl > 0 ? waterMl : null,
    targets: isNutrition ? targets : null,
    weightKg: weightKg,
    weightChange8w: weightChange,
  );
}
