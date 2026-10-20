import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitrix/core/constants/app_constants.dart';
import 'package:fitrix/core/felix/ask_felix.dart';
import 'package:fitrix/core/router/app_router.dart';
import 'package:fitrix/core/session/app_session.dart';
import 'package:fitrix/core/session/session_providers.dart';
import 'package:fitrix/core/time/today_provider.dart';
import 'package:fitrix/features/chat/data/models/assistant_topic.dart';
import 'package:fitrix/features/chat/data/models/chat_message.dart';
import 'package:fitrix/features/chat/presentation/providers/recent_chats_provider.dart';
import 'package:fitrix/features/plan/data/week_plan.dart';
import 'package:fitrix/features/plan/data/week_plan_store.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/main.dart';

import 'support/overflow.dart';

/// Tuesday 20 Oct 2026, mid-afternoon.
final _now = DateTime(2026, 10, 20, 15);

const _profile = <String, Object>{
  AppConstants.keyOnboardingComplete: true,
  'user_name': 'Alex',
};

PlannedSession _plan(String id, int day, Sport sport, String title) =>
    PlannedSession(
      id: id,
      day: DateTime(2026, 10, day),
      sport: sport,
      title: title,
      minutes: 60,
      intensity: Intensity.normal,
    );

String _plans(List<PlannedSession> sessions) => jsonEncode({
      'sessions': [for (final s in sessions) s.toJson()],
      'dismissed': <String>[],
    });

ChatMessage _msg(String id, MessageSender who, String text, DateTime at) =>
    ChatMessage(id: id, content: text, sender: who, timestamp: at);

String _history(List<ChatMessage> messages) =>
    ChatMessage.encodeMessages(messages);

Future<(ProviderContainer, GoRouter)> _app(
  WidgetTester tester,
  Map<String, Object> values, {
  Size size = const Size(390, 2400),
  double textScale = 1,
}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  SharedPreferences.setMockInitialValues({..._profile, ...values});
  final prefs = await SharedPreferences.getInstance();
  final session = AppSession(prefs);
  final container = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    appSessionProvider.overrideWithValue(session),
    clockProvider.overrideWithValue(() => _now),
  ]);
  addTearDown(container.dispose);
  final router = AppRouter.create(session);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: FitrixApp(router: router),
  ));
  await tester.pump();
  return (container, router);
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _open(
    WidgetTester tester, GoRouter router, String location) async {
  router.go(location);
  await _settle(tester);
}

String _location(GoRouter router) => router.state.uri.path;

