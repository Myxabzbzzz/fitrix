import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitrix/core/router/app_router.dart';
import 'package:fitrix/core/session/session_providers.dart';
import 'package:fitrix/core/time/today_provider.dart';
import 'package:fitrix/features/checkin/data/checkin_models.dart';
import 'package:fitrix/features/checkin/data/checkin_store.dart';
import 'package:fitrix/features/checkin/presentation/providers/checkin_provider.dart';
import 'package:fitrix/features/checkin/presentation/screens/recovery_screen.dart';
import 'package:fitrix/features/exercises/data/exercise_catalog.dart';
import 'package:fitrix/features/home/presentation/screens/home_screen.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/features/workouts/data/workout_catalog.dart';
import 'package:fitrix/features/workouts/presentation/providers/workouts_provider.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';
import 'support/overflow.dart';

CheckIn _checkIn({
  DateTime? at,
  Duration sleep = const Duration(hours: 7, minutes: 30),
  SleepQuality quality = SleepQuality.good,
  Soreness soreness = Soreness.medium,
  Set<BodyArea> sore = const {BodyArea.legs},
  Level3 energy = Level3.high,
  Level3 stress = Level3.low,
}) =>
    CheckIn(
      at: at ?? DateTime(2026, 10, 17, 7, 40),
      sleep: sleep,
      quality: quality,
      soreness: soreness,
      sore: sore,
      energy: energy,
      stress: stress,
    );

CompletedWorkout _done(DateTime at, int? rpe) => CompletedWorkout(
      templateId: 't',
      name: 'x',
      sport: Sport.gym,
      startedAt: at.subtract(const Duration(hours: 1)),
      finishedAt: at,
      exercises: const [],
      sessionRpe: rpe,
    );

