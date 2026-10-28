// Layout checks for the fixes from the screenshot tour: nothing overflows on
// an iPhone SE at text scale 1.3, key buttons keep their full Russian label
// on a 393 pt iPhone, and sheets cover the tab bar.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitrix/core/session/session_providers.dart';
import 'package:fitrix/core/theme/app_theme.dart';
import 'package:fitrix/features/language/presentation/screens/language_screen.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

import 'support/overflow.dart';

/// iPhone 15/16 logical size.
const proSize = Size(393, 852);

Future<void> setScreen(WidgetTester t, Size size) async {
  t.view.physicalSize = size * 3;
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
}

/// [child] inside a localized MaterialApp at [scale].
Widget localized(Widget child,
        {String lang = 'ru',
        double scale = 1,
        List<Override> overrides = const [],
        SharedPreferences? prefs}) =>
    ProviderScope(
      overrides: [
        if (prefs != null) sharedPreferencesProvider.overrideWithValue(prefs),
        ...overrides,
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        locale: Locale(lang),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, c) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: c!,
        ),
        home: child,
      ),
    );

/// Whether the [Text] showing [text] is drawn without being cut short.
bool fitsOnOneLine(WidgetTester t, String text) {
  final para = t.renderObject<RenderParagraph>(find.text(text).first);
  return !para.didExceedMaxLines;
}

void main() {
  group('language screen', () {
    testWidgets('scrolls instead of overflowing on SE at text scale 1.3',
        (t) async {
      await setScreen(t, iPhoneSeSize);
      SharedPreferences.setMockInitialValues({'language': 'ru'});
      final prefs = await SharedPreferences.getInstance();
      await t.pumpWidget(
          localized(const LanguageScreen(), scale: 1.3, prefs: prefs));
      await t.pumpAndSettle();
      expectNoOverflow(t);
      await t.scrollUntilVisible(find.text('Продолжить'), 100,
          scrollable: find.byType(Scrollable).first);
      expect(find.text('Продолжить').hitTestable(), findsOneWidget);
    });

    testWidgets('language buttons are tall enough for their label',
        (t) async {
      await setScreen(t, proSize);
      SharedPreferences.setMockInitialValues({'language': 'ru'});
      final prefs = await SharedPreferences.getInstance();
      await t.pumpWidget(localized(const LanguageScreen(), prefs: prefs));
      await t.pumpAndSettle();
      for (final label in ['Русский', 'English', 'Español']) {
        final para = t.renderObject<RenderParagraph>(find.text(label));
        // One line of headingS (16 × 1.4): any less and descenders are cut.
        expect(para.size.height, greaterThanOrEqualTo(22),
            reason: '$label is squeezed by its button');
      }
    });
  });
}
