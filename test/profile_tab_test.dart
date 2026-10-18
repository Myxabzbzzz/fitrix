import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitrix/core/session/session_providers.dart';
import 'package:fitrix/core/settings/theme_mode_provider.dart';
import 'package:fitrix/features/profile/domain/streak.dart';
import 'package:fitrix/features/profile/presentation/screens/about_me_screen.dart';
import 'package:fitrix/features/profile/presentation/screens/profile_tab_screen.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

void main() {
  group('currentStreak', () {
    final today = DateTime(2026, 10, 13, 15);
    DateTime ago(int d, [int hour = 9]) =>
        DateTime(today.year, today.month, today.day - d, hour);

    test('empty is 0', () => expect(currentStreak([], today), 0));
    test('today only is 1', () => expect(currentStreak([today], today), 1));
    test('today, yesterday, 2 days ago is 3', () {
      expect(currentStreak([today, ago(1), ago(2)], today), 3);
    });
    test('yesterday only is 1', () {
      expect(currentStreak([ago(1)], today), 1);
    });
    test('3 days ago is 0', () => expect(currentStreak([ago(3)], today), 0));
    test('several workouts one day count once; gaps stop the run', () {
      expect(currentStreak([ago(0, 8), ago(0, 20), ago(1), ago(3)], today), 2);
    });
  });

  Future<ProviderContainer> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(375, 667) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({
      'user_name': 'Alex',
      'user_surname': 'Smith',
      'user_weight': '72.5',
    });
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    final router = GoRouter(initialLocation: '/me', routes: [
      GoRoute(
        path: '/me',
        builder: (_, __) => const ProfileTabScreen(),
        routes: [
          GoRoute(path: 'about', builder: (_, __) => const AboutMeScreen()),
        ],
      ),
    ]);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ));
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('shows name, initials and stats, no overflow on SE',
      (tester) async {
    await pump(tester);
    expect(find.text('Alex Smith'), findsOneWidget);
    expect(find.text('A'), findsOneWidget);
    expect(find.text('72.5'), findsOneWidget);
    expect(find.text('day streak'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('theme control writes themeModeProvider', (tester) async {
    final container = await pump(tester);
    // Settings sit below the fold on an SE-sized screen now.
    await tester.ensureVisible(find.text('Dark'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(container.read(themeModeProvider), ThemeMode.dark);
    await tester.tap(find.text('Light'));
    await tester.pumpAndSettle();
    expect(container.read(themeModeProvider), ThemeMode.light);
    await tester.tap(find.text('Auto'));
    await tester.pumpAndSettle();
    expect(container.read(themeModeProvider), ThemeMode.system);
  });

  testWidgets('About me row navigates to About me', (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(const Key('profile-about-me')));
    await tester.pumpAndSettle();
    expect(find.byType(AboutMeScreen), findsOneWidget);
  });
}