DateTime testNow = DateTime(2026, 10, 17, 7, 45);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ExerciseCatalog sharedCatalog;
  setUpAll(() async {
    sharedCatalog = await ExerciseCatalog.load(rootBundle);
  });

  group('readiness', () {
    test('prototype inputs give 78 with the documented factors', () {
      final r = readiness(_checkIn(), hardDaysLast7: 4);
      expect(r.score, 78);
      expect([for (final f in r.factors) f.delta], [8, -12, 4, 3, -5]);
      expect(r.label, ReadinessLabel.ready);
    });

    test('sleep hours clamp at -12 and +6; score stays within 0-100', () {
      int sleepDelta(Duration d) =>
          readiness(_checkIn(sleep: d), hardDaysLast7: 0).factors.first.delta;
      // good quality (+5) plus the clamped hour term.
      expect(sleepDelta(const Duration(hours: 1)), 5 - 12);
      expect(sleepDelta(const Duration(hours: 12)), 5 + 6);
      final worst = readiness(
        _checkIn(
          sleep: Duration.zero,
          quality: SleepQuality.poor,
          soreness: Soreness.strong,
          energy: Level3.low,
          stress: Level3.high,
        ),
        hardDaysLast7: 6,
      );
      expect(worst.score, 80 - 22 - 20 - 8 - 8 - 10);
      expect(worst.label, ReadinessLabel.rest);
      final best = readiness(
        _checkIn(
            sleep: const Duration(hours: 12),
            soreness: Soreness.none,
            sore: const {}),
        hardDaysLast7: 0,
      );
      expect(best.score, 98);
    });

    test('labels split at 70 and 50', () {
      // 80 + (-10 + 0) = 70 -> ready; 69 -> light needs a different mix.
      expect(
        readiness(
          _checkIn(
              sleep: const Duration(hours: 7),
              quality: SleepQuality.poor,
              soreness: Soreness.none,
              sore: const {},
              energy: Level3.ok,
              stress: Level3.ok),
          hardDaysLast7: 0,
        ).label,
        ReadinessLabel.ready,
      );
      expect(
        readiness(
          _checkIn(
              sleep: const Duration(hours: 7),
              quality: SleepQuality.poor,
              soreness: Soreness.light,
              energy: Level3.ok,
              stress: Level3.ok),
          hardDaysLast7: 0,
        ).label,
        ReadinessLabel.trainLight,
      );
    });

    test('training load steps', () {
      int load(int n) =>
          readiness(_checkIn(), hardDaysLast7: n).factors.last.delta;
      expect(
          [for (var n = 0; n <= 6; n++) load(n)], [0, 0, 0, -3, -5, -10, -10]);
    });
  });

  group('hardDaysLast7', () {
    final now = DateTime(2026, 10, 18, 9);
    test('counts calendar days with sessionRpe >= 7 once each', () {
      final history = [
        _done(DateTime(2026, 10, 17, 18), 8),
        _done(DateTime(2026, 10, 17, 20), 9), // same day
        _done(DateTime(2026, 10, 16, 18), 7),
        _done(DateTime(2026, 10, 15, 18), 6), // not hard
        _done(DateTime(2026, 10, 14, 18), null), // not hard
        _done(DateTime(2026, 10, 12, 18), 9), // 6 days back: counts
        _done(DateTime(2026, 10, 11, 18), 9), // 7 days back: out
      ];
      expect(hardDaysLast7(history, now), 3);
    });
  });

  group('CheckInStore', () {
    test('today() is null after midnight', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      var clock = DateTime(2026, 10, 17, 23, 59);
      final store = CheckInStore(prefs, now: () => clock);
      await store.save(_checkIn(at: clock));
      expect(store.today(), isNotNull);
      clock = DateTime(2026, 10, 18, 0, 1);
      expect(store.today(), isNull);
      expect(store.lastDays(7), hasLength(1));
    });

    test('keeps 60 days, one check-in per day', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      var clock = DateTime(2026, 1, 1, 8);
      final store = CheckInStore(prefs, now: () => clock);
      for (var i = 0; i < 70; i++) {
        clock = DateTime(2026, 1, 1 + i, 8);
        await store.save(_checkIn(at: clock));
      }
      await store.save(_checkIn(at: clock.add(const Duration(hours: 1))));
      expect(store.lastDays(400).length, lessThanOrEqualTo(61));
      expect(store.lastDays(400).length, greaterThan(55));
      expect(store.lastDays(1), hasLength(1));
    });

    test('swaps are scoped to the day', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      var clock = DateTime(2026, 10, 17, 8);
      final store = CheckInStore(prefs, now: () => clock);
      await store.saveSwaps([(from: 'a', to: 'b')]);
      expect(store.swaps(), [(from: 'a', to: 'b')]);
      clock = DateTime(2026, 10, 18, 8);
      expect(store.swaps(), isEmpty);
    });
  });

  group('sparingSwaps', () {
    late ExerciseCatalog catalog;
    setUpAll(() async {
      catalog = await ExerciseCatalog.load(rootBundle);
    });
    final today = WorkoutCatalog.defaults
        .firstWhere((t) => t.exercises.any((e) => e.name == 'Barbell row'));

    test('sore legs replace Barbell row with a similar non-leg exercise', () {
      final swaps = sparingSwaps(today, {BodyArea.legs}, catalog);
      final row = swaps.firstWhere((s) => s.from == 'Barbell row');
      final to = catalog.byName(row.to)!;
      expect(to.loads, isNot(contains('legs')));
      expect(catalog.similarTo(catalog.byName('Barbell row')!), contains(to));
      for (final s in swaps) {
        expect(catalog.byName(s.to)!.loads, isNot(contains('legs')));
      }
    });

    test('nothing sore, nothing swapped; applySwaps keeps the original', () {
      expect(sparingSwaps(today, {}, catalog), isEmpty);
      final swaps = sparingSwaps(today, {BodyArea.legs}, catalog);
      final swapped = applySwaps(today, swaps);
      expect(
          swapped.exercises.map((e) => e.name), isNot(contains('Barbell row')));
      expect(today.exercises.map((e) => e.name), contains('Barbell row'));
    });
  });

  group('screens', () {
    Future<ProviderContainer> pump(
      WidgetTester tester, {
      required Widget home,
      Size size = const Size(390, 844),
      double textScale = 1,
      CheckIn? existing,
      DateTime? now,
      List<CompletedWorkout> history = const [],
      Map<String, Object> prefsValues = const {},
    }) async {
      tester.view.physicalSize = size * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues(prefsValues);
      final prefs = await SharedPreferences.getInstance();
      final clock = now ?? DateTime(2026, 10, 17, 7, 45);
      testNow = clock;
      if (existing != null) {
        await CheckInStore(prefs, now: () => clock).save(existing);
      }
      final container = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        clockProvider.overrideWithValue(() => testNow),
        exerciseCatalogProvider.overrideWith((ref) => sharedCatalog),
      ]);
      addTearDown(container.dispose);
      for (final h in history) {
        container.read(workoutHistoryProvider.notifier).add(h);
      }
      final router = GoRouter(
        initialLocation: '/start',
        routes: [
          GoRoute(path: '/start', builder: (_, __) => home),
          GoRoute(path: AppRouter.home, builder: (_, __) => home),
          GoRoute(
              path: AppRouter.recovery,
              builder: (_, __) => const RecoveryScreen()),
          for (final p in [
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
          builder: (context, child) => DayRollover(
            child: MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(textScale)),
              child: child!,
            ),
          ),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ));
      await tester.pumpAndSettle();
      return container;
    }

    testWidgets('Home shows Check in before saving, the score after',
        (tester) async {
      final container = await pump(tester, home: const HomeScreen());
      expect(find.text('Check in'), findsOneWidget);
      expect(find.text('Good morning'), findsOneWidget);

      await tester.tap(find.text('Check in'));
      await tester.pumpAndSettle();
      expect(find.text('Morning check-in'), findsOneWidget);
      // Prototype defaults: 7 h 30 m, live preview.
      expect(find.text('7 h 30 m'), findsWidgets);
      await tester.tap(find.byTooltip('Sleep 15 minutes more'));
      await tester.pumpAndSettle();
      expect(find.text('7 h 45 m'), findsWidgets);
      await tester.tap(find.text('Save check-in'));
      await tester.pumpAndSettle();

      expect(container.read(todayCheckInProvider), isNotNull);
      // Saving opens Recovery.
      expect(find.text('Recovery'), findsOneWidget);
    });

    testWidgets('Home after a check-in shows the ring with the score',
        (tester) async {
      await pump(
        tester,
        home: const HomeScreen(),
        existing: _checkIn(),
        history: [
          for (final d in [17, 16, 15, 14]) _done(DateTime(2026, 10, d, 18), 8),
        ],
      );
      expect(find.text('Check in'), findsNothing);
      expect(find.text('78%'), findsOneWidget);
      expect(find.text('Ready to train'), findsOneWidget);
    });

    testWidgets('Recovery renders with no check-in', (tester) async {
      await pump(tester, home: const RecoveryScreen());
      expect(find.text('No check-in yet'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Recovery shows factors, swap card, Undo and Start',
        (tester) async {
      final backTriceps =
          WorkoutCatalog.defaults.firstWhere((t) => t.id == 'gym-back-triceps');
      final container = await pump(
        tester,
        home: const RecoveryScreen(),
        existing: _checkIn(),
        history: [
          for (final d in [17, 16, 15, 14]) _done(DateTime(2026, 10, d, 18), 8),
        ],
      );
      // Make the back-and-triceps plan the first gym template.
      container.read(workoutTemplatesProvider.notifier).state = [
        backTriceps,
        ...WorkoutCatalog.defaults.where((t) => t.id != backTriceps.id),
      ];
      await tester.pumpAndSettle();
      expect(find.text('78%'), findsOneWidget);
      expect(find.text('+8'), findsOneWidget);
      expect(find.text('−12'), findsOneWidget);
      expect(find.text('−5'), findsOneWidget);
      expect(find.text('Last 7 days'), findsOneWidget);
      expect(find.text('Start workout'), findsOneWidget);
      // Suggested, not applied yet: apply, then undo.
      await tester.ensureVisible(find.text('Apply swaps'));
      await tester.tap(find.text('Apply swaps'));
      await tester.pumpAndSettle();
      expect(container.read(appliedSwapsProvider), isNotEmpty);
      await tester.ensureVisible(find.text('Undo'));
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(container.read(appliedSwapsProvider), isEmpty);
      await tester.tap(find.text('Apply swaps'));
      await tester.pumpAndSettle();

      // Start workout starts a swapped copy; the saved template is untouched.
      await tester.ensureVisible(find.text('Start workout'));
      await tester.tap(find.text('Start workout'));
      await tester.pump();
      final active = container.read(activeWorkoutProvider)!;
      expect(
          active.exercises.map((e) => e.name), isNot(contains('Barbell row')));
      expect(
          container
              .read(workoutTemplatesProvider)
              .first
              .exercises
              .map((e) => e.name),
          contains('Barbell row'));
    });

    Future<ProviderContainer> dayRollSetup(WidgetTester tester) async {
      final backTriceps =
          WorkoutCatalog.defaults.firstWhere((t) => t.id == 'gym-back-triceps');
      final container = await pump(
        tester,
        home: const HomeScreen(),
        existing: _checkIn(),
      );
      container.read(workoutTemplatesProvider.notifier).state = [
        backTriceps,
        ...WorkoutCatalog.defaults.where((t) => t.id != backTriceps.id),
      ];
      await container
          .read(appliedSwapsProvider.notifier)
          .apply([(from: 'Barbell row', to: 'Chest-supported row')]);
      await tester.pumpAndSettle();
      expect(find.text('Check in'), findsNothing);
      expect(container.read(todayCheckInProvider), isNotNull);
      return container;
    }

    void expectNewDay(WidgetTester tester, ProviderContainer container) {
      expect(container.read(todayCheckInProvider), isNull);
      expect(container.read(appliedSwapsProvider), isEmpty);
      expect(find.text('Check in'), findsOneWidget);
      expect(find.text('Ready to train'), findsNothing);
    }

    testWidgets('resuming after midnight drops yesterday\'s check-in and swaps',
        (tester) async {
      final container = await dayRollSetup(tester);
      testNow = DateTime(2026, 10, 18, 7, 0);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expectNewDay(tester, container);
    });

    testWidgets('the midnight timer rolls the day over in the foreground',
        (tester) async {
      final container = await dayRollSetup(tester);
      // Not yet midnight: nothing changes.
      await tester.pump(const Duration(hours: 10));
      expect(container.read(todayCheckInProvider), isNotNull);
      testNow = DateTime(2026, 10, 18, 0, 0, 1);
      await tester.pump(const Duration(hours: 7));
      await tester.pumpAndSettle();
      expectNewDay(tester, container);
    });

    for (final scale in [1.0, 1.3]) {
      testWidgets('no overflow at 375x667, text x$scale', (tester) async {
        await pump(tester,
            home: const HomeScreen(), size: iPhoneSeSize, textScale: scale);
        expectNoOverflow(tester);
        await tester.tap(find.text('Check in'));
        await tester.pumpAndSettle();
        expectNoOverflow(tester);
        await tester.tap(find.text('Save check-in'));
        await tester.pumpAndSettle();
        expectNoOverflow(tester);
        await pump(tester,
            home: const RecoveryScreen(),
            size: iPhoneSeSize,
            textScale: scale,
            existing: _checkIn());
        expectNoOverflow(tester);
      });
    }
  });
}
