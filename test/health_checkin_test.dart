import 'dart:convert';

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
import 'package:fitrix/features/checkin/presentation/widgets/checkin_sheet.dart';
import 'package:fitrix/features/exercises/data/exercise_catalog.dart';
import 'package:fitrix/features/health/data/health_daily_store.dart';
import 'package:fitrix/features/health/data/health_source.dart';
import 'package:fitrix/features/home/presentation/screens/home_screen.dart';
import 'package:fitrix/features/progress/presentation/screens/progress_screen.dart';
import 'package:fitrix/features/workouts/presentation/providers/workouts_provider.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';
import 'support/fake_health_source.dart';
import 'support/overflow.dart';

final _now = DateTime(2026, 10, 23, 10);

String _key(int back) {
  final d = DateTime(2026, 10, 23 - back);
  return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

/// Seven earlier days with resting HR 54, HRV 48 and 9,400 steps.
Map<String, HealthDay> _history() => {
      for (var i = 1; i <= 7; i++)
        _key(i): const HealthDay(
            restingHr: 54, hrv: 48, hrvKind: HrvKind.sdnn, steps: 9400),
    };

CheckIn _checkIn() => CheckIn(
      at: DateTime(2026, 10, 23, 7, 40),
      sleep: const Duration(hours: 6, minutes: 15),
      quality: SleepQuality.ok,
      soreness: Soreness.none,
      sore: const {},
      energy: Level3.ok,
      stress: Level3.ok,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ExerciseCatalog catalog;
  setUpAll(() async {
    catalog = await ExerciseCatalog.load(rootBundle);
  });

  late FakeHealthSource fake;

  Future<ProviderContainer> pump(
    WidgetTester tester, {
    required Widget home,
    bool connected = true,
    Map<String, HealthDay> days = const {},
    bool throttled = true,
    bool checkedIn = false,
    Size size = const Size(390, 844),
    double textScale = 1,
  }) async {
    tester.view.physicalSize = size * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({
      if (connected)
        'health_connection_v1': jsonEncode({
          'connected': true,
          'writeWorkouts': true,
          if (throttled) 'lastReadAt': _now.toIso8601String(),
        }),
    });
    final prefs = await SharedPreferences.getInstance();
    await HealthDailyStore(prefs, now: () => _now).putAll(days);
    if (checkedIn) await CheckInStore(prefs, now: () => _now).save(_checkIn());
    final container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      clockProvider.overrideWithValue(() => _now),
      healthSourceProvider.overrideWithValue(fake),
      exerciseCatalogProvider.overrideWith((ref) => catalog),
    ]);
    addTearDown(container.dispose);
    final router = GoRouter(
      initialLocation: '/start',
      routes: [
        GoRoute(path: '/start', builder: (_, __) => home),
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
          AppRouter.weekPlan,
        ])
          GoRoute(path: p, builder: (_, __) => const Scaffold()),
      ],
    );
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
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

  Future<void> openSheet(WidgetTester tester) async {
    await tester.tap(find.text('Check in'));
    await tester.pumpAndSettle();
  }

  Map<String, HealthDay> withToday(HealthDay today) =>
      {..._history(), _key(0): today};

  setUp(() => fake = FakeHealthSource());

  group('check-in sheet', () {
    testWidgets('pre-fills sleep from Health, rounded, with the source',
        (tester) async {
      await pump(tester,
          home: const HomeScreen(),
          days: withToday(const HealthDay(
              sleep: Duration(hours: 7, minutes: 38),
              sleepSource: 'Apple Health')));
      await openSheet(tester);
      expect(find.text('7 h 45 m'), findsWidgets);
      expect(find.text('from Apple Health'), findsOneWidget);
    });

    testWidgets('in-bed sleep is labelled as in bed', (tester) async {
      await pump(tester,
          home: const HomeScreen(),
          days: withToday(const HealthDay(
              sleep: Duration(hours: 8),
              sleepSource: 'Apple Health',
              sleepInBed: true)));
      await openSheet(tester);
      expect(find.text('in bed, from Apple Health'), findsOneWidget);
      expect(find.text('from Apple Health'), findsNothing);
    });

    testWidgets('an in-bed-only night read from Health fills the sheet',
        (tester) async {
      fake.sleepSegments = [
        SleepSegment(
            from: DateTime(2026, 10, 22, 23),
            to: DateTime(2026, 10, 23, 7),
            asleep: false,
            inBed: true,
            sourceName: 'Apple Health'),
      ];
      await pump(tester, home: const HomeScreen(), throttled: false);
      await openSheet(tester);
      await tester.pumpAndSettle();
      expect(find.text('8 h 0 m'), findsWidgets);
      expect(find.text('in bed, from Apple Health'), findsOneWidget);
    });

    testWidgets('moving the slider drops the label', (tester) async {
      await pump(tester,
          home: const HomeScreen(),
          days: withToday(const HealthDay(
              sleep: Duration(hours: 7, minutes: 30),
              sleepSource: 'Apple Health')));
      await openSheet(tester);
      expect(find.text('from Apple Health'), findsOneWidget);
      await tester.tap(find.byTooltip('Sleep 15 minutes more'));
      await tester.pumpAndSettle();
      expect(find.text('from Apple Health'), findsNothing);
      expect(find.text('7 h 45 m'), findsWidgets);
    });

    testWidgets('clamps Health sleep into 3-12 h', (tester) async {
      await pump(tester,
          home: const HomeScreen(),
          days: withToday(const HealthDay(
              sleep: Duration(hours: 14), sleepSource: 'Apple Health')));
      await openSheet(tester);
      expect(find.text('12 h 0 m'), findsWidgets);
    });

    testWidgets('falls back to the platform name without a source',
        (tester) async {
      await pump(tester,
          home: const HomeScreen(),
          days: withToday(const HealthDay(sleep: Duration(hours: 7))));
      await openSheet(tester);
      expect(find.text('from Apple Health'), findsOneWidget);
    });

    testWidgets('sheet with a saved check-in shows the saved sleep',
        (tester) async {
      await pump(tester,
          home: Builder(
              builder: (c) => Scaffold(
                  body: TextButton(
                      onPressed: () => showCheckInSheet(c),
                      child: const Text('Open')))),
          checkedIn: true,
          days: withToday(const HealthDay(
              sleep: Duration(hours: 8), sleepSource: 'Apple Health')));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('6 h 15 m'), findsWidgets);
      expect(find.text('from Apple Health'), findsNothing);
    });

    testWidgets('no Health sleep keeps 7 h 30 m and no label', (tester) async {
      await pump(tester,
          home: const HomeScreen(),
          days: withToday(const HealthDay(restingHr: 55)));
      await openSheet(tester);
      expect(find.text('7 h 30 m'), findsWidgets);
      expect(find.textContaining('from '), findsNothing);
    });

    testWidgets('not connected keeps the default', (tester) async {
      await pump(tester,
          home: const HomeScreen(),
          connected: false,
          days: withToday(const HealthDay(
              sleep: Duration(hours: 8), sleepSource: 'Apple Health')));
      await openSheet(tester);
      expect(find.text('7 h 30 m'), findsWidgets);
      expect(find.textContaining('from '), findsNothing);
    });

    testWidgets('opening the sheet refreshes Health', (tester) async {
      await pump(tester, home: const HomeScreen(), throttled: false);
      final before = fake.readCalls;
      await openSheet(tester);
      expect(fake.readCalls, greaterThan(before));
    });

    testWidgets('sleep arriving after the sheet opened fills it in',
        (tester) async {
      fake.sleepSegments = [
        SleepSegment(
            from: DateTime(2026, 10, 22, 23, 20),
            to: DateTime(2026, 10, 23, 7),
            asleep: true,
            sourceName: 'Apple Health'),
      ];
      await pump(tester, home: const HomeScreen(), throttled: false);
      await openSheet(tester);
      await tester.pumpAndSettle();
      expect(find.text('7 h 45 m'), findsWidgets);
      expect(find.text('from Apple Health'), findsOneWidget);
    });
  });

  group('recovery', () {
    testWidgets('shows resting HR, HRV and steps against your normal',
        (tester) async {
      await pump(tester,
          home: const RecoveryScreen(),
          checkedIn: true,
          days: withToday(const HealthDay(
              restingHr: 60, hrv: 41, hrvKind: HrvKind.sdnn, steps: 8123)));
      await tester.scrollUntilVisible(find.text('60 bpm · your normal 54'), 200,
          scrollable: find.byType(Scrollable).first);
      expect(find.text('60 bpm · your normal 54'), findsOneWidget);
      expect(find.text('41 ms SDNN · your normal 48'), findsOneWidget);
      expect(find.text('Steps today: 8,123\n7-day average: 9,400'), findsOneWidget);
      expect(find.text('Resting heart rate above normal'), findsOneWidget);
      expect(find.text('HRV below normal'), findsOneWidget);
    });

    testWidgets('58 bpm against 54 reads near normal', (tester) async {
      await pump(tester,
          home: const RecoveryScreen(),
          checkedIn: true,
          days: withToday(const HealthDay(restingHr: 58)));
      await tester.scrollUntilVisible(find.text('58 bpm · your normal 54'), 200,
          scrollable: find.byType(Scrollable).first);
      expect(find.text('Resting heart rate near normal'), findsOneWidget);
    });

    testWidgets('RMSSD kind is labelled', (tester) async {
      await pump(tester, home: const RecoveryScreen(), checkedIn: true, days: {
        for (final e in _history().entries)
          e.key: const HealthDay(hrv: 48, hrvKind: HrvKind.rmssd, steps: 9400),
        _key(0): const HealthDay(hrv: 50, hrvKind: HrvKind.rmssd),
      });
      await tester.scrollUntilVisible(
          find.text('50 ms RMSSD · your normal 48'), 200,
          scrollable: find.byType(Scrollable).first);
      expect(find.text('HRV near normal'), findsOneWidget);
    });

    testWidgets('no rows when the values are null', (tester) async {
      await pump(tester,
          home: const RecoveryScreen(),
          checkedIn: true,
          days: withToday(const HealthDay(sleep: Duration(hours: 7))));
      expect(find.textContaining('bpm'), findsNothing);
      expect(find.textContaining('SDNN'), findsNothing);
      expect(find.text('Health data'), findsNothing);
    });

    testWidgets('only yesterday cached: nothing shown for today',
        (tester) async {
      await pump(tester,
          home: const RecoveryScreen(), checkedIn: true, days: _history());
      expect(find.textContaining('bpm'), findsNothing);
      expect(find.textContaining('SDNN'), findsNothing);
    });

    testWidgets('not connected shows no Health rows', (tester) async {
      await pump(tester,
          home: const RecoveryScreen(),
          checkedIn: true,
          connected: false,
          days: withToday(const HealthDay(restingHr: 58, steps: 8123)));
      expect(find.textContaining('bpm'), findsNothing);
      expect(find.textContaining('steps'), findsNothing);
    });

    testWidgets('without a check-in the Health values show above the prompt',
        (tester) async {
      await pump(tester,
          home: const RecoveryScreen(),
          days: withToday(const HealthDay(
              restingHr: 60, hrv: 41, hrvKind: HrvKind.sdnn, steps: 8123)));
      expect(find.text('No check-in yet'), findsOneWidget);
      expect(find.text('Health data'), findsOneWidget);
      expect(find.text('60 bpm · your normal 54'), findsOneWidget);
      expect(find.text('41 ms SDNN · your normal 48'), findsOneWidget);
      expect(tester.getTopLeft(find.text('60 bpm · your normal 54')).dy,
          lessThan(tester.getTopLeft(find.text('No check-in yet')).dy));
      expect(find.text('Check in'), findsOneWidget);
    });

    testWidgets('without a check-in and Health values: only the prompt',
        (tester) async {
      await pump(tester, home: const RecoveryScreen(), days: _history());
      expect(find.text('No check-in yet'), findsOneWidget);
      expect(find.text('Health data'), findsNothing);
    });

    testWidgets("today's bar in the last 7 days is the ring's score",
        (tester) async {
      final c = await pump(tester,
          home: const RecoveryScreen(),
          checkedIn: true,
          days: withToday(const HealthDay(
              restingHr: 60, hrv: 41, hrvKind: HrvKind.sdnn, steps: 8123)));
      final ring = c.read(todayReadinessProvider)!.score;
      final withoutHealth = readiness(_checkIn(), hardDaysLast7: 0).score;
      expect(ring, isNot(withoutHealth));
      await tester.scrollUntilVisible(find.text('Last 7 days'), 200,
          scrollable: find.byType(Scrollable).first);
      expect(find.text('$ring%'), findsOneWidget); // the ring
      expect(find.text('$ring'), findsOneWidget); // today's bar
      expect(find.text('avg $ring%'), findsOneWidget);
      expect(find.text('$withoutHealth'), findsNothing);
    });

    testWidgets('opening recovery refreshes Health', (tester) async {
      await pump(tester,
          home: const RecoveryScreen(), checkedIn: true, throttled: false);
      expect(fake.readCalls, greaterThan(0));
    });
  });

  group('home', () {
    testWidgets('steps tile when connected and steps known, no plan needed',
        (tester) async {
      await pump(tester,
          home: const HomeScreen(),
          days: withToday(const HealthDay(steps: 8123)));
      expect(find.byKey(const Key('home-steps-tile')), findsOneWidget);
      // Same average as the check-in card: the 7 earlier days, not today.
      expect(find.text('Steps today: 8,123\n7-day average: 9,400'), findsOneWidget);
    });

    testWidgets('steps tile without any plan or templates', (tester) async {
      final c = await pump(tester,
          home: const HomeScreen(),
          days: withToday(const HealthDay(steps: 8123)));
      c.read(workoutTemplatesProvider.notifier).state = [];
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('home-today-card')), findsNothing);
      expect(find.byKey(const Key('home-steps-tile')), findsOneWidget);
    });

    testWidgets('no steps line inside the Today card', (tester) async {
      await pump(tester,
          home: const HomeScreen(),
          days: withToday(const HealthDay(steps: 8123)));
      expect(find.byKey(const Key('home-today-card')), findsOneWidget);
      expect(
          find.descendant(
              of: find.byKey(const Key('home-today-card')),
              matching: find.textContaining('Steps')),
          findsNothing);
    });

    testWidgets('SE at 375x667, 1.3x: steps tile with average fits',
        (tester) async {
      await pump(tester,
          home: const HomeScreen(),
          size: iPhoneSeSize,
          textScale: 1.3,
          days: withToday(const HealthDay(steps: 8123)));
      expect(find.byKey(const Key('home-steps-tile')), findsOneWidget);
      expect(find.text('Steps today: 8,123\n7-day average: 9,400'), findsOneWidget);
      expectNoOverflow(tester);
    });

    testWidgets('no steps tile when steps unknown', (tester) async {
      await pump(tester,
          home: const HomeScreen(),
          days: withToday(const HealthDay(restingHr: 55)));
      expect(find.byKey(const Key('home-steps-tile')), findsNothing);
      expect(find.textContaining('steps'), findsNothing);
    });

    testWidgets('no steps tile when not connected', (tester) async {
      await pump(tester,
          home: const HomeScreen(),
          connected: false,
          days: withToday(const HealthDay(steps: 8123)));
      expect(find.byKey(const Key('home-steps-tile')), findsNothing);
      expect(find.textContaining('steps'), findsNothing);
    });
  });

  group('progress steps chart', () {
    // Today and 6 days back: known on days 0, 2, 3; unknown otherwise.
    Map<String, HealthDay> week() => {
          _key(0): const HealthDay(steps: 10000),
          _key(2): const HealthDay(steps: 5000),
          _key(3): const HealthDay(steps: 6000),
        };

    testWidgets('seven bars, unknown days empty, average of known days',
        (tester) async {
      await pump(tester, home: const ProgressScreen(), days: week());
      expect(find.byKey(const ValueKey('steps-week')), findsOneWidget);
      for (var i = 0; i < 7; i++) {
        expect(
            find.byKey(ValueKey('steps-bar-${DateTime(2026, 10, 23 - i).day}')),
            findsOneWidget);
      }
      expect(find.text('10,000'), findsOneWidget);
      expect(find.text('5,000'), findsOneWidget);
      expect(find.text('6,000'), findsOneWidget);
      expect(
          find.descendant(
              of: find.byKey(const ValueKey('steps-week')),
              matching: find.text('0')),
          findsNothing);
      // Same as the check-in: completed days only, today's partial day
      // excluded: (5000 + 6000) / 2, not / 7.
      expect(find.text('Daily average: 5,500'), findsOneWidget);
    });

    testWidgets('hidden when no day has steps', (tester) async {
      await pump(tester,
          home: const ProgressScreen(),
          days: {_key(0): const HealthDay(restingHr: 55)});
      expect(find.byKey(const ValueKey('steps-week')), findsNothing);
    });

    testWidgets('hidden when not connected', (tester) async {
      await pump(tester,
          home: const ProgressScreen(), connected: false, days: week());
      expect(find.byKey(const ValueKey('steps-week')), findsNothing);
    });

    testWidgets('no overflow on iPhone SE at 1.3', (tester) async {
      await pump(tester,
          home: const ProgressScreen(),
          days: {
            for (var i = 0; i < 7; i++) _key(i): const HealthDay(steps: 12345)
          },
          size: iPhoneSeSize,
          textScale: 1.3);
      expect(find.byKey(const ValueKey('steps-week')), findsOneWidget);
      expectNoOverflow(tester);
    });

    test('daily average strings need no plural', () {
      expect(lookupAppLocalizations(const Locale('ru')).healthStepsDailyAvg(1),
          'В среднем за день: 1');
      expect(lookupAppLocalizations(const Locale('uz')).healthStepsDailyAvg(5),
          'Kunlik o‘rtacha: 5');
    });
  });

  test('step lines need no plural in any language', () {
    String steps(String lang, int n) =>
        lookupAppLocalizations(Locale(lang)).healthStepsToday(n);
    String avg(String lang, int n, int a) =>
        lookupAppLocalizations(Locale(lang)).healthStepsTodayAvg(n, a);
    expect(steps('ru', 1), 'Шаги сегодня: 1');
    expect(steps('ru', 3), 'Шаги сегодня: 3');
    expect(avg('ru', 2, 5), 'Шаги сегодня: 2\nВ среднем за 7 дней: 5');
    expect(steps('en', 1), 'Steps today: 1');
    expect(avg('en', 1, 7), 'Steps today: 1\n7-day average: 7');
    expect(steps('es', 1), 'Pasos hoy: 1');
    expect(avg('es', 1, 7), 'Pasos hoy: 1\nMedia de 7 días: 7');
    expect(steps('uz', 1), 'Bugungi qadamlar: 1');
    expect(avg('uz', 1, 7), 'Bugungi qadamlar: 1\n7 kunlik o‘rtacha: 7');
    expect(
        lookupAppLocalizations(const Locale('uz'))
            .healthRestingHrNormal(58, 54),
        contains('me’yoringiz'));
    expect(lookupAppLocalizations(const Locale('uz')).factorHrvLow,
        'HRV me’yordan past');
    expect(
        lookupAppLocalizations(const Locale('es'))
            .healthHrvNormal(41, 'SDNN', 48),
        '41 ms SDNN · tu habitual 48');
  });

  group('no overflow on iPhone SE at 1.3', () {
    final full = withToday(const HealthDay(
        sleep: Duration(hours: 7, minutes: 40),
        sleepSource: 'Apple Health',
        restingHr: 58,
        hrv: 41,
        hrvKind: HrvKind.sdnn,
        steps: 8123));

    testWidgets('home and sheet', (tester) async {
      await pump(tester,
          home: const HomeScreen(),
          days: full,
          size: iPhoneSeSize,
          textScale: 1.3);
      expectNoOverflow(tester);
      await openSheet(tester);
      expectNoOverflow(tester);
    });

    testWidgets('recovery without a check-in', (tester) async {
      await pump(tester,
          home: const RecoveryScreen(),
          days: full,
          size: iPhoneSeSize,
          textScale: 1.3);
      expectNoOverflow(tester);
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -600));
      await tester.pumpAndSettle();
      expectNoOverflow(tester);
      expect(find.text('Check in'), findsOneWidget);
    });

    testWidgets('recovery', (tester) async {
      await pump(tester,
          home: const RecoveryScreen(),
          checkedIn: true,
          days: full,
          size: iPhoneSeSize,
          textScale: 1.3);
      expectNoOverflow(tester);
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -600));
      await tester.pumpAndSettle();
      expectNoOverflow(tester);
    });
  });
}
