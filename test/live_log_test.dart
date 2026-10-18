import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitrix/core/router/app_router.dart';
import 'package:fitrix/core/session/session_providers.dart';
import 'package:fitrix/features/exercises/data/exercise_catalog.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/features/workouts/domain/training_math.dart';
import 'package:fitrix/features/workouts/presentation/providers/workouts_provider.dart';
import 'package:fitrix/features/workouts/presentation/screens/workout_complete_screen.dart';
import 'package:fitrix/features/workouts/presentation/widgets/active_workout_sheet.dart';
import 'package:fitrix/features/workouts/presentation/widgets/rest_timer.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

WorkoutSet _set(double kg, int reps, {double prevKg = 70, bool done = false}) =>
    WorkoutSet(
      previousKg: prevKg,
      previousReps: 8,
      kg: kg,
      reps: reps,
      done: done,
    );

WorkoutTemplate _template() => WorkoutTemplate(
      id: 'back',
      sport: Sport.gym,
      name: 'Back and Triceps',
      focus: 'Gym',
      estimatedDuration: const Duration(hours: 1),
      exercises: [
        Exercise(name: 'Barbell row', sets: [
          for (var i = 0; i < 4; i++) _set(72.5, 8),
        ]),
        Exercise(name: 'Triceps pushdown', sets: [
          for (var i = 0; i < 3; i++) _set(30, 12, prevKg: 30),
        ]),
      ],
    );

CompletedWorkout _earlier({double kg = 70, bool allDone = true}) =>
    CompletedWorkout(
      templateId: 'back',
      name: 'Back and Triceps',
      sport: Sport.gym,
      startedAt: DateTime(2026, 10, 1, 10),
      finishedAt: DateTime(2026, 10, 1, 11),
      exercises: [
        Exercise(name: 'Barbell row', sets: [
          for (var i = 0; i < 4; i++) _set(kg, 8, done: allDone),
        ]),
      ],
    );

ExerciseCatalog _catalog() {
  ExerciseInfo info(String id, String name, List<String> similar) =>
      ExerciseInfo(
        id: id,
        name: name,
        group: MuscleGroup.back,
        primary: const ['Back'],
        secondary: const [],
        equipment: Equipment.barbell,
        pattern: 'Horizontal pull',
        level: 'intermediate',
        compound: true,
        loads: const ['back'],
        steps: const [],
        mistakes: const [],
        similar: similar,
      );
  return ExerciseCatalog([
    info('barbell-row', 'Barbell row', ['dumbbell-row']),
    info('dumbbell-row', 'Dumbbell row', const []),
  ]);
}

/// Plain test clock for the controller unit test.
class _Clock {
  DateTime now = DateTime(2026, 10, 18, 12);
  void advance(Duration d) => now = now.add(d);
}

/// The rest timer's clock in widget tests: the test binding's fake clock, so
/// `tester.pump(Duration)` (and pumpAndSettle) move it too.
DateTime Function() _now = DateTime.now;

/// Moves the (fake) time on.
Future<void> _wait(WidgetTester tester, int seconds) =>
    tester.pump(Duration(seconds: seconds));

Future<ProviderContainer> _container({
  List<CompletedWorkout> history = const [],
  Duration elapsed = Duration.zero,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final c = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    exerciseCatalogProvider.overrideWith((ref) async => _catalog()),
    restTimerProvider.overrideWith((ref) {
      final r = RestTimerController(clock: () => _now());
      ref.onDispose(r.dispose);
      return r;
    }),
  ]);
  addTearDown(c.dispose);
  for (final w in history) {
    c.read(workoutHistoryProvider.notifier).add(w);
  }
  final notifier = c.read(activeWorkoutProvider.notifier)..start(_template());
  if (elapsed > Duration.zero) {
    // ignore: invalid_use_of_protected_member
    notifier.state =
        notifier.state!.copyWith(startedAt: DateTime.now().subtract(elapsed));
  }
  return c;
}

