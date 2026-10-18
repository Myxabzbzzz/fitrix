import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitrix/core/constants/app_constants.dart';
import 'package:fitrix/core/session/app_session.dart';
import 'package:fitrix/core/session/session_providers.dart';
import 'package:fitrix/features/auth/data/account_service.dart';
import 'package:fitrix/features/auth/presentation/providers/auth_provider.dart';
import 'package:fitrix/features/profile/presentation/screens/about_me_screen.dart';
import 'package:fitrix/features/profile/presentation/widgets/about_me_guard.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';
import 'support/fake_auth.dart';

void main() {
  late SharedPreferences prefs;
  late GoRouter router;

  Future<void> pump(
    WidgetTester tester, {
    Map<String, Object?> values = const {},
    Locale? locale,
    double textScale = 1,
  }) async {
    tester.view.physicalSize = const Size(375, 667) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final initial = <String, Object?>{
      'user_name': 'Alex',
      'user_surname': 'Smith',
      'user_age': '30',
      'user_weight': '72.5',
      'user_height': '180',
      ...values,
    };
    SharedPreferences.setMockInitialValues({
      for (final e in initial.entries)
        if (e.value != null) e.key: e.value!,
    });
    prefs = await SharedPreferences.getInstance();
    final account = AccountService(
      prefs: prefs,
      session: AppSession(prefs),
      auth: FakeAuthGateway(users: {}),
      remote: FakeProfileRemote(),
    );
    addTearDown(account.dispose);
    final container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      accountServiceProvider.overrideWithValue(account),
    ]);
    addTearDown(container.dispose);
    router = GoRouter(initialLocation: '/me', routes: [
      GoRoute(
        path: '/me',
        builder: (_, __) => Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => context.push('/me/about'),
              child: const Text('open'),
            ),
          ),
        ),
        routes: [
          GoRoute(
              path: 'about',
              builder: (_, __) => const AboutMeScreen(),
              onExit: aboutMeOnExit),
        ],
      ),
    ]);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: router,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Future<void> reveal(WidgetTester tester, Finder f) async {
    await tester.scrollUntilVisible(f, 200,
        scrollable: find.byType(Scrollable).first);
    await tester.pump();
  }

  bool saveEnabled(WidgetTester tester) {
    final s = tester.widget<Semantics>(find
        .descendant(
            of: find.byKey(const Key('about-save')),
            matching: find.byType(Semantics))
        .first);
    return s.properties.onTap != null;
  }

  testWidgets('save is disabled until something changes', (tester) async {
    await pump(tester);
    expect(saveEnabled(tester), isFalse);
    await tester.enterText(find.byKey(const Key('about-name')), 'Alexey');
    await tester.pump();
    expect(saveEnabled(tester), isTrue);
  });

  testWidgets('edits save to the profile and queue the upload', (tester) async {
    await pump(tester);
    await tester.enterText(find.byKey(const Key('about-name')), 'Alexey');
    await tester.enterText(find.byKey(const Key('about-weight')), '73,5');
    final goal = find.byKey(Key('about-goal-${AppConstants.fitnessGoals[1]}'));
    await reveal(tester, goal);
    await tester.tap(goal);
    final level = find.byKey(const Key('about-level-Advanced'));
    await reveal(tester, level);
    await tester.tap(level);
    final gym = find.byKey(const Key('about-sport-gym'));
    await reveal(tester, gym);
    await tester.tap(gym);
    await tester.pump();
    await tester.tap(find.byKey(const Key('about-save')));
    await tester.pumpAndSettle();

    expect(prefs.getString(AppConstants.keyUserName), 'Alexey');
    expect(prefs.getString(AppConstants.keyUserWeight), '73.5');
    expect(prefs.getString(AppConstants.keyUserExperience), 'Advanced');
    expect(prefs.getStringList(AppConstants.keyUserSports), ['Gym']);
    expect(prefs.getString(AppConstants.keyUserGoal),
        AppConstants.fitnessGoals[1]);
    expect(prefs.getBool(AccountService.keyProfileSyncPending), isTrue);
    expect(find.text('Saved'), findsOneWidget);
    expect(saveEnabled(tester), isFalse);
  });

  testWidgets('custom goal is saved as typed', (tester) async {
    await pump(tester);
    final other = find.byKey(const Key('about-goal-other'));
    await reveal(tester, other);
    await tester.tap(other);
    await tester.pump();
    await tester.enterText(
        find.byKey(const Key('about-goal-text')), 'Run a marathon');
    await tester.pump();
    await tester.tap(find.byKey(const Key('about-save')));
    await tester.pumpAndSettle();
    expect(prefs.getString(AppConstants.keyUserGoal), 'Run a marathon');
  });

  testWidgets('invalid age shows the error and keeps Save disabled',
      (tester) async {
    await pump(tester);
    await tester.enterText(find.byKey(const Key('about-age')), '3');
    await tester.pump();
    expect(find.text('Age must be between 5 and 120'), findsOneWidget);
    expect(saveEnabled(tester), isFalse);
  });

  testWidgets('back with changes asks to discard', (tester) async {
    await pump(tester);
    await tester.enterText(find.byKey(const Key('about-name')), 'Alexey');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
    await tester.pumpAndSettle();
    expect(find.text('Discard changes?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('about-keep-editing')));
    await tester.pumpAndSettle();
    expect(find.byType(AboutMeScreen), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('about-discard')));
    await tester.pumpAndSettle();
    expect(find.byType(AboutMeScreen), findsNothing);
    expect(prefs.getString(AppConstants.keyUserName), 'Alex');
  });

  testWidgets('back without changes leaves straight away', (tester) async {
    await pump(tester);
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
    await tester.pumpAndSettle();
    expect(find.byType(AboutMeScreen), findsNothing);
  });

  testWidgets('sports multi-select caps at 6', (tester) async {
    await pump(tester, values: {
      'user_sports': ['Gym', 'Fitness', 'Cycling', 'Skiing', 'Snowboarding'],
    });
    final running = find.byKey(const Key('about-sport-running'));
    await reveal(tester, running);
    await tester.tap(running);
    await tester.pump();
    expect(find.byKey(const Key('about-sports-limit')), findsNothing);
    final football = find.byKey(const Key('about-sport-football'));
    await reveal(tester, football);
    await tester.tap(football);
    await tester.pump();
    expect(find.byKey(const Key('about-sports-limit')), findsOneWidget);
    await tester.tap(find.byKey(const Key('about-save')));
    await tester.pumpAndSettle();
    expect(prefs.getStringList(AppConstants.keyUserSports)!.length, 6);
    expect(prefs.getStringList(AppConstants.keyUserSports),
        isNot(contains('Football')));
  });

  testWidgets('ru labels render', (tester) async {
    await pump(tester, locale: const Locale('ru'));
    expect(find.text('Имя'), findsOneWidget);
    expect(find.text('Сохранить'), findsOneWidget);
    await reveal(tester, find.text('Виды спорта'));
    expect(find.text('Виды спорта'), findsOneWidget);
    await reveal(tester, find.text('Спортзал'));
    expect(find.text('Спортзал'), findsOneWidget);
    expect(find.text('Начинающий'), findsOneWidget);
  });

  testWidgets('no overflow on SE at 1.3x text', (tester) async {
    await pump(tester, locale: const Locale('ru'), textScale: 1.3);
    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(ListView), const Offset(0, -1500));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('partial profile: errors show once the form is dirty',
      (tester) async {
    await pump(tester, values: {'user_weight': null});
    expect(saveEnabled(tester), isFalse);
    expect(find.text('Enter your weight'), findsNothing);
    final goal = find.byKey(Key('about-goal-${AppConstants.fitnessGoals[0]}'));
    await reveal(tester, goal);
    await tester.tap(goal);
    await tester.pump();
    await tester.drag(find.byType(ListView), const Offset(0, 1500));
    await tester.pump();
    expect(find.text('Enter your weight'), findsOneWidget);
    expect(saveEnabled(tester), isFalse);
    await tester.enterText(find.byKey(const Key('about-weight')), '70');
    await tester.pump();
    expect(saveEnabled(tester), isTrue);
  });

  testWidgets('chat-typed sports match case-insensitively', (tester) async {
    await pump(tester, values: {
      'user_sports': ['gym', 'Skiing'],
    });
    final skiing = find.byKey(const Key('about-sport-extra-Skiing'));
    await reveal(tester, skiing);
    expect(skiing, findsOneWidget);
    expect(find.byKey(const Key('about-sport-extra-gym')), findsNothing);
    expect(saveEnabled(tester), isFalse);
    await tester.tap(find.byKey(const Key('about-sport-fitness')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('about-save')));
    await tester.pumpAndSettle();
    expect(prefs.getStringList(AppConstants.keyUserSports),
        ['Gym', 'Skiing', 'Fitness']);
  });

  testWidgets('answers edit flag is set only when answers changed',
      (tester) async {
    await pump(tester);
    await tester.enterText(find.byKey(const Key('about-name')), 'Alexey');
    await tester.pump();
    await tester.tap(find.byKey(const Key('about-save')));
    await tester.pumpAndSettle();
    expect(prefs.getBool(AccountService.keyAnswersEdited), isNull);
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();

    final level = find.byKey(const Key('about-level-Advanced'));
    await reveal(tester, level);
    await tester.tap(level);
    await tester.pump();
    await tester.tap(find.byKey(const Key('about-save')));
    await tester.pumpAndSettle();
    expect(prefs.getBool(AccountService.keyAnswersEdited), isTrue);
  });

  testWidgets('leaving by another route asks to discard', (tester) async {
    await pump(tester);
    await tester.enterText(find.byKey(const Key('about-name')), 'Alexey');
    await tester.pump();
    await tester.pump();
    router.go('/me');
    await tester.pumpAndSettle();
    expect(find.text('Discard changes?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('about-keep-editing')));
    await tester.pumpAndSettle();
    expect(find.byType(AboutMeScreen), findsOneWidget);
    router.go('/me');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('about-discard')));
    await tester.pumpAndSettle();
    expect(find.byType(AboutMeScreen), findsNothing);
  });

  testWidgets('legacy formatting does not make the form dirty', (tester) async {
    await pump(tester,
        values: {'user_weight': '72,50 ', 'user_name': ' Alex '});
    expect(saveEnabled(tester), isFalse);
  });

  testWidgets('odd level shows as a pill; long goal opens under Other',
      (tester) async {
    await pump(tester, values: {
      'user_experience': 'a bit rusty',
      'user_goal': 'x' * 150,
    });
    expect(tester.takeException(), isNull);
    final other = find.byKey(const Key('about-goal-text'));
    await reveal(tester, other);
    expect(tester.widget<TextField>(other).controller!.text.length, 120);
    final lvl = find.byKey(const Key('about-level-extra-a bit rusty'));
    await reveal(tester, lvl);
    expect(lvl, findsOneWidget);
    expect(saveEnabled(tester), isFalse);
  });
}