Future<void> _leave(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  group('hub', () {
    testWidgets('nine topics in hub order and a greeting with the name',
        (tester) async {
      final (_, router) = await _app(tester, {});
      await _open(tester, router, AppRouter.felix);
      expect(find.text('Good afternoon, Alex'), findsOneWidget);
      expect(find.text('AI coach'), findsOneWidget);
      expect(find.text('Chat with Felix about'), findsOneWidget);
      expect(find.text('9 topics'), findsOneWidget);
      final titles = [
        'Gym',
        'Fitness',
        'Running',
        'Cycling',
        'Football',
        'Winter sports',
        'Nutrition',
        'Recovery',
        'App assistant',
      ];
      final ys = [
        for (final t in titles) tester.getTopLeft(find.text(t)).dy,
      ];
      expect(ys, orderedEquals([...ys]..sort()));
      expect(find.byKey(const ValueKey('topic-row-gym')), findsOneWidget);
      expect(find.text('Recent chats'), findsNothing);
      await _leave(tester);
    });

    testWidgets('today line: session today and the next non-gym day',
        (tester) async {
      final (_, router) = await _app(tester, {
        WeekPlanStore.key: _plans([
          _plan('a', 20, Sport.gym, 'Back and Triceps'),
          _plan('b', 24, Sport.football, 'Match'),
        ]),
      });
      await _open(tester, router, AppRouter.felix);
      expect(find.text('Back and Triceps today · Football on Saturday'),
          findsOneWidget);
      await _leave(tester);
    });

    testWidgets('unplanned with nothing next: no today line', (tester) async {
      final (_, router) = await _app(tester, {});
      await _open(tester, router, AppRouter.felix);
      expect(find.byKey(const ValueKey('felix-today-line')), findsNothing);
      await _leave(tester);
    });

    testWidgets('recent chats: only topics with a user message, newest first',
        (tester) async {
      final (c, router) = await _app(tester, {
        'chat_history_nutrition': _history([
          _msg('n1', MessageSender.user, 'What about protein?',
              DateTime(2026, 10, 19, 19)),
          _msg('n2', MessageSender.assistant, 'Aim for 2 g per kg.',
              DateTime(2026, 10, 19, 19, 1)),
        ]),
        'chat_history_gym': _history([
          _msg('g1', MessageSender.user, 'Bench stalled',
              DateTime(2026, 10, 20, 14, 1)),
          _msg('g2', MessageSender.assistant, 'Try a deload week.',
              DateTime(2026, 10, 20, 14, 2)),
        ]),
      });
      await _open(tester, router, AppRouter.felix);
      final recent = c.read(recentChatsProvider);
      expect(recent.map((r) => r.topic), [
        AssistantTopic.gym,
        AssistantTopic.nutrition,
      ]);
      expect(find.text('Recent chats'), findsOneWidget);
      expect(find.text('See all'), findsOneWidget);
      expect(find.text('14:02'), findsOneWidget);
      expect(find.text('Try a deload week.'), findsOneWidget);
      expect(find.text('Aim for 2 g per kg.'), findsOneWidget);
      expect(find.text('Mon'), findsOneWidget);
      expect(find.byKey(const ValueKey('recent-chat-recovery')), findsNothing);
      await _leave(tester);
    });

    testWidgets('See all opens All chats with recent chats and all topics',
        (tester) async {
      final (_, router) = await _app(tester, {
        'chat_history_gym': _history([
          _msg('g1', MessageSender.user, 'Bench stalled',
              DateTime(2026, 10, 20, 14, 1)),
        ]),
      });
      await _open(tester, router, AppRouter.felix);
      await tester.tap(find.text('See all'));
      await _settle(tester);
      expect(_location(router), AppRouter.felixAll);
      expect(find.text('All chats'), findsOneWidget);
      expect(find.text('All topics'), findsOneWidget);
      expect(find.byKey(const ValueKey('recent-chat-gym')), findsOneWidget);
      expect(find.byKey(const ValueKey('topic-row-recovery')), findsOneWidget);
      await _leave(tester);
    });
  });

  group('chat route', () {
    testWidgets('tapping a topic opens its chat; back and tab re-tap return',
        (tester) async {
      final (_, router) = await _app(tester, {});
      await _open(tester, router, AppRouter.felix);
      await tester.tap(find.text('Recovery'));
      await _settle(tester);
      expect(_location(router), '/felix/chat/recovery');
      expect(find.text('Felix · Recovery'), findsOneWidget);

      await tester.binding.handlePopRoute();
      await _settle(tester);
      expect(_location(router), AppRouter.felix);

      await tester.tap(find.text('Nutrition'));
      await _settle(tester);
      expect(_location(router), '/felix/chat/nutrition');
      await tester.tap(find.bySemanticsLabel('Felix').last);
      await _settle(tester);
      expect(_location(router), AppRouter.felix);
      await _leave(tester);
    });

    testWidgets('Ask Felix for a chat opened from the hub keeps the draft',
        (tester) async {
      final (c, router) = await _app(tester, {});
      await _open(tester, router, AppRouter.felix);
      await tester.tap(find.text('Gym'));
      await _settle(tester);
      expect(_location(router), '/felix/chat/gym');
      await _open(tester, router, AppRouter.sportWorkouts(Sport.gym));
      await tester.tap(find.text('Ask').hitTestable());
      await _settle(tester);
      expect(_location(router), '/felix/chat/gym');
      expect(
          find.byWidgetPredicate((w) =>
              w is TextField && (w.controller?.text.isNotEmpty ?? false)),
          findsOneWidget);
      expect(c.read(felixDraftProvider), isNull);
      await _leave(tester);
    });

    testWidgets('Ask Felix again for the same chat from another tab',
        (tester) async {
      final (c, router) = await _app(tester, {});
      Future<void> ask() async {
        await _open(tester, router, AppRouter.sportWorkouts(Sport.gym));
        await tester.tap(find.text('Ask').hitTestable());
        await _settle(tester);
      }

      await ask();
      expect(_location(router), '/felix/chat/gym');
      final first = tester
          .widget<TextField>(find.byType(TextField).hitTestable())
          .controller!;
      expect(first.text, isNotEmpty);
      first.clear();
      await ask();
      expect(_location(router), '/felix/chat/gym');
      expect(
          find.byWidgetPredicate((w) =>
              w is TextField && (w.controller?.text.isNotEmpty ?? false)),
          findsOneWidget);
      expect(c.read(felixDraftProvider), isNull);
      await _leave(tester);
    });

    testWidgets('the header back arrow returns to the hub', (tester) async {
      final (_, router) = await _app(tester, {});
      await _open(tester, router, AppRouter.felixChat(AssistantTopic.app));
      await tester.tap(find.byTooltip('Back'));
      await _settle(tester);
      expect(_location(router), AppRouter.felix);
      await _leave(tester);
    });

    testWidgets('an unknown topic redirects to the hub', (tester) async {
      final (_, router) = await _app(tester, {});
      await _open(tester, router, '/felix/chat/chess');
      expect(_location(router), AppRouter.felix);
      await _leave(tester);
    });
  });

  group('small phone', () {
    for (final screen in [AppRouter.felix, AppRouter.felixAll]) {
      testWidgets('$screen: no overflow at 375x667, 1.3x text, ru',
          (tester) async {
        final (_, router) = await _app(
          tester,
          {
            AppConstants.keyLanguage: 'ru',
            WeekPlanStore.key: _plans([
              _plan('a', 20, Sport.gym, 'Спина и трицепс'),
              _plan('b', 24, Sport.football, 'Матч'),
            ]),
            'chat_history_gym': _history([
              _msg('g1', MessageSender.user, 'Жим встал на месте',
                  DateTime(2026, 10, 20, 14, 1)),
              _msg(
                  'g2',
                  MessageSender.assistant,
                  'Попробуй неделю разгрузки и вернись к привычным весам '
                      'после неё, не ускоряя прогресс',
                  DateTime(2026, 10, 20, 14, 2)),
            ]),
          },
          size: iPhoneSeSize,
          textScale: 1.3,
        );
        await _open(tester, router, screen);
        await expectNoOverflowWhileScrolling(
            tester, find.byType(Scrollable).first, -400);
        await expectNoOverflowWhileScrolling(
            tester, find.byType(Scrollable).first, -2000);
        await _leave(tester);
      });
    }
  });
}
