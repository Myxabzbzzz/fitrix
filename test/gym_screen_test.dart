import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitrix/core/session/session_providers.dart';
import 'package:fitrix/core/widgets/app_button.dart';
import 'package:fitrix/core/widgets/coach_card.dart';
import 'package:fitrix/core/widgets/workout_card.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/features/workouts/domain/coach_message.dart';
import 'package:fitrix/features/workouts/presentation/providers/workouts_provider.dart';
import 'package:fitrix/features/workouts/presentation/screens/sport_workouts_screen.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

CompletedWorkout _done(DateTime at) => CompletedWorkout(
      templateId: 'gym-legs',
      name: 'Legs',
      sport: Sport.gym,
      startedAt: at,
      finishedAt: at,
      exercises: const [],
    );

Future<ProviderContainer> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(375, 667) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
  addTearDown(container.dispose);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: SportWorkoutsScreen(sport: Sport.gym),
    ),
  ));
  await tester.pumpAndSettle();
  return container;
}

void main() {
  final now = DateTime(2026, 10, 13, 12);

  group('coachMessage', () {
    test('no history: first workout prompt', () {
      final m = coachMessage([], now)!;
      expect(m.title, 'Ready for your first workout?');
      expect(m.message, startsWith('Start with '));
      expect(m.message, endsWith('Felix will adjust the plan after it.'));
    });

    test('trained 1 day ago: null', () {
      expect(coachMessage([_done(now.subtract(const Duration(days: 1)))], now),
          isNull);
    });

    test('trained 5 days ago: welcome back with n = 5', () {
      final m =
          coachMessage([_done(now.subtract(const Duration(days: 5)))], now)!;
      expect(m.title, 'Welcome back');
      expect(m.message, contains('5 days ago'));
    });
  });

  group('gym screen', () {
    testWidgets('first card is TODAY with a primary Start', (tester) async {
      await _pump(tester);
      final first = tester.widgetList<WorkoutCard>(find.byType(WorkoutCard)).first;
      expect(first.today, isTrue);
      expect(find.text('TODAY'), findsOneWidget);
      final button = tester.widget<AppButton>(find.descendant(
          of: find.byType(WorkoutCard).first, matching: find.byType(AppButton)));
      expect(button.style, AppButtonStyle.primary);
      final second = tester.widgetList<WorkoutCard>(find.byType(WorkoutCard)).elementAt(1);
      expect(second.today, isFalse);
      expect(find.byType(AddWorkoutCard), findsOneWidget);
      expect(find.byType(CoachCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Start on a card starts that template', (tester) async {
      final container = await _pump(tester);
      final second = container.read(workoutsForSportProvider(Sport.gym))[1];
      await tester.tap(find.descendant(
          of: find.byType(WorkoutCard).at(1), matching: find.text('Start')));
      await tester.pumpAndSettle();
      expect(container.read(activeWorkoutProvider)?.template.id, second.id);
    });

    testWidgets('Start in the coach card starts today\'s workout',
        (tester) async {
      final container = await _pump(tester);
      final first = container.read(workoutsForSportProvider(Sport.gym)).first;
      await tester.ensureVisible(find.byType(CoachCard));
      await tester.tap(find.descendant(
          of: find.byType(CoachCard), matching: find.text('Start')));
      await tester.pumpAndSettle();
      expect(container.read(activeWorkoutProvider)?.template.id, first.id);
    });

    testWidgets('plus card opens the New workout dialog', (tester) async {
      await _pump(tester);
      await tester.tap(find.byType(AddWorkoutCard));
      await tester.pumpAndSettle();
      expect(find.text('New workout'), findsOneWidget);
    });
  });
}
