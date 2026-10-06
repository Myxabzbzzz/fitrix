import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitrix/core/session/session_providers.dart';
import 'package:fitrix/core/sync/remote_store.dart';
import 'package:fitrix/core/sync/sync_engine.dart';
import 'package:fitrix/core/sync/sync_merge.dart';
import 'package:fitrix/core/sync/sync_providers.dart';
import 'package:fitrix/core/sync/sync_state.dart';
import 'package:fitrix/features/chat/data/models/assistant_topic.dart';
import 'package:fitrix/features/chat/data/models/chat_message.dart';
import 'package:fitrix/features/chat/data/services/chat_api_service.dart';
import 'package:fitrix/features/chat/presentation/providers/chat_provider.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/features/workouts/data/workout_catalog.dart';
import 'package:fitrix/features/workouts/data/workout_storage.dart';
import 'package:fitrix/features/workouts/presentation/providers/workouts_provider.dart';

import 'support/in_memory_remote_store.dart';

WorkoutTemplate plan(
  String id, {
  String? name,
  DateTime? updatedAt,
  DateTime? deletedAt,
}) =>
    WorkoutTemplate(
      id: id,
      sport: Sport.gym,
      name: name ?? id,
      focus: 'Upper body',
      estimatedDuration: const Duration(hours: 1),
      exercises: const [],
      updatedAt: updatedAt,
      deletedAt: deletedAt,
    );

RemotePlan remotePlan(
  String id, {
  String? name,
  required DateTime at,
  bool deleted = false,
  int position = 0,
}) =>
    RemotePlan(
      plan(id, name: name, updatedAt: at, deletedAt: deleted ? at : null),
      position: position,
    );

/// A version both sides agreed on at [at].
PlanVersion agreed(DateTime at) =>
    PlanVersion(local: micros(at), server: micros(at)!);

final t0 = DateTime.utc(2026, 10, 1, 12);
DateTime t(int minutes) => t0.add(Duration(minutes: minutes));

ChatMessage message(String id, DateTime at, {String? text}) => ChatMessage(
      id: id,
      content: text ?? id,
      sender: MessageSender.user,
      timestamp: at,
    );

CompletedWorkout finished(String id, DateTime at) => CompletedWorkout(
      id: id,
      templateId: 'gym-chest-biceps',
      name: 'Chest and Biceps',
      sport: Sport.gym,
      startedAt: at.subtract(const Duration(hours: 1)),
      finishedAt: at,
      exercises: const [],
    );

/// One app install: its own storage and provider container.
class Device {
  Device(this.prefs, this.container);

  final SharedPreferences prefs;
  final ProviderContainer container;

  T read<T>(ProviderListenable<T> provider) => container.read(provider);

  SyncEngine get engine => container.read(syncEngineProvider)!;
  Future<void> sync() => engine.sync();
  SyncStatus get status => container.read(syncStatusProvider);

  List<String> get planNames =>
      [for (final p in read(workoutTemplatesProvider)) p.name];

  List<ChatMessage> storedChat(AssistantTopic topic) {
    final raw = prefs.getString(topic.historyKey);
    return raw == null ? [] : ChatMessage.decodeMessages(raw);
  }
}

ProviderContainer _container(
  SharedPreferences prefs,
  InMemoryRemoteStore remote,
  String? userId,
) {
  final container = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    remoteStoreProvider.overrideWithValue(remote),
    syncUserIdProvider.overrideWithValue(userId),
  ]);
  addTearDown(container.dispose);
  return container;
}

/// A fresh install. (Each call gets its own SharedPreferences instance:
/// resetting the mock gives a new instance, earlier ones keep their data.)
Future<Device> newDevice(
  InMemoryRemoteStore remote, {
  String? userId = 'u1',
  Map<String, Object> stored = const {},
}) async {
  SharedPreferences.setMockInitialValues(stored);
  final prefs = await SharedPreferences.getInstance();
  return Device(prefs, _container(prefs, remote, userId));
}

/// The same install after an app restart (or after signing in).
Device restart(Device device, InMemoryRemoteStore remote, {String? userId}) {
  device.container.dispose();
  return Device(device.prefs, _container(device.prefs, remote, userId));
}

