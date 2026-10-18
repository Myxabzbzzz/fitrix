import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitrix/core/session/session_providers.dart';
import 'package:fitrix/core/sync/sync_engine.dart';
import 'package:fitrix/core/sync/sync_local.dart';
import 'package:fitrix/core/sync/sync_state.dart';
import 'package:fitrix/core/time/day_key.dart';
import 'package:fitrix/core/time/today_provider.dart';
import 'package:fitrix/features/checkin/data/checkin_models.dart';
import 'package:fitrix/features/checkin/presentation/providers/checkin_provider.dart';
import 'package:fitrix/features/nutrition/data/food_catalog.dart';
import 'package:fitrix/features/nutrition/data/food_log_store.dart';
import 'package:fitrix/features/nutrition/data/nutrition_targets.dart';
import 'package:fitrix/features/nutrition/presentation/providers/nutrition_provider.dart';
import 'package:fitrix/features/plan/data/week_plan.dart';
import 'package:fitrix/features/plan/presentation/providers/week_plan_provider.dart';
import 'package:fitrix/features/profile/data/performance_store.dart';
import 'package:fitrix/features/programs/data/program_store.dart';
import 'package:fitrix/features/programs/presentation/providers/programs_provider.dart';
import 'package:fitrix/features/progress/data/body_weight_store.dart';
import 'package:fitrix/features/progress/presentation/providers/progress_providers.dart';
import 'package:fitrix/features/workouts/data/felix_templates_store.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';

import 'support/in_memory_remote_store.dart';

const uid = 'u1';

/// One device: its own storage, providers and sync engine, sharing the
/// server with the others.
class Device {
  Device(this.remote, this.now) {
    SharedPreferences.resetStatic();
    SharedPreferences.setMockInitialValues({});
  }

  final InMemoryRemoteStore remote;
  DateTime Function() now;
  late final SharedPreferences prefs;
  late final ProviderContainer c;
  late final SyncLocal local;
  late final SyncEngine engine;

  Future<Device> init() async {
    prefs = await SharedPreferences.getInstance();
    c = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      clockProvider.overrideWithValue(() => now()),
    ]);
    addTearDown(c.dispose);
    local = SyncLocal(c.read(Provider((ref) => ref)));
    engine = SyncEngine(
      local: local,
      remote: remote,
      userId: uid,
      pollInterval: null,
      pullOverlap: Duration.zero,
    );
    addTearDown(engine.dispose);
    await engine.sync();
    return this;
  }

  Future<void> sync() => engine.sync();

  SyncState get state => SyncState.load(prefs);
}

Future<Device> device(InMemoryRemoteStore remote, [DateTime Function()? now]) =>
    Device(remote, now ?? DateTime.now).init();

FoodEntry entry(String id, DateTime at, {String name = 'Oats'}) => FoodEntry(
      id: id,
      at: at,
      slot: MealSlot.breakfast,
      name: name,
      grams: 100,
      kcal: 380,
      protein: 13,
      carbs: 60,
      fat: 7,
    );

CheckIn checkIn(DateTime at) => CheckIn(
      at: at,
      sleep: const Duration(hours: 8),
      quality: SleepQuality.good,
      soreness: Soreness.none,
      sore: const {},
      energy: Level3.high,
      stress: Level3.low,
    );

