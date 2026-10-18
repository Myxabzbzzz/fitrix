import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitrix/core/session/session_providers.dart';
import 'package:fitrix/core/sync/doc_merge.dart';
import 'package:fitrix/core/sync/local_changes.dart';
import 'package:fitrix/core/sync/remote_store.dart';
import 'package:fitrix/core/sync/sync_engine.dart';
import 'package:fitrix/core/sync/sync_local.dart';
import 'package:fitrix/core/sync/sync_state.dart';
import 'package:fitrix/core/sync/synced_collection.dart';

import 'support/in_memory_remote_store.dart';

class FakeCollection extends SyncedCollection {
  FakeCollection(this.kind);

  @override
  final String kind;
  final docs = <String, Map<String, Object?>>{};
  final applied = <Map<String, Map<String, Object?>?>>[];
  bool cleared = false;

  @override
  Map<String, Map<String, Object?>> read() => {...docs};

  @override
  void apply(Map<String, Map<String, Object?>?> pulled) {
    applied.add(pulled);
    for (final e in pulled.entries) {
      final v = e.value;
      if (v == null) {
        docs.remove(e.key);
      } else {
        docs[e.key] = v;
      }
    }
  }

  @override
  void clear() {
    cleared = true;
    docs.clear();
  }
}

class TestLocal extends SyncLocal {
  TestLocal(super.ref, this._collections);
  final List<SyncedCollection> _collections;

  @override
  List<SyncedCollection> get collections => _collections;
}

class Rig {
  Rig(this.remote, this.prefs, this.container, this.local, this.engine);
  final InMemoryRemoteStore remote;
  final SharedPreferences prefs;
  final ProviderContainer container;
  final TestLocal local;
  final SyncEngine engine;

  SyncState get state => SyncState.load(prefs);
}

Future<Rig> rig(
  InMemoryRemoteStore remote,
  List<SyncedCollection> collections,
) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
  ]);
  addTearDown(container.dispose);
  final local = TestLocal(container.read(Provider((ref) => ref)), collections);
  final engine = SyncEngine(
    local: local,
    remote: remote,
    userId: 'u1',
    pollInterval: null,
    pullOverlap: Duration.zero,
  );
  addTearDown(engine.dispose);
  final r = Rig(remote, prefs, container, local, engine);
  // Settle the built-in plans, so pending counts below are about documents.
  await engine.sync();
  remote.requests = 0;
  return r;
}

Map<String, Object?> doc(String v) => {'v': v};

