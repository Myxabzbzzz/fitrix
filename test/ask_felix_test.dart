import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitrix/core/felix/ask_felix.dart';
import 'package:fitrix/core/router/app_router.dart';
import 'package:fitrix/core/session/session_providers.dart';
import 'package:fitrix/features/chat/data/models/assistant_topic.dart';
import 'package:fitrix/features/chat/presentation/screens/felix_chat_screen.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';

void main() {
  late SharedPreferences prefs;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  testWidgets('askFelix opens Felix with the topic and the draft, unsent',
      (tester) async {
    tester.view.physicalSize = const Size(375, 667) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final gym = AssistantTopic.all.firstWhere((t) => t.sport == Sport.gym);
    final router = GoRouter(routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => Consumer(
          builder: (context, ref, _) => TextButton(
            onPressed: () => askFelix(context, ref,
                topic: gym, draft: 'Why did my bench stall?'),
            child: const Text('ask'),
          ),
        ),
      ),
      GoRoute(
        path: AppRouter.felix,
        builder: (_, __) => const FelixChatScreen(),
      ),
    ]);
    final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ));
    await tester.tap(find.text('ask'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(container.read(selectedAssistantTopicProvider), gym);
    expect(find.widgetWithText(TextField, 'Why did my bench stall?'),
        findsOneWidget);
    expect(container.read(felixDraftProvider), isNull);
    expect(tester.takeException(), isNull);
  });
}
