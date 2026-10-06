import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitrix/core/router/app_router.dart';
import 'package:fitrix/core/session/app_session.dart';
import 'package:fitrix/core/session/session_providers.dart';
import 'package:fitrix/features/progress/data/progress_data.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/features/workouts/data/workout_catalog.dart';
import 'package:fitrix/features/workouts/presentation/providers/workouts_provider.dart';
import 'package:fitrix/features/workouts/presentation/widgets/active_workout_sheet.dart';
import 'package:fitrix/main.dart';

/// The real app root, backed by mock SharedPreferences.
Future<Widget> _app() async {
  final prefs = await SharedPreferences.getInstance();
  final session = AppSession(prefs);
  return FitrixRoot(
    prefs: prefs,
    session: session,
    router: AppRouter.create(session),
  );
}

/// A fresh provider container over the same storage — like an app restart.
Future<ProviderContainer> _restart() async {
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(container.dispose);
  return container;
}

void _phoneSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('formatDuration', () {
    test('matches the design format', () {
      expect(
        formatDuration(const Duration(hours: 1, minutes: 43, seconds: 22)),
        '1h 43m 22s',
      );
      expect(
        formatDuration(const Duration(hours: 1, minutes: 43), withSeconds: false),
        '1h 43m',
      );
      expect(formatDuration(const Duration(seconds: 5)), '5s');
    });
  });

  group('workouts', () {
    test('active workout tracks completed sets and added sets', () async {
      final container = await _restart();
      final notifier = container.read(activeWorkoutProvider.notifier);
      final template = WorkoutCatalog.defaults.first;

      notifier.start(template);
      notifier.toggleSet(0, 0);
      notifier.setKg(0, 1, 26);
      notifier.addSet(0);

      final workout = container.read(activeWorkoutProvider)!;
      expect(workout.completedSets, 1);
      expect(workout.exercises[0].sets[1].kg, 26);
      expect(workout.exercises[0].sets.length,
          template.exercises[0].sets.length + 1);
      // The template itself is not modified by the session.
      expect(template.exercises[0].sets[0].done, isFalse);
    });

    test('workout in progress survives an app restart', () async {
      final first = await _restart();
      first.read(activeWorkoutProvider.notifier)
        ..start(WorkoutCatalog.defaults.first)
        ..toggleSet(0, 0);

      final second = await _restart();
      final restored = second.read(activeWorkoutProvider);
      expect(restored, isNotNull);
      expect(restored!.template.name, 'Chest and Biceps');
      expect(restored.exercises[0].sets[0].done, isTrue);
    });

    test('finishing saves history and feeds "Previous" next time', () async {
      final template = WorkoutCatalog.defaults.first;
      final first = await _restart();
      first.read(activeWorkoutProvider.notifier)
        ..start(template)
        ..setKg(0, 0, 30)
        ..setReps(0, 0, 8)
        ..toggleSet(0, 0);
      expect(first.read(activeWorkoutProvider.notifier).finish(), isTrue);

      final second = await _restart();
      final history = second.read(workoutHistoryProvider);
      expect(history, hasLength(1));
      expect(history.first.name, 'Chest and Biceps');
      expect(history.first.setCount, 1, reason: 'only checked sets are kept');

      second.read(activeWorkoutProvider.notifier).start(template);
      final set = second.read(activeWorkoutProvider)!.exercises[0].sets[0];
      expect(set.previousKg, 30);
      expect(set.previousReps, 8);
      expect(set.done, isFalse);
    });

    test('a workout with no checked sets is not saved', () async {
      final container = await _restart();
      final notifier = container.read(activeWorkoutProvider.notifier)
        ..start(WorkoutCatalog.defaults.first);

      expect(notifier.finish(), isFalse);
      expect(container.read(workoutHistoryProvider), isEmpty);
      expect(container.read(activeWorkoutProvider), isNull);
    });

    test('edited and added plans are persisted', () async {
      final first = await _restart();
      first.read(workoutTemplatesProvider.notifier).add(Sport.running, '5K');

      final second = await _restart();
      expect(
        second.read(workoutsForSportProvider(Sport.running)).map((w) => w.name),
        ['5K'],
      );
    });
  });

  group('ProgressData.strengthFrom', () {
    CompletedWorkout session(DateTime day, String exercise, List<double> kgs) =>
        CompletedWorkout(
          templateId: 't',
          name: 'Test',
          sport: Sport.gym,
          startedAt: day,
          finishedAt: day,
          exercises: [
            Exercise(name: exercise, sets: [
              for (final kg in kgs)
                WorkoutSet(previousKg: 0, previousReps: 10, kg: kg, reps: 10),
            ]),
          ],
        );

    test('charts the best weight per session, oldest first', () {
      final history = [
        session(DateTime(2026, 10, 3), 'Bench press', [80, 85]),
        session(DateTime(2026, 10, 1), 'Bench press', [75, 70]),
      ];

      final series = ProgressData.strengthFrom(history, Sport.gym);

      expect(series.single.title, 'Bench press (kg)');
      expect(series.single.values, [75, 85]);
      expect(series.single.xLabels, ['1 Oct', '3 Oct']);
      expect(series.single.maxY, greaterThan(series.single.minY));
      // Grid lines at whole numbers: range splits evenly into 4 steps.
      final step = (series.single.maxY - series.single.minY) / 4;
      expect(step, step.roundToDouble());
      expect(series.single.minY, lessThanOrEqualTo(75));
      expect(series.single.maxY, greaterThanOrEqualTo(85));
    });

    test('bodyweight exercises chart reps; other sports are excluded', () {
      final history = [session(DateTime(2026, 10, 1), 'Push-ups', [0, 0])];

      expect(ProgressData.strengthFrom(history, Sport.gym).single.title,
          'Push-ups (reps)');
      expect(ProgressData.strengthFrom(history, Sport.running), isEmpty);
    });
  });

  group('onboarding', () {
    testWidgets('first launch starts at the intro', (tester) async {
      _phoneSize(tester);
      await tester.pumpWidget(await _app());
      await tester.pumpAndSettle();

      expect(find.text('Start your journey'), findsOneWidget);
    });

    testWidgets('after onboarding the app opens on Home', (tester) async {
      _phoneSize(tester);
      SharedPreferences.setMockInitialValues({'onboarding_complete': true});
      await tester.pumpWidget(await _app());
      await tester.pumpAndSettle();

      expect(find.text('Start your journey'), findsNothing);
      expect(find.text('FELIX'), findsOneWidget);
    });

    testWidgets('signing out clears data and returns to the intro',
        (tester) async {
      _phoneSize(tester);
      SharedPreferences.setMockInitialValues({
        'onboarding_complete': true,
        'user_name': 'Alex',
      });
      await tester.pumpWidget(await _app());
      AppRouter.router.go(AppRouter.me);
      await tester.pumpAndSettle();
      expect(find.text('Alex'), findsOneWidget);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Sign out'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Sign out'));
      await tester.pumpAndSettle();

      expect(find.text('Start your journey'), findsOneWidget);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getKeys(), isEmpty);
    });
  });

  testWidgets('home → my workouts → start a gym workout', (tester) async {
    _phoneSize(tester);
    await tester.pumpWidget(await _app());
    AppRouter.router.go(AppRouter.home);
    await tester.pumpAndSettle();

    expect(find.text('FELIX'), findsOneWidget);
    expect(find.text('MY\nWORKOUTS'), findsOneWidget);

    await tester.tap(find.text('MY\nWORKOUTS'));
    await tester.pumpAndSettle();
    expect(find.text('My workouts'), findsOneWidget);

    await tester.tap(find.text('GYM'));
    await tester.pumpAndSettle();
    expect(find.text('TODAY’S WORKOUT'), findsOneWidget);
    expect(find.text('Chest and Biceps'), findsOneWidget);

    await tester.tap(find.text('Start').first);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Biceps curl'), findsOneWidget);
    expect(find.text('Previous'), findsWidgets);

    // Finish so the elapsed-time ticker is disposed before the test ends.
    await tester.scrollUntilVisible(
      find.text('Finish workout'),
      300,
      scrollable: find
          .descendant(
            of: find.byType(ActiveWorkoutSheet),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.text('Finish workout'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Finish'));
    await tester.pumpAndSettle();
    expect(find.text('Biceps curl'), findsNothing);
  });

  testWidgets('adding a workout via the + tile', (tester) async {
    _phoneSize(tester);
    await tester.pumpWidget(await _app());
    AppRouter.router.go(AppRouter.sportWorkouts(Sport.gym));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add).last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Shoulders');
    await tester.tap(find.text('Add'));
    // Let the dialog's closing animation run to completion: the text
    // controller must outlive it.
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Shoulders'), findsOneWidget);
  });

  testWidgets('My progress lays out without overflow', (tester) async {
    _phoneSize(tester);
    await tester.pumpWidget(await _app());
    AppRouter.router.go(AppRouter.progress);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('My progress'), findsOneWidget);
  });
}
