import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitrix/core/router/app_router.dart';
import 'package:fitrix/core/session/session_providers.dart';
import 'package:fitrix/core/time/today_provider.dart';
import 'package:fitrix/features/exercises/data/exercise_catalog.dart';
import 'package:fitrix/features/exercises/domain/exercise_stats.dart';
import 'package:fitrix/features/exercises/presentation/add_exercise_screen.dart';
import 'package:fitrix/features/exercises/presentation/exercise_detail_screen.dart';
import 'package:fitrix/features/exercises/presentation/exercise_library_screen.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/features/workouts/presentation/providers/workouts_provider.dart';
import 'package:fitrix/features/workouts/presentation/widgets/active_workout_sheet.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';
import 'package:fitrix/core/i18n/catalog_overlay.dart';
import 'support/catalog_fixtures.dart';
import 'support/overflow.dart';

late ExerciseCatalog _catalog;

WorkoutSet _done(double kg, int reps, {bool warmup = false}) => WorkoutSet(
    previousKg: 0,
    previousReps: 0,
    kg: kg,
    reps: reps,
    done: true,
    warmup: warmup);

WorkoutSet _todo(int reps) =>
    WorkoutSet(previousKg: 0, previousReps: 0, kg: 0, reps: reps);

CompletedWorkout _past(DateTime at, List<Exercise> ex) => CompletedWorkout(
      templateId: 't',
      name: 'Past',
      sport: Sport.gym,
      startedAt: at.subtract(const Duration(hours: 1)),
      finishedAt: at,
      exercises: ex,
    );

WorkoutTemplate _template() => WorkoutTemplate(
      id: 'back',
      sport: Sport.gym,
      name: 'Back and Triceps',
      focus: 'Gym',
      estimatedDuration: const Duration(hours: 1),
      exercises: [
        Exercise(name: 'Deadlift', sets: [_todo(5)]),
        Exercise(name: 'Barbell row', sets: [_todo(8), _todo(8)]),
      ],
    );

Future<ProviderContainer> _container({
  List<CompletedWorkout> history = const [],
  bool active = false,
  String? language,
}) async {
  SharedPreferences.setMockInitialValues(
      {if (language != null) 'language': language});
  final prefs = await SharedPreferences.getInstance();
  final c = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    catalogBundleProvider.overrideWithValue(
        FixtureBundle.locale('ru', {'exercises': ruExercises})),
    exerciseCatalogProvider.overrideWith((ref) async => _catalog),
    todayProvider.overrideWith((ref) => DateTime(2026, 10, 18)),
  ]);
  addTearDown(c.dispose);
  for (final w in history) {
    c.read(workoutHistoryProvider.notifier).add(w);
  }
  if (active) c.read(activeWorkoutProvider.notifier).start(_template());
  return c;
}

