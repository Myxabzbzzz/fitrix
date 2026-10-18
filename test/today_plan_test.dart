import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitrix/core/router/app_router.dart';
import 'package:fitrix/core/session/session_providers.dart';
import 'package:fitrix/core/time/today_provider.dart';
import 'package:fitrix/core/widgets/coach_card.dart';
import 'package:fitrix/core/widgets/workout_card.dart';
import 'package:fitrix/features/checkin/data/checkin_models.dart';
import 'package:fitrix/features/checkin/data/checkin_store.dart';
import 'package:fitrix/features/checkin/presentation/providers/checkin_provider.dart';
import 'package:fitrix/features/checkin/presentation/screens/recovery_screen.dart';
import 'package:fitrix/features/exercises/data/exercise_catalog.dart';
import 'package:fitrix/features/home/presentation/screens/home_screen.dart';
import 'package:fitrix/features/plan/data/week_plan.dart';
import 'package:fitrix/features/plan/presentation/providers/week_plan_provider.dart';
import 'package:fitrix/features/plan/presentation/screens/week_plan_screen.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/features/workouts/data/workout_catalog.dart';
import 'package:fitrix/features/workouts/presentation/providers/workouts_provider.dart';
import 'package:fitrix/features/workouts/presentation/screens/sport_workouts_screen.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

// Wednesday 14 Oct 2026; the week is Mon 12 - Sun 18.
final _now = DateTime(2026, 10, 14, 9);

PlannedSession _s(String id, int day, String templateId,
        {Sport sport = Sport.gym}) =>
    PlannedSession(
      id: id,
      day: DateTime(2026, 10, day),
      sport: sport,
      title: WorkoutCatalog.defaults
          .firstWhere((t) => t.id == templateId,
              orElse: () => WorkoutCatalog.defaults.first)
          .name,
      templateId: templateId,
      minutes: 60,
      intensity: Intensity.normal,
    );

CompletedWorkout _done(String templateId, DateTime at) => CompletedWorkout(
      templateId: templateId,
      name: 'x',
      sport: Sport.gym,
      startedAt: at.subtract(const Duration(hours: 1)),
      finishedAt: at,
      exercises: const [],
    );

CheckIn _soreLegs() => CheckIn(
      at: DateTime(2026, 10, 14, 7, 40),
      sleep: const Duration(hours: 7, minutes: 30),
      quality: SleepQuality.good,
      soreness: Soreness.medium,
      sore: const {BodyArea.legs},
      energy: Level3.ok,
      stress: Level3.ok,
    );