void main() {
  group('mergePlans', () {
    test('a plan without local changes takes the server version', () {
      final merge = mergePlans(
        local: [plan('a', name: 'Old', updatedAt: t(0))],
        tombstones: const [],
        versions: {'a': agreed(t(0))},
        remote: [remotePlan('a', name: 'New', at: t(5))],
      );
      expect(merge.plans.single.name, 'New');
      expect(merge.changed, isTrue);
      expect(merge.versions['a']!.server, micros(t(5)));
      expect(isPlanDirty(merge.plans.single, merge.versions), isFalse);
    });

    test('changed on both sides: the later change wins', () {
      final versions = {'a': agreed(t(0))};
      final mineLater = mergePlans(
        local: [plan('a', name: 'Mine', updatedAt: t(10))],
        tombstones: const [],
        versions: versions,
        remote: [remotePlan('a', name: 'Theirs', at: t(5))],
      );
      expect(mineLater.plans.single.name, 'Mine');
      expect(isPlanDirty(mineLater.plans.single, mineLater.versions), isTrue,
          reason: 'still to be pushed');

      final theirsLater = mergePlans(
        local: [plan('a', name: 'Mine', updatedAt: t(5))],
        tombstones: const [],
        versions: versions,
        remote: [remotePlan('a', name: 'Theirs', at: t(10))],
      );
      expect(theirsLater.plans.single.name, 'Theirs');
      expect(
          isPlanDirty(theirsLater.plans.single, theirsLater.versions), isFalse);
    });

    test('a local edit wins if the server still has the synced version', () {
      // The device clock is behind: the edit looks older than the server
      // version, but nobody else changed the plan since the last sync.
      final merge = mergePlans(
        local: [plan('a', name: 'Edited', updatedAt: t(-60))],
        tombstones: const [],
        versions: {
          'a': PlanVersion(local: micros(t(-90)), server: micros(t(0))!),
        },
        remote: [remotePlan('a', name: 'Synced', at: t(0))],
      );
      expect(merge.plans.single.name, 'Edited');
    });

    test('built-in and pre-sync plans (no updatedAt) lose to the server', () {
      final merge = mergePlans(
        local: [plan('gym-chest-biceps', name: 'Built-in')],
        tombstones: const [],
        versions: const {},
        remote: [remotePlan('gym-chest-biceps', name: 'Edited', at: t(0))],
        fullPull: true,
      );
      expect(merge.plans.single.name, 'Edited');
    });

    test('deletions: a server tombstone removes an unchanged plan', () {
      final merge = mergePlans(
        local: [plan('a', updatedAt: t(0)), plan('b', updatedAt: t(0))],
        tombstones: const [],
        versions: {'a': agreed(t(0)), 'b': agreed(t(0))},
        remote: [remotePlan('a', at: t(5), deleted: true)],
      );
      expect([for (final p in merge.plans) p.id], ['b']);
      expect(merge.versions.containsKey('a'), isFalse);
      expect(merge.changed, isTrue);
    });

    test(
        'deletions: a local tombstone is kept until pushed, unless the '
        'server has a later edit', () {
      final tombstone = plan('a', updatedAt: t(10), deletedAt: t(10));
      final kept = mergePlans(
        local: const [],
        tombstones: [tombstone],
        versions: {'a': agreed(t(0))},
        remote: [remotePlan('a', at: t(5))],
      );
      expect(kept.plans, isEmpty);
      expect(kept.tombstones.single.id, 'a');

      final resurrected = mergePlans(
        local: const [],
        tombstones: [tombstone],
        versions: {'a': agreed(t(0))},
        remote: [remotePlan('a', name: 'Edited elsewhere', at: t(20))],
      );
      expect(resurrected.plans.single.name, 'Edited elsewhere');
      expect(resurrected.tombstones, isEmpty);
    });

    test(
        'new server plans are appended by position; unknown tombstones are '
        'ignored', () {
      final merge = mergePlans(
        local: [plan('mine', updatedAt: t(0))],
        tombstones: const [],
        versions: const {},
        remote: [
          remotePlan('second', at: t(1), position: 2),
          remotePlan('gone', at: t(1), deleted: true),
          remotePlan('first', at: t(1), position: 1),
        ],
      );
      expect([for (final p in merge.plans) p.id], ['mine', 'first', 'second']);
    });

    test('a full pull re-queues plans the server lost', () {
      final merge = mergePlans(
        local: [plan('a', updatedAt: t(0))],
        tombstones: const [],
        versions: {'a': agreed(t(0))},
        remote: const [],
        fullPull: true,
      );
      expect(isPlanDirty(merge.plans.single, merge.versions), isTrue);
      expect(merge.changed, isFalse);
    });
  });

  group('union merges', () {
    test('chat: union by id, ordered by time, stable for ties', () {
      final local = [message('a', t(0)), message('c', t(2))];
      final merge = unionById(
        local: local,
        remote: [message('b', t(1)), message('a', t(0), text: 'dup')],
        idOf: (m) => m.id,
        compare: (a, b) => a.timestamp.compareTo(b.timestamp),
      );
      expect([for (final m in merge.items) m.id], ['a', 'b', 'c']);
      expect(merge.items.first.content, 'a', reason: 'local copy kept');
      expect(merge.changed, isTrue);

      final same = unionById(
        local: local,
        remote: [message('c', t(2))],
        idOf: (m) => m.id,
        compare: (a, b) => a.timestamp.compareTo(b.timestamp),
      );
      expect(same.changed, isFalse);
      expect(identical(same.items, local), isTrue);
    });

    test('history: union by id, newest first', () {
      final merge = unionById(
        local: [finished('x', t(10))],
        remote: [finished('y', t(20)), finished('z', t(0))],
        idOf: (w) => w.id,
        compare: newestFirst,
      );
      expect([for (final w in merge.items) w.id], ['y', 'x', 'z']);
    });

    test('synced ids: a full pull replaces, an incremental one adds', () {
      expect(
          syncedAfterPull({'a', 'b'}, ['b', 'c'], fullPull: true), {'b', 'c'});
      expect(syncedAfterPull({'a'}, ['c'], fullPull: false), {'a', 'c'});
    });
  });

  group('legacy storage', () {
    final legacyPlan = {
      'id': 'p1',
      'sport': 'running',
      'name': '5K',
      'focus': 'Running',
      'estimatedMinutes': 30,
      'exercises': [],
    };
    final legacyWorkout = {
      'templateId': 'p1',
      'name': '5K',
      'sport': 'running',
      'startedAt': '2026-09-30T08:00:00.000',
      'finishedAt': '2026-09-30T08:30:00.000',
      'exercises': [],
    };

    test('plans without timestamps load with none', () {
      final p = WorkoutTemplate.fromJson(legacyPlan);
      expect(p.updatedAt, isNull);
      expect(p.deletedAt, isNull);
      expect(WorkoutTemplate.fromJson(p.toJson()).toJson(), p.toJson());
    });

    test('history without ids gets a stable UUID', () {
      final a = CompletedWorkout.fromJson(legacyWorkout);
      final b = CompletedWorkout.fromJson(legacyWorkout);
      expect(a.id, b.id);
      expect(a.id, matches(RegExp(r'^[0-9a-f-]{36}$')));
      expect(CompletedWorkout.fromJson(a.toJson()).id, a.id);
    });

    test('old data is uploaded on first sign-in, once', () async {
      final remote = InMemoryRemoteStore();
      final device = await newDevice(remote, stored: {
        'workout_templates': jsonEncode([legacyPlan]),
        'workout_history': jsonEncode([legacyWorkout]),
      });

      await device.sync();
      await restart(device, remote, userId: 'u1').sync();

      expect(remote.plansOf('u1').single.template.name, '5K');
      expect(remote.historyOf('u1'), hasLength(1));
      expect(remote.historyOf('u1').single.id,
          CompletedWorkout.fromJson(legacyWorkout).id);
    });
  });

  group('SyncEngine', () {
    test('local-only without a user or remote: no engine', () async {
      final device = await newDevice(InMemoryRemoteStore(), userId: null);
      expect(device.read(syncEngineProvider), isNull);
      expect(device.status.enabled, isFalse);
    });

    test('data made before signing in is uploaded', () async {
      final remote = InMemoryRemoteStore();
      var device = await newDevice(remote, userId: null);
      device.read(workoutTemplatesProvider.notifier).add(Sport.running, '5K');
      device.read(workoutHistoryProvider.notifier).add(finished('w1', t(0)));
      await device.read(chatRepositoryProvider).saveMessages([
        message('m1', t(0)),
      ]);

      device = restart(device, remote, userId: 'u1'); // signs in
      await device.sync();

      expect(remote.plansOf('u1').map((p) => p.template.name), contains('5K'));
      expect(remote.historyOf('u1').single.id, 'w1');
      expect(remote.chatOf('u1').single.topic, 'app');
      expect(device.status.pending, 0);
      expect(device.status.lastSyncedAt, isNotNull);
    });

    test('two devices end up with the same plans, history and chats', () async {
      final remote = InMemoryRemoteStore();
      final a = await newDevice(remote);
      await a.sync();

      final plans = a.read(workoutTemplatesProvider.notifier)
        ..add(Sport.running, '5K')
        ..add(Sport.cycling, 'Hills');
      final fiveK = a.read(workoutTemplatesProvider).firstWhere(
            (p) => p.name == '5K',
          );
      plans
        ..update(fiveK.copyWith(name: '10K'))
        ..remove('gym-back-triceps');
      a.read(activeWorkoutProvider.notifier)
        ..start(WorkoutCatalog.defaults.first)
        ..toggleSet(0, 0);
      a.read(activeWorkoutProvider.notifier).finish();
      final gym = AssistantTopic.all.firstWhere((x) => x.sport == Sport.gym);
      await a.read(chatRepositoryProvider).saveMessages([
        message('m1', t(0), text: 'hi'),
      ]);
      a.prefs.setString(
        gym.historyKey,
        ChatMessage.encodeMessages([message('g1', t(1), text: 'split?')]),
      );
      await a.sync();
      expect(a.status.pending, 0);

      final b = await newDevice(remote);
      await b.sync();

      expect(b.planNames, a.planNames);
      expect(b.planNames, isNot(contains('Back and Triceps')));
      expect(b.planNames, containsAll(['10K', 'Hills']));
      expect(b.read(workoutHistoryProvider).map((w) => w.id),
          a.read(workoutHistoryProvider).map((w) => w.id));
      expect(b.storedChat(AssistantTopic.app).single.content, 'hi');
      expect(b.storedChat(gym).single.content, 'split?');

      // An edit on B reaches A.
      final hills =
          b.read(workoutTemplatesProvider).firstWhere((p) => p.name == 'Hills');
      b
          .read(workoutTemplatesProvider.notifier)
          .update(hills.copyWith(name: 'Big hills'));
      await b.sync();
      await a.sync();
      expect(a.planNames, contains('Big hills'));
      expect(a.planNames, b.planNames);

      // Nothing left to do: another round changes nothing remotely.
      final before = remote.plansOf('u1').map((p) => p.updatedAt).toList();
      await a.sync();
      await b.sync();
      expect(remote.plansOf('u1').map((p) => p.updatedAt), before);
    });

    test('offline changes are queued durably and pushed later', () async {
      final remote = InMemoryRemoteStore()..online = false;
      var device = await newDevice(remote);
      device.read(workoutTemplatesProvider.notifier).add(Sport.running, '5K');
      device.read(workoutHistoryProvider.notifier).add(finished('w1', t(0)));

      await device.sync();
      expect(device.status.error, contains('unreachable'));
      expect(device.status.pending, greaterThan(0));
      expect(remote.plansOf('u1'), isEmpty);

      // The app is killed and restarted later, now online.
      remote.online = true;
      device = restart(device, remote, userId: 'u1');
      await device.sync();

      expect(device.status.error, isNull);
      expect(device.status.pending, 0);
      expect(remote.plansOf('u1').map((p) => p.template.name), contains('5K'));
      expect(remote.historyOf('u1').single.id, 'w1');
    });

    test('a local change is pushed automatically (debounced)', () async {
      final remote = InMemoryRemoteStore();
      final device = await newDevice(remote);
      await device.sync();

      device.read(workoutTemplatesProvider.notifier).add(Sport.running, '5K');
      expect(device.status.pending, 1);

      final deadline = DateTime.now().add(const Duration(seconds: 10));
      while (!remote.plansOf('u1').any((p) => p.template.name == '5K')) {
        expect(DateTime.now().isBefore(deadline), isTrue);
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      await device.sync();
      expect(device.status.pending, 0);
    });

    test('a deletion propagates as a tombstone', () async {
      final remote = InMemoryRemoteStore();
      final a = await newDevice(remote);
      final b = await newDevice(remote);
      await a.sync();
      await b.sync();

      a.read(workoutTemplatesProvider.notifier).remove('gym-chest-biceps');
      expect(
        WorkoutStorage(a.prefs).loadDeletedTemplates().single.id,
        'gym-chest-biceps',
      );
      await a.sync();
      expect(WorkoutStorage(a.prefs).loadDeletedTemplates(), isEmpty,
          reason: 'tombstone dropped once the server has it');
      expect(
        remote
            .plansOf('u1')
            .firstWhere((p) => p.id == 'gym-chest-biceps')
            .isDeleted,
        isTrue,
      );

      await b.sync();
      expect(b.planNames, isNot(contains('Chest and Biceps')));
    });

    test('another account sees nothing; switching accounts drops local data',
        () async {
      final remote = InMemoryRemoteStore();
      var device = await newDevice(remote);
      device.read(workoutTemplatesProvider.notifier).add(Sport.running, 'Mine');
      device.read(workoutHistoryProvider.notifier).add(finished('w1', t(0)));
      await device.sync();

      final other = await newDevice(remote, userId: 'u2');
      await other.sync();
      expect(other.planNames, isNot(contains('Mine')));
      expect(other.read(workoutHistoryProvider), isEmpty);

      // Same install, different account without a sign-out in between.
      device = restart(device, remote, userId: 'u2');
      await device.sync();
      expect(device.planNames, isNot(contains('Mine')));
      expect(device.read(workoutHistoryProvider), isEmpty);
      expect(remote.historyOf('u2'), isEmpty);
      expect(remote.historyOf('u1'), hasLength(1));
    });

    test('an open chat shows synced messages and keeps a streaming reply',
        () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final hanging = Completer<void>();
      server.listen((request) async {
        await hanging.future; // Felix "thinks" until the test ends.
        request.response.statusCode = 503;
        await request.response.close();
      });
      addTearDown(() => server.close(force: true));

      final remote = InMemoryRemoteStore();
      final a = await newDevice(remote);
      await a.read(chatRepositoryProvider).saveMessages([
        message('from-a', t(0), text: 'from A'),
      ]);
      await a.sync();

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        remoteStoreProvider.overrideWithValue(remote),
        syncUserIdProvider.overrideWithValue('u1'),
        chatApiServiceProvider.overrideWithValue(
          ChatApiService(baseUrl: 'http://127.0.0.1:${server.port}'),
        ),
      ]);
      addTearDown(container.dispose);
      final b = Device(prefs, container);

      // B opens the chat: an unsaved greeting, replaced by the synced chat.
      final notifier = b.read(chatMessagesProvider.notifier);
      while (b.read(chatMessagesProvider).valueOrNull == null) {
        await Future<void>.delayed(Duration.zero);
      }
      expect(b.read(chatMessagesProvider).requireValue.first.content,
          AssistantTopic.app.greeting.first);
      await b.sync();
      List<String> shown() => [
            for (final m in b.read(chatMessagesProvider).requireValue)
              m.isStreaming ? '<streaming>' : m.content,
          ];
      expect(shown(), ['from A']);

      // B asks Felix; while the reply streams, A writes more.
      final sending = notifier.sendMessage('hello from B');
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(shown().last, '<streaming>');
      await a.read(chatRepositoryProvider).saveMessages([
        message('from-a', t(0), text: 'from A'),
        message('again-a', t(1), text: 'A again'),
      ]);
      await a.sync();
      await b.sync();

      expect(shown(), ['from A', 'A again', 'hello from B', '<streaming>']);
      expect(remote.chatOf('u1').map((r) => r.message.content),
          unorderedEquals(['from A', 'A again', 'hello from B']),
          reason: 'streaming replies are never pushed');

      hanging.complete();
      await sending;
      expect(b.read(chatMessagesProvider).requireValue.last.isFailed, isTrue);
      await b.sync();
      expect(remote.chatOf('u1'), hasLength(3),
          reason: 'failed replies are never pushed');
      await a.sync();
      expect(a.storedChat(AssistantTopic.app).map((m) => m.content),
          ['from A', 'A again', 'hello from B']);
    });

    test('a sync in flight during sign-out writes nothing back', () async {
      final remote = InMemoryRemoteStore()
        ..putPlan('u1', plan('elsewhere', name: 'From elsewhere'));
      final device = await newDevice(remote);
      remote.hold = Completer();
      final syncing = device.sync();
      await Future<void>.delayed(Duration.zero);

      await device.prefs.clear(); // AppSession.signOut()
      remote.hold!.complete();
      await syncing;

      expect(device.prefs.getKeys(), isEmpty);
    });

    test('retry delay backs off and is capped', () {
      expect(SyncEngine.retryDelay(1), const Duration(seconds: 5));
      expect(SyncEngine.retryDelay(2), const Duration(seconds: 10));
      expect(SyncEngine.retryDelay(20), const Duration(minutes: 5));
    });

    test('sync state survives a round trip through storage', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      SyncState(
        owner: 'u1',
        plans: {'a': const PlanVersion(local: null, server: 42)},
        history: {'h'},
        chat: {'c'},
        chatCursor: t(0),
      ).save(prefs);
      final loaded = SyncState.load(prefs);
      expect(loaded.owner, 'u1');
      expect(loaded.plans['a']!.local, isNull);
      expect(loaded.plans['a']!.server, 42);
      expect(loaded.history, {'h'});
      expect(loaded.chat, {'c'});
      expect(loaded.chatCursor, t(0));
      expect(loaded.plansCursor, isNull);
    });
  });
}
