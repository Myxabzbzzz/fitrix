import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitrix/core/router/app_router.dart';
import 'package:fitrix/core/session/session_providers.dart';
import 'package:fitrix/core/time/today_provider.dart';
import 'package:fitrix/features/exercises/data/exercise_catalog.dart';
import 'package:fitrix/features/plan/data/week_plan.dart';
import 'package:fitrix/features/plan/presentation/providers/week_plan_provider.dart';
import 'package:fitrix/features/programs/data/program_store.dart';
import 'package:fitrix/features/programs/domain/program_catalog.dart';
import 'package:fitrix/features/programs/domain/program_progress.dart';
import 'package:fitrix/features/programs/presentation/providers/programs_provider.dart';
import 'package:fitrix/features/programs/presentation/screens/program_detail_screen.dart';
import 'package:fitrix/features/programs/presentation/screens/program_progress_screen.dart';
import 'package:fitrix/features/programs/presentation/screens/programs_screen.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/features/workouts/presentation/providers/workouts_provider.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

// Wednesday 14 Oct 2026; Monday is 12 Oct.
final _now = DateTime(2026, 10, 14, 9, 0);
DateTime _d(int day) => DateTime(2026, 10, day);

PlannedSession _gym(String id, int day) => PlannedSession(
    id: id,
    day: _d(day),
    sport: Sport.gym,
    title: 'Legs',
    templateId: 'gym-legs',
    minutes: 60,
    intensity: Intensity.hard);

PlannedSession _football(String id, int day) => PlannedSession(
    id: id,
    day: _d(day),
    sport: Sport.football,
    title: 'Football 7×7',
    minutes: 90,
    intensity: Intensity.hard);

