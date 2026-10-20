import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitrix/core/constants/app_constants.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/features/chat/data/models/chat_action.dart';
import 'package:fitrix/features/chat/data/repositories/chat_repository.dart';
import 'package:fitrix/features/chat/data/services/chat_api_service.dart';
import 'package:fitrix/features/chat/presentation/providers/chat_provider.dart';
import 'package:fitrix/features/chat/presentation/screens/chat_screen.dart';
import 'package:fitrix/features/chat/presentation/screens/felix_chat_screen.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';
import 'package:fitrix/features/chat/presentation/widgets/quick_reply_chip.dart';

/// Replies with [reply] chunks, holding the stream open until [release].
class _FakeApi extends ChatApiService {
  _FakeApi();

  Completer<void> release = Completer<void>()..complete();
  final sent = <String>[];

  @override
  Stream<String> streamMessage(
    String message,
    String conversationId, {
    String? topic,
    Map<String, Object>? profile,
    List<Map<String, String>>? history,
    String? language,
    List<String>? images,
    void Function(ChatAction action)? onAction,
  }) async* {
    sent.add(message);
    yield 'Sure';
    await release.future;
  }
}

void main() {
  late _FakeApi api;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    api = _FakeApi();
  });

  Future<void> pumpChat(WidgetTester tester) async {
    tester.view.physicalSize = const Size(375, 667) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        chatMessagesProvider.overrideWith((ref) => ChatNotifier(ChatRepository(
              api,
              greeting: () => const ['Hi, I am Felix', 'Pick a goal'],
            ))),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ChatScreen(),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 500));
  }

  final chips = find.byType(QuickReplyChip);
  final composer = find.byKey(const ValueKey('chat-composer'));

  testWidgets('quick replies live in the composer area, not the list',
      (tester) async {
    await pumpChat(tester);

    expect(chips, findsWidgets);
    expect(find.descendant(of: composer, matching: chips), findsWidgets);
    expect(find.descendant(of: find.byType(ListView), matching: chips),
        findsNothing);
    // Scrolls horizontally, directly above the input.
    final scroll = find.descendant(
        of: composer, matching: find.byType(SingleChildScrollView));
    expect(tester.widget<SingleChildScrollView>(scroll.first).scrollDirection,
        Axis.horizontal);
    expect(tester.takeException(), isNull);
  });

  testWidgets('quick replies hide while Felix replies; tap sends',
      (tester) async {
    api.release = Completer<void>();
    await pumpChat(tester);

    await tester.tap(chips.first);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text(AppConstants.fitnessGoals.first), findsOneWidget,
        reason: 'the sent message is in the list');
    expect(chips, findsNothing, reason: 'hidden while the reply streams');
    expect(api.sent.single, AppConstants.fitnessGoals.first);

    api.release.complete();
    await tester.pumpAndSettle();
    expect(chips, findsWidgets, reason: 'next options appear afterwards');
  });

  testWidgets('bubbles use palette colors, radius 18, max width 247',
      (tester) async {
    await pumpChat(tester);
    await tester.tap(chips.first);
    await tester.pumpAndSettle();

    final palette = AppPalette.of(tester.element(find.byType(ChatScreen)));
    BoxDecoration deco(Finder f) =>
        tester.widget<Container>(f).decoration! as BoxDecoration;

    final bubbles = find.byKey(const ValueKey('chat-bubble'));
    final felix = bubbles.first;
    final user = find.descendant(
        of: bubbles, matching: find.text(AppConstants.fitnessGoals.first));
    final userBubble = find.ancestor(of: user, matching: bubbles).first;

    expect(deco(felix).color, palette.bubble);
    expect(deco(userBubble).color, palette.bubbleUser);
    expect(deco(felix).borderRadius, BorderRadius.circular(18));
    expect(tester.getSize(felix).width, lessThanOrEqualTo(247));
    expect(tester.widget<Text>(user).style!.color, palette.onBubbleUser);
  });

  testWidgets('groups sit 2px apart; avatar 24 only on the last Felix bubble',
      (tester) async {
    await pumpChat(tester);

    final bubbles = find.byKey(const ValueKey('chat-bubble'));
    expect(bubbles, findsNWidgets(2));
    final gap = tester.getTopLeft(bubbles.at(1)).dy -
        tester.getBottomLeft(bubbles.at(0)).dy;
    expect(gap, 2);

    final avatar = find.byKey(const ValueKey('felix-avatar'));
    expect(avatar, findsNWidgets(2)); // one in the header, one in the list
    final listAvatar =
        find.descendant(of: find.byType(ListView), matching: avatar);
    expect(listAvatar, findsOneWidget);
    expect(tester.getSize(listAvatar), const Size(24, 24));
    final header = find.descendant(of: find.byType(AppBar), matching: avatar);
    expect(tester.getSize(header), const Size(32, 32));
    expect(find.text(AppConstants.assistantSubtitle), findsOneWidget);
  });

  group('Felix tab', () {
    Future<void> pumpFelix(WidgetTester tester) async {
      tester.view.physicalSize = const Size(375, 667) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(ProviderScope(
        overrides: [
          chatMessagesProvider
              .overrideWith((ref) => ChatNotifier(ChatRepository(
                    api,
                    greeting: () => const ['Hi, I am Felix'],
                  ))),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: FelixChatScreen(),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 500));
    }

    testWidgets(
        'quick replies sit above the input, hide while streaming, '
        'tap sends', (tester) async {
      api.release = Completer<void>();
      await pumpFelix(tester);

      final composer = find.byKey(const ValueKey('chat-composer'));
      final chips = find.byType(QuickReplyChip);
      expect(find.descendant(of: composer, matching: chips), findsNWidgets(3));
      expect(find.descendant(of: find.byType(ListView), matching: chips),
          findsNothing);
      expect(tester.getBottomLeft(chips.first).dy,
          lessThanOrEqualTo(tester.getTopLeft(find.byType(TextField)).dy));
      expect(tester.getSize(chips.first).height, 32);

      await tester.tap(find.text('Plan my week'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      expect(api.sent.single, 'Plan my week');
      expect(chips, findsNothing);

      api.release.complete();
      await tester.pumpAndSettle();
      expect(chips, findsNWidgets(3));
      expect(tester.takeException(), isNull);
    });
  });
}
