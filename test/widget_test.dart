import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitrix/core/router/app_router.dart';
import 'package:fitrix/core/theme/app_theme.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/features/workouts/data/workout_catalog.dart';
import 'package:fitrix/features/workouts/presentation/providers/workouts_provider.dart';
import 'package:fitrix/features/workouts/presentation/widgets/active_workout_sheet.dart';

Widget _app() => ProviderScope(
      child: MaterialApp.router(
        theme: AppTheme.lightTheme,
        routerConfig: AppRouter.router,
      ),
    );

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

  group('ActiveWorkoutNotifier', () {
    test('tracks completed sets and added sets', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
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

      notifier.finish();
      expect(container.read(activeWorkoutProvider), isNull);
    });
  });

  testWidgets('home → my workouts → start a gym workout', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app());
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
}
