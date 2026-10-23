import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitrix/core/session/session_providers.dart';
import 'package:fitrix/core/theme/app_theme.dart';
import 'package:fitrix/core/time/today_provider.dart';
import 'package:fitrix/features/health/data/health_import_store.dart';
import 'package:fitrix/features/health/data/health_source.dart';
import 'package:fitrix/features/health/domain/health_math.dart';
import 'package:fitrix/features/health/presentation/providers/health_providers.dart';
import 'package:fitrix/features/progress/data/body_weight_store.dart';
import 'package:fitrix/features/progress/presentation/providers/progress_providers.dart';
import 'package:fitrix/features/running/data/run_store.dart';
import 'package:fitrix/features/running/presentation/screens/run_summary_screen.dart';
import 'package:fitrix/features/running/presentation/screens/running_screen.dart';
import 'package:fitrix/features/running/presentation/widgets/run_history_list.dart';
import 'package:fitrix/features/workouts/data/deleted_workouts_store.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/features/workouts/presentation/providers/workouts_provider.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';
import 'package:flutter_map/flutter_map.dart';

import 'support/fake_health_source.dart';
import 'support/overflow.dart';

HealthWorkoutRecord _rec(
  String uuid, {
  String activity = 'RUNNING',
  DateTime? from,
  int minutes = 30,
  double? meters = 5200,
  double? kcal = 310,
  String sourceId = 'com.apple.health.watch',
  String sourceName = 'Apple Watch',
}) {
  final f = from ?? DateTime(2026, 10, 22, 18);
  return HealthWorkoutRecord(
    uuid: uuid,
    activity: activity,
    from: f,
    to: f.add(Duration(minutes: minutes)),
    meters: meters,
    kcal: kcal,
    sourceId: sourceId,
    sourceName: sourceName,
  );
}

HealthSample _hr(DateTime at, double v) => HealthSample(
    uuid: 'hr${at.microsecondsSinceEpoch}',
    from: at,
    to: at,
    value: v,
    sourceId: 'w',
    sourceName: 'Apple Watch');

HealthSample _kg(DateTime at, double v,
        {String sourceId = 'com.mi', String name = 'Mi Fitness'}) =>
    HealthSample(
        uuid: 'kg${at.microsecondsSinceEpoch}',
        from: at,
        to: at,
        value: v,
        sourceId: sourceId,
        sourceName: name);