void main() {
  late InMemoryRemoteStore remote;
  late FakeCollection food;
  late FakeCollection water;

  setUp(() {
    remote = InMemoryRemoteStore();
    food = FakeCollection('food');
    water = FakeCollection('water');
  });

  test('first sync pushes all local docs, the second pushes nothing', () async {
    final r = await rig(remote, [food, water]);
    food.docs['a'] = doc('1');
    water.docs['2026-10-19'] = doc('2');
    expect(r.engine.pendingCount(), 2);

    await r.engine.sync();
    expect(remote.docsOf('u1').map((d) => d.key).toSet(),
        {'food/a', 'water/2026-10-19'});
    expect(r.engine.pendingCount(), 0);

    final stamps = {for (final d in remote.docsOf('u1')) d.key: d.updatedAt};
    await r.engine.sync();
    expect({for (final d in remote.docsOf('u1')) d.key: d.updatedAt}, stamps);
  });

  test('remote change applies when local is clean', () async {
    food.docs['a'] = doc('1');
    final r = await rig(remote, [food]);
    await r.engine.sync();

    remote.putDoc('u1', 'food', 'a', doc('2'));
    remote.putDoc('u1', 'food', 'b', doc('3'));
    await r.engine.sync();
    expect(food.docs, {'a': doc('2'), 'b': doc('3')});
    expect(r.engine.pendingCount(), 0);
  });

  test('remote change is ignored when local is dirty, and local wins',
      () async {
    food.docs['a'] = doc('1');
    final r = await rig(remote, [food]);
    await r.engine.sync();

    food.docs['a'] = doc('mine');
    remote.putDoc('u1', 'food', 'a', doc('theirs'));
    await r.engine.sync();
    expect(food.docs['a'], doc('mine'));
    expect(remote.docsOf('u1').singleWhere((d) => d.docId == 'a').data,
        doc('mine'));
    expect(r.engine.pendingCount(), 0);
  });

  test('local delete pushes a deleted row and clears the tombstone', () async {
    food.docs['a'] = doc('1');
    final r = await rig(remote, [food]);
    await r.engine.sync();

    food.docs.remove('a');
    r.local.recordDocDeleted('food', 'a');
    expect(r.engine.pendingCount(), 1);
    await r.engine.sync();
    final row = remote.docsOf('u1').single;
    expect(row.isDeleted, isTrue);
    expect(r.state.docTombstones, isEmpty);
    expect(r.engine.pendingCount(), 0);
  });

  test('recordDocDeleted pings local changes', () async {
    final r = await rig(remote, [food]);
    var pings = 0;
    r.container.read(localChangesProvider).stream.listen((_) => pings++);
    r.local.recordDocDeleted('food', 'a');
    expect(pings, 1);
  });

  test('remote delete is applied as null', () async {
    food.docs['a'] = doc('1');
    final r = await rig(remote, [food]);
    await r.engine.sync();

    remote.putDoc('u1', 'food', 'a', null);
    await r.engine.sync();
    expect(food.applied.last, {'a': null});
    expect(food.docs, isEmpty);
    expect(r.engine.pendingCount(), 0);
  });

  test('a doc edited while its push is in flight is pushed again', () async {
    final r = await rig(remote, [food]);
    food.docs['a'] = doc('1');
    remote.upsertDocsHold = Completer<void>();
    final sync = r.engine.sync();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    food.docs['a'] = doc('edited');
    remote.upsertDocsHold!.complete();
    remote.upsertDocsHold = null;
    await sync; // the loop does not rerun: no change ping, so run again
    expect(remote.docsOf('u1').single.data, doc('1'));
    expect(r.engine.pendingCount(), 1);

    await r.engine.sync();
    expect(remote.docsOf('u1').single.data, doc('edited'));
    expect(r.engine.pendingCount(), 0);
  });

  test('a row of an unknown kind is skipped, the rest applies', () async {
    remote.putDoc('u1', 'hologram', 'x', doc('?'));
    remote.putDoc('u1', 'food', 'a', doc('1'));
    final r = await rig(remote, [food]);
    await r.engine.sync();
    expect(food.docs, {'a': doc('1')});
    expect(r.state.docs.keys, ['food/a']);
    expect(r.engine.status.value.error, isNull);
  });

  test('pendingCount includes dirty docs and tombstones', () async {
    food.docs['a'] = doc('1');
    food.docs['b'] = doc('2');
    final r = await rig(remote, [food]);
    await r.engine.sync();
    food.docs['a'] = doc('changed');
    food.docs.remove('b');
    r.local.recordDocDeleted('food', 'b');
    expect(r.engine.pendingCount(), 2);
  });

  test('agreed hashes of docs pruned locally are dropped, no delete pushed',
      () async {
    water.docs['d1'] = doc('1');
    water.docs['d2'] = doc('2');
    final r = await rig(remote, [water]);
    await r.engine.sync();
    expect(r.state.docs.length, 2);

    water.docs.remove('d1'); // the store pruned an old day
    await r.engine.sync();
    expect(r.state.docs.keys, ['water/d2']);
    expect(remote.docsOf('u1').length, 2);
    expect(remote.docsOf('u1').every((d) => !d.isDeleted), isTrue);
    expect(r.engine.pendingCount(), 0);
  });

  test('old saved state without document fields still loads', () async {
    SharedPreferences.setMockInitialValues({
      SyncState.storageKey:
          '{"owner":"u1","plans":{},"history":["h"],"chat":[]}',
    });
    final prefs = await SharedPreferences.getInstance();
    final state = SyncState.load(prefs);
    expect(state.owner, 'u1');
    expect(state.history, {'h'});
    expect(state.docs, isEmpty);
    expect(state.docTombstones, isEmpty);
    expect(state.docsCursor, isNull);
  });

  test('mergeDocs: dirty docs keep local, clean ones take remote', () {
    final remoteDocs = [
      RemoteDoc(
          kind: 'k', docId: 'dirty', data: doc('r'), updatedAt: DateTime(2026)),
      RemoteDoc(
          kind: 'k', docId: 'clean', data: doc('r'), updatedAt: DateTime(2026)),
    ];
    final result = mergeDocs(
      local: {'dirty': doc('l'), 'clean': doc('old')},
      agreed: {'dirty': docHash(doc('x')), 'clean': docHash(doc('old'))},
      tombstones: {},
      remote: remoteDocs,
    );
    expect(result.apply, {'clean': doc('r')});
    expect(result.agreed['clean'], docHash(doc('r')));
    expect(result.agreed['dirty'], docHash(doc('x')));
  });
}
