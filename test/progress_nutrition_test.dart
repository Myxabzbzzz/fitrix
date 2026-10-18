import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitrix/core/session/session_providers.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_theme.dart';
import 'package:fitrix/features/nutrition/presentation/screens/nutrition_screen.dart';

Widget _host(Widget child) => MaterialApp(
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );

/// The Nutrition screen with a complete profile and nothing logged.
Future<Widget> _nutrition() async {
  SharedPreferences.setMockInitialValues({
    'user_name': 'Alex',
    'user_age': '26',
    'user_weight': '78.4',
    'user_height': '181',
    'performance_profile_v1': '{"sex":"male"}',
  });
  final prefs = await SharedPreferences.getInstance();
  return ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    child: _host(const NutritionScreen()),
  );
}

void _se(WidgetTester tester) {
  tester.view.physicalSize = const Size(375, 667) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

void main() {
  group('Nutrition', () {
    testWidgets('ring shows eaten and the computed target', (t) async {
      _se(t);
      await t.pumpWidget((await _nutrition()));
      await t.pumpAndSettle();
      expect(find.text('0'), findsOneWidget);
      // Mifflin-St Jeor 1790 x 1.375 (3 h assumed) = 2461, maintain.
      expect(find.text('of 2,450 kcal'), findsOneWidget);
    });

    testWidgets('macro labels are shown', (t) async {
      _se(t);
      await t.pumpWidget((await _nutrition()));
      await t.pumpAndSettle();
      for (final l in ['Protein', 'Carbs', 'Fat']) {
        expect(find.text(l), findsOneWidget);
      }
      expect(t.takeException(), isNull);
    });

    testWidgets('ring is 132 px with a buttonMuted track', (t) async {
      _se(t);
      await t.pumpWidget((await _nutrition()));
      await t.pumpAndSettle();
      final ring = find.byKey(const ValueKey('calorie-ring'));
      expect(t.getSize(ring), const Size(132, 132));
      final painter = t
          .widget<CustomPaint>(
              find.descendant(of: ring, matching: find.byType(CustomPaint)))
          .painter as dynamic;
      expect(painter.track, AppPalette.light.buttonMuted);
    });

    testWidgets('reduced motion renders full state at once', (t) async {
      _se(t);
      await t.pumpWidget(MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: (await _nutrition()),
      ));
      await t.pump();
      expect(t.hasRunningAnimations, isFalse);
    });
  });
}
