import 'package:flutter_test/flutter_test.dart';

import 'package:fitrix/features/checkin/data/checkin_models.dart';
import 'package:fitrix/features/chat/data/felix_snapshot.dart';
import 'package:fitrix/features/chat/data/models/assistant_topic.dart';
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
}
