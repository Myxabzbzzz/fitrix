import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitrix/core/router/app_router.dart';
import 'package:fitrix/core/session/app_session.dart';
import 'package:fitrix/core/session/session_providers.dart';

import 'package:fitrix/features/transition/presentation/screens/chat_transition_screen.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

void main() {
  for (final language in ['ru', 'uz', 'es', 'en']) {
    testWidgets('the transition types and offers its button in $language',
        (tester) async {
      final l10n = lookupAppLocalizations(Locale(language));
      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
          locale: Locale(language),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ChatTransitionScreen(),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 600));
      await tester
          .pump(Duration(milliseconds: l10n.transitionReady.length * 70 + 50));
      await tester.pump(const Duration(milliseconds: 900));

      expect(find.text(l10n.transitionReady), findsOneWidget);
      expect(find.text(l10n.transitionGo), findsOneWidget);
    });
  }

  group('hand-off to Home', () {
    tearDown(() => ShellEntrance.handOff = null);

    Future<void> finish(WidgetTester tester, AppSession session) async {
      final l10n = lookupAppLocalizations(const Locale('en'));
      final router = GoRouter(routes: [
        GoRoute(path: '/', builder: (_, __) => const ChatTransitionScreen()),
        GoRoute(
            path: AppRouter.home,
            builder: (_, __) => const Scaffold(body: Text('home'))),
      ]);
      await tester.pumpWidget(ProviderScope(
        overrides: [appSessionProvider.overrideWithValue(session)],
        child: MaterialApp.router(
          routerConfig: router,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ));
      await tester.pump(const Duration(milliseconds: 600));
      await tester
          .pump(Duration(milliseconds: l10n.transitionReady.length * 70 + 50));
      await tester.pump(const Duration(milliseconds: 900));
      await tester.tap(find.text(l10n.transitionGo));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));
      await tester.pump(const Duration(milliseconds: 100));
    }

    testWidgets('is set once onboarding is completed, then Home opens',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final session = AppSession(await SharedPreferences.getInstance());
      await finish(tester, session);

      expect(ShellEntrance.handOff, ChatTransitionScreen.foreground);
      expect(find.text('home'), findsOneWidget);
      expect(session.onboardingComplete, isTrue);
    });

    testWidgets('is not left behind when completing onboarding fails',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final session = _FailingSession(await SharedPreferences.getInstance());
      await finish(tester, session);

      expect(ShellEntrance.handOff, isNull);
      expect(find.text('home'), findsNothing);

      // The circle shrinks back and Go tries again.
      await tester.pump(const Duration(milliseconds: 900));
      await tester.tap(
          find.text(lookupAppLocalizations(const Locale('en')).transitionGo));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));
      await tester.pump(const Duration(milliseconds: 100));
      expect(session.attempts, 2);
    });
  });
}

class _FailingSession extends AppSession {
  _FailingSession(super.prefs);

  int attempts = 0;

  @override
  Future<void> completeOnboarding({bool notify = true}) {
    attempts++;
    return Future.error(StateError('prefs write failed'));
  }
}
