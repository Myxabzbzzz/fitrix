import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitrix/core/constants/app_constants.dart';
import 'package:fitrix/core/router/app_router.dart';
import 'package:fitrix/core/session/app_session.dart';
import 'package:fitrix/features/language/presentation/providers/language_provider.dart';
import 'package:fitrix/main.dart';

Map<String, dynamic> _arb(String language) => jsonDecode(
    File('lib/l10n/app_$language.arb').readAsStringSync()) as Map<String, dynamic>;

Set<String> _placeholders(String text) =>
    RegExp(r'\{(\w+)\}').allMatches(text).map((m) => m.group(1)!).toSet();

Future<SharedPreferences> _pumpApp(
  WidgetTester tester,
  Map<String, Object> prefs,
) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues(prefs);
  final storage = await SharedPreferences.getInstance();
  final session = AppSession(storage);
  await tester.pumpWidget(FitrixRoot(
    prefs: storage,
    session: session,
    router: AppRouter.create(session),
  ));
  await tester.pumpAndSettle();
  return storage;
}

void main() {
  group('translations', () {
    final english = _arb('en');
    final keys = english.keys.where((k) => !k.startsWith('@')).toSet();

    for (final language in AppConstants.languages.keys) {
      test('$language has every key and placeholder of English', () {
        final arb = _arb(language);
        expect(arb['@@locale'], language);
        expect(arb.keys.where((k) => !k.startsWith('@')).toSet(), keys);
        for (final key in keys) {
          final text = arb[key] as String;
          expect(text.trim(), isNotEmpty, reason: '$language.$key');
          expect(_placeholders(text), _placeholders(english[key] as String),
              reason: '$language.$key');
        }
      });
    }
  });

  group('app language', () {
    test('saved choice, else the device language if translated, else English',
        () async {
      SharedPreferences.setMockInitialValues({'language': 'uz'});
      var prefs = await SharedPreferences.getInstance();
      expect(LanguageNotifier(prefs, deviceLanguage: 'ru').state, 'uz');

      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      expect(LanguageNotifier(prefs, deviceLanguage: 'es').state, 'es');
      expect(LanguageNotifier(prefs, deviceLanguage: 'de').state, 'en');
      expect(LanguageNotifier(prefs, deviceLanguage: 'es').isSaved, isFalse);
    });

    testWidgets('a saved language shows the app in it', (tester) async {
      await _pumpApp(tester, {
        'language': 'ru',
        'onboarding_complete': true,
        'user_name': 'Alex',
        'user_weight': '72',
      });
      AppRouter.router.go(AppRouter.me);
      await tester.pumpAndSettle();

      expect(find.text('Обо мне'), findsOneWidget);
      expect(find.text('Выйти'), findsOneWidget);
      expect(find.text('72 кг'), findsOneWidget);
    });

    testWidgets('picking a language switches the app right away and saves it',
        (tester) async {
      final prefs = await _pumpApp(tester, {});
      expect(find.text('Start your journey'), findsOneWidget);
      await tester.tap(find.text('Start your journey'));
      await tester.pumpAndSettle();

      expect(find.text('Continue'), findsOneWidget);
      await tester.tap(find.text('Español'));
      await tester.pumpAndSettle();
      expect(find.text('Continuar'), findsOneWidget);
      expect(prefs.getString('language'), 'es');

      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      expect(AppRouter.router.routerDelegate.currentConfiguration.uri.path,
          AppRouter.signIn);
    });

    testWidgets('Continue keeps the device default even without a tap',
        (tester) async {
      final prefs = await _pumpApp(tester, {});
      AppRouter.router.go(AppRouter.language);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(prefs.getString('language'), 'en');
    });
  });
}