Future<void> _pump(
  WidgetTester tester,
  ProviderContainer c,
  String location, {
  Size size = const Size(390, 6000),
  double textScale = 1,
  Widget? home,
  Locale? locale,
}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final router = GoRouter(initialLocation: location, routes: [
    GoRoute(
      path: '/',
      builder: (_, __) => home ?? const Scaffold(body: Text('root')),
    ),
    GoRoute(
      path: AppRouter.exerciseLibrary,
      builder: (_, __) => const ExerciseLibraryScreen(),
      routes: [
        GoRoute(
          path: 'add',
          builder: (_, s) => AddExerciseScreen(
            replace: s.uri.queryParameters['mode'] == 'replace',
            index: int.tryParse(s.uri.queryParameters['index'] ?? '') ?? 0,
          ),
        ),
        GoRoute(
          path: ':id',
          builder: (_, s) => ExerciseDetailScreen(id: s.pathParameters['id']!),
        ),
      ],
    ),
    GoRoute(
        path: AppRouter.felix,
        builder: (_, __) => const Scaffold(body: Text('felix'))),
  ]);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: c,
    child: MaterialApp.router(
      routerConfig: router,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

Finder _row(String id) => find.byKey(ValueKey('exercise-$id'));
Finder _pick(String id) => find.byKey(ValueKey('pick-$id'));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    _catalog = await ExerciseCatalog.load(rootBundle);
  });

  group('stats', () {
    test('filters by group, equipment and alias search', () {
      final chest = filterExercises(_catalog.all, group: MuscleGroup.chest);
      expect(chest.every((e) => e.group == MuscleGroup.chest), isTrue);
      final barbellChest = filterExercises(_catalog.all,
          group: MuscleGroup.chest, equipment: Equipment.barbell);
      expect(barbellChest.length, lessThan(chest.length));
      expect(
          filterExercises(_catalog.all, query: 'barbell bench press')
              .map((e) => e.id),
          contains('bench-press'));
    });

    test('rounds half up', () {
      expect(round1(107.25), 107.3);
    });

    test('weekly sets skip warm-ups and other weeks', () {
      final week = DateTime(2026, 10, 12);
      final history = [
        _past(DateTime(2026, 10, 14), [
          Exercise(name: 'Barbell row', sets: [
            _done(60, 8),
            _done(20, 10, warmup: true),
          ]),
        ]),
        _past(DateTime(2026, 10, 9), [
          Exercise(name: 'Barbell row', sets: [_done(60, 8)]),
        ]),
        _past(DateTime(2026, 10, 19), [
          Exercise(name: 'Barbell row', sets: [_done(60, 8)]),
        ]),
      ];
      expect(weeklySets(MuscleGroup.back, _catalog, history, week), 1);
    });
  });

  group('library', () {
    testWidgets('group and equipment pills narrow the list', (tester) async {
      final c = await _container();
      await _pump(tester, c, AppRouter.exerciseLibrary);
      expect(_row('bench-press'), findsOneWidget);
      expect(_row('barbell-row'), findsOneWidget);

      await tester.tap(find.text('Chest'));
      await tester.pumpAndSettle();
      expect(_row('bench-press'), findsOneWidget);
      expect(_row('barbell-row'), findsNothing);

      await tester.tap(find.text('Barbell'));
      await tester.pumpAndSettle();
      expect(_row('bench-press'), findsOneWidget);
      expect(_row('dumbbell-bench-press'), findsNothing);
    });

    testWidgets('search "bench" finds Bench press', (tester) async {
      final c = await _container();
      await _pump(tester, c, AppRouter.exerciseLibrary);
      await tester.enterText(find.byType(TextField), 'bench');
      await tester.pumpAndSettle();
      expect(_row('bench-press'), findsOneWidget);
      expect(_row('barbell-row'), findsNothing);
    });

    testWidgets('your recent shows the best set from history', (tester) async {
      final c = await _container(history: [
        _past(DateTime(2026, 10, 10), [
          Exercise(name: 'Bench press', sets: [_done(82.5, 9), _done(60, 10)]),
        ]),
      ]);
      await _pump(tester, c, AppRouter.exerciseLibrary);
      expect(find.text('Your recent'), findsOneWidget);
      expect(find.text('82.5 × 9'), findsOneWidget);
    });
  });

  group('detail', () {
    testWidgets('with history: e1RM 107.3 for 82.5 x 9', (tester) async {
      final c = await _container(history: [
        _past(DateTime(2026, 8, 3), [
          Exercise(name: 'Bench press', sets: [_done(70, 8)]),
        ]),
        _past(DateTime(2026, 10, 10), [
          Exercise(name: 'Bench press', sets: [_done(82.5, 9)]),
        ]),
      ]);
      await _pump(tester, c, '${AppRouter.exerciseLibrary}/bench-press');
      expect(find.text('Your numbers'), findsOneWidget);
      expect(find.text('107.3 kg'), findsOneWidget);
      expect(find.text('82.5 × 9'), findsOneWidget);
      expect(find.text('Do it once to see your numbers'), findsNothing);
    });

    testWidgets('without history: empty text', (tester) async {
      final c = await _container();
      await _pump(tester, c, '${AppRouter.exerciseLibrary}/bench-press');
      expect(find.text('Do it once to see your numbers'), findsOneWidget);
      expect(find.text('How to do it'), findsOneWidget);
    });

    testWidgets('add to workout starts a Quick workout when none is active',
        (tester) async {
      final c = await _container();
      await _pump(tester, c, '${AppRouter.exerciseLibrary}/bench-press');
      await tester.tap(find.text('Add to workout'));
      await tester.pumpAndSettle();
      final w = c.read(activeWorkoutProvider)!;
      expect(w.template.name, 'Quick workout');
      expect(w.exercises.map((e) => e.name), ['Bench press']);
      expect(
          c.read(workoutTemplatesProvider).any((t) => t.id == 'quick-workout'),
          isFalse);
    });

    testWidgets('add to workout appends to the active one', (tester) async {
      final c = await _container(active: true);
      await _pump(tester, c, '${AppRouter.exerciseLibrary}/bench-press');
      await tester.tap(find.text('Add to workout'));
      await tester.pumpAndSettle();
      expect(c.read(activeWorkoutProvider)!.exercises.last.name, 'Bench press');
      expect(c.read(activeWorkoutProvider)!.exercises.length, 3);
    });

    testWidgets('similar chip opens that exercise', (tester) async {
      final c = await _container();
      await _pump(tester, c, '${AppRouter.exerciseLibrary}/bench-press');
      await tester.tap(find.byKey(const ValueKey('similar-incline-bench')));
      await tester.pumpAndSettle();
      expect(find.text('Incline bench'), findsWidgets);
    });
  });

  group('add exercise', () {
    testWidgets('add mode with 2 selected adds 2 exercises', (tester) async {
      final c = await _container(active: true);
      await _pump(tester, c, AppRouter.addExerciseTo());
      expect(find.text('Add to Back and Triceps'), findsOneWidget);
      await tester.tap(_pick('chest-supported-row'));
      await tester.tap(_pick('straight-arm-pulldown'));
      await tester.pumpAndSettle();
      expect(find.text('Add 2 exercises'), findsOneWidget);
      await tester.tap(find.text('Add 2 exercises'));
      await tester.pumpAndSettle();
      final names =
          c.read(activeWorkoutProvider)!.exercises.map((e) => e.name).toList();
      expect(names.length, 4);
      expect(
          names.sublist(2), ['Chest-supported row', 'Straight-arm pulldown']);
    });

    testWidgets('exercises already in the workout cannot be picked',
        (tester) async {
      final c = await _container(active: true);
      await _pump(tester, c, AppRouter.addExerciseTo());
      expect(find.text('Barbell · In this workout'), findsWidgets);
      await tester.tap(_pick('barbell-row'));
      await tester.pumpAndSettle();
      expect(find.text('Add 0 exercises'), findsOneWidget);
    });

    testWidgets('replace mode swaps index 1', (tester) async {
      final c = await _container(active: true);
      await _pump(tester, c, AppRouter.addExerciseTo(replace: true, index: 1));
      expect(find.text('Swap in Back and Triceps'), findsOneWidget);
      await tester.tap(_pick('dumbbell-row'));
      await tester.tap(_pick('seated-cable-row'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Swap'));
      await tester.pumpAndSettle();
      final names =
          c.read(activeWorkoutProvider)!.exercises.map((e) => e.name).toList();
      expect(names, ['Deadlift', 'Seated cable row']);
    });

    testWidgets('weekly sets hint for back with 10 sets this week',
        (tester) async {
      final c = await _container(active: true, history: [
        _past(DateTime(2026, 10, 14), [
          Exercise(
              name: 'Barbell row',
              sets: [for (var i = 0; i < 6; i++) _done(60, 8)]),
          Exercise(
              name: 'Lat pulldown',
              sets: [for (var i = 0; i < 4; i++) _done(50, 10)]),
        ]),
      ]);
      await _pump(tester, c, AppRouter.addExerciseTo());
      expect(find.text('Back got 10 sets this week, target is 14.'),
          findsOneWidget);
    });

    testWidgets('no hint at the target', (tester) async {
      final c = await _container(active: true, history: [
        _past(DateTime(2026, 10, 14), [
          Exercise(
              name: 'Barbell row',
              sets: [for (var i = 0; i < 14; i++) _done(60, 8)]),
        ]),
      ]);
      await _pump(tester, c, AppRouter.addExerciseTo());
      expect(find.byKey(const ValueKey('weekly-hint')), findsNothing);
    });

    testWidgets('picker on an empty workout renders and adds', (tester) async {
      final c = await _container(active: true);
      final n = c.read(activeWorkoutProvider.notifier);
      n.removeExercise(1);
      n.removeExercise(0);
      expect(c.read(activeWorkoutProvider)!.exercises, isEmpty);
      await _pump(tester, c, AppRouter.addExerciseTo());
      expect(tester.takeException(), isNull);
      await tester.tap(_pick('dumbbell-row'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add 1 exercise'));
      await tester.pumpAndSettle();
      expect(c.read(activeWorkoutProvider)!.exercises.map((e) => e.name),
          ['Dumbbell row']);
    });

    testWidgets('replace with an out-of-range index does not throw',
        (tester) async {
      final c = await _container(active: true);
      await _pump(tester, c, AppRouter.addExerciseTo(replace: true, index: 99));
      expect(tester.takeException(), isNull);
      await tester.tap(_pick('dumbbell-row'));
      await tester.pumpAndSettle();
      // No valid index: it behaves as add.
      await tester.tap(find.text('Add 1 exercise'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(c.read(activeWorkoutProvider)!.exercises.length, 3);
    });

    testWidgets('system back from the picker re-expands the sheet',
        (tester) async {
      final c = await _container(active: true);
      await _pump(tester, c, '/',
          size: const Size(390, 844),
          home: const Scaffold(body: ActiveWorkoutSheet()));
      c.read(activeWorkoutExpandedProvider.notifier).state = true;
      await tester.pumpAndSettle();
      await tester.tap(find.text('Exercise'));
      await tester.pumpAndSettle();
      expect(c.read(activeWorkoutExpandedProvider), isFalse);
      await tester
          .state<NavigatorState>(find.byType(Navigator).last)
          .maybePop();
      await tester.pumpAndSettle();
      expect(find.text('Add to Back and Triceps'), findsNothing);
      expect(c.read(activeWorkoutExpandedProvider), isTrue);
      expect(c.read(activeWorkoutProvider)!.exercises.length, 2);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('live log "+ Exercise" opens the picker and returns to the log',
        (tester) async {
      final c = await _container(active: true);
      await _pump(tester, c, '/',
          size: const Size(390, 844),
          home: const Scaffold(body: ActiveWorkoutSheet()));
      c.read(activeWorkoutExpandedProvider.notifier).state = true;
      await tester.pumpAndSettle();
      await tester.tap(find.text('Exercise'));
      await tester.pumpAndSettle();
      expect(find.text('Add to Back and Triceps'), findsOneWidget);
      expect(c.read(activeWorkoutExpandedProvider), isFalse);
      await tester.tap(find.byKey(const ValueKey('suggest-dumbbell-row')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add 1 exercise'));
      await tester.pumpAndSettle();
      expect(find.text('Add to Back and Triceps'), findsNothing);
      expect(c.read(activeWorkoutExpandedProvider), isTrue);
      expect(c.read(activeWorkoutProvider)!.exercises.length, 3);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('small screen at 1.3x text', () {
    const se = Size(375, 667);
    for (final entry in {
      'library': AppRouter.exerciseLibrary,
      'detail': '${AppRouter.exerciseLibrary}/bench-press',
      'add': AppRouter.addExerciseTo(),
    }.entries) {
      testWidgets('${entry.key}: no overflow', (tester) async {
        final c = await _container(active: true, history: [
          _past(DateTime(2026, 10, 10), [
            Exercise(name: 'Bench press', sets: [_done(82.5, 9)]),
            Exercise(name: 'Barbell row', sets: [_done(60, 8)]),
          ]),
          _past(DateTime(2026, 8, 10), [
            Exercise(name: 'Bench press', sets: [_done(70, 9)]),
          ]),
        ]);
        await _pump(tester, c, entry.value, size: se, textScale: 1.3);
        expectNoOverflow(tester);
      });
    }
  });

  group('in Russian (catalog overlay)', () {
    const ru = Locale('ru');
    const benchRu = 'Жим штанги лёжа на горизонтальной скамье';

    testWidgets('detail shows the name, steps, mistakes, muscles and pattern',
        (tester) async {
      final c = await _container(language: 'ru');
      await _pump(tester, c, '${AppRouter.exerciseLibrary}/bench-press',
          locale: ru);
      expect(find.text(benchRu), findsOneWidget);
      expect(find.text('Bench press'), findsNothing);
      expect(find.textContaining('Глаза под грифом'), findsOneWidget);
      expect(find.text('Отбив грифа от груди'), findsOneWidget);
      expect(find.text('Грудные мышцы'), findsOneWidget);
      expect(find.text('Передние дельтовидные'), findsOneWidget);
      expect(find.text('ГОРИЗОНТАЛЬНЫЙ ЖИМ'), findsOneWidget);
    });

    testWidgets('adding it to a workout stores the English name',
        (tester) async {
      final c = await _container(language: 'ru');
      await _pump(tester, c, '${AppRouter.exerciseLibrary}/bench-press',
          locale: ru);
      final l10n = lookupAppLocalizations(ru);
      await tester.tap(find.text(l10n.exerciseAddToWorkout));
      await tester.pump();
      expect(c.read(activeWorkoutProvider)!.exercises.map((e) => e.name),
          ['Bench press']);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('library lists it in Russian and finds it by a Russian alias',
        (tester) async {
      final c = await _container(language: 'ru');
      await _pump(tester, c, AppRouter.exerciseLibrary, locale: ru);
      await tester.enterText(find.byType(TextField), 'жим штанги');
      await tester.pumpAndSettle();
      expect(_row('bench-press'), findsOneWidget);
      expect(
          find.descendant(
              of: _row('bench-press'), matching: find.text(benchRu)),
          findsOneWidget);
      await tester.enterText(find.byType(TextField), 'bench press');
      await tester.pumpAndSettle();
      expect(_row('bench-press'), findsOneWidget);
    });

    testWidgets('the picker finds it by its Russian name', (tester) async {
      final c = await _container(language: 'ru', active: true);
      await _pump(tester, c, AppRouter.addExerciseTo(), locale: ru);
      // The picker opens on the workout's group (back): show every group.
      await tester.tap(find.text(lookupAppLocalizations(ru).exercisesAll));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'скамье');
      await tester.pumpAndSettle();
      expect(_pick('bench-press'), findsOneWidget);
      await tester.tap(_pick('bench-press'));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('confirm-add')));
      await tester.pumpAndSettle();
      expect(c.read(activeWorkoutProvider)!.exercises.last.name, 'Bench press');
    });

    const se = Size(375, 667);
    for (final entry in {
      'library': AppRouter.exerciseLibrary,
      'detail': '${AppRouter.exerciseLibrary}/bench-press',
      'add': AppRouter.addExerciseTo(),
    }.entries) {
      testWidgets('${entry.key} fits SE at 1.3x text', (tester) async {
        final c = await _container(language: 'ru', active: true, history: [
          _past(DateTime(2026, 10, 10), [
            Exercise(name: 'Bench press', sets: [_done(82.5, 9)]),
          ]),
          _past(DateTime(2026, 8, 10), [
            Exercise(name: 'Bench press', sets: [_done(70, 9)]),
          ]),
        ]);
        await _pump(tester, c, entry.value,
            size: se, textScale: 1.3, locale: ru);
        expectNoOverflow(tester);
        await expectNoOverflowWhileScrolling(
            tester, find.byType(Scrollable).first, -600);
      });
    }
  });
}
