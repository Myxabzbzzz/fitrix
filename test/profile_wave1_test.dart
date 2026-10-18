import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitrix/core/router/app_router.dart';
import 'package:fitrix/core/session/session_providers.dart';
import 'package:fitrix/features/profile/data/performance_store.dart';
import 'package:fitrix/features/profile/domain/hr_zones.dart';
import 'package:fitrix/features/profile/presentation/screens/connected_apps_screen.dart';
import 'package:fitrix/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:fitrix/features/profile/presentation/screens/hr_zones_screen.dart';
import 'package:fitrix/features/profile/presentation/screens/profile_tab_screen.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

void main() {
  group('zones maths', () {
    test('karvonenZones(56, 194)', () {
      final z = karvonenZones(56, 194);
      expect(z, hasLength(5));
      expect((z[0].low, z[0].high), (125, 139));
      expect((z[1].low, z[1].high), (139, 153));
      expect((z[4].low, z[4].high), (180, 194));
      expect(z[0].karvonenRange, '125–139');
    });

    test('frielZones(172)', () {
      final z = frielZones(172);
      expect(z, hasLength(7));
      expect(z[0].high, 146);
      expect(z[0].frielRange(first: true), '< 146');
      expect(z[4].name, 'Z5a');
      expect(z[4].low, 172);
      expect(z[4].frielRange(first: false), '172–176');
      expect(z[6].high, isNull);
      expect(z[6].frielRange(first: false), '≥ 182');
    });

    test('tanakaMaxHr(26) == 190', () => expect(tanakaMaxHr(26), 190));
  });

  Future<ProviderContainer> pumpScreen(
    WidgetTester tester,
    Widget screen, {
    Map<String, Object> prefsValues = const {},
    double textScale = 1,
    List<String> pushed = const [],
  }) async {
    tester.view.physicalSize = const Size(375, 667) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues(prefsValues);
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    final router = GoRouter(initialLocation: '/', routes: [
      GoRoute(path: '/', builder: (_, __) => screen),
      for (final p in [AppRouter.editProfile, AppRouter.hrZones])
        GoRoute(path: p, builder: (_, __) => Scaffold(body: Text('route $p'))),
    ]);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MediaQuery(
        data: MediaQueryData(
          size: const Size(375, 667),
          textScaler: TextScaler.linear(textScale),
        ),
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    ));
    await tester.pumpAndSettle();
    return container;
  }

  const base = <String, Object>{
    'user_name': 'Alex',
    'user_surname': 'Smith',
    'user_age': '26',
    'user_weight': '72.5',
    'user_height': '180',
  };

  group('HR zones screen', () {
    testWidgets('without age or max HR shows the profile prompt',
        (tester) async {
      await pumpScreen(tester, const HrZonesScreen(),
          prefsValues: {'user_name': 'Alex'});
      expect(find.byKey(const Key('zones-complete-profile')), findsOneWidget);
      expect(find.textContaining('Tanaka'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('max HR missing but age known shows the Tanaka estimate',
        (tester) async {
      await pumpScreen(tester, const HrZonesScreen(), prefsValues: base);
      expect(find.textContaining('= 190 bpm'), findsOneWidget);
    });

    testWidgets('shows Karvonen and Friel tables', (tester) async {
      await pumpScreen(tester, const HrZonesScreen(), prefsValues: {
        ...base,
        performanceProfileKey: jsonEncode({
          'restingHr': 56,
          'maxHr': 194,
          'lthr': 172,
        }),
      });
      expect(find.text('125–139'), findsOneWidget);
      expect(find.text('180–194'), findsOneWidget);
      await tester.tap(find.text('LTHR (Friel)'));
      await tester.pumpAndSettle();
      expect(find.text('< 146'), findsOneWidget);
      expect(find.text('172–176'), findsOneWidget);
      expect(find.text('≥ 182'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('SE at 1.3x text: no overflow', (tester) async {
      await pumpScreen(tester, const HrZonesScreen(),
          textScale: 1.3,
          prefsValues: {
            ...base,
            performanceProfileKey:
                jsonEncode({'restingHr': 56, 'maxHr': 194, 'lthr': 172}),
          });
      expect(tester.takeException(), isNull);
    });
  });

  group('Edit profile', () {
    Future<void> enter(WidgetTester tester, String key, String text) async {
      await tester.ensureVisible(find.byKey(Key(key)));
      await tester.enterText(find.byKey(Key(key)), text);
      await tester.pump();
    }

    testWidgets('saves base fields and performance fields', (tester) async {
      final c = await pumpScreen(tester, const EditProfileScreen(),
          prefsValues: base);
      await enter(tester, 'edit-weight', '74');
      await enter(tester, 'edit-resting', '56');
      await enter(tester, 'edit-max', '194');
      await enter(tester, 'edit-ftp', '245');
      await enter(tester, 'edit-5k', '20:31');
      await tester.ensureVisible(find.byKey(const Key('edit-sex-male')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('edit-sex-male')));
      await tester.pump();
      await tester.ensureVisible(find.byKey(const Key('edit-save')));
      await tester.tap(find.byKey(const Key('edit-save')));
      await tester.pumpAndSettle();

      final p = c.read(performanceProfileProvider);
      expect(p.restingHr, 56);
      expect(p.maxHr, 194);
      expect(p.ftpW, 245);
      expect(p.fiveK, const Duration(minutes: 20, seconds: 31));
      expect(p.sex, Sex.male);
      final prefs = c.read(sharedPreferencesProvider);
      expect(prefs.getString(performanceProfileKey), isNotNull);
      expect(prefs.getString('user_weight'), '74');
      expect(prefs.getString('user_surname'), 'Smith');
    });

    testWidgets('rejects HR 300 and saves nothing', (tester) async {
      final c = await pumpScreen(tester, const EditProfileScreen(),
          prefsValues: base);
      await enter(tester, 'edit-weight', '74');
      await enter(tester, 'edit-max', '300');
      await tester.ensureVisible(find.byKey(const Key('edit-save')));
      await tester.tap(find.byKey(const Key('edit-save')));
      await tester.pumpAndSettle();
      expect(find.text('Enter 30–230 bpm'), findsOneWidget);
      expect(c.read(performanceProfileProvider).maxHr, isNull);
      expect(
          c.read(sharedPreferencesProvider).getString('user_weight'), '72.5');
    });

    testWidgets('rejects a 5K outside 12:00-60:00', (tester) async {
      final c = await pumpScreen(tester, const EditProfileScreen(),
          prefsValues: base);
      await enter(tester, 'edit-5k', '9:00');
      await tester.ensureVisible(find.byKey(const Key('edit-save')));
      await tester.tap(find.byKey(const Key('edit-save')));
      await tester.pumpAndSettle();
      expect(find.text('Enter a time from 12:00 to 60:00'), findsOneWidget);
      expect(c.read(performanceProfileProvider).fiveK, isNull);
    });

    testWidgets('SE at 1.3x text: no overflow', (tester) async {
      await pumpScreen(tester, const EditProfileScreen(),
          textScale: 1.3, prefsValues: base);
      expect(tester.takeException(), isNull);
    });
  });

  group('Connected apps', () {
    testWidgets('4 apps not connected; Connect opens a disabled sheet',
        (tester) async {
      await pumpScreen(tester, const ConnectedAppsScreen());
      expect(find.text('Not connected', skipOffstage: false), findsNWidgets(4));
      expect(find.text('Apple Health'), findsOneWidget);
      expect(find.text('WHOOP', skipOffstage: false), findsOneWidget);
      await tester.tap(find.byKey(const Key('connect-garmin')));
      await tester.pumpAndSettle();
      expect(find.text('Connect Garmin Connect'), findsOneWidget);
      expect(find.text('Coming in a later update'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('SE at 1.3x text: no overflow', (tester) async {
      await pumpScreen(tester, const ConnectedAppsScreen(), textScale: 1.3);
      await tester.scrollUntilVisible(
          find.byKey(const Key('connect-garmin')), 100);
      await tester.tap(find.byKey(const Key('connect-garmin')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('Profile tab', () {
    testWidgets('shows 0 of 4 connected and the zones summary', (tester) async {
      await pumpScreen(tester, const ProfileTabScreen(), prefsValues: {
        ...base,
        'user_experience': 'Intermediate',
        'user_goal': 'Build muscle',
        'user_sports': ['Gym', 'Running'],
        performanceProfileKey: jsonEncode({'restingHr': 56, 'maxHr': 194}),
      });
      expect(find.text('0 of 4 connected'), findsOneWidget);
      expect(find.text('Rest 56 · max 194 bpm'), findsOneWidget);
      expect(find.text('180'), findsOneWidget);
      expect(find.text('26'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('zones row says Set up without data; SE 1.3x no overflow',
        (tester) async {
      await pumpScreen(tester, const ProfileTabScreen(),
          textScale: 1.3, prefsValues: base);
      expect(find.text('Set up'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