void main() {
  late InMemoryRemoteStore remote;
  final today = dayOf(DateTime.now());
  final noon = today.add(const Duration(hours: 12));

  setUp(() => remote = InMemoryRemoteStore());

  List<String> kinds() => [for (final d in remote.docsOf(uid)) d.kind];

  test('a fresh device with no user data pushes no documents', () async {
    final a = await device(remote);
    // Build every provider, as the app does; defaults must not become docs.
    a.c.read(activeProgramProvider);
    a.c.read(performanceProfileProvider);
    a.c.read(nutritionSettingsProvider);
    a.c.read(weekPlanProvider);
    a.c.read(felixTemplateIdsProvider);
    a.c.read(foodLogProvider);
    await a.sync();
    expect(remote.docsOf(uid), isEmpty);
    expect(a.engine.pendingCount(), 0);
  });

  test(
      'food: add pushes a doc, the other device sees it; remove is a tombstone',
      () async {
    final a = await device(remote);
    final b = await device(remote);
    b.c.read(todayEntriesProvider); // built before the pull

    await a.c.read(foodLogProvider.notifier).add(entry('e1', noon));
    expect(a.engine.pendingCount(), 1);
    await a.sync();
    expect(remote.docsOf(uid).single.key, 'food/e1');

    await b.sync();
    expect(b.c.read(todayEntriesProvider).map((e) => e.id), ['e1']);
    expect(b.engine.pendingCount(), 0);

    await b.c.read(foodLogProvider.notifier).remove('e1');
    expect(b.state.docTombstones.keys, ['food/e1']);
    await b.sync();
    expect(remote.docsOf(uid).single.isDeleted, isTrue);

    await a.sync();
    expect(a.c.read(todayEntriesProvider), isEmpty);
    expect(a.engine.pendingCount(), 0);
  });

  test('removing an entry that does not exist records nothing', () async {
    final a = await device(remote);
    await a.c.read(foodLogProvider.notifier).remove('nope');
    expect(a.state.docTombstones, isEmpty);
  });

  test('replaceDay tombstones the entries it removes, not the kept ones',
      () async {
    final a = await device(remote);
    final log = a.c.read(foodLogProvider.notifier);
    await log.add(entry('old1', noon));
    await log.add(entry('keep', noon));
    await log.replaceDay(today, [entry('keep', noon), entry('new', noon)]);
    expect(a.state.docTombstones.keys, ['food/old1']);
    await a.sync();
    final byKey = {for (final d in remote.docsOf(uid)) d.key: d};
    expect(byKey['food/old1']!.isDeleted, isTrue);
    expect(byKey['food/keep']!.isDeleted, isFalse);
    expect(byKey['food/new']!.isDeleted, isFalse);
  });

  test('water round trip', () async {
    final a = await device(remote);
    final b = await device(remote);
    b.c.read(todayWaterProvider);
    await a.c.read(foodLogProvider.notifier).addWater(today, 250);
    await a.sync();
    expect(remote.docsOf(uid).single.data, {'ml': 250});
    expect(remote.docsOf(uid).single.docId, dayKey(today));
    await b.sync();
    expect(b.c.read(todayWaterProvider), 250);
  });

  test('check-in round trip, shown by the provider the screen watches',
      () async {
    final a = await device(remote);
    final b = await device(remote);
    expect(b.c.read(todayCheckInProvider), isNull);
    await a.c.read(todayCheckInProvider.notifier).save(checkIn(noon));
    expect(a.engine.pendingCount(), 1);
    await a.sync();
    expect(remote.docsOf(uid).single.key, 'checkin/${dayKey(today)}');
    await b.sync();
    expect(b.c.read(todayCheckInProvider)?.energy, Level3.high);
    expect(b.c.read(checkInHistoryProvider), hasLength(1));
    expect(b.engine.pendingCount(), 0);
  });

  test(
      'weight: round trip; Felix Undo pushes a tombstone, other device removes',
      () async {
    final a = await device(remote);
    final b = await device(remote);
    b.c.read(bodyWeightProvider);
    final w = WeighIn(at: noon, kg: 80.5);
    await a.c.read(bodyWeightProvider.notifier).record(w);
    expect(a.engine.pendingCount(), 1);
    await a.sync();
    expect(remote.docsOf(uid).single.key, 'weight/${dayKey(today)}');
    await b.sync();
    expect(b.c.read(bodyWeightProvider).single.kg, 80.5);

    await a.c.read(bodyWeightProvider.notifier).unrecord(noon);
    expect(a.state.docTombstones.keys, ['weight/${dayKey(today)}']);
    await a.sync();
    await b.sync();
    expect(b.c.read(bodyWeightProvider), isEmpty);
  });

  test('weight Undo that restores the replaced weigh-in keeps the doc',
      () async {
    final a = await device(remote);
    final first = WeighIn(at: noon.subtract(const Duration(hours: 1)), kg: 80);
    final notifier = a.c.read(bodyWeightProvider.notifier);
    await notifier.record(first);
    final replaced = await notifier.record(WeighIn(at: noon, kg: 81));
    await notifier.unrecord(noon, replaced: replaced);
    expect(a.state.docTombstones, isEmpty);
    await a.sync();
    expect(remote.docsOf(uid).single.data!['kg'], 80);
  });

  test('week plan round trip', () async {
    final a = await device(remote);
    final b = await device(remote);
    b.c.read(weekPlanProvider);
    b.c.read(dismissedSuggestionsProvider);
    await a.c.read(weekPlanProvider.notifier).add(PlannedSession(
          id: 's1',
          day: today,
          sport: Sport.gym,
          title: 'Push',
          minutes: 45,
          intensity: Intensity.normal,
        ));
    await a.c.read(dismissedSuggestionsProvider.notifier).dismiss('x', today);
    await a.sync();
    expect(remote.docsOf(uid).single.key, 'week_plan/current');
    await b.sync();
    expect(b.c.read(weekPlanProvider).single.title, 'Push');
    expect(b.c.read(dismissedSuggestionsProvider), hasLength(1));
    expect(b.engine.pendingCount(), 0);
  });

  test('program round trip; clearing it is a tombstone', () async {
    final a = await device(remote);
    final b = await device(remote);
    b.c.read(activeProgramProvider);
    await a.c.read(activeProgramProvider.notifier).set(ActiveProgram(
          programId: 'p',
          start: today,
          weekdays: const [1, 3],
          sessionTemplateIds: const {'A': 't1'},
        ));
    await a.sync();
    expect(remote.docsOf(uid).single.key, 'program/active');
    await b.sync();
    expect(b.c.read(activeProgramProvider)?.programId, 'p');

    await b.c.read(activeProgramProvider.notifier).clear();
    expect(b.state.docTombstones.keys, ['program/active']);
    await b.sync();
    await a.sync();
    expect(a.c.read(activeProgramProvider), isNull);
  });

  test('performance profile and nutrition settings round trip', () async {
    final a = await device(remote);
    final b = await device(remote);
    b.c.read(performanceProfileProvider);
    b.c.read(nutritionSettingsProvider);
    await a.c
        .read(performanceProfileProvider.notifier)
        .save(const PerformanceProfile(sex: Sex.female, maxHr: 190));
    await a.c
        .read(nutritionSettingsProvider.notifier)
        .save(const NutritionSettings(goal: Goal.loseFat, proteinPerKg: 2.0));
    await a.sync();
    expect(kinds()..sort(), ['nutrition_settings', 'performance']);
    await b.sync();
    expect(b.c.read(performanceProfileProvider).maxHr, 190);
    expect(b.c.read(nutritionSettingsProvider).goal, Goal.loseFat);
    expect(b.engine.pendingCount(), 0);
  });

  test('felix plans round trip', () async {
    final a = await device(remote);
    final b = await device(remote);
    b.c.read(felixTemplateIdsProvider);
    final felix = a.c.read(felixTemplateIdsProvider.notifier);
    felix.add(['t1', 't2']);
    felix.recordBatch(123, ['t1', 't2']);
    await a.sync();
    expect(remote.docsOf(uid).single.key, 'felix_plans/state');
    await b.sync();
    expect(b.c.read(felixTemplateIdsProvider), {'t1', 't2'});
    expect(
        b.c.read(felixTemplateIdsProvider.notifier).batch(123), ['t1', 't2']);
    expect(b.engine.pendingCount(), 0);
  });

  test('pruning old food and check-in days pushes nothing and deletes nothing',
      () async {
    var now = noon;
    final a = await device(remote, () => now);
    final old = noon.subtract(const Duration(days: 3));
    await a.c.read(foodLogProvider.notifier).add(entry('old', old));
    await a.c.read(foodLogProvider.notifier).addWater(old, 500);
    await a.c.read(todayCheckInProvider.notifier).save(checkIn(old));
    await a.sync();
    expect(remote.docsOf(uid), hasLength(3));

    now = noon.add(const Duration(days: 90)); // all three are past retention
    await a.c.read(foodLogProvider.notifier).add(entry('new', now));
    await a.c.read(todayCheckInProvider.notifier).save(checkIn(now));
    expect(a.c.read(foodLogStoreProvider).hasEntry('old'), isFalse);
    expect(a.c.read(checkInStoreProvider).all(), hasLength(1));
    expect(a.state.docTombstones, isEmpty);
    await a.sync();
    final byKey = {for (final d in remote.docsOf(uid)) d.key: d};
    expect(byKey['food/old']!.isDeleted, isFalse);
    expect(byKey['checkin/${dayKey(old)}']!.isDeleted, isFalse);
    expect(byKey['water/${dayKey(old)}']!.isDeleted, isFalse);
  });

  test('a full pull of old days stores nothing and pushes nothing', () async {
    final old = noon.subtract(const Duration(days: 100));
    remote.putDoc(uid, 'food', 'ancient', entry('ancient', old).toJson());
    remote.putDoc(uid, 'water', dayKey(old), {'ml': 300});
    remote.putDoc(uid, 'checkin', dayKey(old), checkIn(old).toJson());
    final a = await device(remote);
    expect(a.c.read(foodLogStoreProvider).allEntries(), isEmpty);
    expect(a.c.read(foodLogStoreProvider).waterDays(), isEmpty);
    expect(a.c.read(checkInStoreProvider).all(), isEmpty);
    expect(a.state.docTombstones, isEmpty);
    expect(a.engine.pendingCount(), 0);
    await a.sync();
    expect(remote.docsOf(uid).every((d) => !d.isDeleted), isTrue);
  });

  test('malformed documents are skipped, the rest still apply', () async {
    remote.putDoc(uid, 'food', 'bad', {'id': 'bad', 'at': 'not a date'});
    remote.putDoc(uid, 'food', 'good', entry('good', noon).toJson());
    remote.putDoc(uid, 'water', dayKey(today), {'ml': 'lots'});
    remote.putDoc(uid, 'checkin', dayKey(today), {'at': 5});
    remote.putDoc(uid, 'weight', dayKey(today), {'kg': 'x'});
    remote.putDoc(uid, 'program', 'active', {'programId': 3});
    remote.putDoc(uid, 'week_plan', 'current', {'sessions': 'nope'});
    remote.putDoc(uid, 'felix_plans', 'state', {'ids': 1});
    remote.putDoc(uid, 'performance', 'profile', {'maxHr': 'x', 'extra': 1});
    final a = await device(remote);
    expect(a.c.read(todayEntriesProvider).map((e) => e.id), ['good']);
    expect(a.c.read(todayWaterProvider), 0);
    expect(a.c.read(todayCheckInProvider), isNull);
    expect(a.c.read(bodyWeightProvider), isEmpty);
    expect(a.c.read(activeProgramProvider), isNull);
    expect(a.c.read(weekPlanProvider), isEmpty);
    expect(a.c.read(felixTemplateIdsProvider), isEmpty);
  });

  test('applying pulled docs does not ping local changes', () async {
    remote.putDoc(uid, 'food', 'e1', entry('e1', noon).toJson());
    final a = await device(remote);
    var pings = 0;
    a.local.changes.listen((_) => pings++);
    remote.putDoc(uid, 'food', 'e2', entry('e2', noon).toJson());
    remote.putDoc(uid, 'nutrition_settings', 'settings',
        const NutritionSettings(goal: Goal.leanBulk).toJson());
    await a.sync();
    expect(a.c.read(todayEntriesProvider), hasLength(2));
    expect(pings, 0);
  });

  test('SyncLocal.clear empties every new collection', () async {
    final a = await device(remote);
    await a.c.read(foodLogProvider.notifier).add(entry('e1', noon));
    await a.c.read(foodLogProvider.notifier).addWater(today, 100);
    await a.c.read(todayCheckInProvider.notifier).save(checkIn(noon));
    await a.c
        .read(bodyWeightProvider.notifier)
        .record(WeighIn(at: noon, kg: 70));
    await a.c
        .read(nutritionSettingsProvider.notifier)
        .save(const NutritionSettings(goal: Goal.leanBulk));
    await a.c
        .read(performanceProfileProvider.notifier)
        .save(const PerformanceProfile(maxHr: 180));
    a.c.read(felixTemplateIdsProvider.notifier).add(['t']);
    await a.c.read(activeProgramProvider.notifier).set(ActiveProgram(
        programId: 'p',
        start: today,
        weekdays: const [1],
        sessionTemplateIds: const {}));
    a.local.clear();
    expect(a.c.read(todayEntriesProvider), isEmpty);
    expect(a.c.read(todayWaterProvider), 0);
    expect(a.c.read(todayCheckInProvider), isNull);
    expect(a.c.read(bodyWeightProvider), isEmpty);
    expect(a.c.read(nutritionSettingsProvider).goal, Goal.maintain);
    expect(a.c.read(performanceProfileProvider), PerformanceProfile.empty);
    expect(a.c.read(felixTemplateIdsProvider), isEmpty);
    expect(a.c.read(activeProgramProvider), isNull);
    for (final col in a.local.collections) {
      expect(col.read(), isEmpty, reason: col.kind);
    }
  });
}
