import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitrix/core/constants/app_constants.dart';
import 'package:fitrix/core/router/app_router.dart';
import 'package:fitrix/core/session/app_session.dart';
import 'package:fitrix/core/session/session_providers.dart';
import 'package:fitrix/core/time/today_provider.dart';
import 'package:fitrix/features/chat/data/models/assistant_topic.dart';
import 'package:fitrix/features/chat/presentation/screens/felix_chat_screen.dart';
import 'package:fitrix/features/checkin/data/checkin_models.dart';
import 'package:fitrix/features/checkin/data/checkin_store.dart';
import 'package:fitrix/features/exercises/data/exercise_catalog.dart';
import 'package:fitrix/features/nutrition/data/food_catalog.dart';
import 'package:fitrix/features/nutrition/data/food_log_store.dart';
import 'package:fitrix/features/nutrition/presentation/providers/nutrition_provider.dart';
import 'package:fitrix/features/plan/data/week_plan.dart';
import 'package:fitrix/features/plan/data/week_plan_store.dart';
import 'package:fitrix/features/profile/data/performance_store.dart';
import 'package:fitrix/features/programs/data/program_store.dart';
import 'package:fitrix/features/programs/domain/program_catalog.dart';
import 'package:fitrix/features/progress/data/body_weight_store.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/main.dart';

/// Wednesday 14 Oct 2026, late afternoon (the dinner idea shows after 15:00).
final _now = DateTime(2026, 10, 14, 16);

const _profile = <String, Object>{
  AppConstants.keyOnboardingComplete: true,
  'user_name': 'Alex',
  'user_age': '26',
  'user_weight': '78.4',
  'user_height': '181',
  performanceProfileKey: '{"sex":"male"}',
};

CompletedWorkout _bench(DateTime day, double kg) => CompletedWorkout(
      id: 'b${day.toIso8601String()}',
      templateId: 'gym-chest-biceps',
      name: 'Chest',
      sport: Sport.gym,
      startedAt: DateTime(day.year, day.month, day.day, 18),
      finishedAt: DateTime(day.year, day.month, day.day, 19),
      sessionRpe: 7,
      exercises: [
        Exercise(name: 'Bench press', sets: [
          WorkoutSet(
              previousKg: 0, previousReps: 8, kg: kg, reps: 8, done: true),
        ]),
      ],
    );

/// A bench session every second day for six weeks, weight going up.
List<CompletedWorkout> _sixWeeks() => [
      for (var i = 20; i >= 0; i--)
        _bench(DateTime(2026, 10, 14 - i * 2), 100 - i.toDouble()),
    ];

PlannedSession _plan(String id, int day, Sport sport, String title) =>
    PlannedSession(
      id: id,
      day: DateTime(2026, 10, day),
      sport: sport,
      title: title,
      templateId: sport == Sport.gym ? 'gym-legs' : null,
      minutes: 70,
      intensity: Intensity.hard,
    );

/// The real app (real route table, local-only, signed out) over [values].
Future<(ProviderContainer, GoRouter)> _app(
    WidgetTester tester, Map<String, Object> values) async {
  // Tall enough that every card is built without scrolling.
  tester.view.physicalSize = const Size(390, 2400) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({..._profile, ...values});
  final prefs = await SharedPreferences.getInstance();
  final session = AppSession(prefs);
  final container = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    appSessionProvider.overrideWithValue(session),
    clockProvider.overrideWithValue(() => _now),
  ]);
  addTearDown(container.dispose);
  // Asset loading needs real async time.
  await tester.runAsync(() async {
    await container.read(exerciseCatalogProvider.future);
    await container.read(foodCatalogProvider.future);
    await container.read(programCatalogProvider.future);
  });
  final router = AppRouter.create(session);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: FitrixApp(router: router),
  ));
  await tester.pump();
  return (container, router);
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _open(
    WidgetTester tester, GoRouter router, String location) async {
  router.go(location);
  await _settle(tester);
}

/// The top page's location, pushed pages included.
String _location(GoRouter router) => router.state.uri.path;

