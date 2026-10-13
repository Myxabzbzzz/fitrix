import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_theme.dart';
import 'package:fitrix/core/widgets/coach_card.dart';
import 'package:fitrix/features/nutrition/presentation/screens/nutrition_screen.dart';
import 'package:fitrix/features/progress/presentation/widgets/progress_chart.dart';

Widget _host(Widget child) =>
    MaterialApp(theme: AppTheme.lightTheme, home: child);

void _se(WidgetTester tester) {
  tester.view.physicalSize = const Size(375, 667) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

ProgressChart _chart(List<double> values) => ProgressChart(
      title: 'Bench',
      values: values,
      xLabels: [for (var i = 0; i < values.length; i++) '${i + 1}'],
      minY: 0,
      maxY: 100,
      footerLeft: 'First: 1',
      footerRight: 'Latest: 2',
    );

void main() {
  group('Nutrition', () {
    testWidgets('ring shows consumed and goal', (t) async {
      _se(t);
      await t.pumpWidget(_host(const NutritionScreen()));
      await t.pumpAndSettle();
      expect(find.text('1,700'), findsOneWidget);
      expect(find.text('of 2,400 kcal'), findsOneWidget);
    });

    testWidgets('macro labels and Felix tip are shown', (t) async {
      _se(t);
      await t.pumpWidget(_host(const NutritionScreen()));
      await t.pumpAndSettle();
      for (final l in ['Protein', 'Carbs', 'Fat']) {
        expect(find.text(l), findsOneWidget);
      }
      await t.scrollUntilVisible(find.byType(CoachCard), 100);
      expect(find.byType(CoachCard), findsOneWidget);
      expect(t.takeException(), isNull);
    });

    testWidgets('ring is 132 px with a buttonMuted track', (t) async {
      _se(t);
      await t.pumpWidget(_host(const NutritionScreen()));
      await t.pumpAndSettle();
      final ring = find.byKey(const ValueKey('calorie-ring'));
      expect(t.getSize(ring), const Size(132, 132));
      final painter = t.widget<CustomPaint>(find.descendant(
          of: ring, matching: find.byType(CustomPaint))).painter as dynamic;
      expect(painter.track, AppPalette.light.buttonMuted);
    });

    testWidgets('reduced motion renders full state at once', (t) async {
      _se(t);
      await t.pumpWidget(MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: _host(const NutritionScreen()),
      ));
      await t.pump();
      expect(t.hasRunningAnimations, isFalse);
    });
  });

  group('ProgressChart', () {
    testWidgets('paints with 1 point', (t) async {
      await t.pumpWidget(_host(Scaffold(body: _chart([50]))));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    });

    testWidgets('paints with 8 points and shows foot row', (t) async {
      await t.pumpWidget(_host(
          Scaffold(body: _chart([10, 20, 30, 40, 50, 60, 70, 80]))));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      expect(find.text('First: 1'), findsOneWidget);
      expect(find.text('Latest: 2'), findsOneWidget);
    });

    testWidgets('shows the delta label when given', (t) async {
      await t.pumpWidget(_host(const Scaffold(
        body: ProgressChart(
          title: 'Bench',
          values: [1, 2],
          xLabels: ['a', 'b'],
          minY: 0,
          maxY: 4,
          delta: '+1 kg',
        ),
      )));
      await t.pumpAndSettle();
      expect(find.text('+1 kg'), findsOneWidget);
    });

    testWidgets('SE size: no overflow', (t) async {
      _se(t);
      await t.pumpWidget(_host(Scaffold(
          body: ListView(children: [
        _chart([10, 20, 30, 40, 50, 60, 70, 80]),
      ]))));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    });
  });
}
