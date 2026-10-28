import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitrix/core/session/session_providers.dart';
import 'package:fitrix/features/chat/data/felix_snapshot.dart';
import 'package:fitrix/features/chat/data/models/assistant_topic.dart';
import 'package:fitrix/features/chat/data/models/chat_action.dart';
import 'package:fitrix/features/chat/data/models/chat_message.dart';
import 'package:fitrix/features/chat/data/services/chat_api_service.dart';
import 'package:fitrix/features/chat/presentation/providers/chat_provider.dart';
import 'package:fitrix/features/chat/presentation/providers/felix_snapshot_provider.dart';
import 'package:fitrix/features/chat/presentation/screens/felix_chat_screen.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

/// Answers with [reply], or throws [failure] while it is set.
class _FakeApi extends ChatApiService {
  ChatFailure? failure;
  String reply = 'Sure';
  int calls = 0;

  @override
  Stream<String> streamMessage(
    String message,
    String conversationId, {
    String? topic,
    Map<String, Object>? profile,
    List<Map<String, String>>? history,
    String? language,
    Map<String, Object>? context,
    List<String>? images,
    void Function(ChatAction action)? onAction,
  }) async* {
    calls++;
    final failure = this.failure;
    if (failure != null) throw ChatException(failure);
    yield reply;
  }
}

final _topic = AssistantTopic.forSport(Sport.running);

ChatMessage _message(int i, MessageSender sender, String text) => ChatMessage(
      id: 'm$i',
      content: text,
      sender: sender,
      timestamp: DateTime(2026, 10, 20, 9, i),
    );

void main() {
  late _FakeApi api;
  late SharedPreferences prefs;

  Future<void> pump(WidgetTester tester, {List<ChatMessage>? stored}) async {
    SharedPreferences.setMockInitialValues({
      if (stored != null)
        _topic.historyKey: ChatMessage.encodeMessages(stored),
    });
    prefs = await SharedPreferences.getInstance();
    tester.view.physicalSize = const Size(375, 667) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      chatApiServiceProvider.overrideWithValue(api),
      felixSnapshotProvider
          .overrideWith((ref, t) => FelixSnapshot(today: DateTime(2026))),
    ]);
    addTearDown(container.dispose);
    // The chat was loaded before (as when it is reopened from the hub).
    final chat = topicChatMessagesProvider(_topic);
    container.listen(chat, (_, __) {});
    await tester.runAsync(() async {
      while (container.read(chat).valueOrNull == null) {
        await Future<void>.delayed(Duration.zero);
      }
    });
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: FelixChatScreen(topic: _topic),
      ),
    ));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  setUp(() => api = _FakeApi());

  final ru = lookupAppLocalizations(const Locale('ru'));

  testWidgets('a long chat opens at its newest message', (tester) async {
    await pump(tester, stored: [
      for (var i = 0; i < 30; i++)
        _message(
          i,
          i.isEven ? MessageSender.user : MessageSender.assistant,
          i == 29 ? 'Newest answer' : 'Message $i with some text to read',
        ),
    ]);

    final list = tester.state<ScrollableState>(find
        .ancestor(
            of: find.byKey(const ValueKey('chat-bubble')).first,
            matching: find.byType(Scrollable))
        .first);
    expect(list.position.pixels, greaterThan(0));
    expect(list.position.pixels, list.position.maxScrollExtent);
    expect(find.text('Newest answer'), findsOneWidget);
    expect(find.text('Message 0 with some text to read'), findsNothing);
  });

  testWidgets(
      'Felix unavailable: the question is marked, Retry asks again; '
      'nothing is made up', (tester) async {
    api.failure = ChatFailure.unavailable;
    await pump(tester);

    await tester.enterText(find.byType(TextField), 'Привет, ты тут?');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.text('Привет, ты тут?'), findsOneWidget);
    expect(find.text(ru.chatFailedUnavailable), findsOneWidget);
    expect(find.byKey(const ValueKey('chat-retry')), findsOneWidget);
    expect(prefs.getString(_topic.historyKey), isNot(contains('Thanks')));

    api
      ..failure = null
      ..reply = 'Да, я здесь.';
    await tester.tap(find.byKey(const ValueKey('chat-retry')));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.text('Да, я здесь.'), findsOneWidget);
    expect(find.byKey(const ValueKey('chat-failed')), findsNothing);
    expect(api.calls, 2);
  });

  testWidgets('a question left unanswered by a closed app offers a retry',
      (tester) async {
    await pump(tester, stored: [
      _message(0, MessageSender.assistant, 'Hi, I am your running coach'),
      _message(1, MessageSender.user, 'Как мне улучшить темп на 5 км?'),
    ]);

    expect(find.text(ru.chatFailedInterrupted), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('chat-retry')));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Sure'), findsOneWidget);
    expect(find.byKey(const ValueKey('chat-failed')), findsNothing);
  });
}