/// Taps the visible "Ask Felix" and checks Felix opened on [topic] with a
/// draft that passes [draft], unsent.
Future<void> _askFelix(
  WidgetTester tester,
  ProviderContainer container,
  GoRouter router, {
  required AssistantTopic topic,
  required bool Function(String) draft,
  String label = 'Ask Felix',
}) async {
  final button = find.text(label).hitTestable();
  expect(button, findsOneWidget);
  await tester.tap(button);
  await _settle(tester);
  expect(_location(router), AppRouter.felix);
  expect(container.read(selectedAssistantTopicProvider), topic);
  final field = find.byWidgetPredicate((w) =>
      w is TextField && w.controller != null && draft(w.controller!.text));
  expect(field, findsOneWidget);
  expect(tester.takeException(), isNull);
}

AssistantTopic get _gym =>
    AssistantTopic.all.firstWhere((t) => t.sport == Sport.gym);

Future<void> _leave(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  group('wave-1 taps', () {
    testWidgets('Home: the Today card opens the week plan', (tester) async {
      final (_, router) = await _app(tester, {});
      final card = find.byKey(const Key('home-today-card'));
      expect(card, findsOneWidget);
      await tester.tap(card);
      await _settle(tester);
      expect(_location(router), AppRouter.weekPlan);
      await _leave(tester);
    });

    testWidgets('Program progress: the top-right button opens the program',
        (tester) async {
      final (_, router) = await _app(tester, {
        ProgramStore.key: jsonEncode(ActiveProgram(
            programId: 'upper-lower-4',
            start: DateTime(2026, 10, 12),
            weekdays: const [1, 2, 4, 5],
            sessionTemplateIds: const {}).toJson()),
      });
      await _open(tester, router, AppRouter.programsActive);
      await tester.tap(find.byKey(const Key('program-open-detail')));
      await _settle(tester);
      expect(_location(router), AppRouter.program('upper-lower-4'));
      await _leave(tester);
    });

    testWidgets('Nutrition: a low micronutrient chip opens Micronutrients',
        (tester) async {
      final (c, router) = await _app(tester, {});
      final foods = c.read(foodCatalogProvider).requireValue;
      await c.read(foodLogProvider.notifier).add(FoodEntry.fromFood(
          foods.byId('chicken_breast')!,
          grams: 150,
          slot: MealSlot.lunch,
          at: DateTime(2026, 10, 14, 13),
          id: 'e1'));
      await _open(tester, router, AppRouter.nutrition);
      final chip = find.byKey(const ValueKey('low-micro-chip')).first;
      expect(chip, findsOneWidget);
      await tester.tap(chip);
      await _settle(tester);
      expect(_location(router), AppRouter.nutritionMicros);
      await _leave(tester);
    });
  });

  group('Ask Felix', () {
    testWidgets('Gym coach card asks the gym trainer about the first workout',
        (tester) async {
      final (c, router) = await _app(tester, {});
      await _open(tester, router, AppRouter.sportWorkouts(Sport.gym));
      await _askFelix(tester, c, router,
          label: 'Ask',
          topic: _gym,
          draft: (t) =>
              t ==
              "I'm about to do my first Gym workout. "
                  'What should I focus on?');
      await _leave(tester);
    });

    testWidgets('Recovery asks how hard to train with today\'s numbers',
        (tester) async {
      final (c, router) = await _app(tester, {
        CheckInStore.key: jsonEncode([
          CheckIn(
            at: DateTime(2026, 10, 14, 7, 40),
            sleep: const Duration(hours: 7, minutes: 30),
            quality: SleepQuality.good,
            soreness: Soreness.medium,
            sore: {BodyArea.legs},
            energy: Level3.ok,
            stress: Level3.ok,
          ).toJson(),
        ]),
      });
      await _open(tester, router, AppRouter.recovery);
      await _askFelix(tester, c, router,
          topic: _gym,
          draft: (t) =>
              t ==
              'My readiness today is 76% (Ready to train). Sleep 7 h 30 m, '
                  'soreness: medium (legs). How hard should I train today?');
      await _leave(tester);
    });

    testWidgets('Week plan Felix card asks about the two hard days',
        (tester) async {
      final (c, router) = await _app(tester, {
        WeekPlanStore.key: jsonEncode({
          'sessions': [
            _plan('f', 17, Sport.football, 'Football 7×7').toJson(),
            _plan('l', 18, Sport.gym, 'Legs').toJson(),
          ],
          'dismissed': <String>[],
        }),
      });
      await _open(tester, router, AppRouter.weekPlan);
      expect(find.byKey(const Key('plan-felix-card')), findsOneWidget);
      await _askFelix(tester, c, router,
          topic: _gym,
          draft: (t) =>
              t ==
              'Football 7×7 on Saturday and Legs on Sunday are both hard. '
                  'How should I arrange my week?');
      await _leave(tester);
    });

    testWidgets('Progress insight asks the app assistant about the load',
        (tester) async {
      final (c, router) = await _app(tester, {
        AppConstants.keyWorkoutHistory:
            jsonEncode([for (final w in _sixWeeks()) w.toJson()]),
      });
      await _open(tester, router, AppRouter.progress);
      await _askFelix(tester, c, router,
          topic: AssistantTopic.app,
          draft: (t) =>
              t.startsWith('My training load this week is ') &&
              t.contains(' AU and my load balance is ') &&
              t.endsWith('What should I do next week?'));
      await _leave(tester);
    });

    testWidgets('Lift detail asks the gym trainer about that lift',
        (tester) async {
      final (c, router) = await _app(tester, {
        AppConstants.keyWorkoutHistory:
            jsonEncode([for (final w in _sixWeeks()) w.toJson()]),
      });
      await _open(tester, router, AppRouter.progressLift('Bench press'));
      await _askFelix(tester, c, router,
          topic: _gym,
          draft: (t) =>
              t.startsWith('My Bench press e1RM is ') &&
              t.endsWith('kg. How do I keep it climbing?'));
      await _leave(tester);
    });

    testWidgets('Body weight off-track card asks about eating', (tester) async {
      final (c, router) = await _app(tester, {
        'nutrition_settings_v1': jsonEncode({'goal': 'leanBulk'}),
        BodyWeightStore.key: jsonEncode([
          for (var i = 8; i >= 0; i--)
            {
              'at': DateTime(2026, 10, 14 - i * 7).toIso8601String(),
              'kg': 80 - 0.5 * (8 - i),
            },
        ]),
      });
      await _open(tester, router, AppRouter.progressWeight);
      await _askFelix(tester, c, router,
          topic: AssistantTopic.app,
          draft: (t) =>
              t.startsWith('My weight is 76') &&
              t.contains('a week. My goal: lean bulk') &&
              t.endsWith('How should I change what I eat?'));
      await _leave(tester);
    });

    testWidgets('Nutrition dinner idea asks what to eat for dinner',
        (tester) async {
      final (c, router) = await _app(tester, {});
      await _open(tester, router, AppRouter.nutrition);
      expect(find.byKey(const ValueKey('dinner-idea')), findsOneWidget);
      await _askFelix(tester, c, router,
          topic: AssistantTopic.app,
          draft: (t) =>
              t.startsWith('I have ') &&
              t.contains(' kcal and ') &&
              t.endsWith(' g of protein left today. '
                  'What should I eat for dinner?'));
      await _leave(tester);
    });

    testWidgets('Add food "Can\'t find it" drafts in the app language',
        (tester) async {
      final (c, router) = await _app(tester, {AppConstants.keyLanguage: 'ru'});
      await _open(tester, router, AppRouter.addFood(MealSlot.dinner));
      // A search with no results brings the tile up.
      await tester.enterText(find.byType(TextField).hitTestable(), 'qqq');
      await tester.pump();
      final tile = find.byKey(const ValueKey('cant-find'));
      await tester.ensureVisible(tile);
      await tester.tap(tile);
      await _settle(tester);
      expect(_location(router), AppRouter.felix);
      expect(c.read(selectedAssistantTopicProvider), AssistantTopic.app);
      expect(
          find.byWidgetPredicate((w) =>
              w is TextField &&
              w.controller?.text == 'Оцени калорийность блюда: '),
          findsOneWidget);
      await _leave(tester);
    });
  });
}