/// Today's row weights, heavier than the 70 kg of [_earlier].
void _raise(ProviderContainer c) {
  final n = c.read(activeWorkoutProvider.notifier);
  for (var i = 0; i < 4; i++) {
    n.setKg(0, i, 72.5);
  }
}

Widget _app(ProviderContainer c, {double textScale = 1}) {
  final router = GoRouter(routes: [
    GoRoute(
      path: '/',
      builder: (_, __) => const Scaffold(body: ActiveWorkoutSheet()),
    ),
    GoRoute(
      path: AppRouter.workoutComplete,
      builder: (_, __) => const WorkoutCompleteScreen(),
    ),
    GoRoute(
      path: AppRouter.progress,
      builder: (_, __) => const Scaffold(body: Text('progress page')),
    ),
    GoRoute(
      path: AppRouter.home,
      builder: (_, __) => const Scaffold(body: Text('home page')),
    ),
  ]);
  return UncontrolledProviderScope(
    container: c,
    child: MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
    ),
  );
}

Future<void> _open(
  WidgetTester tester,
  ProviderContainer c, {
  Size size = const Size(390, 844),
  double textScale = 1,
}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  _now = () => tester.binding.clock.now();
  await tester.pumpWidget(_app(c, textScale: textScale));
  await tester.pump();
  c.read(activeWorkoutExpandedProvider.notifier).state = true;
  await tester.pumpAndSettle();
}

Finder _check(int e, int s) => find.descendant(
      of: find.byKey(ValueKey('set-$e-$s')),
      matching: find.byKey(ActiveWorkoutSheet.checkKey),
    );

/// Scrolls [finder] into view, then taps it.
Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pump();
}

Future<void> _leave(WidgetTester tester) => tester.pumpWidget(const SizedBox());

