import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitrix/core/session/session_providers.dart';
import 'package:fitrix/features/progress/presentation/screens/progress_screen.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/features/workouts/presentation/providers/workouts_provider.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_theme.dart';
import 'package:fitrix/core/widgets/coach_card.dart';
import 'package:fitrix/features/nutrition/presentation/screens/nutrition_screen.dart';
import 'package:fitrix/features/progress/presentation/widgets/progress_chart.dart';

Widget _host(Widget child) => MaterialApp(
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );

/// The Nutrition screen with empty storage (so it shows the sample day).
Future<Widget> _nutrition() async {
  SharedPreferences.setMockInitialValues({});
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

ProgressChart _chart(List<double> values) => ProgressChart(
      title: 'Bench',
      values: values,
      xLabels: [for (var i = 0; i < values.length; i++) '${i + 1}'],
      minY: 0,
      maxY: 100,
      footerLeft: 'First: 1',
      footerRight: 'Latest: 2',
    );

CompletedWorkout _session(String id, DateTime at, double kg) =>
    CompletedWorkout(
      id: id,
      templateId: 'gym-chest-biceps',
      name: 'Chest and Biceps',
      sport: Sport.gym,
      startedAt: at.subtract(const Duration(hours: 1)),
      finishedAt: at,
      exercises: [
        Exercise(name: 'Bench press', sets: [
          WorkoutSet(previousKg: 0, previousReps: 8, kg: kg, reps: 8),
        ]),
      ],
    );

void main() {
  group('ProgressScreen', () {
    testWidgets('SE size: charts, foot rows, delta and stat tiles', (t) async {
      _se(t);
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
      addTearDown(container.dispose);
      final notifier = container.read(workoutHistoryProvider.notifier);
      notifier.add(_session('a', DateTime(2026, 9, 1), 60));
      notifier.add(_session('b', DateTime(2026, 10, 1), 62.5));

      await t.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: _host(const ProgressScreen()),
      ));
      await t.pumpAndSettle();

      expect(find.text('First: 60'), findsOneWidget);
      expect(find.text('Latest: 62.5'), findsOneWidget);
      expect(find.text('+2.5'), findsOneWidget);

      await t.drag(find.byType(ListView).last, const Offset(0, -3000));
      await t.pumpAndSettle();
      expect(find.text('Intake, avg'), findsOneWidget);
      expect(find.text('Burn, avg'), findsOneWidget);
      expect(find.text('2,000'), findsOneWidget);
      expect(find.text('1,800'), findsOneWidget);
      expect(t.takeException(), isNull);
    });
  });

  group('Nutrition', () {
    testWidgets('ring shows consumed and goal', (t) async {
      _se(t);
      await t.pumpWidget((await _nutrition()));
      await t.pumpAndSettle();
      expect(find.text('1,700'), findsOneWidget);
      expect(find.text('of 2,400 kcal'), findsOneWidget);
    });

    testWidgets('macro labels and Felix tip are shown', (t) async {
      _se(t);
      await t.pumpWidget((await _nutrition()));
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

  group('ProgressChart', () {
    testWidgets('paints with 1 point', (t) async {
      await t.pumpWidget(_host(Scaffold(body: _chart([50]))));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    });

    testWidgets('paints with 8 points and shows foot row', (t) async {
      await t.pumpWidget(
          _host(Scaffold(body: _chart([10, 20, 30, 40, 50, 60, 70, 80]))));
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
