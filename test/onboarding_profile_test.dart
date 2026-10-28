import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitrix/core/router/app_router.dart';
import 'package:fitrix/core/session/session_providers.dart';
import 'package:fitrix/core/time/today_provider.dart';
import 'package:fitrix/features/nutrition/presentation/providers/nutrition_provider.dart';
import 'package:fitrix/features/profile/data/performance_store.dart';
import 'package:fitrix/features/profile/presentation/screens/profile_screen.dart';
import 'package:fitrix/features/progress/data/body_weight_store.dart';
import 'package:fitrix/features/progress/presentation/providers/progress_providers.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

import 'support/overflow.dart';

final _now = DateTime(2026, 10, 20, 9, 30);

void main() {
  Future<ProviderContainer> pump(WidgetTester t,
      {Map<String, Object> values = const {},
      String language = 'en',
      double textScale = 1}) async {
    t.view.physicalSize = iPhoneSeSize * 3;
    t.view.devicePixelRatio = 3;
    t.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(t.view.reset);
    addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
    SharedPreferences.setMockInitialValues(values);
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      clockProvider.overrideWithValue(() => _now),
    ]);
    addTearDown(container.dispose);
    final router = GoRouter(initialLocation: AppRouter.profile, routes: [
      GoRoute(
          path: AppRouter.profile, builder: (_, __) => const ProfileScreen()),
      GoRoute(path: AppRouter.chat, builder: (_, __) => const Text('chat')),
    ]);
    await t.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: router,
        locale: Locale(language),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ));
    await t.pumpAndSettle();
    return container;
  }

  Future<void> fill(WidgetTester t) async {
    for (final (key, text) in [
      ('profile-name', 'Eli'),
      ('profile-age', '29'),
      ('profile-weight', '78'),
      ('profile-height', '181'),
    ]) {
      await t.enterText(find.byKey(Key(key)), text);
    }
    await t.pump();
  }

  Future<void> tapKey(WidgetTester t, String key) async {
    await t.ensureVisible(find.byKey(Key(key)));
    await t.pumpAndSettle();
    await t.tap(find.byKey(Key(key)));
    await t.pumpAndSettle();
  }

  Future<void> continueTap(WidgetTester t) async {
    final button = find.byType(ElevatedButton);
    await t.ensureVisible(button);
    await t.pumpAndSettle();
    await t.tap(button);
    await t.pumpAndSettle();
  }

  testWidgets(
      'sex is asked; with it Nutrition has targets and the weight starts '
      'the body-weight chart', (t) async {
    final c = await pump(t);
    final l10n = lookupAppLocalizations(const Locale('en'));
    await fill(t);

    await continueTap(t);
    expect(find.text('chat'), findsNothing, reason: 'sex not picked yet');
    expect(find.text(l10n.profileErrSexRequired), findsOneWidget);

    await tapKey(t, 'profile-sex-female');
    expect(find.text(l10n.profileErrSexRequired), findsNothing);
    await continueTap(t);

    expect(find.text('chat'), findsOneWidget);
    expect(c.read(performanceProfileProvider).sex, Sex.female);
    expect(c.read(missingTargetInputsProvider), isEmpty);
    expect(c.read(targetsProvider), isNotNull);
    final weighIns = c.read(bodyWeightProvider);
    expect(weighIns, hasLength(1));
    expect(weighIns.single.kg, 78);
    expect(weighIns.single.at, _now);
  });

  testWidgets('an existing body-weight history is left alone', (t) async {
    final c = await pump(t, values: {
      BodyWeightStore.key: '[{"at":"2026-09-01T08:00:00.000","kg":80.0}]',
      performanceProfileKey: '{"sex":"male","maxHr":190}',
    });
    await fill(t);
    await continueTap(t);

    expect(find.text('chat'), findsOneWidget,
        reason: 'the saved sex is prefilled');
    expect(c.read(bodyWeightProvider).single.kg, 80);
    expect(c.read(performanceProfileProvider).maxHr, 190);
  });

  testWidgets('SE, text 1.3, ru: the form with the sex choice fits', (t) async {
    await pump(t, language: 'ru', textScale: 1.3);
    await t.ensureVisible(find.byKey(const Key('profile-sex')));
    await t.pumpAndSettle();
    expect(find.text('Женский'), findsOneWidget);
    expectNoOverflow(t);
  });
}