void main() {
  late SharedPreferences prefs;
  late FakeHealthSource fake;
  late ProviderContainer c;

  Future<void> setUpC([Map<String, Object> initial = const {}]) async {
    SharedPreferences.setMockInitialValues({
      'user_name': 'Alex',
      'user_weight': '78.4',
      'performance_profile_v1': '{"sex":"male"}',
      ...initial,
    });
    prefs = await SharedPreferences.getInstance();
    fake = FakeHealthSource();
    c = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      healthSourceProvider.overrideWithValue(fake),
      clockProvider.overrideWithValue(() => DateTime(2026, 10, 23, 10)),
    ]);
    addTearDown(c.dispose);
  }

  Future<void> importAll() async {
    for (final i in c.read(healthImportersProvider)) {
      await i.run(fake, DateTime(2026, 9, 23), DateTime(2026, 10, 23, 10));
    }
  }

  setUp(() => setUpC());

  group('workouts', () {
    test('a watch run becomes a running workout with import and run doc',
        () async {
      fake.workoutRecords = [_rec('r1')];
      fake.heartRateSamples = [
        _hr(DateTime(2026, 10, 22, 17, 59), 200), // before: ignored
        _hr(DateTime(2026, 10, 22, 18, 10), 140),
        _hr(DateTime(2026, 10, 22, 18, 20), 151),
        _hr(DateTime(2026, 10, 22, 18, 31), 200), // after: ignored
      ];
      await importAll();

      final id = importedWorkoutId(HealthPlatform.appleHealth, 'r1');
      final w = c.read(workoutHistoryProvider).single;
      expect(w.id, id);
      expect(w.sport, Sport.running);
      expect(w.duration, const Duration(minutes: 30));
      expect(w.exercises, isEmpty);
      expect(w.sessionRpe, isNull);
      expect(w.loadEstimated, isTrue);
      expect(w.name, 'Running');

      final imp = c.read(healthImportsProvider)[id]!;
      expect(imp.source, 'Apple Watch');
      expect(imp.healthUuid, 'r1');
      expect(imp.meters, 5200);
      expect(imp.avgHr, 146); // 145.5 rounds to 146
      expect(imp.kcal, 310);

      final run = c.read(runsProvider)[id]!;
      expect(run.meters, 5200);
      expect(run.route, isEmpty);
      expect(run.splits, isEmpty);
      expect(run.moving, const Duration(minutes: 30));
      expect(run.elapsed, const Duration(minutes: 30));
    });

    test('reading again adds nothing', () async {
      fake.workoutRecords = [_rec('r1'), _rec('c1', activity: 'BIKING')];
      await importAll();
      await importAll();
      expect(c.read(workoutHistoryProvider), hasLength(2));
      expect(c.read(healthImportsProvider), hasLength(2));
      expect(c.read(runsProvider), hasLength(1));
    });

    test('a second device / new container produces the same id', () async {
      fake.workoutRecords = [_rec('r1')];
      await importAll();
      final first = c.read(workoutHistoryProvider).single.id;
      await setUpC();
      fake.workoutRecords = [_rec('r1')];
      await importAll();
      expect(c.read(workoutHistoryProvider).single.id, first);
    });

    test(
        'zero distance and energy (iOS) are unknown, no avg HR without samples',
        () async {
      fake.workoutRecords = [_rec('r1', meters: 0, kcal: 0)];
      await importAll();
      final imp = c.read(healthImportsProvider).values.single;
      expect(imp.meters, isNull);
      expect(imp.kcal, isNull);
      expect(imp.avgHr, isNull);
    });

    test('FITRIX own records are skipped', () async {
      fake.workoutRecords = [_rec('r1', sourceId: fitrixHealthSourceId)];
      await importAll();
      expect(c.read(workoutHistoryProvider), isEmpty);
    });

    test('a record overlapping a FITRIX run is skipped', () async {
      c.read(workoutHistoryProvider.notifier).add(CompletedWorkout(
            templateId: 'free_run',
            name: 'Run',
            sport: Sport.running,
            startedAt: DateTime(2026, 10, 22, 18, 1),
            finishedAt: DateTime(2026, 10, 22, 18, 29),
            exercises: const [],
          ));
      fake.workoutRecords = [
        _rec('r1'),
        // different sport at the same time is kept
        _rec('c1', activity: 'BIKING'),
      ];
      await importAll();
      final ws = c.read(workoutHistoryProvider);
      expect(ws, hasLength(2));
      expect(ws.where((w) => w.sport == Sport.running), hasLength(1));
      expect(c.read(healthImportsProvider), hasLength(1));
    });

    test('an imported workout does not block another import', () async {
      fake.workoutRecords = [
        _rec('r1', sourceName: 'Apple Watch'),
        _rec('r2', sourceName: 'Garmin Connect', sourceId: 'com.garmin'),
      ];
      await importAll();
      expect(c.read(workoutHistoryProvider), hasLength(2));
    });

    test('a deleted imported workout is not imported again', () async {
      fake.workoutRecords = [_rec('r1')];
      await importAll();
      final id = c.read(workoutHistoryProvider).single.id;
      c.read(workoutHistoryProvider.notifier).remove(id);
      expect(c.read(deletedWorkoutsStoreProvider).deletedAt(id), isNotNull);
      await importAll();
      expect(c.read(workoutHistoryProvider), isEmpty);
    });

    test('sport mapping and names', () async {
      fake.workoutRecords = [
        _rec('a', activity: 'BIKING', sourceName: 'Garmin Connect'),
        _rec('b', activity: 'SOCCER', from: DateTime(2026, 10, 21, 18)),
        _rec('d', activity: 'YOGA', from: DateTime(2026, 10, 20, 18)),
      ];
      await importAll();
      final bySport = {
        for (final w in c.read(workoutHistoryProvider)) w.sport: w
      };
      expect(bySport.keys, {Sport.cycling, Sport.football, Sport.fitness});
      expect(bySport[Sport.football]!.name, 'Football');
      expect(bySport[Sport.cycling]!.name, 'Cycling');
      // Not a run: no run doc.
      expect(c.read(runsProvider), isEmpty);
    });

    test('a failing read imports nothing (HealthSync swallows the throw)',
        () async {
      fake.throwOnRead = true;
      await expectLater(importAll(), throwsStateError);
      expect(c.read(workoutHistoryProvider), isEmpty);
    });

    test('health_import docs survive a restart and drop on remove', () async {
      fake.workoutRecords = [_rec('r1')];
      await importAll();
      final id = c.read(workoutHistoryProvider).single.id;
      final again = ProviderContainer(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
      addTearDown(again.dispose);
      expect(again.read(healthImportsProvider).keys, [id]);
      again.read(healthImportsProvider.notifier).remove(id);
      expect(again.read(healthImportsProvider), isEmpty);
    });
  });

  group('weight', () {
    test('a scale weigh-in lands in history and updates the profile', () async {
      fake.weightSamples = [_kg(DateTime(2026, 10, 22, 7, 30), 81.4)];
      await importAll();
      final w = c.read(bodyWeightProvider).single;
      expect(w.kg, 81.4);
      expect(w.at.day, 22);
      expect(prefs.getString('user_weight'), '81.4');
    });

    test('latest sample of the day wins; FITRIX and out-of-range skipped',
        () async {
      fake.weightSamples = [
        _kg(DateTime(2026, 10, 22, 7), 81.0),
        _kg(DateTime(2026, 10, 22, 21), 81.6),
        _kg(DateTime(2026, 10, 22, 22), 70,
            sourceId: fitrixHealthSourceId, name: 'FITRIX'),
        _kg(DateTime(2026, 10, 21, 7), 5),
      ];
      await importAll();
      expect(c.read(bodyWeightProvider).map((e) => e.kg), [81.6]);
    });

    test('a manual entry the same day is kept', () async {
      await c
          .read(bodyWeightProvider.notifier)
          .log(WeighIn(at: DateTime(2026, 10, 22, 9), kg: 80));
      fake.weightSamples = [_kg(DateTime(2026, 10, 22, 7, 30), 81.4)];
      await importAll();
      expect(c.read(bodyWeightProvider).map((e) => e.kg), [80]);
      expect(prefs.getString('user_weight'), '80');
    });

    test('an older import does not override a newer profile weight', () async {
      await c
          .read(bodyWeightProvider.notifier)
          .log(WeighIn(at: DateTime(2026, 10, 22, 9), kg: 80));
      fake.weightSamples = [_kg(DateTime(2026, 10, 20, 7), 83)];
      await importAll();
      expect(c.read(bodyWeightProvider).map((e) => e.kg), [83, 80]);
      expect(prefs.getString('user_weight'), '80');
    });

    test('reading again changes nothing', () async {
      fake.weightSamples = [_kg(DateTime(2026, 10, 22, 7, 30), 81.4)];
      await importAll();
      await importAll();
      expect(c.read(bodyWeightProvider), hasLength(1));
    });
  });

  test('importers are registered', () async {
    expect(c.read(healthImportersProvider), hasLength(2));
  });

  group('screens', () {
    Widget host(Widget child, {double scale = 1}) => UncontrolledProviderScope(
          container: c,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: Scaffold(body: SingleChildScrollView(child: child)),
          ),
        );

    void se(WidgetTester t) {
      t.view.physicalSize = const Size(375, 667) * 3;
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
    }

    testWidgets('run history row shows the source name', (t) async {
      se(t);
      fake.workoutRecords = [_rec('r1')];
      await importAll();
      await t.pumpWidget(host(
          Consumer(
              builder: (_, ref, __) =>
                  RunHistoryList(runs: ref.watch(runHistoryProvider))),
          scale: 1.3));
      await t.pumpAndSettle();
      expect(find.textContaining('Apple Watch'), findsOneWidget);
      expectNoOverflow(t);
    });

    testWidgets('imported run summary has no map and does not crash',
        (t) async {
      se(t);
      fake.workoutRecords = [_rec('r1')];
      await importAll();
      final id = c.read(workoutHistoryProvider).single.id;
      await t.pumpWidget(UncontrolledProviderScope(
        container: c,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.3)),
            child: child!,
          ),
          home: RunSummaryScreen(id: id),
        ),
      ));
      await t.pumpAndSettle();
      expect(find.byType(FlutterMap), findsNothing);
      expect(find.text('No route recorded'), findsNothing);
      expect(find.textContaining('Apple Watch'), findsOneWidget);
      expectNoOverflow(t);
    });
  });
}
