import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitrix/core/session/session_providers.dart';
import 'package:fitrix/features/running/data/activity_kind.dart';
import 'package:fitrix/features/running/data/activity_settings.dart';
import 'package:fitrix/features/running/presentation/widgets/activity_settings_sheet.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

import 'support/overflow.dart';

Future<ProviderContainer> _container(
    [Map<String, Object> values = const {}]) async {
  SharedPreferences.setMockInitialValues(values);
  final prefs = await SharedPreferences.getInstance();
  final c = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
  addTearDown(c.dispose);
  return c;
}

Future<void> _open(WidgetTester t, ProviderContainer c, ActivityKind kind,
    {String language = 'en', double scale = 1}) async {
  t.view.physicalSize = iPhoneSeSize * 3;
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
  await t.pumpWidget(UncontrolledProviderScope(
    container: c,
    child: MaterialApp(
      locale: Locale(language),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => showActivitySettingsSheet(context, kind),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  ));
  await t.tap(find.text('open'));
  await t.pumpAndSettle();
}

void main() {
  test('defaults: run on, ride and ski off', () async {
    final c = await _container();
    expect(c.read(activityVoiceProvider), {
      ActivityKind.run: true,
      ActivityKind.ride: false,
      ActivityKind.ski: false,
    });
  });

  test('a choice persists and is read back by a new container', () async {
    final c = await _container();
    c.read(activityVoiceProvider.notifier).set(ActivityKind.ride, true);
    c.read(activityVoiceProvider.notifier).set(ActivityKind.run, false);
    final prefs = c.read(sharedPreferencesProvider);
    final c2 = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
    addTearDown(c2.dispose);
    expect(c2.read(activityVoiceProvider), {
      ActivityKind.run: false,
      ActivityKind.ride: true,
      ActivityKind.ski: false,
    });
  });

  test('garbage in prefs falls back to the defaults', () async {
    final c = await _container({'activity_voice_v1': '[1,'});
    expect(c.read(activityVoiceProvider)[ActivityKind.run], true);
  });

  testWidgets('the sheet toggles the voice of its own activity', (t) async {
    final c = await _container();
    await _open(t, c, ActivityKind.ride);
    expect(find.text('Workout settings'), findsOneWidget);
    final toggle = find.byKey(const ValueKey('activity-voice-toggle'));
    expect(t.widget<Switch>(toggle).value, false);
    await t.tap(toggle);
    await t.pumpAndSettle();
    expect(t.widget<Switch>(toggle).value, true);
    expect(c.read(activityVoiceProvider)[ActivityKind.ride], true);
    expect(c.read(activityVoiceProvider)[ActivityKind.ski], false);
    expect(c.read(activityVoiceProvider)[ActivityKind.run], true);
  });

  for (final kind in ActivityKind.values) {
    testWidgets('SE x1.3 without overflow: $kind in ru', (t) async {
      final c = await _container();
      await _open(t, c, kind, language: 'ru', scale: 1.3);
      expectNoOverflow(t);
    });
  }
}
