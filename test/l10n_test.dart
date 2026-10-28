import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fitrix/features/workouts/presentation/widgets/sport_coach_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitrix/core/session/session_providers.dart';
import 'package:fitrix/core/widgets/coach_card.dart';
import 'package:fitrix/core/widgets/feature_tile.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/features/workouts/data/workout_catalog.dart';
import 'package:fitrix/features/workouts/presentation/providers/workouts_provider.dart';
import 'package:fitrix/features/workouts/presentation/screens/sport_workouts_screen.dart';
import 'package:fitrix/features/workouts/presentation/widgets/active_workout_sheet.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';
import 'package:fitrix/features/language/presentation/screens/language_screen.dart';
import 'package:fitrix/features/profile/presentation/screens/profile_tab_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitrix/core/constants/app_constants.dart';
import 'package:fitrix/core/router/app_router.dart';
import 'package:fitrix/core/session/app_session.dart';
import 'package:fitrix/features/language/presentation/providers/language_provider.dart';
import 'package:fitrix/main.dart';

Map<String, dynamic> _arb(String language) =>
    jsonDecode(File('lib/l10n/app_$language.arb').readAsStringSync())
        as Map<String, dynamic>;

/// `{name}` and `{name, plural, ...}` placeholders; the bodies of plural
/// branches (`=1{ride}`, `few{поездки}`) are text, not placeholders.
Set<String> _placeholders(String text) =>
    RegExp(r'(?<!(?:=\d+|\b(?:zero|one|two|few|many|other)))\{(\w+)(?=[,}])')
        .allMatches(text)
        .map((m) => m.group(1)!)
        .toSet();

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
      expect(find.text('72'), findsOneWidget);
      expect(find.text('кг · вес'), findsOneWidget);
    });

    testWidgets('changing the language from Profile returns to Profile',
        (tester) async {
      await _pumpApp(tester, {
        'onboarding_complete': true,
        'user_name': 'Alex',
      });
      AppRouter.router.go(AppRouter.me);
      await tester.pumpAndSettle();
      expect(find.text('Profile'), findsWidgets);

      await tester.tap(find.byKey(const Key('profile-language')));
      await tester.pumpAndSettle();
      expect(find.byType(LanguageScreen), findsOneWidget);
      await tester.tap(find.text('Русский'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Продолжить'));
      await tester.pumpAndSettle();

      expect(find.byType(LanguageScreen), findsNothing);
      expect(find.byType(ProfileTabScreen), findsOneWidget);
      expect(find.text('Профиль'), findsWidgets);
      expect(find.text('Выйти'), findsOneWidget);
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

  group('uz apostrophes', () {
    test('o‘ and g‘ use U+2018, never an ASCII apostrophe', () {
      final uz = _arb('uz');
      for (final e in uz.entries) {
        if (e.value is! String) continue;
        expect(RegExp(r"[oOgG]'").hasMatch(e.value as String), isFalse,
            reason: e.key);
      }
    });
  });

  group('Russian unit labels agree with their number', () {
    final ru = lookupAppLocalizations(const Locale('ru'));
    test('ski days, descents, rides', () {
      expect([1, 2, 5, 21].map(ru.skiUnitDays),
          ['лыжный день', 'лыжных дня', 'лыжных дней', 'лыжный день']);
      expect([0, 1, 3].map(ru.skiUnitDescents), ['спусков', 'спуск', 'спуска']);
      expect([1, 2, 7].map(ru.cyclingUnitRides),
          ['поездка', 'поездки', 'поездок']);
    });
    test('profile workouts and streak', () {
      expect([1, 3, 7].map(ru.profileWorkouts),
          ['тренировка', 'тренировки', 'тренировок']);
      expect([1, 2, 5].map(ru.profileDayStreak),
          ['день подряд', 'дня подряд', 'дней подряд']);
    });
  });

  group('localized workout copy', () {
    Future<ProviderContainer> pumpRu(WidgetTester tester, Widget home) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
      addTearDown(container.dispose);
      container
          .read(activeWorkoutProvider.notifier)
          .start(WorkoutCatalog.defaults.first);
      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: home,
        ),
      ));
      await tester.pump();
      return container;
    }

    testWidgets('active workout sheet shows "x из y подходов" in ru',
        (tester) async {
      final container =
          await pumpRu(tester, const Scaffold(body: ActiveWorkoutSheet()));
      container.read(activeWorkoutExpandedProvider.notifier).state = true;
      await tester.pumpAndSettle();
      final total = container.read(activeWorkoutProvider)!.totalSets;
      expect(total, greaterThanOrEqualTo(5));
      expect(find.text('Подход 1 из $total · поднято 0,0 т'), findsOneWidget);
      expect(find.text('Добавить подход'), findsWidgets);
      expect(find.text('Add set'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('coach card renders in ru', (tester) async {
      await pumpRu(tester, const SportWorkoutsScreen(sport: Sport.gym));
      await tester.pumpAndSettle();
      expect(find.byType(CoachCard), findsOneWidget);
      expect(find.text('Готовы к первой тренировке?'), findsOneWidget);
      expect(find.text('Ready for your first workout?'), findsNothing);
    });

    for (final (sport, word) in [
      (Sport.running, 'темп'),
      (Sport.cycling, 'нагрузк'),
      (Sport.football, 'восстановиться'),
      (Sport.winterSports, 'спуск'),
    ]) {
      testWidgets('first-run coach card talks about ${sport.name}, not weights',
          (tester) async {
        await pumpRu(tester,
            Scaffold(body: SportCoachCard(sport: sport, onStart: (_) {})));
        await tester.pumpAndSettle();
        final card = tester.widget<CoachCard>(find.byType(CoachCard));
        expect(card.message, contains(word));
        expect(card.message, isNot(contains('веса')));
      });
    }
  });

  group('home tiles', () {
    const labels = {
      'ru': [
        'МОЙ\nПРОГРЕСС',
        'МОЁ\nПИТАНИЕ',
        'МОИ\nТРЕНИРОВКИ',
        'МАГАЗИН',
        'КАРТА\nFITRIX'
      ],
      'uz': [
        'MENING\nNATIJAM',
        'MENING\nOVQATIM',
        'MENING\nMASHG‘ULOT',
        'DO‘KON',
        'FITRIX\nXARITASI'
      ],
      'es': [
        'MI\nPROGRESO',
        'MI\nNUTRICIÓN',
        'MIS\nENTRENOS',
        'TIENDA',
        'MAPA\nFITRIX'
      ],
    };
    for (final language in labels.keys) {
      testWidgets('are localized and fit their tiles on iPhone SE in $language',
          (tester) async {
        tester.view.physicalSize = const Size(375, 667) * 3;
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        SharedPreferences.setMockInitialValues({
          'language': language,
          'onboarding_complete': true,
          'user_name': 'Alex',
        });
        final storage = await SharedPreferences.getInstance();
        final session = AppSession(storage);
        await tester.pumpWidget(FitrixRoot(
          prefs: storage,
          session: session,
          router: AppRouter.create(session),
        ));
        await tester.pumpAndSettle();
        for (final label in labels[language]!) {
          final finder = find.text(label);
          expect(finder, findsOneWidget, reason: label);
          final tile =
              find.ancestor(of: finder, matching: find.byType(FeatureTile));
          expect(tile, findsOneWidget, reason: label);
          final text = tester.getRect(finder);
          final bounds = tester.getRect(tile);
          expect(
              bounds.contains(text.topLeft) &&
                  bounds.contains(text.bottomRight),
              isTrue,
              reason: '$label: $text outside $bounds');
          // The label's own width is not clipped to the tile.
          final painter = TextPainter(
            text: TextSpan(
                text: label,
                style: tester.widget<Text>(finder).style ??
                    DefaultTextStyle.of(tester.element(finder)).style),
            textDirection: TextDirection.ltr,
          )..layout();
          expect(painter.width, lessThanOrEqualTo(bounds.width), reason: label);
        }
        expect(tester.takeException(), isNull);
      });
    }
  });
}
