import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitrix/core/constants/app_constants.dart';
import 'package:fitrix/core/session/session_providers.dart';
import 'package:fitrix/core/sync/sync_merge.dart';
import 'package:fitrix/core/time/today_provider.dart';
import 'package:fitrix/features/chat/data/models/chat_action.dart';
import 'package:fitrix/features/chat/data/models/chat_message.dart';
import 'package:fitrix/features/chat/data/repositories/chat_repository.dart';
import 'package:fitrix/features/chat/presentation/providers/chat_provider.dart';
import 'package:fitrix/features/nutrition/data/food_catalog.dart';
import 'package:fitrix/features/nutrition/data/food_log_store.dart';
import 'package:fitrix/features/nutrition/presentation/providers/nutrition_provider.dart';
import 'package:fitrix/features/progress/data/body_weight_store.dart';

import 'support/felix_action_fixtures.dart';

void main() {
  late SharedPreferences prefs;

  Future<void> seed({
    String weight = '75',
    Map<String, dynamic>? action,
    bool applied = false,
  }) async {
    prefs =
        await seedFelixPrefs(weight: weight, action: action, applied: applied);
  }

  group('message', () {
    test('carries the action, persists it, keeps it out of history', () async {
      await seed();
      final api = FakeFelixApi()
        ..action = ChatAction.tryParse(workoutPlanAction);
      final notifier = ChatNotifier(
          ChatRepository(api, prefs: prefs, greeting: const ['Hi']));
      await Future<void>.delayed(Duration.zero);
      await notifier.sendMessage('plan my week');

      final reply = notifier.state.requireValue.last;
      expect(reply.action, isA<WorkoutPlanAction>());
      expect(reply.actionApplied, isFalse);

      // Persisted locally with the message and restored.
      final stored = ChatMessage.decodeMessages(
          prefs.getString(AppConstants.keyChatHistory)!);
      expect(stored.last.action, isA<WorkoutPlanAction>());

      // Never sent as history, which has only role and content.
      final history = ChatMessage.toApiHistory(notifier.state.requireValue);
      for (final turn in history) {
        expect(turn.keys, unorderedEquals(['role', 'content']));
      }
      expect(jsonEncode(history), isNot(contains('workout_plan')));

      // Applied state persists too.
      await notifier.markActionApplied(reply.id);
      final again = ChatMessage.decodeMessages(
          prefs.getString(AppConstants.keyChatHistory)!);
      expect(again.last.actionApplied, isTrue);
    });
  });

  group('nutrition store', () {
    FoodEntry entry(String id, DateTime at, int kcal) => FoodEntry(
        id: id,
        at: at,
        slot: MealSlot.lunch,
        name: id,
        grams: 0,
        kcal: kcal,
        protein: 0,
        carbs: 0,
        fat: 0);

    test('a plan applied on a new day is stored under that day only', () async {
      await seed();
      var now = DateTime(2026, 10, 12, 22);
      final container = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        clockProvider.overrideWithValue(() => now),
      ]);
      addTearDown(container.dispose);
      final notifier = container.read(foodLogProvider.notifier);
      await notifier.replaceDay(container.read(todayProvider),
          [entry('Yesterday', DateTime(2026, 10, 12, 21), 100)]);

      now = DateTime(2026, 10, 13, 8); // the app stayed open overnight
      container.read(todayProvider.notifier).state = DateTime(2026, 10, 13);
      expect(container.read(todayEntriesProvider), isEmpty);
      await notifier.replaceDay(container.read(todayProvider),
          [entry('Today', DateTime(2026, 10, 13, 8), 200)]);

      final store = FoodLogStore(prefs, now: () => now);
      expect(store.day(DateTime(2026, 10, 13)).map((e) => e.name), ['Today']);
      expect(
          store.day(DateTime(2026, 10, 12)).map((e) => e.name), ['Yesterday']);
    });

    test('applying a second meal plan replaces the first', () async {
      await seed();
      final container = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ]);
      addTearDown(container.dispose);
      final notifier = container.read(foodLogProvider.notifier);
      final today = container.read(todayProvider);
      DateTime at() => DateTime(today.year, today.month, today.day, 12);
      await notifier
          .replaceDay(today, [entry('A', at(), 1), entry('B', at(), 2)]);
      await notifier.replaceDay(today, [entry('C', at(), 3)]);
      expect(container.read(todayEntriesProvider).map((m) => m.name), ['C']);
      expect(FoodLogStore(prefs).day(today).map((m) => m.name), ['C']);
    });
  });

  group('persistence', () {
    test('sync pull keeps the local action and applied state', () {
      final local = felixMessage(workoutPlanAction, applied: true);
      final remote = ChatMessage(
        id: local.id,
        content: local.content,
        sender: local.sender,
        timestamp: local.timestamp,
      );
      final merge = unionById<ChatMessage>(
        local: [local],
        remote: [remote],
        idOf: (m) => m.id,
        compare: (a, b) => a.timestamp.compareTo(b.timestamp),
      );
      expect(merge.items.single.action, isA<WorkoutPlanAction>());
      expect(merge.items.single.actionApplied, isTrue);
    });

    test('a malformed stored action loads as a plain message', () async {
      await seed();
      await prefs.setString(
        AppConstants.keyChatHistory,
        jsonEncode([
          {
            'id': 'x',
            'content': 'hello',
            'sender': 'assistant',
            'timestamp': DateTime(2026).toIso8601String(),
            'action': {'type': 'weight', 'mode': 'bogus', 'kg': 'x'},
            'actionApplied': true,
          }
        ]),
      );
      final notifier = ChatNotifier(
          ChatRepository(FakeFelixApi(), prefs: prefs, greeting: const ['Hi']));
      await Future<void>.delayed(Duration.zero);
      final message = notifier.state.requireValue.single;
      expect(message.content, 'hello');
      expect(message.action, isNull);
    });
  });

  group('BodyWeightStore.remove', () {
    test('removes that weigh-in only', () async {
      SharedPreferences.setMockInitialValues({});
      final store = BodyWeightStore(await SharedPreferences.getInstance());
      await store.add(WeighIn(at: DateTime(2026, 10, 16, 8), kg: 80));
      await store.add(WeighIn(at: DateTime(2026, 10, 18, 8), kg: 81.4));
      await store.remove(DateTime(2026, 10, 18, 8));
      expect(store.all().map((w) => w.kg), [80]);
    });
  });
}