const _swap = (from: 'Barbell row', to: 'Chest-supported row');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ExerciseCatalog catalog;
  setUpAll(() async {
    catalog = await ExerciseCatalog.load(rootBundle);
  });

  group('todayPlanOf', () {
    final today = DateTime(2026, 10, 14);

    test('empty plan, or only past weeks: unplanned', () {
      expect(todayPlanOf(const [], const [], today).kind, TodayKind.unplanned);
      expect(todayPlanOf([_s('a', 9, 'gym-legs')], const [], today).kind,
          TodayKind.unplanned);
    });

    test('an open session today', () {
      final p = todayPlanOf(
          [_s('a', 14, 'gym-legs'), _s('b', 16, 'gym-chest-biceps')],
          const [],
          today);
      expect(p.kind, TodayKind.session);
      expect(p.session!.id, 'a');
    });

    test('today\'s sessions all done: done, with the next one', () {
      final p = todayPlanOf(
          [_s('a', 14, 'gym-legs'), _s('b', 16, 'gym-chest-biceps')],
          [_done('gym-legs', DateTime(2026, 10, 14, 8))],
          today);
      expect(p.kind, TodayKind.done);
      expect(p.next!.id, 'b');
    });

    test('nothing today: rest, with the earliest later session', () {
      final p = todayPlanOf([
        _s('late', 20, 'gym-legs'),
        _s('past', 12, 'gym-legs'),
        _s('soon', 16, 'gym-chest-biceps'),
      ], const [], today);
      expect(p.kind, TodayKind.rest);
      expect(p.next!.id, 'soon');
      // Only a session earlier this week: still a planned week.
      final q = todayPlanOf([_s('past', 12, 'gym-legs')], const [], today);
      expect(q.kind, TodayKind.rest);
      expect(q.next, isNull);
    });
  });

  group('screens', () {
    Future<ProviderContainer> pump(
      WidgetTester tester, {
      required Widget home,
      List<PlannedSession> plan = const [],
      List<CompletedWorkout> history = const [],
      bool checkIn = false,
      List<({String from, String to})> swaps = const [],
      Size size = const Size(390, 844),
    }) async {
      tester.view.physicalSize = size * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      if (checkIn) {
        final store = CheckInStore(prefs, now: () => _now);
        await store.save(_soreLegs());
        await store.saveSwaps(swaps);
      }
      final container = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        clockProvider.overrideWithValue(() => _now),
        exerciseCatalogProvider.overrideWith((ref) => catalog),
      ]);
      addTearDown(container.dispose);
      for (final h in history) {
        container.read(workoutHistoryProvider.notifier).add(h);
      }
      await container.read(weekPlanProvider.notifier).addAll(plan);
      final router = GoRouter(
        initialLocation: '/start',
        routes: [
          GoRoute(path: '/start', builder: (_, __) => home),
          GoRoute(
              path: AppRouter.recovery,
              builder: (_, __) => const RecoveryScreen()),
          for (final p in [
            AppRouter.home,
            AppRouter.weekPlan,
            AppRouter.progress,
            AppRouter.nutrition,
            AppRouter.workouts,
            AppRouter.felix,
            AppRouter.shop,
            AppRouter.fitrixMap,
          ])
            GoRoute(path: p, builder: (_, __) => const Scaffold()),
        ],
      );
      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ));
      await tester.pumpAndSettle();
      return container;
    }

    Finder todayCard() => find.byKey(const Key('home-today-card'));
    Finder inCard(Finder f) => find.descendant(of: todayCard(), matching: f);

    List<String> activeNames(ProviderContainer c) => [
          for (final e in c.read(activeWorkoutProvider)!.exercises) e.name,
        ];

    group('Home Today card', () {
      testWidgets('rest day: says so and names the next session',
          (tester) async {
        await pump(tester,
            home: const HomeScreen(),
            plan: [_s('a', 12, 'gym-legs'), _s('b', 15, 'gym-legs')]);
        expect(inCard(find.text('Rest day')), findsOneWidget);
        expect(inCard(find.text('Next: Thursday · Legs')), findsOneWidget);
        expect(inCard(find.text('Start')), findsNothing);
        expect(inCard(find.text(WorkoutCatalog.defaults.first.name)),
            findsNothing);
      });

      testWidgets('after today\'s session: done for today, then the next one',
          (tester) async {
        await pump(tester, home: const HomeScreen(), plan: [
          _s('a', 14, 'gym-legs'),
          _s('b', 16, 'gym-back-triceps'),
        ], history: [
          _done('gym-legs', DateTime(2026, 10, 14, 8))
        ]);
        expect(inCard(find.text('Done for today')), findsOneWidget);
        expect(inCard(find.text('Next: Friday · Back and Triceps')),
            findsOneWidget);
        expect(inCard(find.text('Start')), findsNothing);
      });

      testWidgets('nothing planned after today says so', (tester) async {
        await pump(tester,
            home: const HomeScreen(), plan: [_s('a', 13, 'gym-legs')]);
        expect(inCard(find.text('Rest day')), findsOneWidget);
        expect(inCard(find.text('Nothing else planned yet')), findsOneWidget);
      });

      testWidgets('rest day at 375x667 and text x1.3 lays out', (tester) async {
        await pump(tester,
            home: const MediaQuery(
              data: MediaQueryData(
                  size: Size(375, 667), textScaler: TextScaler.linear(1.3)),
              child: HomeScreen(),
            ),
            size: const Size(375, 667),
            plan: [_s('b', 15, 'gym-back-triceps')]);
        expect(tester.takeException(), isNull);
      });

      testWidgets('Start applies today\'s check-in swaps', (tester) async {
        final c = await pump(tester,
            home: const HomeScreen(),
            plan: [_s('a', 14, 'gym-back-triceps')],
            checkIn: true,
            swaps: const [_swap]);
        expect(inCard(find.text('Back and Triceps')), findsOneWidget);
        await tester.tap(inCard(find.text('Start')));
        await tester.pumpAndSettle();
        expect(activeNames(c), contains('Chest-supported row'));
        expect(activeNames(c), isNot(contains('Barbell row')));
        expect(c.read(activeWorkoutExpandedProvider), isTrue);
      });

      testWidgets('Start asks before replacing another running workout',
          (tester) async {
        final c = await pump(tester,
            home: const HomeScreen(), plan: [_s('a', 14, 'gym-back-triceps')]);
        c.read(activeWorkoutProvider.notifier).start(
            WorkoutCatalog.defaults.firstWhere((t) => t.id == 'gym-legs'));
        await tester.pumpAndSettle();
        await tester.tap(inCard(find.text('Start')));
        await tester.pumpAndSettle();
        expect(find.text('Discard current workout?'), findsOneWidget);
        expect(
            find.text('“Legs” is still in progress and won\'t be saved. '
                'Start “Back and Triceps” instead?'),
            findsOneWidget);
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(c.read(activeWorkoutProvider)!.template.id, 'gym-legs');
        await tester.tap(inCard(find.text('Start')));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(TextButton, 'Discard and start'));
        await tester.pumpAndSettle();
        expect(c.read(activeWorkoutProvider)!.template.id, 'gym-back-triceps');
      });
    });

    group('check-in on a planned week', () {
      test('rest day: no gym template, so nothing is swapped', () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final c = ProviderContainer(overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          clockProvider.overrideWithValue(() => _now),
        ]);
        addTearDown(c.dispose);
        expect(c.read(todaysGymTemplateProvider)?.id, 'gym-chest-biceps');
        await c
            .read(weekPlanProvider.notifier)
            .addAll([_s('b', 16, 'gym-back-triceps')]);
        expect(c.read(todaysGymTemplateProvider), isNull);
        await c
            .read(weekPlanProvider.notifier)
            .add(_s('a', 14, 'gym-back-triceps'));
        expect(c.read(todaysGymTemplateProvider)?.id, 'gym-back-triceps');
        c
            .read(workoutHistoryProvider.notifier)
            .add(_done('gym-back-triceps', DateTime(2026, 10, 14, 8)));
        expect(c.read(todaysGymTemplateProvider), isNull);
      });

      testWidgets('Recovery on a rest day shows no swap card or Start',
          (tester) async {
        await pump(tester,
            home: const RecoveryScreen(),
            plan: [_s('b', 16, 'gym-back-triceps')],
            checkIn: true);
        expect(find.text('Apply swaps'), findsNothing);
        expect(find.text('Start workout'), findsNothing);
        expect(tester.takeException(), isNull);
      });
    });

    testWidgets('week plan Start applies today\'s swaps', (tester) async {
      final c = await pump(tester,
          home: const WeekPlanScreen(),
          plan: [_s('a', 14, 'gym-back-triceps')],
          checkIn: true,
          swaps: const [_swap]);
      await tester.ensureVisible(find.byKey(const Key('plan-start-a')));
      await tester.tap(find.byKey(const Key('plan-start-a')));
      await tester.pumpAndSettle();
      expect(activeNames(c), contains('Chest-supported row'));
    });

    group('Gym screen', () {
      Future<ProviderContainer> gym(WidgetTester tester,
              {List<PlannedSession> plan = const [],
              List<CompletedWorkout> history = const [],
              bool checkIn = false,
              List<({String from, String to})> swaps = const []}) =>
          pump(tester,
              home: const SportWorkoutsScreen(sport: Sport.gym),
              size: const Size(375, 667),
              plan: plan,
              history: history,
              checkIn: checkIn,
              swaps: swaps);

      WorkoutCard card(WidgetTester tester, String title) =>
          tester.widget<WorkoutCard>(find
              .byWidgetPredicate((w) => w is WorkoutCard && w.title == title));

      testWidgets(
          'Today only on the session planned today; next dates on '
          'other planned plans; no badge otherwise', (tester) async {
        await gym(tester, plan: [
          _s('a', 14, 'gym-back-triceps'),
          _s('b', 16, 'gym-legs'),
          _s('c', 21, 'gym-legs'),
        ]);
        expect(card(tester, 'Back and Triceps').today, isTrue);
        expect(card(tester, 'Back and Triceps').dayLabel, 'Today');
        expect(card(tester, 'Legs').today, isFalse);
        expect(card(tester, 'Legs').dayLabel, 'Friday');
        expect(card(tester, 'Chest and Biceps').today, isFalse);
        expect(card(tester, 'Chest and Biceps').dayLabel, isNull);
        expect(find.text('TODAY'), findsOneWidget);
        // The coach card names today's session and starts it.
        expect(
            find.descendant(
                of: find.byType(CoachCard),
                matching: find.textContaining('Back and Triceps')),
            findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('rest day: no Today, coach names the next session',
          (tester) async {
        final c = await gym(tester, plan: [_s('b', 16, 'gym-legs')]);
        expect(find.text('TODAY'), findsNothing);
        expect(card(tester, 'Legs').dayLabel, 'Friday');
        expect(
            find.descendant(
                of: find.byType(CoachCard),
                matching: find.textContaining('Legs')),
            findsOneWidget);
        await tester.ensureVisible(find.byType(CoachCard));
        await tester.tap(find.descendant(
            of: find.byType(CoachCard), matching: find.text('Start')));
        await tester.pumpAndSettle();
        expect(c.read(activeWorkoutProvider)!.template.id, 'gym-legs');
      });

      testWidgets('a session done today shows Done and the next date',
          (tester) async {
        await gym(tester,
            plan: [_s('a', 14, 'gym-legs'), _s('b', 16, 'gym-legs')],
            history: [_done('gym-legs', DateTime(2026, 10, 14, 8))]);
        expect(card(tester, 'Legs').done, isTrue);
        expect(card(tester, 'Legs').today, isFalse);
        expect(card(tester, 'Legs').dayLabel, 'Friday');
      });

      testWidgets('next week\'s date carries the day of the month',
          (tester) async {
        await gym(tester, plan: [_s('b', 21, 'gym-legs')]);
        expect(card(tester, 'Legs').dayLabel, 'Wed 21');
      });

      testWidgets(
          'Start on today\'s plan applies the swaps; another plan '
          'starts unchanged', (tester) async {
        final c = await gym(tester,
            plan: [_s('a', 14, 'gym-back-triceps')],
            checkIn: true,
            swaps: const [_swap]);
        Finder start(String title) => find.descendant(
            of: find
                .byWidgetPredicate((w) => w is WorkoutCard && w.title == title),
            matching: find.text('Start'));
        await tester.tap(start('Back and Triceps'));
        await tester.pumpAndSettle();
        expect(activeNames(c), contains('Chest-supported row'));
        c.read(activeWorkoutProvider.notifier).discard();
        await tester.pumpAndSettle();
        await tester.tap(start('Chest and Biceps'));
        await tester.pumpAndSettle();
        expect(c.read(activeWorkoutProvider)!.template.id, 'gym-chest-biceps');
      });
    });
  });
}
