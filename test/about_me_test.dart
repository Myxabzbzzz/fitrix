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
import 'package:fitrix/l10n/generated/app_localizations.dart';
import 'support/fake_auth.dart';

void main() {
  late SharedPreferences prefs;

  Future<void> pump(
    WidgetTester tester, {
    Map<String, Object> values = const {},
    Locale? locale,
    double textScale = 1,
  }) async {
    tester.view.physicalSize = const Size(375, 667) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({
      'user_name': 'Alex',
      'user_surname': 'Smith',
      'user_age': '30',
      'user_weight': '72.5',
      'user_height': '180',
      ...values,
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
    final router = GoRouter(initialLocation: '/me', routes: [
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
          GoRoute(path: 'about', builder: (_, __) => const AboutMeScreen()),
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
          data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(textScale)),
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
    final s = tester.widget<Semantics>(find.descendant(
        of: find.byKey(const Key('about-save')),
        matching: find.byType(Semantics)).first);
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
}
