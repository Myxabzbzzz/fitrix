import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitrix/core/session/session_providers.dart';
import 'package:fitrix/features/health/data/health_source.dart';
import 'package:fitrix/features/health/data/health_import_store.dart';
import 'package:fitrix/features/health/data/health_writer.dart';
import 'package:fitrix/features/health/presentation/providers/health_providers.dart';
import 'package:fitrix/features/running/data/run_store.dart';
import 'package:fitrix/features/running/data/run_track.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/features/workouts/presentation/providers/workouts_provider.dart';

import 'support/fake_health_source.dart';

CompletedWorkout _w(String id,
        {Sport sport = Sport.gym,
        String name = 'Push day',
        String templateId = 't1'}) =>
    CompletedWorkout(
      id: id,
      templateId: templateId,
      name: name,
      sport: sport,
      startedAt: DateTime(2026, 10, 23, 9),
      finishedAt: DateTime(2026, 10, 23, 10),
      exercises: const [],
    );

void main() {
  late SharedPreferences prefs;
  late FakeHealthSource fake;
  late ProviderContainer c;

  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 20));

  ProviderContainer make() {
    final cc = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      healthSourceProvider.overrideWithValue(fake),
    ]);
    addTearDown(cc.dispose);
    return cc;
  }

  Future<void> connect({bool write = true}) async {
    await c.read(healthConnectionProvider.notifier).connect();
    await c.read(healthConnectionProvider.notifier).setWriteWorkouts(write);
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    fake = FakeHealthSource();
    c = make();
  });

  test('activityForSport names', () {
    expect(activityForSport(Sport.gym), 'TRADITIONAL_STRENGTH_TRAINING');
    expect(activityForSport(Sport.fitness), 'OTHER');
    expect(activityForSport(Sport.cycling), 'BIKING');
    expect(activityForSport(Sport.running), 'RUNNING');
    expect(activityForSport(Sport.football), 'SOCCER');
    expect(activityForSport(Sport.winterSports), 'DOWNHILL_SKIING');
    const a = HealthPlatform.healthConnect;
    expect(activityForSport(Sport.gym, platform: a), 'STRENGTH_TRAINING');
    expect(activityForSport(Sport.football, platform: a), 'OTHER');
  });

  test('a gym workout is written once with its name', () async {
    await connect();
    c.read(workoutHistoryProvider.notifier).add(_w('a'));
    await settle();
    expect(fake.written, hasLength(1));
    final w = fake.written.single;
    expect(w.activity, 'TRADITIONAL_STRENGTH_TRAINING');
    expect(w.from, DateTime(2026, 10, 23, 9));
    expect(w.to, DateTime(2026, 10, 23, 10));
    expect(w.title, 'Push day');
    expect(w.meters, isNull);
  });

  test('a run carries the meters saved right after the workout', () async {
    await connect();
    c.read(workoutHistoryProvider.notifier).add(_w('r', sport: Sport.running));
    c.read(runsProvider.notifier).put(
        'r',
        RunDetails(
          startedAt: DateTime(2026, 10, 23, 9),
          moving: const Duration(hours: 1),
          elapsed: const Duration(hours: 1),
          pauses: 0,
          meters: 10234.6,
          splits: const [],
          route: const [],
        ));
    await settle();
    expect(fake.written.single.activity, 'RUNNING');
    expect(fake.written.single.meters, 10234.6);
  });

  test('toggle off, not connected: no write', () async {
    await connect(write: false);
    c.read(workoutHistoryProvider.notifier).add(_w('a'));
    await settle();
    expect(fake.written, isEmpty);

    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    c = make();
    c.read(workoutHistoryProvider.notifier).add(_w('b'));
    await settle();
    expect(fake.written, isEmpty);
  });

  test('synced-in and imported workouts are not written', () async {
    await connect();
    final n = c.read(workoutHistoryProvider.notifier);
    n.applySynced([_w('s')]);
    n.addImported(_w('i', templateId: healthImportTemplateId));
    await settle();
    expect(fake.written, isEmpty);
  });

  test('editing a logged workout (new id, old removed) does not write again',
      () async {
    await connect();
    final n = c.read(workoutHistoryProvider.notifier);
    n.add(_w('a'));
    await settle();
    // What the match log sheet does when the time or length changes.
    n.add(_w('b', name: 'Edited'), toHealth: false);
    n.remove('a');
    await settle();
    expect(fake.written, hasLength(1));

    // Also after a restart: the original id is still remembered.
    c = make();
    await connect();
    c.read(workoutHistoryProvider.notifier).add(_w('a'));
    await settle();
    expect(fake.written, hasLength(1));
  });

  test('false or throwing write: no crash, no retry, not remembered', () async {
    await connect();
    fake.writeResult = false;
    final n = c.read(workoutHistoryProvider.notifier);
    n.add(_w('a'));
    await settle();
    expect(fake.written, hasLength(1));

    fake.throwOnWrite = true;
    n.add(_w('b'));
    await settle();
    expect(fake.written, hasLength(2));
    await settle();
    expect(fake.written, hasLength(2));

    // Not remembered, so the next local add of the id is tried again.
    fake.throwOnWrite = false;
    fake.writeResult = true;
    n.add(_w('a'));
    await settle();
    expect(fake.written, hasLength(3));
  });

  test('the written ledger keeps the last 200 ids', () async {
    await connect();
    final n = c.read(workoutHistoryProvider.notifier);
    for (var i = 0; i < 205; i++) {
      n.add(_w('w$i'));
      await Future<void>.delayed(const Duration(milliseconds: 2));
    }
    expect(prefs.getString(HealthWriter.key)!.split(',').length, 200);
  });
}