void main() {
  group('training math additions', () {
    test('warm-up plan is ~55% and ~75% rounded to plate', () {
      final plan = warmupPlan(72.5);
      expect(plan.map((s) => (s.kg, s.reps)).toList(), [(40.0, 10), (55.0, 5)]);
    });

    test('best set picks the highest e1RM, bodyweight by reps', () {
      final best =
          bestSet([_set(60, 10, done: true), _set(72.5, 8, done: true)]);
      expect((best!.kg, best.reps), (72.5, 8));
      final bw = bestSet([_set(0, 8, done: true), _set(0, 12, done: true)]);
      expect(bw!.reps, 12);
      expect(bestSet([_set(60, 10)]), isNull);
    });
  });

  group('active workout notifier', () {
    test('setRpe, setNote (and clearing), setRest', () async {
      final c = await _container();
      final n = c.read(activeWorkoutProvider.notifier);
      n.setRpe(0, 1, 8);
      expect(c.read(activeWorkoutProvider)!.exercises[0].sets[1].rpe, 8);
      n.setNote(0, 'Straps');
      expect(c.read(activeWorkoutProvider)!.exercises[0].note, 'Straps');
      n.setNote(0, '  ');
      expect(c.read(activeWorkoutProvider)!.exercises[0].note, isNull);
      n.setRest(1, 90);
      expect(c.read(activeWorkoutProvider)!.exercises[1].restSeconds, 90);
    });

    test('warm-ups are excluded from set counts and added once', () async {
      final c = await _container();
      final n = c.read(activeWorkoutProvider.notifier);
      n.addWarmupSets(0);
      n.addWarmupSets(0);
      final w = c.read(activeWorkoutProvider)!;
      expect(w.exercises[0].sets.length, 6);
      expect(w.totalSets, 7);
      expect(w.exercises[0].sets.take(2).every((s) => s.warmup), isTrue);
      n.toggleSet(0, 0);
      expect(c.read(activeWorkoutProvider)!.completedSets, 0);
    });

    test('move, remove, replace and add exercises', () async {
      final c = await _container(history: [_earlier()]);
      final n = c.read(activeWorkoutProvider.notifier);
      n.moveExercise(0, 1);
      expect(c.read(activeWorkoutProvider)!.exercises.map((e) => e.name),
          ['Triceps pushdown', 'Barbell row']);
      n.replaceExercise(0, 'Barbell row');
      final replaced = c.read(activeWorkoutProvider)!.exercises[0];
      expect(replaced.name, 'Barbell row');
      expect(replaced.sets.every((s) => !s.done), isTrue);
      expect(replaced.sets.first.previousKg, 70); // from history
      n.addExercises(['Lat pulldown', 'Face pull']);
      expect(c.read(activeWorkoutProvider)!.exercises.length, 4);
      n.removeExercise(3);
      expect(c.read(activeWorkoutProvider)!.exercises.length, 3);
    });

    test('finish returns the saved workout; discard drops it', () async {
      final c = await _container();
      final n = c.read(activeWorkoutProvider.notifier);
      expect(n.finish(), isNull); // nothing done: not saved
      expect(c.read(activeWorkoutProvider), isNull);
      n.start(_template());
      n.toggleSet(0, 0);
      final done = n.finish(sessionRpe: 7);
      expect(done!.sessionRpe, 7);
      expect(c.read(workoutHistoryProvider).single.id, done.id);
      n.start(_template());
      n.discard();
      expect(c.read(activeWorkoutProvider), isNull);
    });

    test('Exercise.copyWith(clearNote) removes the note', () {
      const e = Exercise(name: 'x', sets: [], note: 'a', restSeconds: 60);
      expect(e.copyWith(clearNote: true).note, isNull);
      expect(e.copyWith(clearNote: true).restSeconds, 60);
    });
  });

  group('RestTimerController', () {
    test('start, add, tick, skip', () {
      final clock = _Clock();
      final r = RestTimerController(clock: () => clock.now);
      expect(r.active, isFalse);
      r.start(const Duration(seconds: 120));
      expect(r.remaining, const Duration(seconds: 120));
      r.add(const Duration(seconds: 15));
      expect(r.remaining, const Duration(seconds: 135));
      clock.advance(const Duration(seconds: 5));
      expect(r.remaining, const Duration(seconds: 130));
      r.add(const Duration(seconds: -200));
      expect(r.active, isFalse); // ran out
      r.start(const Duration(seconds: 30), next: 'Set 2');
      expect(r.next, 'Set 2');
      r.skip();
      expect(r.active, isFalse);
    });
  });

  group('rest timer keeps time while the bar is away', () {
    testWidgets('collapsed sheet: 60 s later 1:00 is left', (tester) async {
      final c = await _container();
      await _open(tester, c);
      await tester.tap(_check(0, 0));
      await tester.pump();
      c.read(activeWorkoutExpandedProvider.notifier).state = false;
      await tester.pumpAndSettle();
      expect(find.text('Skip'), findsNothing);
      await _wait(tester, 60);
      c.read(activeWorkoutExpandedProvider.notifier).state = true;
      // Not pumpAndSettle: the rest ticker would run the countdown out.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      // ~60 s passed (plus the sheet's animation time), not 0 s.
      final rest = c.read(restTimerProvider);
      expect(rest.remaining.inSeconds, inInclusiveRange(55, 60));
      expect(find.text(formatClock(rest.remaining)), findsOneWidget);
      await tester.tap(find.text('+15s'));
      await tester.pump();
      expect(rest.remaining.inSeconds, inInclusiveRange(70, 75));
      await tester.tap(find.text('Skip'));
      await tester.pump();
      expect(find.text('Skip'), findsNothing);
      await _leave(tester);
    });

    testWidgets('focused field hides the bar but not the time', (tester) async {
      final c = await _container();
      await _open(tester, c);
      await tester.tap(_check(0, 0));
      await tester.pump();
      await tester.tap(find.byType(TextField).first);
      await tester.pumpAndSettle();
      expect(find.text('Skip'), findsNothing);
      await _wait(tester, 60);
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final rest = c.read(restTimerProvider);
      expect(rest.remaining.inSeconds, inInclusiveRange(55, 60));
      expect(find.text(formatClock(rest.remaining)), findsOneWidget);
      await _leave(tester);
    });
  });

  group('set fields follow the model', () {
    String fieldText(WidgetTester tester, int row, int field) {
      final w = tester.widget<EditableText>(find
          .descendant(
              of: find.byKey(ValueKey('set-0-$row')),
              matching: find.byType(EditableText))
          .at(field));
      return w.controller.text;
    }

    testWidgets('after warm-ups, a swap and a removal', (tester) async {
      final c = await _container();
      await _open(tester, c);
      expect(fieldText(tester, 0, 0), '72.5');
      c.read(activeWorkoutProvider.notifier).addWarmupSets(0);
      await tester.pumpAndSettle();
      expect(fieldText(tester, 0, 0), '40');
      expect(fieldText(tester, 0, 1), '10');
      expect(fieldText(tester, 1, 0), '55');
      expect(fieldText(tester, 2, 0), '72.5');

      c.read(activeWorkoutProvider.notifier).replaceExercise(0, 'Dumbbell row');
      await tester.pumpAndSettle();
      expect(fieldText(tester, 0, 0), '0');
      expect(fieldText(tester, 0, 1), '8');

      c.read(activeWorkoutProvider.notifier).removeExercise(0);
      await tester.pumpAndSettle();
      expect(fieldText(tester, 0, 0), '30');
      expect(fieldText(tester, 0, 1), '12');
      await _leave(tester);
    });
  });

  group('live log', () {
    testWidgets('ticking a working set starts the rest bar at 2:00',
        (tester) async {
      final c = await _container();
      await _open(tester, c);
      expect(find.text('Skip'), findsNothing);
      await tester.tap(_check(0, 0));
      await tester.pump();
      expect(find.text('2:00'), findsOneWidget);
      await tester.tap(find.text('+15s'));
      await tester.pump();
      expect(find.text('2:15'), findsOneWidget);
      await _wait(tester, 5);
      expect(find.text('2:10'), findsOneWidget);
      await tester.tap(find.text('−15s'));
      await tester.pump();
      expect(find.text('1:55'), findsOneWidget);
      await tester.tap(find.text('Skip'));
      await tester.pump();
      expect(find.text('Skip'), findsNothing);
      await _leave(tester);
    });

    testWidgets('rest uses the exercise rest time and expires', (tester) async {
      final c = await _container();
      c.read(activeWorkoutProvider.notifier).setRest(0, 30);
      await _open(tester, c);
      await tester.tap(_check(0, 0));
      await tester.pump();
      expect(find.text('0:30'), findsOneWidget);
      await _wait(tester, 31);
      await tester.pump();
      expect(find.text('Skip'), findsNothing);
      await _leave(tester);
    });

    testWidgets('RPE picker sets the set RPE', (tester) async {
      final c = await _container();
      await _open(tester, c);
      await tester.tap(find.byKey(const ValueKey('rpe-0-2')));
      await tester.pumpAndSettle();
      expect(find.textContaining('RPE FOR SET 3'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('rpePick-8')));
      await tester.pumpAndSettle();
      expect(
          find.text('RPE 8 · about 2 reps left in the tank'), findsOneWidget);
      expect(c.read(activeWorkoutProvider)!.exercises[0].sets[2].rpe, 8);
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
            of: find.byKey(const ValueKey('rpe-0-2')),
            matching: find.text('8')),
        findsOneWidget,
      );
      await _leave(tester);
    });

    testWidgets('menu: add warm-up sets gives 40 x 10 and 55 x 5 with W',
        (tester) async {
      final c = await _container();
      await _open(tester, c);
      await tester.tap(find.byKey(const ValueKey('exerciseMenu-0')));
      await tester.pumpAndSettle();
      expect(find.text('2 sets: 40 kg × 10, 55 kg × 5'), findsOneWidget);
      await tester.tap(find.text('Add warm-up sets'));
      await tester.pumpAndSettle();
      final sets = c.read(activeWorkoutProvider)!.exercises[0].sets;
      expect((sets[0].kg, sets[0].reps, sets[0].warmup), (40.0, 10, true));
      expect((sets[1].kg, sets[1].reps, sets[1].warmup), (55.0, 5, true));
      expect(find.text('W'), findsNWidgets(2));
      await _leave(tester);
    });

    testWidgets('menu: swap shows similar exercises and replaces',
        (tester) async {
      final c = await _container();
      await _open(tester, c);
      await tester.tap(find.byKey(const ValueKey('exerciseMenu-0')));
      await tester.pumpAndSettle();
      expect(find.text('Similar: Dumbbell row'), findsOneWidget);
      await tester.tap(find.text('Swap exercise'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dumbbell row'));
      await tester.pumpAndSettle();
      expect(c.read(activeWorkoutProvider)!.exercises[0].name, 'Dumbbell row');
      await _leave(tester);
    });

    testWidgets('menu: rest stepper, note and remove', (tester) async {
      final c = await _container();
      await _open(tester, c);
      await tester.tap(find.byKey(const ValueKey('exerciseMenu-0')));
      await tester.pumpAndSettle();
      expect(find.text('2:00'), findsWidgets);
      await tester.tap(find.byKey(const ValueKey('restPlus')));
      await tester.pumpAndSettle();
      expect(c.read(activeWorkoutProvider)!.exercises[0].restSeconds, 150);
      await tester.tap(find.byKey(const ValueKey('moveDown')));
      await tester.pumpAndSettle();
      expect(c.read(activeWorkoutProvider)!.exercises[1].name, 'Barbell row');
      await tester.tap(find.text('Remove exercise'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Remove'));
      await tester.pumpAndSettle();
      expect(c.read(activeWorkoutProvider)!.exercises.length, 1);
      await _leave(tester);
    });

    testWidgets('no history: no Felix line and no PR chip', (tester) async {
      final c = await _container();
      await _open(tester, c);
      expect(find.textContaining('Last time'), findsNothing);
      for (var s = 0; s < 4; s++) {
        await tester.tap(_check(0, s));
        await tester.pump();
      }
      await tester.pumpAndSettle();
      expect(find.text('PR'), findsNothing);
      await _leave(tester);
    });

    testWidgets('with history: Felix line and a PR chip on a done exercise',
        (tester) async {
      final c = await _container(history: [_earlier()]);
      _raise(c);
      await _open(tester, c);
      expect(find.text('Last time 70 × 8. Try 72.5 kg today.'), findsOneWidget);
      for (var s = 0; s < 4; s++) {
        await tester.tap(_check(0, s));
        await tester.pump();
      }
      await tester.pumpAndSettle();
      expect(find.text('PR'), findsOneWidget);
      await _leave(tester);
    });

    testWidgets('caption counts only working sets', (tester) async {
      final c = await _container();
      c.read(activeWorkoutProvider.notifier).addWarmupSets(0);
      await _open(tester, c);
      expect(
          tester.widget<Text>(find.byKey(ActiveWorkoutSheet.captionKey)).data,
          'Set 1 of 7 · 0.0 t lifted');
      await tester.tap(_check(0, 2)); // first working set
      await tester.pump();
      expect(
          tester.widget<Text>(find.byKey(ActiveWorkoutSheet.captionKey)).data,
          'Set 2 of 7 · 0.6 t lifted');
      await _leave(tester);
    });
  });

  group('workout complete', () {
    Future<void> finishWithSet(WidgetTester tester, ProviderContainer c) async {
      await tester.tap(_check(0, 0));
      await tester.pump();
      await tester.tap(find.text('Finish workout'));
      await tester.pumpAndSettle();
    }

    testWidgets('Load appears after RPE 7 on an 86-minute workout',
        (tester) async {
      final c = await _container(elapsed: const Duration(minutes: 86));
      await _open(tester, c);
      await finishWithSet(tester, c);
      expect(find.text('Workout complete'), findsOneWidget);
      expect(find.text('Load'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('completeRpe-7')));
      await tester.pumpAndSettle();
      expect(find.text('Load'), findsOneWidget);
      expect(find.text('602'), findsOneWidget);
      expect(find.text('1:26'), findsOneWidget);
      await _leave(tester);
    });

    testWidgets('Save stores the workout with sessionRpe and opens progress',
        (tester) async {
      final c = await _container(elapsed: const Duration(minutes: 86));
      await _open(tester, c);
      await finishWithSet(tester, c);
      await tester.tap(find.byKey(const ValueKey('completeRpe-7')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save workout'));
      await tester.pumpAndSettle();
      final history = c.read(workoutHistoryProvider);
      expect(history.length, 1);
      expect(history.single.sessionRpe, 7);
      expect(c.read(activeWorkoutProvider), isNull);
      expect(c.read(pendingCompletedWorkoutProvider), isNull);
      expect(find.text('progress page'), findsOneWidget);
      await _leave(tester);
    });

    testWidgets('Discard asks first, then leaves history unchanged',
        (tester) async {
      final c = await _container();
      await _open(tester, c);
      await finishWithSet(tester, c);
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();
      // Keep going: nothing changes.
      await tester.tap(find.text('Keep going'));
      await tester.pumpAndSettle();
      expect(c.read(activeWorkoutProvider), isNotNull);
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Discard'));
      await tester.pumpAndSettle();
      expect(c.read(workoutHistoryProvider), isEmpty);
      expect(c.read(activeWorkoutProvider), isNull);
      expect(c.read(pendingCompletedWorkoutProvider), isNull);
      expect(find.text('home page'), findsOneWidget);
      await _leave(tester);
    });

    testWidgets('records, exercise rows and next-time card', (tester) async {
      final c = await _container(history: [_earlier()]);
      _raise(c);
      await _open(tester, c);
      for (var s = 0; s < 4; s++) {
        await tester.tap(_check(0, s));
        await tester.pump();
      }
      await tester.tap(find.text('Finish workout'));
      await tester.pumpAndSettle();
      expect(find.text('Back and Triceps · 1 new record'), findsOneWidget);
      expect(find.text('Best set 72.5 × 8'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('NEXT TIME'), 200);
      expect(find.text('NEXT TIME'), findsOneWidget);
      expect(find.textContaining('75 kg'), findsOneWidget);
      expect(find.textContaining('Energy'), findsNothing);
      await _leave(tester);
    });

    testWidgets('opens home when there is no pending workout', (tester) async {
      final c = await _container();
      tester.view.physicalSize = const Size(390, 844) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_app(c));
      await tester.pump();
      GoRouter.of(tester.element(find.byType(Scaffold)))
          .go(AppRouter.workoutComplete);
      await tester.pumpAndSettle();
      expect(find.text('home page'), findsOneWidget);
      await _leave(tester);
    });
  });

  group('small screens', () {
    for (final scale in [1.0, 1.3]) {
      testWidgets('live log fits 375x667 at text scale $scale', (tester) async {
        final c = await _container(history: [_earlier()]);
        c.read(activeWorkoutProvider.notifier).addWarmupSets(0);
        await _open(tester, c, size: const Size(375, 667), textScale: scale);
        await _tapVisible(tester, _check(0, 2));
        await _tapVisible(tester, find.byKey(const ValueKey('rpe-0-3')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Done'));
        await tester.pumpAndSettle();
        await _tapVisible(tester, find.byKey(const ValueKey('exerciseMenu-0')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await _leave(tester);
      });

      testWidgets('complete screen fits 375x667 at text scale $scale',
          (tester) async {
        final c = await _container(
            history: [_earlier()], elapsed: const Duration(minutes: 86));
        _raise(c);
        await _open(tester, c, size: const Size(375, 667), textScale: scale);
        for (var s = 0; s < 4; s++) {
          await _tapVisible(tester, _check(0, s));
        }
        await _tapVisible(tester, find.text('Finish workout'));
        await tester.pumpAndSettle();
        await _tapVisible(tester, find.byKey(const ValueKey('completeRpe-7')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await _leave(tester);
      });
    }
  });
}
