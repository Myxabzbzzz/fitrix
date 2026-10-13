import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitrix/core/router/app_router.dart';
import 'package:fitrix/core/session/session_providers.dart';
import 'package:fitrix/features/chat/presentation/screens/felix_chat_screen.dart';
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

Future<ProviderContainer> _pump(WidgetTester tester,
    {double textScale = 1, GoRouter? router}) async {
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
    child: router != null
        ? MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          )
        : MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(textScale)),
              child: child!,
            ),
            home: const SportWorkoutsScreen(sport: Sport.gym),
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
      expect(m.kind, CoachMessageKind.firstWorkout);
      // 2026-10-13 is a Tuesday: the weekday is the fallback.
      expect(m.today, 'Tuesday');
    });

    test('trained 1 day ago: null', () {
      expect(coachMessage([_done(now.subtract(const Duration(days: 1)))], now),
          isNull);
    });

    test('first workout names today\'s workout when given', () {
      final m = coachMessage([], now, todayWorkout: 'Legs')!;
      expect(m.kind, CoachMessageKind.firstWorkout);
      expect(m.today, 'Legs');
    });

    test('calendar-day boundaries', () {
      expect(coachMessage([_done(DateTime(2026, 10, 11, 23))], now), isNull);
      final three = coachMessage([_done(DateTime(2026, 10, 10, 23))], now)!;
      expect(three.kind, CoachMessageKind.welcomeBack);
      expect(three.days, 3);
      // Late evening to early next morning is 1 day.
      expect(
          coachMessage(
              [_done(DateTime(2026, 10, 12, 23, 30))], DateTime(2026, 10, 13, 6)),
          isNull);
    });

    test('daylight-saving change does not shift the day count', () {
      // Clocks go forward in many zones between these dates.
      final m = coachMessage(
          [_done(DateTime(2026, 3, 28, 12))], DateTime(2026, 3, 31, 0, 30))!;
      expect(m.days, 3);
    });

    test('trained 5 days ago: welcome back with n = 5', () {
      final m =
          coachMessage([_done(now.subtract(const Duration(days: 5)))], now)!;
      expect(m.kind, CoachMessageKind.welcomeBack);
      expect(m.days, 5);
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
    testWidgets('lays out at 1.5x text on a small phone', (tester) async {
      await _pump(tester, textScale: 1.5);
      expect(tester.takeException(), isNull);
      await tester.drag(find.byType(ListView).last, const Offset(0, -600));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('Ask opens the sport\'s Felix chat', (tester) async {
      final router = GoRouter(routes: [
        GoRoute(
            path: '/',
            builder: (_, __) => const SportWorkoutsScreen(sport: Sport.gym)),
        GoRoute(
            path: AppRouter.felix,
            builder: (_, __) => const Text('felix-chat')),
      ]);
      final container = await _pump(tester, router: router);
      await tester.ensureVisible(find.byType(CoachCard));
      await tester.tap(find.descendant(
          of: find.byType(CoachCard), matching: find.text('Ask')));
      await tester.pumpAndSettle();
      expect(container.read(selectedAssistantTopicProvider).sport, Sport.gym);
      expect(find.text('felix-chat'), findsOneWidget);
    });
  });
}
