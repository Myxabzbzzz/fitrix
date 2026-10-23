import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitrix/core/session/session_providers.dart';
import 'package:fitrix/core/time/today_provider.dart';
import 'package:fitrix/features/health/data/health_source.dart';
import 'package:fitrix/features/health/presentation/providers/health_providers.dart';
import 'package:fitrix/features/profile/presentation/screens/connected_apps_screen.dart';
import 'package:fitrix/features/profile/presentation/screens/profile_tab_screen.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';
import 'support/fake_health_source.dart';
import 'support/overflow.dart';

void main() {
  late FakeHealthSource fake;

  Future<ProviderContainer> pump(
    WidgetTester tester, {
    Widget screen = const ConnectedAppsScreen(),
    HealthPlatform platform = HealthPlatform.appleHealth,
    HealthAvailability availability = HealthAvailability.available,
    bool grant = true,
    double textScale = 1,
    Map<String, Object> prefsValues = const {},
  }) async {
    tester.view.physicalSize = const Size(375, 667) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues(prefsValues);
    final prefs = await SharedPreferences.getInstance();
    fake = FakeHealthSource(
        platform: platform,
        availabilityValue: availability,
        grantAccess: grant);
    final container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      healthSourceProvider.overrideWithValue(fake),
      clockProvider.overrideWithValue(() => DateTime(2026, 10, 23, 10)),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MediaQuery(
        data: MediaQueryData(
          size: const Size(375, 667),
          textScaler: TextScaler.linear(textScale),
        ),
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: screen,
        ),
      ),
    ));
    await tester.pumpAndSettle();
    return container;
  }

  Future<void> tapKey(WidgetTester tester, String key) async {
    final f = find.byKey(Key(key));
    if (f.evaluate().isEmpty) {
      await tester.dragUntilVisible(
          f, find.byType(ListView), const Offset(0, -100));
    }
    await tester.ensureVisible(f);
    await tester.pumpAndSettle();
    await tester.tap(f);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('iOS shows Apple Health and no Health Connect', (tester) async {
    await pump(tester);
    expect(find.byKey(const Key('connect-apple-health')), findsOneWidget);
    expect(find.byKey(const Key('connect-health-connect')), findsNothing);
    expect(find.text('Health Connect'), findsNothing);
  });

  testWidgets('Android shows Health Connect and no Apple Health',
      (tester) async {
    await pump(tester, platform: HealthPlatform.healthConnect);
    expect(find.byKey(const Key('connect-health-connect')), findsOneWidget);
    expect(find.byKey(const Key('connect-apple-health')), findsNothing);
    expect(find.text('Apple Health'), findsNothing);
  });

  testWidgets('Connect asks once, shows Connected and last read, toggle on',
      (tester) async {
    final c = await pump(tester);
    await tapKey(tester, 'connect-apple-health');
    expect(fake.requestAccessCalls, 1);
    expect(c.read(healthConnectionProvider).connected, isTrue);
    expect(find.text('Connected'), findsOneWidget);
    expect(find.text('Last read 10:00'), findsOneWidget);
    final toggle =
        tester.widget<Switch>(find.byKey(const Key('health-write-toggle')));
    expect(toggle.value, isTrue);
    expect(find.byKey(const Key('health-disconnect')), findsOneWidget);
  });

  testWidgets('write toggle persists the choice', (tester) async {
    final c = await pump(tester, prefsValues: {
      'health_connection_v1':
          '{"connected":true,"writeWorkouts":true,"lastReadAt":"2026-10-23T09:00:00.000"}',
    });
    expect(
        tester
            .widget<Switch>(find.byKey(const Key('health-write-toggle')))
            .value,
        isTrue);
    await tapKey(tester, 'health-write-toggle');
    expect(c.read(healthConnectionProvider).writeWorkouts, isFalse);
  });

  testWidgets('Disconnect: not connected, iOS shows the Settings hint',
      (tester) async {
    final c = await pump(tester, prefsValues: {
      'health_connection_v1': '{"connected":true,"writeWorkouts":true}',
    });
    await tapKey(tester, 'health-disconnect');
    expect(c.read(healthConnectionProvider).connected, isFalse);
    expect(find.byKey(const Key('connect-apple-health')), findsOneWidget);
    expect(
        find.textContaining('Settings › Health › Data Access'), findsOneWidget);
  });

  testWidgets('denied access: stays not connected, snack explains',
      (tester) async {
    final c = await pump(tester, grant: false);
    await tapKey(tester, 'connect-apple-health');
    expect(c.read(healthConnectionProvider).connected, isFalse);
    expect(find.textContaining("Access wasn't granted"), findsOneWidget);
    expect(find.byKey(const Key('connect-apple-health')), findsOneWidget);
  });

  testWidgets('Android without Health Connect offers Install', (tester) async {
    await pump(tester,
        platform: HealthPlatform.healthConnect,
        availability: HealthAvailability.notInstalled);
    expect(find.byKey(const Key('connect-health-connect')), findsNothing);
    await tapKey(tester, 'health-install');
    expect(fake.openInstallCalls, 1);
    expect(fake.requestAccessCalls, 0);
  });

  testWidgets('Garmin sheet points to Apple Health and is still Coming soon',
      (tester) async {
    await pump(tester);
    await tapKey(tester, 'connect-garmin');
    expect(find.text('Coming in a later update'), findsOneWidget);
    expect(find.textContaining('Apple Health'), findsWidgets);
    expect(
        find.textContaining('send its data to Apple Health'), findsOneWidget);
  });

  testWidgets('old coming-later copy is gone, new help copy is there',
      (tester) async {
    await pump(tester);
    expect(find.textContaining('When connecting arrives'), findsNothing);
    expect(
        find.textContaining('Health data stays on this phone'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -2000));
    await tester.pumpAndSettle();
    expect(
        find.textContaining('does not delete it from Apple Health',
            skipOffstage: false),
        findsOneWidget);
  });

  testWidgets('profile row counts the connected Health', (tester) async {
    await pump(tester, screen: const ProfileTabScreen(), prefsValues: {
      'user_name': 'Alex',
      'health_connection_v1': '{"connected":true,"writeWorkouts":true}',
    });
    expect(find.text('1 of 4 connected'), findsOneWidget);
  });

  testWidgets('SE at 1.3x: connected, not connected and sheet fit',
      (tester) async {
    await pump(tester, textScale: 1.3);
    expectNoOverflow(tester);
    await tapKey(tester, 'connect-apple-health');
    expectNoOverflow(tester);
    await tapKey(tester, 'connect-garmin');
    expectNoOverflow(tester);
  });

  testWidgets('SE at 1.3x: Android install and disconnected hint fit',
      (tester) async {
    await pump(tester,
        platform: HealthPlatform.healthConnect,
        availability: HealthAvailability.needsUpdate,
        textScale: 1.3);
    expectNoOverflow(tester);
  });

  testWidgets(
      'Android: back from the store, the Connect button replaces Install',
      (tester) async {
    await pump(tester,
        platform: HealthPlatform.healthConnect,
        availability: HealthAvailability.notInstalled);
    expect(find.byKey(const Key('health-install')), findsOneWidget);
    fake.availabilityValue = HealthAvailability.available;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('health-install')), findsNothing);
    expect(find.byKey(const Key('connect-health-connect')), findsOneWidget);
  });

  testWidgets('why-box names Apple Watch on iOS', (tester) async {
    await pump(tester);
    expect(find.textContaining('Apple Watch, Garmin'), findsOneWidget);
  });

  testWidgets('why-box has no Apple Watch on Android', (tester) async {
    await pump(tester, platform: HealthPlatform.healthConnect);
    expect(find.textContaining('Apple Watch'), findsNothing);
    expect(find.textContaining('Garmin, WHOOP and Mi Band'), findsOneWidget);
  });
}
