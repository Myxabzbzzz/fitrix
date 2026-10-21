import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitrix/core/session/session_providers.dart';
import 'package:fitrix/core/time/today_provider.dart';
import 'package:fitrix/features/checkin/presentation/providers/checkin_provider.dart';
import 'package:fitrix/features/exercises/data/exercise_catalog.dart';
import 'package:fitrix/features/plan/data/week_plan.dart';
import 'package:fitrix/features/plan/data/week_plan_store.dart';
import 'package:fitrix/features/plan/presentation/providers/week_plan_provider.dart';
import 'package:fitrix/features/plan/presentation/screens/week_plan_screen.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/features/workouts/data/workout_catalog.dart';
import 'package:fitrix/features/workouts/presentation/providers/workouts_provider.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';
import 'support/overflow.dart';

// Wednesday 14 Oct 2026; the week is Mon 12 - Sun 18.
final _now = DateTime(2026, 10, 14, 9, 0);
DateTime _d(int day) => DateTime(2026, 10, day);

PlannedSession _s(
  String id,
  int day, {
  Sport sport = Sport.gym,
  String title = 'Legs',
  String? templateId = 'gym-legs',
  int minutes = 70,
  Intensity intensity = Intensity.hard,
}) =>
    PlannedSession(
      id: id,
      day: _d(day),
      sport: sport,
      title: title,
      templateId: templateId,
      minutes: minutes,
      intensity: intensity,
    );

PlannedSession _football(String id, int day) => _s(id, day,
    sport: Sport.football,
    title: 'Football 7×7',
    templateId: null,
    minutes: 90);

