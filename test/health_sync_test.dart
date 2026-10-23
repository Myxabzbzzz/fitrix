import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitrix/core/session/app_session.dart';
import 'package:fitrix/core/session/session_providers.dart';
import 'package:fitrix/core/time/today_provider.dart';
import 'package:fitrix/features/health/data/health_daily_store.dart';
import 'package:fitrix/features/health/data/health_source.dart';
import 'package:fitrix/features/health/presentation/providers/health_providers.dart';
import 'support/fake_health_source.dart';

HealthSample _s(DateTime to, double v) => HealthSample(
    uuid: 'u${to.microsecondsSinceEpoch}',
    from: to,
    to: to,
    value: v,
    sourceId: 'x',
    sourceName: 'Watch');

class _Throwing implements HealthImporter {
  int runs = 0;
  @override
  Future<void> run(HealthSource s, DateTime from, DateTime to) async {
    runs++;
    throw StateError('boom');
  }
}

class _Counting implements HealthImporter {
  DateTime? from;
  @override
  Future<void> run(HealthSource s, DateTime f, DateTime to) async => from = f;
}

void main() {
  late SharedPreferences prefs;
  late FakeHealthSource fake;
  late DateTime now;
  late ProviderContainer c;

  FakeHealthSource freshFake() => FakeHealthSource(
        sleepSegments: [
          SleepSegment(
              from: DateTime(2026, 10, 22, 23),
              to: DateTime(2026, 10, 23, 6, 30),
              asleep: true,
              sourceName: 'Watch'),
        ],
        restingHrSamples: [
          _s(DateTime(2026, 10, 23, 6), 58),
          _s(DateTime(2026, 10, 23, 8), 55),
        ],
        hrvSamples: [
          _s(DateTime(2026, 10, 23, 3), 40),
          _s(DateTime(2026, 10, 23, 5), 44),
        ],
        stepsValue: 1200,
      );

  ProviderContainer make({List<HealthImporter> importers = const []}) {
    final cc = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      healthSourceProvider.overrideWithValue(fake),
      clockProvider.overrideWithValue(() => now),
      healthImportersProvider.overrideWithValue(importers),
    ]);
    addTearDown(cc.dispose);
    return cc;
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    fake = freshFake();
    now = DateTime(2026, 10, 23, 10);
    c = make();
  });

  String key(int daysBack) {
    final d = DateTime(2026, 10, 23 - daysBack);
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  test('connect asks for access, marks connected and persists', () async {
    expect(c.read(healthConnectionProvider).connected, isFalse);
    expect(await c.read(healthConnectionProvider.notifier).connect(), isTrue);
    expect(fake.requestAccessCalls, 1);
    expect(c.read(healthConnectionProvider).connected, isTrue);
    expect(
        prefs.getString('health_connection_v1'), contains('"connected":true'));
    // A new container (app restart) sees it.
    expect(make().read(healthConnectionProvider).connected, isTrue);
  });

  test('denied access stays disconnected', () async {
    fake.grantAccess = false;
    expect(await c.read(healthConnectionProvider.notifier).connect(), isFalse);
    expect(c.read(healthConnectionProvider).connected, isFalse);
  });

  test('refresh fills today with sleep, resting HR, HRV and steps', () async {
    await c.read(healthConnectionProvider.notifier).connect();
    final d = c.read(healthDailyStoreProvider).day(key(0))!;
    expect(d.sleep, const Duration(hours: 7, minutes: 30));
    expect(d.sleepSource, 'Watch');
    expect(d.restingHr, 55);
    expect(d.hrv, 44);
    expect(d.hrvKind, HrvKind.sdnn);
    expect(d.steps, 1200);
    final t = c.read(healthTodayProvider);
    expect(t.restingHr, 55);
    expect(t.stepsToday, 1200);
  });

  test('resting HR falls back to the last 24 hours', () async {
    fake.restingHrSamples = [_s(DateTime(2026, 10, 22, 14), 61)];
    await c.read(healthConnectionProvider.notifier).connect();
    expect(c.read(healthDailyStoreProvider).day(key(0))!.restingHr, 61);
  });

  test('first read covers 30 days', () async {
    await c.read(healthConnectionProvider.notifier).connect();
    final store = c.read(healthDailyStoreProvider);
    expect(store.day(key(30)), isNotNull);
    expect(store.day(key(31)), isNull);
  });

  test('throttled to 15 minutes; force reads anyway', () async {
    await c.read(healthConnectionProvider.notifier).connect();
    fake.stepsValue = 5;
    now = now.add(const Duration(minutes: 14));
    await c.read(healthSyncProvider).refresh();
    expect(c.read(healthDailyStoreProvider).day(key(0))!.steps, 1200);
    now = now.add(const Duration(minutes: 2));
    await c.read(healthSyncProvider).refresh();
    expect(c.read(healthDailyStoreProvider).day(key(0))!.steps, 5);
    fake.stepsValue = 9;
    await c.read(healthSyncProvider).refresh();
    expect(c.read(healthDailyStoreProvider).day(key(0))!.steps, 5);
    await c.read(healthSyncProvider).refresh(force: true);
    expect(c.read(healthDailyStoreProvider).day(key(0))!.steps, 9);
  });

  test('later reads start 2 days back', () async {
    final imp = _Counting();
    c = make(importers: [imp]);
    await c.read(healthConnectionProvider.notifier).connect();
    expect(imp.from, DateTime(2026, 9, 23));
    now = now.add(const Duration(hours: 1));
    await c.read(healthSyncProvider).refresh();
    expect(imp.from, DateTime(2026, 10, 21));
  });

  test('not connected: no reads, no permission request', () async {
    fake.throwOnRead = true;
    await c.read(healthSyncProvider).refresh(force: true);
    expect(fake.requestAccessCalls, 0);
    expect(c.read(healthDailyStoreProvider).day(key(0)), isNull);
    expect(c.read(healthConnectionProvider).lastReadAt, isNull);
  });

  test('a second refresh while one runs shares it', () async {
    await c.read(healthConnectionProvider.notifier).connect();
    final sync = c.read(healthSyncProvider);
    final a = sync.refresh(force: true);
    final b = sync.refresh(force: true);
    expect(identical(a, b), isTrue);
    await a;
  });

  test('a throwing source leaves cache and lastReadAt alone', () async {
    await c.read(healthConnectionProvider.notifier).connect();
    final before = c.read(healthConnectionProvider).lastReadAt;
    final raw = prefs.getString('health_days_v1');
    fake.throwOnRead = true;
    now = now.add(const Duration(hours: 1));
    await c.read(healthSyncProvider).refresh(force: true);
    expect(c.read(healthConnectionProvider).lastReadAt, before);
    expect(prefs.getString('health_days_v1'), raw);
  });

  test('importers run each in their own guard', () async {
    final bad = _Throwing();
    final good = _Counting();
    c = make(importers: [bad, good]);
    await c.read(healthConnectionProvider.notifier).connect();
    expect(bad.runs, 1);
    expect(good.from, isNotNull);
  });

  test('unknown steps stay null, not 0', () async {
    fake.stepsValue = null;
    await c.read(healthConnectionProvider.notifier).connect();
    expect(c.read(healthDailyStoreProvider).day(key(0))!.steps, isNull);
    expect(c.read(healthTodayProvider).stepsToday, isNull);
  });

  test('store merge keeps old non-null values', () async {
    final store = c.read(healthDailyStoreProvider);
    await store.put('2026-10-23', const HealthDay(steps: 10, restingHr: 50));
    await store.put('2026-10-23', const HealthDay(restingHr: 52));
    final d = store.day('2026-10-23')!;
    expect(d.steps, 10);
    expect(d.restingHr, 52);
  });

  test('store keeps 60 days', () async {
    final store = c.read(healthDailyStoreProvider);
    await store.put(key(59), const HealthDay(steps: 1));
    await store.put(key(61), const HealthDay(steps: 1));
    expect(store.day(key(59)), isNotNull);
    expect(store.day(key(61)), isNull);
  });

  Future<void> seed(Map<int, HealthDay> byBack) async {
    await c.read(healthConnectionProvider.notifier).setWriteWorkouts(false);
    // connect without reading: set state through a read-less source
    fake.throwOnRead = true;
    await c.read(healthConnectionProvider.notifier).connect();
    fake.throwOnRead = false;
    final store = c.read(healthDailyStoreProvider);
    for (final e in byBack.entries) {
      await store.put(key(e.key), e.value);
    }
  }

  test('baselines come from at least five cached days', () async {
    await seed({
      0: const HealthDay(restingHr: 60, hrv: 30, hrvKind: HrvKind.sdnn),
      for (var i = 1; i <= 5; i++)
        i: HealthDay(
            restingHr: 50, hrv: 50, hrvKind: HrvKind.sdnn, steps: 1000 * i),
    });
    c.invalidate(healthDailyStoreProvider);
    final t = c.read(healthTodayProvider);
    expect(t.restingHr, 60);
    expect(t.restingHrBaseline, 50);
    expect(t.hrvBaseline, 50);
    expect(t.steps7dAvg, 3000);
  });

  test('fewer than five days: no baseline', () async {
    await seed({
      0: const HealthDay(restingHr: 60),
      for (var i = 1; i <= 4; i++) i: const HealthDay(restingHr: 50),
    });
    expect(c.read(healthTodayProvider).restingHrBaseline, isNull);
  });

  test('only yesterday cached: today values are all null', () async {
    await seed({
      for (var i = 1; i <= 6; i++)
        i: const HealthDay(
            restingHr: 50,
            hrv: 50,
            hrvKind: HrvKind.sdnn,
            steps: 4000,
            sleep: Duration(hours: 7)),
    });
    final t = c.read(healthTodayProvider);
    expect(t.restingHr, isNull);
    expect(t.hrv, isNull);
    expect(t.hrvKind, isNull);
    expect(t.stepsToday, isNull);
  });

  test('HRV baseline never mixes kinds', () async {
    await seed({
      0: const HealthDay(hrv: 40, hrvKind: HrvKind.rmssd),
      for (var i = 1; i <= 5; i++)
        i: const HealthDay(hrv: 80, hrvKind: HrvKind.sdnn),
    });
    var t = c.read(healthTodayProvider);
    expect(t.hrvKind, HrvKind.rmssd);
    expect(t.hrvBaseline, isNull);
    await c
        .read(healthDailyStoreProvider)
        .put(key(6), const HealthDay(hrv: 30, hrvKind: HrvKind.rmssd));
    for (var i = 7; i <= 10; i++) {
      await c
          .read(healthDailyStoreProvider)
          .put(key(i), const HealthDay(hrv: 30, hrvKind: HrvKind.rmssd));
    }
    c.invalidate(healthDailyStoreProvider);
    t = c.read(healthTodayProvider);
    expect(t.hrvBaseline, 30);
  });

  test('clearLocalData and reload empty the store and the connection',
      () async {
    await c.read(healthConnectionProvider.notifier).connect();
    expect(c.read(healthDailyStoreProvider).day(key(0)), isNotNull);

    final session = AppSession(prefs);
    await session.clearLocalData();
    session.reload();

    // The app rebuilds its ProviderScope on reload: a fresh container.
    final c2 = make();
    expect(c2.read(healthConnectionProvider).connected, isFalse);
    expect(c2.read(healthConnectionProvider).lastReadAt, isNull);
    expect(c2.read(healthDailyStoreProvider).day(key(0)), isNull);
    expect(
        c2.read(healthDailyStoreProvider).lastDays(60, DateTime(2026, 10, 23)),
        isEmpty);
    expect(c2.read(healthTodayProvider).restingHr, isNull);
  });
}
