import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitrix/core/constants/app_constants.dart';
import 'package:fitrix/core/session/session_providers.dart';
import 'package:fitrix/core/theme/app_theme.dart';
import 'package:fitrix/features/chat/data/models/chat_action.dart';
import 'package:fitrix/features/chat/data/models/chat_message.dart';
import 'package:fitrix/features/chat/data/repositories/chat_repository.dart';
import 'package:fitrix/features/chat/data/services/chat_api_service.dart';
import 'package:fitrix/features/chat/presentation/providers/chat_provider.dart';
import 'package:fitrix/features/chat/presentation/screens/felix_chat_screen.dart';
import 'package:fitrix/features/nutrition/presentation/providers/nutrition_provider.dart';
import 'package:fitrix/features/nutrition/presentation/screens/nutrition_screen.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/features/workouts/presentation/providers/workouts_provider.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

const _weightDelta = {'type': 'weight', 'mode': 'delta', 'kg': 3};
const _plan = {
  'type': 'workout_plan',
  'sport': 'gym',
  'templates': [
    {
      'name': 'Upper body',
      'exercises': [
        {'name': 'Bench press', 'sets': 4, 'reps': 8, 'kg': 60},
        {'name': 'Row', 'sets': 3, 'reps': 10},
      ],
    },
    {
      'name': 'Legs',
      'exercises': [
        {'name': 'Squat', 'sets': 5, 'reps': 5, 'kg': 80},
      ],
    },
  ],
};
const _meals = {
  'type': 'meal_plan',
  'meals': [
    {'name': 'Breakfast', 'items': 'Oatmeal, banana', 'kcal': 520},
    {'name': 'Lunch', 'items': 'Chicken, rice', 'kcal': 700},
  ],
};

/// Replies with "Sure" and the given action (if any).
class _FakeApi extends ChatApiService {
  ChatAction? action;
  final histories = <List<Map<String, String>>?>[];

  @override
  Stream<String> streamMessage(
    String message,
    String conversationId, {
    String? topic,
    Map<String, Object>? profile,
    List<Map<String, String>>? history,
    String? language,
    void Function(ChatAction action)? onAction,
  }) async* {
    histories.add(history);
    yield 'Sure';
    if (action != null) onAction?.call(action!);
  }
}

ChatMessage _felixMessage(Map<String, dynamic> action,
        {bool applied = false}) =>
    ChatMessage(
      id: 'm1',
      content: 'Here is a plan. Tap the button below.',
      sender: MessageSender.assistant,
      timestamp: DateTime(2026, 10, 13, 9),
      action: ChatAction.tryParse(action),
      actionApplied: applied,
    );