CompletedWorkout _done(DateTime at, String templateId, Sport sport) =>
    CompletedWorkout(
      templateId: templateId,
      name: 'x',
      sport: sport,
      startedAt: at.subtract(const Duration(hours: 1)),
      finishedAt: at,
      exercises: const [],
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ExerciseCatalog catalog;
  setUpAll(() async {
    catalog = await ExerciseCatalog.load(rootBundle);
  });

  group('statusOf', () {
    test('done: same template on that day', () {
      final s = _s('a', 12);
      final h = [_done(DateTime(2026, 10, 12, 18), 'gym-legs', Sport.gym)];
      expect(statusOf(s, h, _now), SessionStatus.done);
    });

    test('a different template on that day is not done', () {
      final s = _s('a', 12);
      final h = [_done(DateTime(2026, 10, 12, 18), 'gym-chest', Sport.gym)];
      expect(statusOf(s, h, _now), SessionStatus.missed);
    });

    test('without a template the sport decides', () {
      final s = _football('f', 12);
      final h = [_done(DateTime(2026, 10, 12, 18), 'x', Sport.football)];
      expect(statusOf(s, h, _now), SessionStatus.done);
    });

    test('missed before today, today today, planned after', () {
      expect(statusOf(_s('a', 13), const [], _now), SessionStatus.missed);
      expect(statusOf(_s('a', 14), const [], _now), SessionStatus.today);
      expect(statusOf(_s('a', 15), const [], _now), SessionStatus.planned);
    });

    test('done today wins over today', () {
      final h = [_done(DateTime(2026, 10, 14, 8), 'gym-legs', Sport.gym)];
      expect(statusOf(_s('a', 14), h, _now), SessionStatus.done);
    });

    test('a free run completes the day\'s templated running session', () {
      final felix = _s('r', 12,
          sport: Sport.running, title: 'Easy run', templateId: 'felix-run');
      final h = [_done(DateTime(2026, 10, 12, 18), 'free_run', Sport.running)];
      expect(statusOf(felix, h, _now, plan: [felix]), SessionStatus.done);
      expect(completedFor(felix, h, plan: [felix]), same(h.single));
    });

    test('a football log completes the day\'s templated football session', () {
      final s = _s('f', 12,
          sport: Sport.football, title: '7×7', templateId: 'felix-ball');
      final h = [
        _done(DateTime(2026, 10, 12, 20), 'football_log', Sport.football)
      ];
      expect(statusOf(s, h, _now, plan: [s]), SessionStatus.done);
    });

    test('one free run claims only the first of two running sessions', () {
      final a = _s('a', 12,
          sport: Sport.running, title: 'Easy', templateId: 'felix-easy');
      final b = _s('b', 12,
          sport: Sport.running, title: 'Strides', templateId: 'felix-strides');
      final plan = [a, b];
      final h = [_done(DateTime(2026, 10, 12, 18), 'free_run', Sport.running)];
      expect(statusOf(a, h, _now, plan: plan), SessionStatus.done);
      expect(statusOf(b, h, _now, plan: plan), SessionStatus.missed);
    });

    test('a session done by its own template leaves the free run to the next',
        () {
      final a = _s('a', 12,
          sport: Sport.running, title: 'Easy', templateId: 'felix-easy');
      final b = _s('b', 12,
          sport: Sport.running, title: 'Strides', templateId: 'felix-strides');
      final plan = [a, b];
      final h = [
        _done(DateTime(2026, 10, 12, 8), 'felix-easy', Sport.running),
        _done(DateTime(2026, 10, 12, 18), 'free_run', Sport.running),
      ];
      expect(completedFor(a, h, plan: plan), same(h.first));
      expect(completedFor(b, h, plan: plan), same(h.last));
    });

    test('a free run is not claimed again past an untemplated session', () {
      final open =
          _s('o', 12, sport: Sport.running, title: 'Run', templateId: null);
      final felix = _s('r', 12,
          sport: Sport.running, title: 'Easy run', templateId: 'felix-run');
      final plan = [open, felix];
      final h = [_done(DateTime(2026, 10, 12, 18), 'free_run', Sport.running)];
      expect(statusOf(open, h, _now, plan: plan), SessionStatus.done);
      expect(statusOf(felix, h, _now, plan: plan), SessionStatus.missed);
    });

    test('a free run leaves a gym session and other days alone', () {
      final gym = _s('g', 12);
      final run = _s('r', 13,
          sport: Sport.running, title: 'Easy run', templateId: 'felix-run');
      final plan = [gym, run];
      final h = [_done(DateTime(2026, 10, 12, 18), 'free_run', Sport.running)];
      expect(statusOf(gym, h, _now, plan: plan), SessionStatus.missed);
      expect(statusOf(run, h, _now, plan: plan), SessionStatus.missed);
    });
  });

  group('intensity and legs', () {
    test('intensityOfTemplate', () {
      WorkoutTemplate t(Sport sport, String name, String focus, int min) =>
          WorkoutTemplate(
            id: name,
            sport: sport,
            name: name,
            focus: focus,
            estimatedDuration: Duration(minutes: min),
            exercises: const [],
          );
      expect(intensityOfTemplate(t(Sport.gym, 'Legs', 'Lower body', 40)),
          Intensity.hard);
      expect(intensityOfTemplate(t(Sport.gym, 'Whole', 'Full body', 40)),
          Intensity.hard);
      expect(intensityOfTemplate(t(Sport.gym, 'Arms', 'Upper body', 59)),
          Intensity.normal);
      expect(intensityOfTemplate(t(Sport.gym, 'Arms', 'Upper body', 60)),
          Intensity.hard);
      expect(intensityOfTemplate(t(Sport.football, 'Five', 'Football', 40)),
          Intensity.hard);
      expect(
          intensityOfTemplate(t(Sport.fitness, 'Stretching', 'Recovery', 90)),
          Intensity.easy);
    });

    test('loadsLegs', () {
      expect(loadsLegs(_football('f', 12), catalog), isTrue);
      expect(
          loadsLegs(
              _s('r', 12, sport: Sport.running, templateId: null), catalog),
          isTrue);
      expect(
          loadsLegs(_s('r', 12, sport: Sport.winterSports, templateId: null),
              catalog),
          isTrue);
      expect(loadsLegs(_s('l', 12), catalog), isTrue);
      expect(
          loadsLegs(
              _s('b', 12,
                  title: 'Back and Triceps', templateId: 'gym-back-triceps'),
              catalog),
          isFalse);
      expect(
          loadsLegs(
              _s('c', 12,
                  sport: Sport.cycling, templateId: null, title: 'Ride'),
              catalog),
          isFalse);
    });
  });

  group('suggestPlanChange', () {
    test('Football Sat + Legs Sun: move Legs to Monday', () {
      final week = [_football('f', 17), _s('l', 18)];
      final s = suggestPlanChange(week, _d(14), catalog)!;
      expect(s.sessionId, 'l');
      expect(s.from, _d(18));
      expect(s.to, _d(19));
    });

    test('nothing when two days apart', () {
      final week = [_football('f', 16), _s('l', 18)];
      expect(suggestPlanChange(week, _d(14), catalog), isNull);
    });

    test('skips a following day that already has a hard session', () {
      final week = [
        _football('f', 17),
        _s('l', 18),
        _s('c', 19,
            title: 'Chest and Biceps',
            templateId: 'gym-chest-biceps',
            minutes: 100),
      ];
      final s = suggestPlanChange(week, _d(14), catalog)!;
      expect(s.to, _d(20));
    });

    test('first session yesterday still counts; later one not done', () {
      final week = [_football('f', 17), _s('l', 18)];
      final s = suggestPlanChange(week, _d(18), catalog)!;
      expect(s.sessionId, 'l');
      expect(s.to, _d(19));
      expect(
          suggestPlanChange(week, _d(18), catalog, isDone: (x) => x.id == 'l'),
          isNull);
    });

    test('ignores pairs in the past', () {
      final week = [_football('f', 12), _s('l', 13)];
      expect(suggestPlanChange(week, _d(14), catalog), isNull);
    });
  });

  group('hard days', () {
    test('hardInNext3Days counts today and the two days after', () {
      final week = [
        _s('a', 13),
        _s('b', 14),
        _football('c', 16),
        _s('d', 17),
        _s('e', 15, intensity: Intensity.easy),
      ];
      expect(hardInNext3Days(week, _d(14)), 2);
    });

    test('wouldBeThirdHardDayInARow', () {
      final week = [_s('a', 16), _s('b', 17)];
      expect(wouldBeThirdHardDayInARow(week, _d(18), Intensity.hard), isTrue);
      expect(wouldBeThirdHardDayInARow(week, _d(15), Intensity.hard), isTrue);
      expect(wouldBeThirdHardDayInARow(week, _d(19), Intensity.hard), isFalse);
      expect(wouldBeThirdHardDayInARow(week, _d(18), Intensity.easy), isFalse);
      // Joining the two ends of a gap also makes three.
      final gap = [_s('a', 16), _s('b', 18)];
      expect(wouldBeThirdHardDayInARow(gap, _d(17), Intensity.hard), isTrue);
    });
  });

  group('store', () {
    test('round-trips and skips corrupt entries', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = WeekPlanStore(prefs);
      await store.save([_s('a', 14), _football('b', 15)]);
      expect([for (final s in store.all()) s.id], ['a', 'b']);
      expect(store.all().first.day, _d(14));

      await prefs.setString(
          'week_plan_v1',
          '{"sessions":[{"id":"a","day":"2026-10-14","sport":"gym",'
              '"title":"Legs","minutes":70,"intensity":"hard"},'
              '{"id":"bad"},"junk",'
              '{"id":"c","day":"nope","sport":"gym","title":"x","minutes":1,'
              '"intensity":"easy"}],"dismissed":["a@2026-10-12",5]}');
      expect([for (final s in WeekPlanStore(prefs).all()) s.id], ['a']);
      expect(WeekPlanStore(prefs).dismissed(), {'a@2026-10-12'});
    });

    test('totally corrupt blob gives an empty plan', () async {
      SharedPreferences.setMockInitialValues({'week_plan_v1': '{{{'});
      final prefs = await SharedPreferences.getInstance();
      expect(WeekPlanStore(prefs).all(), isEmpty);
    });
  });

  group('providers', () {
    Future<ProviderContainer> container(
        List<PlannedSession> plan, List<CompletedWorkout> history) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await WeekPlanStore(prefs).save(plan);
      final c = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        clockProvider.overrideWithValue(() => _now),
      ]);
      addTearDown(c.dispose);
      for (final h in history) {
        c.read(workoutHistoryProvider.notifier).add(h);
      }
      return c;
    }

    test('todaysGymTemplate follows the plan; first gym only without one',
        () async {
      var c = await container([_s('a', 14, templateId: 'gym-legs')], []);
      expect(c.read(todaysGymTemplateProvider)!.id, 'gym-legs');
      // A rest day on a planned week: no session to adjust.
      c = await container([_s('a', 15, templateId: 'gym-legs')], []);
      expect(c.read(todaysGymTemplateProvider), isNull);
      c = await container([], []);
      expect(c.read(todaysGymTemplateProvider)!.id,
          WorkoutCatalog.defaults.first.id);
    });

    test('a done session is skipped', () async {
      final c = await container([
        _s('a', 14, templateId: 'gym-legs'),
        _s('b', 14, templateId: 'gym-back-triceps', title: 'Back and Triceps'),
      ], [
        _done(DateTime(2026, 10, 14, 8), 'gym-legs', Sport.gym)
      ]);
      expect(c.read(todaysGymTemplateProvider)!.id, 'gym-back-triceps');
    });

    test('notifier move, remove, replaceFutureGym persist', () async {
      final c = await container([
        _s('a', 13),
        _s('b', 16),
        _football('f', 17),
      ], []);
      final n = c.read(weekPlanProvider.notifier);
      await n.move('b', _d(19));
      await n.remove('f');
      await n.replaceFutureGym([_s('n', 15)]);
      final store = WeekPlanStore(c.read(sharedPreferencesProvider));
      // 'a' is in the past and stays; 'b' (gym, future) is replaced by 'n'.
      expect([for (final s in store.all()) s.id]..sort(), ['a', 'n']);
    });
  });

  group('screen', () {
    Future<ProviderContainer> pump(
      WidgetTester tester,
      List<PlannedSession> plan, {
      List<CompletedWorkout> history = const [],
      Size size = const Size(390, 844),
      double textScale = 1.0,
      Set<String> dismissed = const {},
      DateTime? now,
    }) async {
      tester.view.physicalSize = size * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = WeekPlanStore(prefs);
      await store.save(plan);
      if (dismissed.isNotEmpty) await store.saveDismissed(dismissed);
      final c = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        clockProvider.overrideWithValue(() => now ?? _now),
        exerciseCatalogProvider.overrideWith((ref) async => catalog),
      ]);
      addTearDown(c.dispose);
      for (final h in history) {
        c.read(workoutHistoryProvider.notifier).add(h);
      }
      await tester.pumpWidget(UncontrolledProviderScope(
        container: c,
        child: MaterialApp(
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
          home: const WeekPlanScreen(),
        ),
      ));
      await tester.pumpAndSettle();
      return c;
    }

    String loadLabel(WidgetTester tester) =>
        tester.widget<Text>(find.byKey(const Key('plan-load-label'))).data!;

    testWidgets('load bar: 0 hard is Easy', (tester) async {
      await pump(tester, [_s('a', 18, intensity: Intensity.easy)]);
      expect(loadLabel(tester), 'Easy');
      expect(find.text('0 hard sessions in the next 3 days.'), findsOneWidget);
    });

    testWidgets('load bar: 2 hard is Normal', (tester) async {
      await pump(tester, [_s('a', 14), _football('b', 16)]);
      expect(loadLabel(tester), 'Normal');
    });

    testWidgets('load bar: 4 hard is High', (tester) async {
      await pump(tester, [
        _s('a', 14),
        _football('b', 15),
        _s('c', 16, templateId: 'gym-back-triceps', title: 'Back'),
        _s('d', 16, templateId: 'gym-chest-biceps', title: 'Chest'),
      ]);
      expect(loadLabel(tester), 'High');
      expect(find.text('4 hard sessions in the next 3 days.'), findsOneWidget);
    });

    testWidgets('header counts sessions and done', (tester) async {
      await pump(tester, [
        _s('a', 12),
        _s('b', 14),
      ], history: [
        _done(DateTime(2026, 10, 12, 18), 'gym-legs', Sport.gym)
      ]);
      expect(find.text('12–18 Oct · 2 sessions · 1 done'), findsOneWidget);
    });

    testWidgets('Optimize moves the session and persists it', (tester) async {
      final c = await pump(tester, [_football('f', 17), _s('l', 18)]);
      expect(find.byKey(const Key('plan-felix-card')), findsOneWidget);
      await tester.tap(find.text('Optimize plan'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('plan-felix-card')), findsNothing);
      final store = WeekPlanStore(c.read(sharedPreferencesProvider));
      expect(store.all().firstWhere((s) => s.id == 'l').day, _d(19));
    });

    testWidgets('Keep hides the card and remembers it', (tester) async {
      final c = await pump(tester, [_football('f', 17), _s('l', 18)]);
      await tester.tap(find.text('Keep'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('plan-felix-card')), findsNothing);
      final store = WeekPlanStore(c.read(sharedPreferencesProvider));
      expect(store.dismissed(), isNotEmpty);
      expect(store.all(), hasLength(2));
    });

    testWidgets('Start on today\'s gym item starts the template',
        (tester) async {
      final c = await pump(tester, [_s('l', 14)]);
      await tester.tap(find.byKey(const Key('plan-start-l')));
      await tester.pumpAndSettle();
      expect(c.read(activeWorkoutProvider)!.template.id, 'gym-legs');
    });

    testWidgets('missed item shows Missed', (tester) async {
      await pump(tester, [_s('l', 13)]);
      expect(find.text('Missed'), findsOneWidget);
    });

    testWidgets('add session: pick Football, add for today', (tester) async {
      final c = await pump(tester, [_s('l', 16)]);
      await tester.tap(find.byKey(const Key('plan-add')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Football').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add Football 7×7 · Today'));
      await tester.pumpAndSettle();
      final store = WeekPlanStore(c.read(sharedPreferencesProvider));
      final added = store.all().firstWhere((s) => s.sport == Sport.football);
      expect(added.day, _d(14));
      expect(added.intensity, Intensity.hard);
      expect(added.minutes, 90);
      expect(find.text('Football 7×7'), findsOneWidget);
    });

    testWidgets('add session warns about a 3rd hard day and picks another',
        (tester) async {
      // Hard on Thu and Fri: a hard session today would be the 3rd in a row.
      final c = await pump(tester, [
        _football('f1', 15),
        _s('l', 16),
      ]);
      await tester.tap(find.byKey(const Key('plan-add')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Football').last);
      await tester.pumpAndSettle();
      // Today (Wed) joins Thu+Fri: third hard day in a row, so Felix moves it.
      expect(find.byKey(const Key('plan-add-warning')), findsOneWidget);
      await tester.tap(find.textContaining('Add Football 7×7 · '));
      await tester.pumpAndSettle();
      final store = WeekPlanStore(c.read(sharedPreferencesProvider));
      final added = store.all().firstWhere((s) => s.id != 'f1' && s.id != 'l');
      expect(added.day, _d(18));
    });

    testWidgets('empty plan offers Plan my week', (tester) async {
      final c = await pump(tester, const []);
      expect(find.text('Plan my week'), findsOneWidget);
      expect(
          find.text('Set up your gym workouts for the rest of this week in '
              'one tap.'),
          findsOneWidget);
      await tester.tap(find.text('Plan my week'));
      await tester.pumpAndSettle();
      final store = WeekPlanStore(c.read(sharedPreferencesProvider));
      // Mon 12 is past: Wed 14 and Fri 16 only.
      expect([for (final s in store.all()) s.day], [_d(14), _d(16)]);
      expect(find.text('Plan my week'), findsNothing);
    });

    testWidgets('Sunday: a session added for Tuesday shows under Next week',
        (tester) async {
      final sunday = DateTime(2026, 10, 18, 9);
      final c = await pump(tester, const [], now: sunday);
      await tester.tap(find.byKey(const Key('plan-add')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Football').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add Football 7×7 · Tuesday'));
      await tester.pumpAndSettle();
      final added = WeekPlanStore(c.read(sharedPreferencesProvider)).all();
      expect(added.single.day, _d(20));
      await tester.scrollUntilVisible(find.text('Next week'), 300,
          scrollable: find.byType(Scrollable).first);
      expect(find.text('Next week'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Football 7×7'), 300,
          scrollable: find.byType(Scrollable).first);
      expect(find.text('Football 7×7'), findsOneWidget);
      // Header counts stay this-week only.
      await tester.fling(
          find.byType(Scrollable).first, const Offset(0, 3000), 3000);
      await tester.pumpAndSettle();
      expect(find.textContaining('0 sessions'), findsOneWidget);
    });

    testWidgets('Saturday: Plan next week seeds next Mon/Wed/Fri',
        (tester) async {
      final saturday = DateTime(2026, 10, 17, 9);
      final c = await pump(tester, const [], now: saturday);
      expect(find.text('Plan my week'), findsNothing);
      expect(find.text('Set up your gym workouts for next week in one tap.'),
          findsOneWidget);
      await tester.tap(find.text('Plan next week'));
      await tester.pumpAndSettle();
      final days = [
        for (final s in WeekPlanStore(c.read(sharedPreferencesProvider)).all())
          s.day
      ];
      expect(days, [_d(19), _d(21), _d(23)]);
      await tester.scrollUntilVisible(find.text('Next week'), 300,
          scrollable: find.byType(Scrollable).first);
      expect(find.text('Next week'), findsOneWidget);
    });

    testWidgets('SE size and 1.3 text: no overflow', (tester) async {
      await pump(
          tester,
          [
            _football('f', 17),
            _s('l', 18),
            _s('t', 14),
            _s('m', 13),
          ],
          size: iPhoneSeSize,
          textScale: 1.3);
      expectNoOverflow(tester);
      await tester.tap(find.byKey(const Key('plan-add')));
      await tester.pumpAndSettle();
      expectNoOverflow(tester);
      await tester.tap(find.text('Football').last);
      await tester.pumpAndSettle();
      expectNoOverflow(tester);
    });
  });
}
