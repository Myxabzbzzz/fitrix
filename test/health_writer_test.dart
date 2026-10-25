import 'dart:async';

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

class _SlowWrite extends FakeHealthSource {
  final gate = Completer<void>();
  final entered = Completer<void>();

  @override
  Future<bool> writeWorkout({
    required String activity,
    required DateTime from,
    required DateTime to,
    double? meters,
    String? title,
  }) async {
    entered.complete();
    await gate.future;
    return super.writeWorkout(
        activity: activity, from: from, to: to, meters: meters, title: title);
  }
}

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

  test('disconnected while the write runs: ledger untouched', () async {
    final gated = _SlowWrite();
    fake = gated;
    c = make();
    await connect();
    c.read(workoutHistoryProvider.notifier).add(_w('a'));
    await gated.entered.future;
    await c.read(healthConnectionProvider.notifier).disconnect();
    gated.gate.complete();
    await settle();
    expect(gated.written, hasLength(1));
    expect(prefs.containsKey(HealthWriter.key), isFalse);
    expect(prefs.containsKey(HealthWriter.timesKey), isFalse);
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

  test('a ride and a ski day carry their meters too', () async {
    await connect();
    for (final (id, sport, kind) in [
      ('b', Sport.cycling, ActivityKind.ride),
      ('s', Sport.winterSports, ActivityKind.ski),
    ]) {
      c.read(workoutHistoryProvider.notifier).add(_w(id, sport: sport));
      c.read(runsProvider.notifier).put(
          id,
          RunDetails(
            startedAt: DateTime(2026, 10, 23, 9),
            moving: const Duration(hours: 1),
            elapsed: const Duration(hours: 1),
            pauses: 0,
            meters: 20000,
            splits: const [],
            route: const [],
            kind: kind,
          ));
    }
    await settle();
    expect(fake.written.map((w) => w.meters), [20000, 20000]);
  });

  test('a write is recorded with its time; old ids have none', () async {
    await connect();
    await prefs.setString(HealthWriter.key, '["legacy"]');
    c.read(workoutHistoryProvider.notifier).add(_w('a'));
    await settle();
    final t = DateTime(2000);
    expect(HealthWriter.writtenSince(prefs, t), 1);
    expect(HealthWriter.writtenSince(prefs, DateTime(2100)), 0);
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
