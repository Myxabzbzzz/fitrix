import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:fitrix/features/checkin/data/checkin_models.dart';
import 'package:fitrix/features/chat/data/felix_snapshot.dart';
import 'package:fitrix/features/chat/data/models/assistant_topic.dart';
import 'package:fitrix/features/football/data/match_log.dart';
import 'package:fitrix/features/health/data/health_import_store.dart';
import 'package:fitrix/features/health/data/health_source.dart';
import 'package:fitrix/features/health/domain/health_math.dart';
import 'package:fitrix/features/running/data/ski_math.dart';
import 'package:fitrix/features/running/data/run_track.dart';
import 'package:fitrix/features/nutrition/data/food_catalog.dart';
import 'package:fitrix/features/nutrition/data/food_log_store.dart';
import 'package:fitrix/features/nutrition/data/nutrition_targets.dart';
import 'package:fitrix/features/plan/data/week_plan.dart';
import 'package:fitrix/features/progress/data/body_weight_store.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';

void main() {
  final today = DateTime(2026, 10, 20); // a Tuesday

  CompletedWorkout workout(Sport sport, DateTime day, String name,
          {int minutes = 60, int rpe = 6}) =>
      CompletedWorkout(
        templateId: 't',
        name: name,
        sport: sport,
        startedAt: day,
        finishedAt: day.add(Duration(minutes: minutes)),
        exercises: const [],
        sessionRpe: rpe,
      );

  Map<String, Object> json(
    AssistantTopic topic, {
    List<PlannedSession> plan = const [],
    List<CompletedWorkout> history = const [],
    Readiness? readiness,
    double? sleepHours,
    List<FoodEntry> entries = const [],
    Targets? targets,
    List<WeighIn> weighIns = const [],
    Map<String, RunDetails> runs = const {},
    Map<String, MatchLog> matches = const {},
    HealthSignals? health,
    Map<String, HealthImport> imports = const {},
  }) =>
      buildFelixSnapshot(
        topic: topic,
        today: today,
        plan: plan,
        history: history,
        readiness: readiness,
        sleepHours: sleepHours,
        entries: entries,
        targets: targets,
        weighIns: weighIns,
        runs: runs,
        matches: matches,
        health: health,
        imports: imports,
      ).toJson();

  test('empty inputs give only the date, weekday and an unplanned today', () {
    for (final topic in AssistantTopic.all) {
      expect(
          json(topic),
          {
            'date': '2026-10-20',
            'weekday': 'tue',
            'today': {'status': 'unplanned'},
          },
          reason: topic.id);
    }
  });

  test('recovery sees the full check-in', () {
    final r = Readiness(
        78,
        [
          for (final f in ['sleep', 'soreness', 'energy', 'stress', 'load'])
            (factor: f, delta: 0),
        ],
        ReadinessLabel.ready);
    final j = json(AssistantTopic.recovery, readiness: r, sleepHours: 7.5);
    final readiness = j['readiness'] as Map;
    expect(readiness['score'], 78);
    expect(readiness['label'], 'ready');
    expect(readiness['sleepHours'], 7.5);
    expect(readiness['factors'], hasLength(5));

    final app = json(AssistantTopic.app, readiness: r, sleepHours: 7.5);
    expect(app['readiness'], {'score': 78, 'label': 'ready'});
  });

  test('last workout and load follow the topic', () {
    final history = [
      workout(Sport.gym, DateTime(2026, 10, 16, 18), 'Chest and Biceps',
          minutes: 86),
      workout(Sport.football, DateTime(2026, 10, 18, 18), 'Match'),
    ];
    final gym = json(AssistantTopic.gym, history: history);
    expect((gym['lastWorkout'] as Map)['name'], 'Chest and Biceps');
    expect((gym['lastWorkout'] as Map)['minutes'], 86);
    expect((gym['load'] as Map)['last7'], 6 * 86);

    final app = json(AssistantTopic.app, history: history);
    expect((app['lastWorkout'] as Map)['sport'], 'football');
    expect((app['load'] as Map)['last7'], 6 * 86 + 6 * 60);
    expect((app['load'] as Map).containsKey('acwr'), isFalse);

    final recovery = json(AssistantTopic.recovery, history: history);
    expect((recovery['load'] as Map).containsKey('acwr'), isTrue);
    expect((recovery['load'] as Map)['hardDays7'], 0);
  });

  test('next session is of the topic sport; today shows the open session', () {
    final plan = [
      PlannedSession(
          id: 'a',
          day: today,
          sport: Sport.running,
          title: 'Easy run',
          minutes: 40,
          intensity: Intensity.easy),
      PlannedSession(
          id: 'b',
          day: DateTime(2026, 10, 21),
          sport: Sport.running,
          title: 'Tempo',
          minutes: 45,
          intensity: Intensity.hard),
      PlannedSession(
          id: 'c',
          day: DateTime(2026, 10, 22),
          sport: Sport.gym,
          title: 'Legs',
          minutes: 60,
          intensity: Intensity.normal),
    ];
    final gym = json(AssistantTopic.gym, plan: plan);
    expect(gym['today'], {
      'status': 'session',
      'sport': 'running',
      'title': 'Easy run',
      'minutes': 40
    });
    expect(
        gym['next'], {'date': '2026-10-22', 'sport': 'gym', 'title': 'Legs'});
    expect((json(AssistantTopic.app, plan: plan)['next'] as Map)['title'],
        'Tempo');
    expect(json(AssistantTopic.nutrition, plan: plan).containsKey('next'),
        isFalse);
  });

  test('a long session title is passed on unchanged', () {
    final title = 'x' * 90;
    final plan = [
      PlannedSession(
          id: 'a',
          day: today,
          sport: Sport.gym,
          title: title,
          minutes: 60,
          intensity: Intensity.normal),
    ];
    expect(
        (json(AssistantTopic.gym, plan: plan)['today'] as Map)['title'], title);
  });

  test('nutrition sees food, targets and weight, nothing about training', () {
    final entries = [
      FoodEntry(
          id: '1',
          at: today,
          slot: MealSlot.lunch,
          name: 'Rice',
          grams: 300,
          kcal: 1523,
          protein: 66,
          carbs: 200,
          fat: 40),
    ];
    final j = json(
      AssistantTopic.nutrition,
      entries: entries,
      targets: const Targets(
          bmr: 1800,
          activity: 1.5,
          tdee: 2700,
          kcal: 3400,
          protein: 141,
          fat: 90,
          carbs: 400,
          waterMl: 3000),
      weighIns: [
        WeighIn(at: DateTime(2026, 8, 25, 8), kg: 78.9),
        WeighIn(at: DateTime(2026, 10, 17, 8), kg: 78.4),
      ],
      readiness: const Readiness(70, [], ReadinessLabel.ready),
      history: [workout(Sport.gym, DateTime(2026, 10, 16), 'Legs')],
    );
    expect((j['food'] as Map)['kcal'], 1523);
    expect((j['food'] as Map)['protein'], 66);
    expect((j['targets'] as Map)['protein'], 141);
    expect(j['weight'], {'kg': 78.4, 'change8wKg': -0.5});
    expect(j.containsKey('readiness'), isFalse);
    expect(j.containsKey('lastWorkout'), isFalse);
    expect(j.containsKey('load'), isFalse);
  });

  group('run and match details', () {
    RunDetails run(double meters, Duration moving) => RunDetails(
        startedAt: DateTime(2026, 10, 19, 7),
        moving: moving,
        elapsed: moving,
        pauses: 0,
        meters: meters,
        splits: const [],
        route: const []);

    CompletedWorkout runWorkout() =>
        workout(Sport.running, DateTime(2026, 10, 19, 7), 'Run', minutes: 30);

    test('a run adds distance and pace', () {
      final w = runWorkout();
      final j = json(AssistantTopic.running,
          history: [w],
          runs: {w.id: run(6214, const Duration(minutes: 30, seconds: 12))});
      final last = j['lastWorkout'] as Map;
      expect(last['distanceKm'], 6.21);
      expect(last['paceSecPerKm'], 292);
    });

    test('a run without details has no distance keys', () {
      final j = json(AssistantTopic.running, history: [runWorkout()]);
      final last = j['lastWorkout'] as Map;
      expect(last.containsKey('distanceKm'), isFalse);
      expect(last.containsKey('paceSecPerKm'), isFalse);
    });

    test('pace is omitted for a tiny or absurd run, distance for zero', () {
      final w = runWorkout();
      var last = json(AssistantTopic.running,
              history: [w],
              runs: {w.id: run(40, const Duration(minutes: 5))})['lastWorkout']
          as Map;
      expect(last['distanceKm'], 0.04);
      expect(last.containsKey('paceSecPerKm'), isFalse);
      last = json(AssistantTopic.running, history: [
        w
      ], runs: {
        w.id: run(5000, const Duration(minutes: 5))
      })['lastWorkout'] as Map;
      expect(last.containsKey('paceSecPerKm'), isFalse);
      last = json(AssistantTopic.running,
              history: [w],
              runs: {w.id: run(0, const Duration(minutes: 5))})['lastWorkout']
          as Map;
      expect(last.containsKey('distanceKm'), isFalse);
      expect(last.containsKey('paceSecPerKm'), isFalse);
    });

    test('a match adds its details; a training only minutes and rpe', () {
      final m = workout(Sport.football, DateTime(2026, 10, 19, 18), 'Match',
          minutes: 50);
      var j = json(AssistantTopic.football, history: [
        m
      ], matches: {
        m.id: MatchLog(
            type: FootballType.match,
            date: m.finishedAt,
            format: '7x7',
            minutes: 50,
            position: 'CM',
            rpe: 8,
            goalsFor: 3,
            goalsAgainst: 4,
            goals: 1)
      });
      expect((j['lastWorkout'] as Map)['match'], {
        'type': 'match',
        'format': '7x7',
        'minutes': 50,
        'rpe': 8,
        'goalsFor': 3,
        'goalsAgainst': 4,
      });
      j = json(AssistantTopic.app, history: [
        m
      ], matches: {
        m.id: MatchLog(
            type: FootballType.training,
            date: m.finishedAt,
            format: '7x7',
            minutes: 60,
            rpe: 5,
            goalsFor: 1)
      });
      expect((j['lastWorkout'] as Map)['match'],
          {'type': 'training', 'minutes': 60, 'rpe': 5});
    });
  });

  group('health values', () {
    const full = HealthSignals(
        restingHr: 52.4,
        restingHrBaseline: 55.04,
        hrv: 61.6,
        hrvBaseline: 58.26,
        hrvKind: HrvKind.sdnn,
        stepsToday: 4200,
        steps7dAvg: 8123);
    const ready = Readiness(
        70,
        [
          (factor: ReadinessFactorKey.restingHr, delta: 5),
          (factor: ReadinessFactorKey.hrv, delta: -3),
        ],
        ReadinessLabel.ready);

    test('recovery gets every health field and the factors', () {
      final r = json(AssistantTopic.recovery,
          readiness: ready, health: full)['readiness'] as Map;
      expect(r['restingHr'], 52);
      expect(r['restingHrBaseline'], 55.0);
      expect(r['hrv'], 62);
      expect(r['hrvKind'], 'sdnn');
      expect(r['hrvBaseline'], 58.3);
      expect(r['stepsToday'], 4200);
      expect(r['steps7dAvg'], 8123);
      expect((r['factors'] as List).map((f) => (f as Map)['factor']),
          ['restingHr', 'hrv']);
    });

    test('null values are omitted, and hrv needs its kind', () {
      final r = json(AssistantTopic.recovery,
          readiness: ready,
          health: const HealthSignals(
              hrv: 50, hrvBaseline: 50, stepsToday: 0))['readiness'] as Map;
      for (final k in [
        'restingHr',
        'restingHrBaseline',
        'hrv',
        'hrvBaseline',
        'hrvKind',
        'steps7dAvg'
      ]) {
        expect(r.containsKey(k), isFalse, reason: k);
      }
      expect(r['stepsToday'], 0);
    });

    test('recovery without a check-in still gets the health values', () {
      final r = json(AssistantTopic.recovery, health: full)['readiness'] as Map;
      expect(r, {
        'restingHr': 52,
        'restingHrBaseline': 55.0,
        'hrv': 62,
        'hrvBaseline': 58.3,
        'hrvKind': 'sdnn',
        'stepsToday': 4200,
        'steps7dAvg': 8123,
      });
    });

    test('no check-in and no health values: no readiness block', () {
      expect(
          json(AssistantTopic.recovery, health: const HealthSignals())
              .containsKey('readiness'),
          isFalse);
      expect(json(AssistantTopic.recovery).containsKey('readiness'), isFalse);
    });

    test('sport topics without a check-in get no health values', () {
      expect(json(AssistantTopic.gym, health: full).containsKey('readiness'),
          isFalse);
    });

    test('sport topics keep only score and label', () {
      final r =
          json(AssistantTopic.gym, readiness: ready, health: full)['readiness']
              as Map;
      expect(r, {'score': 70, 'label': 'ready'});
    });

    test('nutrition is unchanged', () {
      expect(json(AssistantTopic.nutrition, readiness: ready, health: full),
          json(AssistantTopic.nutrition));
    });

    test('an imported last workout carries source, avgHr and distance', () {
      final w =
          workout(Sport.running, DateTime(2026, 10, 19, 7), 'Run', minutes: 30);
      final last = json(AssistantTopic.running, history: [
        w
      ], imports: {
        w.id: const HealthImport(
            source: 'Apple Watch', healthUuid: 'u', meters: 6000, avgHr: 148)
      })['lastWorkout'] as Map;
      expect(last['source'], 'Apple Watch');
      expect(last['avgHr'], 148);
      expect(last['distanceKm'], 6.0);
      expect(last['paceSecPerKm'], 300);
    });

    test('the run doc distance wins over the import meters', () {
      final w =
          workout(Sport.running, DateTime(2026, 10, 19, 7), 'Run', minutes: 30);
      final last = json(AssistantTopic.running, history: [
        w
      ], runs: {
        w.id: RunDetails(
            startedAt: w.startedAt,
            moving: const Duration(minutes: 30),
            elapsed: const Duration(minutes: 30),
            pauses: 0,
            meters: 5000,
            splits: const [],
            route: const [])
      }, imports: {
        w.id: const HealthImport(
            source: 'Watch', healthUuid: 'u', meters: 6000, avgHr: 20)
      })['lastWorkout'] as Map;
      expect(last['distanceKm'], 5.0);
      expect(last.containsKey('avgHr'), isFalse);
    });

    group('rides and ski days', () {
      RunDetails ride(
              {double meters = 30000,
              Duration moving = const Duration(hours: 1),
              double? maxSpeed = 12.5,
              double? gain = 320.4,
              bool indoor = false,
              int? power}) =>
          RunDetails(
              startedAt: DateTime(2026, 10, 19, 7),
              moving: moving,
              elapsed: moving,
              pauses: 0,
              meters: meters,
              elevationGain: gain,
              maxSpeed: maxSpeed,
              kind: ActivityKind.ride,
              indoor: indoor,
              avgPowerW: power,
              splits: const [],
              route: const []);

      RunDetails skiDay(List<SkiDescent> d) => RunDetails(
          startedAt: DateTime(2026, 10, 19, 7),
          moving: const Duration(hours: 3),
          elapsed: const Duration(hours: 5),
          pauses: 0,
          meters: 0,
          kind: ActivityKind.ski,
          ski:
              SkiDay(descents: d, lifts: 4, liftTime: const Duration(hours: 1)),
          splits: const [],
          route: const []);

      SkiDescent descent(double meters, double vertical, double max) =>
          SkiDescent(
              start: DateTime(2026, 10, 19, 9),
              end: DateTime(2026, 10, 19, 9, 5),
              meters: meters,
              vertical: vertical,
              maxSpeed: max,
              avgSpeed: 8,
              routeFrom: 0,
              routeTo: 1);

      Map lastOf(Sport s, AssistantTopic t, RunDetails r) {
        final w = workout(s, DateTime(2026, 10, 19, 7), 'x', minutes: 60);
        return json(t, history: [w], runs: {w.id: r})['lastWorkout'] as Map;
      }

      test('a ride has speeds and climb but no pace', () {
        final last = lastOf(Sport.cycling, AssistantTopic.cycling, ride());
        expect(last['distanceKm'], 30.0);
        expect(last['avgSpeedKmh'], 30.0);
        expect(last['maxSpeedKmh'], 45.0);
        expect(last['elevationGainM'], 320);
        expect(last.containsKey('paceSecPerKm'), isFalse);
        expect(last.containsKey('indoor'), isFalse);
      });

      test('ride values outside the backend ranges are omitted', () {
        final last = lastOf(
            Sport.cycling,
            AssistantTopic.cycling,
            ride(
                meters: 600000,
                moving: const Duration(hours: 1),
                maxSpeed: 0.1,
                gain: 20000));
        expect(last.containsKey('distanceKm'), isFalse);
        expect(last.containsKey('avgSpeedKmh'), isFalse);
        expect(last.containsKey('maxSpeedKmh'), isFalse);
        expect(last.containsKey('elevationGainM'), isFalse);
        final bare = lastOf(Sport.cycling, AssistantTopic.cycling,
            ride(maxSpeed: null, gain: null));
        expect(bare.containsKey('maxSpeedKmh'), isFalse);
        expect(bare.containsKey('elevationGainM'), isFalse);
      });

      test('an indoor ride has power and distance only when set', () {
        var last = lastOf(
            Sport.cycling,
            AssistantTopic.cycling,
            ride(
                indoor: true,
                power: 180,
                meters: 25000,
                maxSpeed: null,
                gain: null));
        expect(last['indoor'], isTrue);
        expect(last['avgPowerW'], 180);
        expect(last['distanceKm'], 25.0);
        last = lastOf(Sport.cycling, AssistantTopic.cycling,
            ride(indoor: true, meters: 0, maxSpeed: null, gain: null));
        expect(last['indoor'], isTrue);
        expect(last.containsKey('avgPowerW'), isFalse);
        expect(last.containsKey('distanceKm'), isFalse);
        expect(last.containsKey('avgSpeedKmh'), isFalse);
        last = lastOf(Sport.cycling, AssistantTopic.cycling,
            ride(indoor: true, power: 5000, meters: 0));
        expect(last.containsKey('avgPowerW'), isFalse);
      });

      test('a ski day has a ski block and no pace', () {
        final last = lastOf(Sport.winterSports, AssistantTopic.winterSports,
            skiDay([descent(1500, 300.4, 20), descent(2000.6, 410, 25)]));
        expect(last['ski'], {
          'descents': 2,
          'verticalM': 710,
          'distanceKm': 3.5,
          'maxSpeedKmh': 90.0,
        });
        expect(last.containsKey('paceSecPerKm'), isFalse);
        expect(last.containsKey('distanceKm'), isFalse);
      });

      test('ski values outside the ranges are omitted', () {
        final last = lastOf(Sport.winterSports, AssistantTopic.winterSports,
            skiDay([descent(600000, 40000, 100)]));
        expect(last['ski'], {'descents': 1});
        final none =
            lastOf(Sport.winterSports, AssistantTopic.winterSports, skiDay([]));
        expect(none['ski'], {'descents': 0, 'verticalM': 0});
      });
    });

    test('stays under 8 KB with 60 cached days of history', () {
      final history = [
        for (var i = 0; i < 60; i++)
          workout(Sport.running, today.subtract(Duration(days: i)), 'Run $i')
      ];
      final j = json(AssistantTopic.recovery,
          history: history, readiness: ready, health: full, sleepHours: 7);
      expect(jsonEncode(j).length, lessThan(8192));
    });
  });
}
