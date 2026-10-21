import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitrix/core/session/session_providers.dart';
import 'package:fitrix/core/sync/collections.dart';
import 'package:fitrix/core/sync/sync_local.dart';
import 'package:fitrix/core/sync/sync_state.dart';
import 'package:fitrix/features/running/data/run_store.dart';
import 'package:fitrix/features/running/data/run_track.dart';
import 'package:fitrix/features/workouts/data/doc_rpe.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/features/workouts/presentation/providers/workouts_provider.dart';

final t0 = DateTime.utc(2026, 10, 1, 7);

RunDetails details({int? rpe}) => RunDetails(
      startedAt: t0,
      moving: const Duration(minutes: 30),
      elapsed: const Duration(minutes: 31),
      pauses: 0,
      meters: 5000,
      splits: const [],
      route: const [
        [51.1, -0.1],
        [51.2, -0.2],
      ],
      rpe: rpe,
    );

CompletedWorkout workout(String id) => CompletedWorkout(
      id: id,
      templateId: 'free_run',
      name: 'Run',
      sport: Sport.running,
      startedAt: t0,
      finishedAt: t0.add(const Duration(minutes: 30)),
      exercises: const [],
    );

Future<ProviderContainer> container(
    [Map<String, Object> initial = const {}]) async {
  SharedPreferences.setMockInitialValues(initial);
  final prefs = await SharedPreferences.getInstance();
  final c = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
  addTearDown(c.dispose);
  return c;
}

void main() {
  test('put, all and remove persist across store instances', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    RunStore(prefs).put('a', details(rpe: 5));
    RunStore(prefs).put('b', details());
    expect(RunStore(prefs).all().keys, {'a', 'b'});
    expect(RunStore(prefs).all()['a']!.rpe, 5);
    RunStore(prefs).remove('a');
    expect(RunStore(prefs).all().keys, {'b'});
    RunStore(prefs).clear();
    expect(RunStore(prefs).all(), isEmpty);
  });

  test('a corrupt store reads as empty', () async {
    SharedPreferences.setMockInitialValues({'runs_v1': 'not json'});
    final prefs = await SharedPreferences.getInstance();
    expect(RunStore(prefs).all(), isEmpty);
  });

  test('RunCollection reads and applies docs', () async {
    final c = await container();
    final col = RunCollection(c.read(_refProvider));
    expect(col.kind, 'run');
    c.read(runStoreProvider).put('r1', details(rpe: 6));
    final docs = col.read();
    expect(docs.keys, {'r1'});

    final other = await container();
    RunCollection(other.read(_refProvider)).apply({
      'r1': docs['r1'],
      'bad': {'nonsense': true},
    });
    expect(other.read(runStoreProvider).all().keys, {'r1'});
    expect(other.read(runsProvider).keys, {'r1'});
    RunCollection(other.read(_refProvider)).apply({'r1': null});
    expect(other.read(runStoreProvider).all(), isEmpty);
  });

  test('removing a run records the deletion for sync', () async {
    final c = await container();
    c.read(runsProvider.notifier).put('r1', details());
    c.read(runsProvider.notifier).remove('r1');
    expect(c.read(runsProvider), isEmpty);
    final state = SyncState.load(c.read(sharedPreferencesProvider));
    expect(state.docTombstones.keys, contains('run/r1'));
  });

  test('a pulled run doc sets the RPE on its workout', () async {
    final c = await container();
    c.read(workoutHistoryProvider.notifier).add(workout('w1'));
    c.read(workoutHistoryProvider.notifier).add(workout('w2'));
    final doc = (await _docFor(details(rpe: 8)));
    RunCollection(c.read(_refProvider)).apply({'w1': doc});
    final h = c.read(workoutHistoryProvider);
    expect(h.firstWhere((w) => w.id == 'w1').sessionRpe, 8);
    expect(h.firstWhere((w) => w.id == 'w2').sessionRpe, isNull);
  });

  test('a history pull after the doc also ends with the RPE', () async {
    final c = await container();
    RunCollection(c.read(_refProvider))
        .apply({'w1': await _docFor(details(rpe: 8))});
    // The workout arrives afterwards, as a synced history list.
    SyncLocal(c.read(_refProvider)).applyHistory([workout('w1')]);
    expect(c.read(workoutHistoryProvider).single.sessionRpe, 8);
  });

  test('the overlay does nothing when the RPE already matches', () async {
    final c = await container();
    c.read(runStoreProvider).put('w1', details(rpe: 8));
    c
        .read(workoutHistoryProvider.notifier)
        .applySynced([workout('w1').copyWith(sessionRpe: 8)]);
    final before = c.read(workoutHistoryProvider);
    applyDocRpe(c.read(_refProvider));
    expect(identical(c.read(workoutHistoryProvider), before), isTrue);
  });
}

final _refProvider = Provider<Ref>((ref) => ref);

Future<Map<String, Object?>> _docFor(RunDetails d) async => d.toJson();
