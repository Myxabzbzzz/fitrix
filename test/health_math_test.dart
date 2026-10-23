import 'package:flutter_test/flutter_test.dart';

import 'package:fitrix/core/time/day_key.dart';
import 'package:fitrix/features/checkin/data/checkin_models.dart';
import 'package:fitrix/features/health/data/health_source.dart';
import 'package:fitrix/features/health/domain/health_math.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';

SleepSegment seg(DateTime a, DateTime b,
        {bool asleep = true, String src = 'w'}) =>
    SleepSegment(from: a, to: b, asleep: asleep, sourceName: src);

CompletedWorkout own(Sport s, DateTime a, DateTime b) => CompletedWorkout(
    templateId: 't',
    name: 'n',
    sport: s,
    startedAt: a,
    finishedAt: b,
    exercises: const []);

HealthWorkoutRecord rec(DateTime a, DateTime b) => HealthWorkoutRecord(
    uuid: 'u',
    activity: 'RUNNING',
    from: a,
    to: b,
    sourceId: 's',
    sourceName: 'n');

void main() {
  final today = DateTime(2026, 10, 23);
  DateTime t(int d, int h, [int m = 0]) => DateTime(2026, 10, 23 + d, h, m);

  group('sleepLastNight', () {
    test('overnight', () {
      expect(sleepLastNight([seg(t(-1, 23, 30), t(0, 7, 10))], today),
          const Duration(hours: 7, minutes: 40));
    });
    test('nap yesterday afternoon is outside the window', () {
      expect(sleepLastNight([seg(t(-1, 14), t(-1, 15))], today), isNull);
    });
    test('two segments with a gap', () {
      expect(
          sleepLastNight([
            seg(t(-1, 23), t(0, 3)),
            seg(t(0, 3, 20), t(0, 7)),
          ], today),
          const Duration(hours: 7, minutes: 40));
    });
    test('in bed not added', () {
      expect(
          sleepLastNight([
            seg(t(-1, 22, 30), t(-1, 23), asleep: false),
            seg(t(-1, 23), t(0, 7)),
          ], today),
          const Duration(hours: 8));
    });
    test('overlapping sources counted once', () {
      expect(
          sleepLastNight([
            seg(t(-1, 23), t(0, 6), src: 'a'),
            seg(t(-1, 23, 30), t(0, 7), src: 'b'),
          ], today),
          const Duration(hours: 8));
    });
    test('empty is null', () => expect(sleepLastNight([], today), isNull));
  });

  group('baseline', () {
    Map<String, double> days(int n, {double v = 50}) => {
          for (var i = 1; i <= n; i++) dayKey(DateTime(2026, 10, 23 - i)): v,
        };
    test('4 values -> null', () => expect(baseline(days(4), today), isNull));
    test('5 values -> mean', () {
      final m = days(5)..[dayKey(DateTime(2026, 10, 18))] = 60;
      expect(baseline(m, today), closeTo(52, 1e-9));
    });
    test('ignores today and day 29', () {
      final m = days(5);
      m[dayKey(today)] = 1000;
      m[dayKey(DateTime(2026, 10, 23 - 29))] = 1000;
      expect(baseline(m, today), 50);
    });
    test('day 28 counts', () {
      final m = days(4);
      m[dayKey(DateTime(2026, 10, 23 - 28))] = 50;
      expect(baseline(m, today), 50);
    });
  });

  test('restingHrDelta', () {
    expect(restingHrDelta(59, 54), -6);
    expect(restingHrDelta(62, 54), -10);
    expect(restingHrDelta(58, 54), 0);
  });

  test('hrvDelta', () {
    expect(hrvDelta(43, 48), -6);
    expect(hrvDelta(38, 48), -10);
    expect(hrvDelta(53, 48), 3);
    expect(hrvDelta(45, 48), 0);
  });

  group('readiness with health', () {
    final c = CheckIn(
      at: DateTime(2026, 10, 23, 8),
      sleep: const Duration(hours: 7),
      quality: SleepQuality.ok,
      soreness: Soreness.none,
      sore: const {},
      energy: Level3.ok,
      stress: Level3.ok,
    );
    test('resting HR factor', () {
      final base = readiness(c, hardDaysLast7: 0);
      final r = readiness(c,
          hardDaysLast7: 0,
          health: const HealthSignals(restingHr: 62, restingHrBaseline: 54));
      expect(r.score, base.score - 10);
      expect(r.factors.where((f) => f.factor == 'restingHr').single.delta, -10);
    });
    test('hrv factor', () {
      final r = readiness(c,
          hardDaysLast7: 0,
          health: const HealthSignals(hrv: 43, hrvBaseline: 48));
      expect(r.factors.where((f) => f.factor == 'hrv').single.delta, -6);
    });
    test('no factor without baseline', () {
      final base = readiness(c, hardDaysLast7: 0);
      final r = readiness(c,
          hardDaysLast7: 0,
          health: const HealthSignals(restingHr: 62, hrv: 30));
      expect(r.score, base.score);
      expect(r.factors.length, base.factors.length);
    });
  });

  test('sportForActivity', () {
    expect(sportForActivity('RUNNING'), Sport.running);
    expect(sportForActivity('BIKING'), Sport.cycling);
    expect(sportForActivity('BIKING_STATIONARY'), Sport.cycling);
    expect(sportForActivity('SOCCER'), Sport.football);
    for (final a in [
      'DOWNHILL_SKIING',
      'CROSS_COUNTRY_SKIING',
      'SNOWBOARDING',
      'SKATING'
    ]) {
      expect(sportForActivity(a), Sport.winterSports, reason: a);
    }
    for (final a in [
      'TRADITIONAL_STRENGTH_TRAINING',
      'FUNCTIONAL_STRENGTH_TRAINING',
      'WEIGHTLIFTING'
    ]) {
      expect(sportForActivity(a), Sport.gym, reason: a);
    }
    expect(sportForActivity('YOGA'), Sport.fitness);
    expect(sportForActivity('nonsense'), Sport.fitness);
  });

  test('importedWorkoutId', () {
    final a = importedWorkoutId(HealthPlatform.appleHealth, 'x');
    expect(a, importedWorkoutId(HealthPlatform.appleHealth, 'x'));
    expect(a, isNot(importedWorkoutId(HealthPlatform.healthConnect, 'x')));
    expect(a, isNot(importedWorkoutId(HealthPlatform.appleHealth, 'y')));
  });

  group('overlapsSameSport', () {
    final r = rec(t(0, 18), t(0, 18, 40));
    test('same sport mostly overlapping', () {
      expect(
          overlapsSameSport(r, Sport.running,
              [own(Sport.running, t(0, 18, 5), t(0, 18, 45))]),
          isTrue);
    });
    test('different sport', () {
      expect(
          overlapsSameSport(
              r, Sport.running, [own(Sport.gym, t(0, 18, 5), t(0, 18, 45))]),
          isFalse);
    });
    test('10 of 40 minutes', () {
      expect(
          overlapsSameSport(r, Sport.running,
              [own(Sport.running, t(0, 18, 30), t(0, 19, 30))]),
          isFalse);
    });
  });
}
