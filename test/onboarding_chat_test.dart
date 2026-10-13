import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitrix/core/constants/app_constants.dart';
import 'package:fitrix/core/router/app_router.dart';
import 'package:fitrix/core/widgets/app_button.dart';
import 'package:fitrix/features/chat/data/repositories/chat_repository.dart';
import 'package:fitrix/features/chat/data/services/chat_api_service.dart';
import 'package:fitrix/features/chat/presentation/providers/chat_provider.dart';
import 'package:fitrix/features/chat/presentation/screens/chat_screen.dart';
import 'package:fitrix/features/chat/presentation/widgets/quick_reply_chip.dart';
import 'package:fitrix/features/profile/data/repositories/profile_repository.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

class _FakeApi extends ChatApiService {
  final profiles = <Map<String, Object>?>[];

  @override
  Stream<String> streamMessage(
    String message,
    String conversationId, {
    String? topic,
    Map<String, Object>? profile,
    List<Map<String, String>>? history,
    String? language,
  }) async* {
    profiles.add(profile);
    yield 'Sure';
  }
}

void main() {
  late _FakeApi api;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    api = _FakeApi();
  });

  Future<void> pumpChat(WidgetTester tester,
      {bool reducedMotion = false}) async {
    tester.view.physicalSize = const Size(375, 667) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, __) => const ChatScreen()),
      GoRoute(
          path: AppRouter.transition,
          builder: (_, __) => const Text('transition-screen')),
    ]);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        chatMessagesProvider.overrideWith((ref) => ChatNotifier(ChatRepository(
              api,
              profileRepository: ProfileRepository(),
              greeting: const ['Hi, I am Felix'],
            ))),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data:
              MediaQuery.of(context).copyWith(disableAnimations: reducedMotion),
          child: child!,
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  Future<void> tapReply(WidgetTester tester, String label) async {
    await tester.tap(find.widgetWithText(QuickReplyChip, label));
    await tester.pumpAndSettle();
  }

  Future<void> finishOnboarding(WidgetTester tester) async {
    await tapReply(tester, AppConstants.fitnessGoals.first);
    await tapReply(tester, 'Gym');
    await tapReply(tester, 'Once a week or less');
    await tapReply(tester, 'Beginner');
  }

  final startKey = find.byKey(const ValueKey('start'));
  final input = find.byType(TextField);

  testWidgets('goal, sport and level answers land in the profile',
      (tester) async {
    await pumpChat(tester);
    final repo = ProfileRepository();

    await tapReply(tester, AppConstants.fitnessGoals.first);
    var profile = await repo.getProfile();
    expect(profile!.goal, AppConstants.fitnessGoals.first);
    // The very message that carries the goal already includes it.
    expect(api.profiles.last!['goal'], AppConstants.fitnessGoals.first);

    await tapReply(tester, 'Fitness');
    await tapReply(tester, 'Once a week or less');
    await tapReply(tester, 'Beginner');
    profile = await repo.getProfile();
    expect(profile!.goal, AppConstants.fitnessGoals.first);
    expect(profile.sports, ['Fitness']);
    expect(profile.experience, 'Beginner');
    expect(api.profiles.last!['experience'], 'Beginner');
    expect(api.profiles.last!['sports'], ['Fitness']);
  });

  testWidgets('a typed answer is saved too, other fields stay', (tester) async {
    SharedPreferences.setMockInitialValues({'user_name': 'Misha'});
    await pumpChat(tester);
    await tester.enterText(input, 'Get fit for a marathon');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    final profile = await ProfileRepository().getProfile();
    expect(profile!.goal, 'Get fit for a marathon');
    expect(profile.name, 'Misha');
  });

  testWidgets('Start is full width with an arrow and replaces the input',
      (tester) async {
    await pumpChat(tester);
    expect(input, findsOneWidget);
    expect(startKey, findsNothing);

    await finishOnboarding(tester);

    expect(startKey, findsOneWidget);
    final button = find.descendant(
        of: startKey, matching: find.byIcon(Icons.arrow_forward));
    expect(button, findsOneWidget);
    final width = tester.getSize(find.byType(AppButton)).width;
    expect(width, closeTo(375 - 2 * 16, 0.5));
    expect(input, findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Start fades and slides in; instant with reduced motion',
      (tester) async {
    await pumpChat(tester);
    await tapReply(tester, AppConstants.fitnessGoals.first);
    await tapReply(tester, 'Gym');
    await tapReply(tester, 'Once a week or less');
    await tester.tap(find.widgetWithText(QuickReplyChip, 'Beginner'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));

    double opacity() => tester
        .widgetList<Opacity>(
            find.descendant(of: startKey, matching: find.byType(Opacity)))
        .first
        .opacity;
    expect(startKey, findsOneWidget);
    expect(opacity(), lessThan(1));
    await tester.pumpAndSettle();
    expect(opacity(), 1);
  });

  testWidgets('no entrance animation with reduced motion', (tester) async {
    await pumpChat(tester, reducedMotion: true);
    await tapReply(tester, AppConstants.fitnessGoals.first);
    await tapReply(tester, 'Gym');
    await tapReply(tester, 'Once a week or less');
    await tester.tap(find.widgetWithText(QuickReplyChip, 'Beginner'));
    await tester.pump();
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 10));
    }
    expect(startKey, findsOneWidget);
    expect(find.byType(TweenAnimationBuilder<double>), findsNothing);
  });

  testWidgets('tapping Start goes to the transition screen', (tester) async {
    await pumpChat(tester);
    await finishOnboarding(tester);

    await tester.tap(find.descendant(
        of: startKey, matching: find.byIcon(Icons.arrow_forward)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();
    expect(find.text('transition-screen'), findsOneWidget);
  });
}