void main() {
  late SharedPreferences prefs;

  Future<void> seed({
    String weight = '75',
    Map<String, dynamic>? action,
    bool applied = false,
  }) async {
    SharedPreferences.setMockInitialValues({
      AppConstants.keyUserName: 'Ann',
      AppConstants.keyUserWeight: weight,
      if (action != null)
        AppConstants.keyChatHistory: ChatMessage.encodeMessages(
            [_felixMessage(action, applied: applied)]),
    });
    prefs = await SharedPreferences.getInstance();
  }

  group('parsing', () {
    test('valid actions parse, invalid ones are dropped', () {
      expect(ChatAction.tryParse(_weightDelta), isA<WeightAction>());
      expect(ChatAction.tryParse(_plan), isA<WorkoutPlanAction>());
      expect(ChatAction.tryParse(_meals), isA<MealPlanAction>());
      expect(ChatAction.tryParse({'type': 'weight', 'mode': 'x', 'kg': 1}),
          isNull);
      expect(ChatAction.tryParse({'type': 'workout_plan', 'sport': 'golf'}),
          isNull);
      expect(ChatAction.tryParse({'type': 'meal_plan', 'meals': []}), isNull);
      expect(ChatAction.tryParse('nope'), isNull);
    });

    test('weight result: delta from current, rounded and clamped', () {
      const delta = WeightAction(isSet: false, kg: 3);
      expect(delta.resultFrom(75), 78);
      expect(const WeightAction(isSet: false, kg: 0.26).resultFrom(75), 75.3);
      expect(delta.resultFrom(null), isNull);
      expect(const WeightAction(isSet: false, kg: -50).resultFrom(30), 20);
      expect(const WeightAction(isSet: true, kg: 82.04).resultFrom(null), 82);
      expect(const WeightAction(isSet: true, kg: 500).resultFrom(70), 400);
    });

    test('ChatApiService reads the action event before done', () async {
      HttpOverrides.global = null;
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      server.listen((request) async {
        await utf8.decoder.bind(request).join();
        request.response.headers.contentType =
            ContentType('application', 'x-ndjson', charset: 'utf-8');
        for (final event in [
          {'delta': 'Hi'},
          {'action': _weightDelta},
          {
            'action': {'type': 'bogus'}
          },
          {'done': true},
        ]) {
          request.response.write('${jsonEncode(event)}\n');
        }
        await request.response.close();
      });
      final api = ChatApiService(
          baseUrl: 'http://${server.address.host}:${server.port}');
      final actions = <ChatAction>[];
      final chunks =
          await api.streamMessage('hi', 'c', onAction: actions.add).toList();
      expect(chunks, ['Hi']);
      expect(actions, hasLength(1));
      expect((actions.single as WeightAction).kg, 3);
    });
  });

  group('message', () {
    test('carries the action, persists it, keeps it out of history', () async {
      await seed();
      final api = _FakeApi()..action = ChatAction.tryParse(_plan);
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

  group('cards', () {
    late ProviderContainer container;

    Future<void> pumpFelix(
      WidgetTester tester, {
      Locale locale = const Locale('en'),
    }) async {
      tester.view.physicalSize = const Size(375, 667) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      container = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        chatMessagesProvider.overrideWith((ref) => ChatNotifier(
            ChatRepository(_FakeApi(), prefs: prefs, greeting: const ['Hi']))),
      ]);
      addTearDown(container.dispose);
      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: FelixChatScreen()),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 500));
    }

    final card = find.byKey(const ValueKey('chat-action-card'));
    final applied = find.byKey(const ValueKey('chat-action-applied'));

    testWidgets('weight delta shows 75 → 78 kg and updates the profile',
        (tester) async {
      await seed(action: _weightDelta);
      await pumpFelix(tester);
      expect(find.text('Update weight: 75 → 78 kg'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      expect(prefs.getString(AppConstants.keyUserWeight), '78');
      expect(applied, findsOneWidget);
      expect(find.text('Confirm'), findsNothing);
    });

    testWidgets('weight set replaces the weight', (tester) async {
      await seed(
          action: {'type': 'weight', 'mode': 'set', 'kg': 82.5}, weight: '75');
      await pumpFelix(tester);
      expect(find.text('Update weight: 75 → 82.5 kg'), findsOneWidget);
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      expect(prefs.getString(AppConstants.keyUserWeight), '82.5');
    });

    testWidgets('workout plan creates templates for that sport',
        (tester) async {
      await seed(action: _plan);
      await pumpFelix(tester);
      expect(find.text('Add 2 workouts to Gym'), findsOneWidget);
      expect(find.text('Upper body · 2 exercises'), findsOneWidget);
      final before = container
          .read(workoutTemplatesProvider)
          .where((t) => t.sport == Sport.gym)
          .length;

      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      final gym = container
          .read(workoutTemplatesProvider)
          .where((t) => t.sport == Sport.gym)
          .toList();
      expect(gym.length, before + 2);
      final upper = gym.firstWhere((t) => t.name == 'Upper body');
      expect(upper.exercises.first.name, 'Bench press');
      expect(upper.exercises.first.sets, hasLength(4));
      expect(upper.exercises.first.sets.first.kg, 60);
      expect(upper.exercises.first.sets.first.reps, 8);
      expect(find.text('Workouts added to Gym'), findsOneWidget);
      expect(find.text('Open'), findsNothing); // no router in this test
      expect(applied, findsOneWidget);
    });

    testWidgets('meal plan is stored and shown on the Nutrition screen',
        (tester) async {
      await seed(action: _meals);
      await pumpFelix(tester);
      expect(find.text('Add to today’s nutrition'), findsOneWidget);
      expect(find.text('1220 kcal in total'), findsOneWidget);

      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      expect(container.read(todayMealsProvider), hasLength(2));
      expect(prefs.getString('nutrition_today_v1'), contains('Oatmeal'));

      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const NutritionScreen(),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Oatmeal, banana'), findsOneWidget);
      expect(find.text('Chicken, rice'), findsOneWidget);
      expect(find.text('1,220'), findsOneWidget);
    });

    testWidgets('an applied action cannot be applied again', (tester) async {
      await seed(action: _weightDelta, applied: true);
      await pumpFelix(tester);
      expect(card, findsOneWidget);
      expect(applied, findsOneWidget);
      expect(find.text('Confirm'), findsNothing);
      expect(prefs.getString(AppConstants.keyUserWeight), '75');
    });

    testWidgets('applying twice changes the weight only once', (tester) async {
      await seed(action: _weightDelta);
      await pumpFelix(tester);
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      expect(prefs.getString(AppConstants.keyUserWeight), '78');
      expect(find.text('Confirm'), findsNothing);
      // Reopened later: still applied, button gone, weight unchanged.
      await pumpFelix(tester);
      expect(applied, findsOneWidget);
      expect(find.text('Confirm'), findsNothing);
      expect(prefs.getString(AppConstants.keyUserWeight), '78');
    });

    testWidgets('delta without a known weight offers no button',
        (tester) async {
      await seed(action: _weightDelta, weight: '');
      await pumpFelix(tester);
      expect(find.textContaining('Weight change: +3 kg'), findsOneWidget);
      expect(find.text('Confirm'), findsNothing);
    });

    testWidgets('Russian strings render without overflow on SE',
        (tester) async {
      await seed(action: _plan);
      await pumpFelix(tester, locale: const Locale('ru'));
      expect(find.text('Подтвердить'), findsOneWidget);
      expect(find.textContaining('Добавить 2 тренировки'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
