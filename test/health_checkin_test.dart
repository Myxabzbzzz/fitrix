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
import 'package:fitrix/features/checkin/presentation/screens/recovery_screen.dart';
import 'package:fitrix/features/checkin/presentation/widgets/checkin_sheet.dart';
import 'package:fitrix/features/exercises/data/exercise_catalog.dart';
import 'package:fitrix/features/health/data/health_daily_store.dart';
import 'package:fitrix/features/health/data/health_source.dart';
import 'package:fitrix/features/home/presentation/screens/home_screen.dart';
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
      expect(find.text('8,123 steps today · 7-day avg 9,400'), findsOneWidget);
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
      expect(find.textContaining('steps'), findsNothing);
      expect(find.text('Health data'), findsNothing);
    });

    testWidgets('only yesterday cached: nothing shown for today',
        (tester) async {
      await pump(tester,
          home: const RecoveryScreen(), checkedIn: true, days: _history());
      expect(find.textContaining('bpm'), findsNothing);
      expect(find.textContaining('steps'), findsNothing);
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

    testWidgets('opening recovery refreshes Health', (tester) async {
      await pump(tester,
          home: const RecoveryScreen(), checkedIn: true, throttled: false);
      expect(fake.readCalls, greaterThan(0));
    });
  });

  group('home', () {
    testWidgets('steps line only when connected and steps known',
        (tester) async {
      await pump(tester,
          home: const HomeScreen(),
          days: withToday(const HealthDay(steps: 8123)));
      expect(find.text('8,123 steps today'), findsOneWidget);
    });

    testWidgets('no steps line when steps unknown', (tester) async {
      await pump(tester,
          home: const HomeScreen(),
          days: withToday(const HealthDay(restingHr: 55)));
      expect(find.textContaining('steps'), findsNothing);
    });

    testWidgets('no steps line when not connected', (tester) async {
      await pump(tester,
          home: const HomeScreen(),
          connected: false,
          days: withToday(const HealthDay(steps: 8123)));
      expect(find.textContaining('steps'), findsNothing);
    });
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