CompletedWorkout _bench(DateTime at, {double kg = 82.5, int reps = 9}) =>
    CompletedWorkout(
      templateId: 'x',
      name: 'x',
      sport: Sport.gym,
      startedAt: at.subtract(const Duration(hours: 1)),
      finishedAt: at,
      exercises: [
        Exercise(name: 'Bench press', sets: [
          WorkoutSet(
              previousKg: 0, previousReps: 0, kg: kg, reps: reps, done: true),
        ]),
      ],
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ExerciseCatalog exercises;
  late ProgramCatalog catalog;
  late TrainingProgram ul4;
  setUpAll(() async {
    exercises = await ExerciseCatalog.load(rootBundle);
    catalog = ProgramCatalog.parse(
        File('assets/data/training_programs.json').readAsStringSync());
    ul4 = catalog.byId('upper-lower-4')!;
  });

  group('catalog', () {
    test('5 programs, every exercise resolves in the exercise catalog', () {
      expect(catalog.programs, hasLength(5));
      expect([
        for (final p in catalog.programs) p.name
      ], [
        'GZCLP',
        'Full body 3×',
        'StrongLifts 5×5',
        'Push / Pull / Legs',
        'Upper / Lower 4×',
      ]);
      expect(ul4.deloadWeek, 7);
      for (final p in catalog.programs) {
        for (final s in p.sessions) {
          for (final e in s.exercises) {
            expect(exercises.byName(e.exercise), isNotNull,
                reason: '${p.name}: ${e.exercise}');
          }
        }
      }
    });

    test('profile text maps leniently; no match picks the first program', () {
      expect(programGoalFor('Build muscle'), 'muscle');
      expect(programGoalFor('Get stronger'), 'strength');
      expect(programGoalFor('Lose fat'), 'fat_loss');
      expect(programGoalFor('???'), isNull);
      expect(programLevelFor('Beginner'), 'beginner');
      expect(programLevelFor('Intermediate'), 'intermediate');
      expect(programLevelFor('Advanced'), 'advanced');
      expect(pickProgram(catalog.programs, 'Build muscle', 'Intermediate')!.id,
          'upper-lower-4');
      expect(pickProgram(catalog.programs, 'Build strength', 'Beginner')!.id,
          'gzclp');
      expect(pickProgram(catalog.programs, '', '')!.id, 'gzclp');
    });
  });

  group('schedule', () {
    test('defaultWeekdays avoids the hard non-gym day and the day before', () {
      final days = defaultWeekdays(ul4, [_football('f', 17)]); // Saturday
      expect(days, hasLength(4));
      expect(days, isNot(contains(6)));
      expect(days, isNot(contains(5)));
      expect(defaultWeekdays(ul4, const []), [1, 2, 4, 5]);
    });

    test('an easy non-gym session does not block days', () {
      final easy = PlannedSession(
          id: 'r',
          day: _d(17),
          sport: Sport.running,
          title: 'Run',
          minutes: 30,
          intensity: Intensity.easy);
      expect(defaultWeekdays(ul4, [easy]), [1, 2, 4, 5]);
    });

    test('scheduleProgram: 8 weeks x 4 = 32 sessions from the start date', () {
      final ids = {for (final s in ul4.sessions) s.name: 't-${s.name}'};
      final list = scheduleProgram(ul4, _d(19), [1, 2, 4, 7], ids);
      expect(list, hasLength(32));
      expect(list.first.day, _d(19));
      expect(list.first.title, 'Upper 1');
      expect(list.first.templateId, 't-Upper 1');
      expect({for (final s in list) s.id}, hasLength(32));
      // Any 7 days hold exactly 4 sessions.
      final week = list.where((s) => s.day.isBefore(_d(26))).length;
      expect(week, 4);
      expect(list.last.day.isBefore(DateTime(2026, 12, 15)), isTrue);
    });

    test('a start between training days still gives 32', () {
      final list = scheduleProgram(ul4, _d(15), [1, 2, 4, 5], const {});
      expect(list, hasLength(32));
      expect(list.first.day, _d(15));
    });
  });

  group('startKg', () {
    test('82.5 x 9 history, 8 reps -> 80 kg', () {
      expect(startKg('Bench press', [_bench(_d(9))], 8), 80);
    });
    test('aliases merge through the catalog', () {
      expect(
          startKg('Barbell bench press', [_bench(_d(9))], 8,
              catalog: exercises),
          80);
    });
    test('no history -> null', () {
      expect(startKg('Bench press', const [], 8), isNull);
    });
  });

  group('store', () {
    test('round trip and corruption', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = ProgramStore(prefs);
      expect(store.load(), isNull);
      await store.save(ActiveProgram(
          programId: 'upper-lower-4',
          start: DateTime(2026, 10, 19, 15),
          weekdays: [1, 2, 4, 5],
          sessionTemplateIds: {'Upper 1': 'a'}));
      final a = store.load()!;
      expect(a.start, _d(19));
      expect(a.weekdays, [1, 2, 4, 5]);
      expect(a.sessionTemplateIds, {'Upper 1': 'a'});
      await prefs.setString(ProgramStore.key, '{nope');
      expect(store.load(), isNull);
      await prefs.setString(ProgramStore.key, '{"programId":"x"}');
      expect(store.load(), isNull);
    });
  });

  group('plan and templates', () {
    Future<ProviderContainer> container(List<PlannedSession> plan,
        {List<CompletedWorkout> history = const []}) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final c = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        clockProvider.overrideWithValue(() => _now),
        exerciseCatalogProvider.overrideWith((ref) async => exercises),
      ]);
      addTearDown(c.dispose);
      await c.read(weekPlanProvider.notifier).addAll(plan);
      for (final h in history) {
        c.read(workoutHistoryProvider.notifier).add(h);
      }
      return c;
    }

    test('replaceFutureGym keeps a gym session already done today', () async {
      final c = await container([
        _gym('done-today', 14),
        _gym('open-today', 14),
        _gym('later', 16),
        _football('f', 17),
      ]);
      await c.read(weekPlanProvider.notifier).replaceFutureGym(
        [_gym('new', 19)],
        isDone: (s) => s.id == 'done-today',
      );
      expect([for (final s in c.read(weekPlanProvider)) s.id]..sort(),
          ['done-today', 'f', 'new']);
    });

    test('addPlans returns the new template ids in order', () {
      SharedPreferences.setMockInitialValues({});
      return SharedPreferences.getInstance().then((prefs) {
        final c = ProviderContainer(overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ]);
        addTearDown(c.dispose);
        final ids =
            c.read(workoutTemplatesProvider.notifier).addPlans(Sport.gym, [
          (name: 'A', exercises: <Exercise>[], minutes: 45, focus: 'Upper 1'),
          (name: 'B', exercises: <Exercise>[], minutes: 80, focus: 'Lower 1'),
        ]);
        expect(ids, hasLength(2));
        final t = c.read(workoutTemplatesProvider);
        expect(t.firstWhere((x) => x.id == ids[1]).name, 'B');
        expect(t.firstWhere((x) => x.id == ids[1]).estimatedDuration.inMinutes,
            80);
      });
    });

    test('start with replace removes future gym sessions, keeps football',
        () async {
      final c = await container([
        _gym('g1', 16),
        _gym('g2', 18),
        _football('f', 17),
      ]);
      final active = await c.read(programStarterProvider).start(
            program: ul4,
            start: _d(19),
            weekdays: [1, 2, 4, 7],
            replacePlan: true,
          );
      final plan = c.read(weekPlanProvider);
      expect(plan.where((s) => s.id == 'g1' || s.id == 'g2'), isEmpty);
      expect(plan.where((s) => s.id == 'f'), hasLength(1));
      expect(plan.where((s) => s.id.startsWith('prog-upper-lower-4-')),
          hasLength(32));
      expect(c.read(activeProgramProvider)!.programId, 'upper-lower-4');
      expect(active.sessionTemplateIds.keys, hasLength(4));
      for (final id in active.sessionTemplateIds.values) {
        expect(c.read(workoutTemplatesProvider).any((t) => t.id == id), isTrue);
      }
    });

    test('start without replace keeps the existing gym sessions', () async {
      final c = await container([_gym('g1', 16)]);
      await c.read(programStarterProvider).start(
          program: ul4,
          start: _d(19),
          weekdays: [1, 2, 4, 7],
          replacePlan: false);
      expect(c.read(weekPlanProvider).any((s) => s.id == 'g1'), isTrue);
    });

    test('prefilled sets use the start weight, 0 without history', () async {
      final c = await container([], history: [_bench(_d(9))]);
      await c.read(programStarterProvider).start(
          program: ul4,
          start: _d(19),
          weekdays: [1, 2, 4, 7],
          replacePlan: true);
      final t = c
          .read(workoutTemplatesProvider)
          .firstWhere((t) => t.name.endsWith('Upper 1'));
      final bench = t.exercises.firstWhere((e) => e.name == 'Bench press');
      expect(bench.sets, hasLength(4));
      expect(bench.sets.first.kg, 80); // 107.25 / (1 + 10/30) at 8 reps
      final row = t.exercises.firstWhere((e) => e.name == 'Barbell row');
      expect(row.sets.first.kg, 0);
    });

    test('ending removes the future program sessions and the active program',
        () async {
      final c = await container([_football('f', 17)]);
      await c.read(programStarterProvider).start(
          program: ul4,
          start: _d(19),
          weekdays: [1, 2, 4, 7],
          replacePlan: true);
      await c.read(programStarterProvider).end();
      expect(c.read(activeProgramProvider), isNull);
      expect(c.read(weekPlanProvider), hasLength(1));
    });
  });

  group('progress math', () {
    test('slots match workouts per template, stats and next increase', () {
      final a = ActiveProgram(
          programId: 'upper-lower-4',
          start: _d(12),
          weekdays: [
            1,
            2,
            4,
            5
          ],
          sessionTemplateIds: {
            for (final s in ul4.sessions) s.name: 't-${s.name}'
          });
      CompletedWorkout w(DateTime at, String tpl, int reps) => CompletedWorkout(
            templateId: tpl,
            name: tpl,
            sport: Sport.gym,
            startedAt: at,
            finishedAt: at.add(const Duration(hours: 1)),
            exercises: [
              Exercise(name: 'Bench press', sets: [
                for (var i = 0; i < 4; i++)
                  WorkoutSet(
                      previousKg: 0,
                      previousReps: 0,
                      kg: 80,
                      reps: reps,
                      done: true),
              ]),
            ],
          );
      final history = [
        w(DateTime(2026, 10, 12, 8), 't-Upper 1', 8),
        w(DateTime(2026, 10, 14, 8), 't-Upper 2', 8), // Lower 1 slot missed
      ];
      final slots = programSlots(ul4, a, history);
      expect(slots, hasLength(32));
      expect(slots[0].isDone, isTrue);
      expect(slots[1].isDone, isFalse);
      final stats = programStats(slots, _d(14), history, a.start);
      expect(stats.planned, 2); // Mon and Tue; Thu 15 is not due on Wed
      expect(stats.done, 1);
      expect(programWeek(a, ul4, _d(14)), 1);
      expect(programWeek(a, ul4, _d(26)), 3);
      final inc = nextIncrease(ul4, a, history, exercises);
      expect(inc, isNotNull);
      expect(inc!.exercise, 'Bench press');
      expect(inc.nextKg, 82.5);
    });
  });

  group('screens', () {
    Future<ProviderContainer> pump(
      WidgetTester tester,
      String location, {
      List<PlannedSession> plan = const [],
      List<CompletedWorkout> history = const [],
      Size size = const Size(390, 844),
      double textScale = 1.0,
      ActiveProgram? active,
    }) async {
      tester.view.physicalSize = size * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      if (active != null) await ProgramStore(prefs).save(active);
      final c = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        clockProvider.overrideWithValue(() => _now),
        exerciseCatalogProvider.overrideWith((ref) async => exercises),
        programCatalogProvider.overrideWith((ref) async => catalog),
      ]);
      addTearDown(c.dispose);
      await c.read(weekPlanProvider.notifier).addAll(plan);
      for (final h in history) {
        c.read(workoutHistoryProvider.notifier).add(h);
      }
      final router = GoRouter(initialLocation: location, routes: [
        GoRoute(
            path: AppRouter.programs,
            builder: (_, __) => const ProgramsScreen()),
        GoRoute(
            path: AppRouter.programsActive,
            builder: (_, __) => const ProgramProgressScreen()),
        GoRoute(
            path: '${AppRouter.programs}/:id',
            builder: (_, s) =>
                ProgramDetailScreen(id: s.pathParameters['id']!)),
      ]);
      await tester.pumpWidget(UncontrolledProviderScope(
        container: c,
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
        ),
      ));
      await tester.pumpAndSettle();
      return c;
    }

    const detail = '${AppRouter.programs}/upper-lower-4';

    testWidgets('list: cards, filters, picked card', (tester) async {
      await pump(tester, AppRouter.programs);
      expect(find.text('Programs'), findsWidgets);
      expect(find.byKey(const Key('programs-card-gzclp')), findsOneWidget);
      expect(find.byKey(const Key('programs-active-card')), findsNothing);
      expect(find.byKey(const Key('programs-picked')), findsOneWidget);
      expect(find.text('5 programs'), findsOneWidget);
      await tester.tap(find.text('5+'));
      await tester.pumpAndSettle();
      expect(find.text('1 programs'), findsNothing);
      expect(find.byKey(const Key('programs-card-ppl-6')), findsOneWidget);
      expect(find.byKey(const Key('programs-card-gzclp')), findsNothing);
    });

    testWidgets('list: active program card', (tester) async {
      await pump(tester, AppRouter.programs,
          active: ActiveProgram(
              programId: 'upper-lower-4',
              start: _d(12),
              weekdays: [1, 2, 4, 5],
              sessionTemplateIds: const {}));
      expect(find.byKey(const Key('programs-active-card')), findsOneWidget);
      expect(find.text('Week 1 of 8'), findsOneWidget);
    });

    testWidgets('detail: clash, Felix card, first session', (tester) async {
      await pump(tester, detail, plan: [_football('f', 17)]);
      expect(find.text('Upper / Lower 4×'), findsWidgets);
      expect(find.text('1 clash'), findsOneWidget);
      expect(find.text('Bench press'), findsOneWidget);
      await tester.scrollUntilVisible(
          find.byKey(const Key('program-felix-card')), 200,
          scrollable: find.byType(Scrollable).first);
      expect(find.text('Deload in week 7'), findsOneWidget);
    });

    testWidgets('detail: no Felix card without a clash', (tester) async {
      await pump(tester, detail);
      expect(find.byKey(const Key('program-felix-card')), findsNothing);
      expect(find.text('1 clash'), findsNothing);
    });

    testWidgets('start sheet: weights from history, start shows week 1 of 8',
        (tester) async {
      final c = await pump(tester, detail,
          plan: [_football('f', 17), _gym('g', 16)], history: [_bench(_d(9))]);
      await tester.tap(find.byKey(const Key('program-start')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('start-weights')), findsOneWidget);
      expect(find.text('80 kg × 8'), findsOneWidget);
      await tester.tap(find.byKey(const Key('start-confirm')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Week 1 of 8'), findsOneWidget);
      expect(c.read(activeProgramProvider), isNotNull);
      expect(c.read(weekPlanProvider).any((s) => s.id == 'g'), isFalse);
      expect(c.read(weekPlanProvider).any((s) => s.id == 'f'), isTrue);
    });

    testWidgets('start sheet: no history hides start weights', (tester) async {
      await pump(tester, detail);
      await tester.tap(find.byKey(const Key('program-start')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('start-weights')), findsNothing);
      expect(find.byKey(const Key('start-confirm')), findsOneWidget);
    });

    testWidgets('start needs exactly perWeek days', (tester) async {
      await pump(tester, detail);
      await tester.tap(find.byKey(const Key('program-start')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('start-day-3')));
      await tester.pumpAndSettle();
      expect(find.text('5 of 4 picked'), findsOneWidget);
      final btn = tester.widget<InkWell>(find.descendant(
          of: find.byKey(const Key('start-confirm')),
          matching: find.byType(InkWell)));
      expect(btn.onTap, isNull);
    });

    testWidgets('progress: end program asks first', (tester) async {
      final c = await pump(tester, AppRouter.programsActive,
          active: ActiveProgram(
              programId: 'upper-lower-4',
              start: _d(12),
              weekdays: [1, 2, 4, 5],
              sessionTemplateIds: const {}));
      expect(find.textContaining('Week 1 of 8'), findsOneWidget);
      await tester.scrollUntilVisible(find.byKey(const Key('program-end')), 300,
          scrollable: find.byType(Scrollable).first);
      await tester.tap(find.byKey(const Key('program-end')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(c.read(activeProgramProvider), isNotNull);
      await tester.tap(find.byKey(const Key('program-end')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('program-end-confirm')));
      await tester.pumpAndSettle();
      expect(c.read(activeProgramProvider), isNull);
    });

    for (final scale in [1.0, 1.3]) {
      testWidgets('no overflow on SE at text scale $scale', (tester) async {
        final active = ActiveProgram(
            programId: 'upper-lower-4',
            start: _d(12),
            weekdays: [1, 2, 4, 5],
            sessionTemplateIds: const {});
        for (final loc in [AppRouter.programs, detail]) {
          await pump(tester, loc,
              size: const Size(375, 667),
              textScale: scale,
              active: active,
              plan: [_football('f', 17)],
              history: [_bench(_d(9))]);
          expect(tester.takeException(), isNull, reason: loc);
        }
        await pump(tester, AppRouter.programsActive,
            size: const Size(375, 667),
            textScale: scale,
            active: active,
            history: [_bench(_d(9))]);
        expect(tester.takeException(), isNull);
        await pump(tester, detail,
            size: const Size(375, 667),
            textScale: scale,
            plan: [_football('f', 17)],
            history: [_bench(_d(9))]);
        await tester.tap(find.byKey(const Key('program-start')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  });
}
