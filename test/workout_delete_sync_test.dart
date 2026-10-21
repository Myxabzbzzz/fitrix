import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitrix/core/session/session_providers.dart';
import 'package:fitrix/core/sync/sync_engine.dart';
import 'package:fitrix/core/sync/sync_providers.dart';
import 'package:fitrix/features/workouts/data/deleted_workouts_store.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/features/workouts/presentation/providers/workouts_provider.dart';

import 'support/in_memory_remote_store.dart';

CompletedWorkout finished(String id, DateTime at) => CompletedWorkout(
      id: id,
      templateId: 'gym-chest-biceps',
      name: 'Chest and Biceps',
      sport: Sport.gym,
      startedAt: at.subtract(const Duration(hours: 1)),
      finishedAt: at,
      exercises: const [],
    );

class Device {
  Device(this.prefs, this.container);
  final SharedPreferences prefs;
  final ProviderContainer container;

  SyncEngine get engine => container.read(syncEngineProvider)!;
  Future<void> sync() => engine.sync();
  WorkoutHistoryNotifier get history =>
      container.read(workoutHistoryProvider.notifier);
  List<String> get ids =>
      [for (final w in container.read(workoutHistoryProvider)) w.id];
}

Future<Device> newDevice(InMemoryRemoteStore remote) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    remoteStoreProvider.overrideWithValue(remote),
    syncUserIdProvider.overrideWithValue('u1'),
  ]);
  addTearDown(container.dispose);
  return Device(prefs, container);
}

final at = DateTime.utc(2026, 10, 1, 12);

void main() {
  late InMemoryRemoteStore remote;
  setUp(() => remote = InMemoryRemoteStore());

  test('deleting a workout removes it from the cloud and other devices',
      () async {
    final a = await newDevice(remote);
    final b = await newDevice(remote);
    a.history.add(finished('x', at));
    a.history.add(finished('y', at.add(const Duration(days: 1))));
    await a.sync();
    await b.sync();
    expect(b.ids, containsAll(['x', 'y']));

    a.history.remove('x');
    await a.sync();
    expect(remote.historyOf('u1').map((w) => w.id), ['y']);
    expect(
        remote.docsOf('u1').map((d) => d.key), contains('workout_deleted/x'));

    await b.sync();
    expect(b.ids, ['y']);
    expect(b.container.read(deletedWorkoutsStoreProvider).ids(), {'x'});
    await b.sync();
    expect(b.ids, ['y'], reason: 'stays gone');
  });

  test('a fresh device never gets a deleted workout, even if the row stayed',
      () async {
    final a = await newDevice(remote);
    a.history.add(finished('x', at));
    await a.sync();
    remote.failDeleteHistory = true;
    a.history.remove('x');
    await a.sync();
    expect(remote.historyOf('u1').map((w) => w.id), ['x'],
        reason: 'the row delete failed');

    final c = await newDevice(remote);
    await c.sync();
    expect(c.ids, isEmpty);
    expect(c.container.read(deletedWorkoutsStoreProvider).ids(), {'x'});
  });

  test('a failed row delete is retried on the next sync, once it works',
      () async {
    final a = await newDevice(remote);
    a.history.add(finished('x', at));
    await a.sync();
    remote.failDeleteHistory = true;
    a.history.remove('x');
    await a.sync();
    expect(remote.docsOf('u1').map((d) => d.key), contains('workout_deleted/x'),
        reason: 'other channels still ran');

    remote.failDeleteHistory = false;
    await a.sync();
    expect(remote.historyOf('u1'), isEmpty);
    final calls = remote.deleteHistoryCalls;
    await a.sync();
    expect(remote.deleteHistoryCalls, calls, reason: 'deleted once');
  });

  test('removing an id twice is a no-op', () async {
    final a = await newDevice(remote);
    a.history.add(finished('x', at));
    a.history.remove('x');
    a.history.remove('x');
    a.history.remove('never-existed');
    expect(a.ids, isEmpty);
    expect(a.container.read(deletedWorkoutsStoreProvider).ids(), {'x'});
  });

  test('the store keeps ids in prefs and clear empties it', () async {
    SharedPreferences.setMockInitialValues({});
    final store = DeletedWorkoutsStore(await SharedPreferences.getInstance());
    store.add('a', DateTime.utc(2026, 10, 1));
    store.add('a', DateTime.utc(2026, 10, 2));
    expect(store.ids(), {'a'});
    store.clear();
    expect(store.ids(), isEmpty);
  });
}
