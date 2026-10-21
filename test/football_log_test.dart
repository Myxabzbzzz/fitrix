import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitrix/core/constants/app_constants.dart';
import 'package:fitrix/core/router/app_router.dart';
import 'package:fitrix/core/session/app_session.dart';
import 'package:fitrix/core/session/session_providers.dart';
import 'package:fitrix/core/sync/collections.dart';
import 'package:fitrix/core/sync/sync_state.dart';
import 'package:fitrix/core/time/today_provider.dart';
import 'package:fitrix/features/chat/data/felix_snapshot.dart';
import 'package:fitrix/features/chat/data/models/assistant_topic.dart';
import 'package:fitrix/features/football/data/match_log.dart';
import 'package:fitrix/features/football/data/match_store.dart';
import 'package:fitrix/features/football/presentation/football_screen.dart';
import 'package:fitrix/features/football/presentation/match_log_sheet.dart';
import 'package:fitrix/features/plan/data/week_plan.dart';
import 'package:fitrix/features/plan/presentation/providers/week_plan_provider.dart';
import 'package:fitrix/features/workouts/data/deleted_workouts_store.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/features/workouts/domain/training_math.dart';
import 'package:fitrix/features/workouts/presentation/providers/workouts_provider.dart';
import 'package:fitrix/features/workouts/presentation/start_workout.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';
import 'package:fitrix/main.dart';

import 'support/overflow.dart';

/// A Tuesday afternoon.
final _now = DateTime(2026, 10, 20, 15, 30);

final _refProvider = Provider<Ref>((ref) => ref);

class _Rig {
  _Rig(this.tester, this.container);
  final WidgetTester tester;
  final ProviderContainer container;

  List<CompletedWorkout> get history => container.read(workoutHistoryProvider);
  Map<String, MatchLog> get matches => container.read(matchesProvider);

  Future<void> openSheet({String? editId, WorkoutTemplate? template}) async {
    tester
        .state<_LauncherState>(find.byType(_Launcher))
        .open(editId: editId, template: template);
    await tester.pumpAndSettle();
  }

  Future<void> tap(String key) async {
    final f = find.byKey(ValueKey(key));
    await tester.ensureVisible(f);
    await tester.tap(f);
    await tester.pumpAndSettle();
  }
}

class _Launcher extends ConsumerStatefulWidget {
  const _Launcher();
  @override
  ConsumerState<_Launcher> createState() => _LauncherState();
}

class _LauncherState extends ConsumerState<_Launcher> {
  void open({String? editId, WorkoutTemplate? template}) =>
      showMatchLogSheet(context, ref, template: template, editId: editId);

  void start(WorkoutTemplate template) => startWorkout(context, ref, template);

  @override
  Widget build(BuildContext context) => const Scaffold(body: SizedBox());
}

Future<_Rig> _rig(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  double textScale = 1,
  String language = 'en',
  Widget home = const _Launcher(),
}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    clockProvider.overrideWithValue(() => _now),
  ]);
  addTearDown(container.dispose);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      locale: Locale(language),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    ),
  ));
  await tester.pumpAndSettle();
  return _Rig(tester, container);
}

void main() {
  group('log a match', () {
    testWidgets('7x7, 50 min, RPE 8, 3-4 creates the workout and the doc',
        (t) async {
      final r = await _rig(t);
      await r.container.read(weekPlanProvider.notifier).add(PlannedSession(
            id: 'p1',
            day: DateTime(2026, 10, 20),
            sport: Sport.football,
            title: 'Football',
            minutes: 90,
            intensity: Intensity.hard,
          ));
      await r.openSheet();
      await r.tap('fb-rpe-8');
      for (var i = 0; i < 3; i++) {
        await r.tap('fb-for-plus');
      }
      for (var i = 0; i < 4; i++) {
        await r.tap('fb-against-plus');
      }
      await r.tap('fb-save');

      final w = r.history.single;
      expect(w.sport, Sport.football);
      expect(w.name, 'Football 7×7');
      expect(w.templateId, 'football_log');
      expect(w.duration, const Duration(minutes: 50));
      expect(w.sessionRpe, 8);
      expect(w.load, sessionLoad(8, const Duration(minutes: 50)));
      expect(w.finishedAt, _now);
      final m = r.matches[w.id]!;
      expect(m.type, FootballType.match);
      expect(m.format, '7x7');
      expect(m.minutes, 50);
      expect(m.rpe, 8);
      expect(m.goalsFor, 3);
      expect(m.goalsAgainst, 4);
      expect(m.templateId, 'football_log');
      final plan = r.container.read(weekPlanProvider).single;
      expect(statusOf(plan, r.history, _now), SessionStatus.done);
    });

    testWidgets('a match saved without touching the score has no result',
        (t) async {
      final r = await _rig(t);
      await r.openSheet();
      expect(
          t.widget<Text>(find.byKey(const ValueKey('fb-for-value'))).data, '–');
      expect(
          t.widget<Text>(find.byKey(const ValueKey('fb-against-value'))).data,
          '–');
      await r.tap('fb-save');
      final w = r.history.single;
      final m = r.matches[w.id]!;
      expect(m.type, FootballType.match);
      expect(m.goalsFor, isNull);
      expect(m.goalsAgainst, isNull);
      expect(m.goals, 0);
      expect(m.assists, 0);

      final felix = buildFelixSnapshot(
        topic: AssistantTopic.football,
        today: _now,
        history: r.history,
        matches: r.matches,
      ).toJson();
      final match = (felix['lastWorkout']! as Map)['match'] as Map;
      expect(match['type'], 'match');
      expect(match.containsKey('goalsFor'), isFalse);
      expect(match.containsKey('goalsAgainst'), isFalse);
    });

    testWidgets('touching one score stepper sets the whole result', (t) async {
      final r = await _rig(t);
      await r.openSheet();
      await r.tap('fb-for-plus');
      expect(
          t.widget<Text>(find.byKey(const ValueKey('fb-against-value'))).data,
          '0');
      await r.tap('fb-save');
      final m = r.matches[r.history.single.id]!;
      expect(m.goalsFor, 1);
      expect(m.goalsAgainst, 0);
    });

    testWidgets('editing a match without a result keeps it without one',
        (t) async {
      final r = await _rig(t);
      await r.openSheet();
      await r.tap('fb-save');
      final id = r.history.single.id;
      await r.openSheet(editId: id);
      expect(
          t.widget<Text>(find.byKey(const ValueKey('fb-for-value'))).data, '–');
      await r.tap('fb-rpe-6');
      await r.tap('fb-save');
      expect(r.matches[id]!.goalsFor, isNull);
      expect(r.matches[id]!.goalsAgainst, isNull);
    });

    testWidgets('a past date finishes at 20:00 of that day', (t) async {
      final r = await _rig(t);
      await r.openSheet();
      await r.tap('fb-date');
      await t.tap(find.text('19'));
      await t.tap(find.text('OK'));
      await t.pumpAndSettle();
      await r.tap('fb-save');
      final w = r.history.single;
      expect(w.finishedAt, DateTime(2026, 10, 19, 20));
      expect(w.startedAt, DateTime(2026, 10, 19, 19, 10));
    });

    testWidgets('training hides result, goals and assists and saves none',
        (t) async {
      final r = await _rig(t);
      await r.openSheet();
      expect(find.byKey(const ValueKey('fb-for-plus')), findsOneWidget);
      expect(find.byKey(const ValueKey('fb-goals-plus')), findsOneWidget);
      await r.tap('fb-goals-plus');
      await r.tap('fb-type-training');
      expect(find.byKey(const ValueKey('fb-for-plus')), findsNothing);
      expect(find.byKey(const ValueKey('fb-against-plus')), findsNothing);
      expect(find.byKey(const ValueKey('fb-goals-plus')), findsNothing);
      expect(find.byKey(const ValueKey('fb-assists-plus')), findsNothing);
      expect(find.byKey(const ValueKey('fb-format-7x7')), findsNothing);
      expect(find.byKey(const ValueKey('fb-note')), findsNothing);
      await r.tap('fb-save');
      final w = r.history.single;
      expect(w.name, 'Football training');
      final m = r.matches[w.id]!;
      expect(m.type, FootballType.training);
      expect(m.goals, isNull);
      expect(m.format, isNull);
      expect(m.note, isNull);
      expect(m.goalsFor, isNull);
      expect(m.assists, isNull);
    });

    testWidgets('a template names the training and is remembered', (t) async {
      final r = await _rig(t);
      const tpl = WorkoutTemplate(
        id: 'tpl',
        sport: Sport.football,
        name: 'Tuesday drills',
        focus: 'Football',
        estimatedDuration: Duration(minutes: 60),
        exercises: [],
      );
      await r.openSheet(template: tpl);
      await r.tap('fb-type-training');
      await r.tap('fb-save');
      expect(r.history.single.name, 'Tuesday drills');
      expect(r.history.single.templateId, 'tpl');
      expect(r.matches.values.single.templateId, 'tpl');
    });

    testWidgets('the position comes from the last log', (t) async {
      final r = await _rig(t);
      await r.openSheet();
      await r.tap('fb-position-CB');
      await r.tap('fb-save');
      await r.openSheet();
      await r.tap('fb-save');
      expect(r.matches.values.map((m) => m.position), ['CB', 'CB']);
    });
  });

  group('edit and delete', () {
    Future<(_Rig, String)> logged(WidgetTester t) async {
      final r = await _rig(t);
      await r.openSheet();
      await r.tap('fb-rpe-8');
      await r.tap('fb-save');
      return (r, r.history.single.id);
    }

    testWidgets('editing the RPE keeps the id', (t) async {
      final (r, id) = await logged(t);
      await r.openSheet(editId: id);
      await r.tap('fb-rpe-5');
      await r.tap('fb-save');
      expect(r.history.single.id, id);
      expect(r.history.single.sessionRpe, 5);
      expect(r.matches[id]!.rpe, 5);
      expect(r.container.read(deletedWorkoutsStoreProvider).ids(), isEmpty);
    });

    testWidgets('editing the minutes makes a new id and deletes the old',
        (t) async {
      final (r, id) = await logged(t);
      await r.openSheet(editId: id);
      await r.tap('fb-minutes-plus');
      await r.tap('fb-save');
      final w = r.history.single;
      expect(w.id, isNot(id));
      expect(w.duration, const Duration(minutes: 55));
      expect(w.sessionRpe, 8);
      expect(r.matches.keys, {w.id});
      expect(r.container.read(deletedWorkoutsStoreProvider).ids(), {id});
      final state = SyncState.load(r.container.read(sharedPreferencesProvider));
      expect(state.docTombstones.keys, contains('match/$id'));
    });

    testWidgets('changing the format makes a new id and name', (t) async {
      final (r, id) = await logged(t);
      await r.openSheet(editId: id);
      await r.tap('fb-format-5x5');
      await r.tap('fb-save');
      final w = r.history.single;
      expect(w.id, isNot(id));
      expect(w.name, 'Football 5×5');
      expect(w.sessionRpe, 8);
      expect(r.matches.keys, {w.id});
      expect(r.container.read(deletedWorkoutsStoreProvider).ids(), {id});
    });

    testWidgets('changing the type to training renames with a new id',
        (t) async {
      final (r, id) = await logged(t);
      await r.openSheet(editId: id);
      await r.tap('fb-type-training');
      await r.tap('fb-save');
      final w = r.history.single;
      expect(w.id, isNot(id));
      expect(w.name, 'Football training');
      expect(r.matches[w.id]!.type, FootballType.training);
      expect(r.matches[w.id]!.format, isNull);
      expect(r.container.read(deletedWorkoutsStoreProvider).ids(), {id});
    });

    testWidgets('a 400 day old log can be opened and its date picked',
        (t) async {
      final r = await _rig(t);
      final at = _now.subtract(const Duration(days: 400));
      r.container.read(workoutHistoryProvider.notifier).add(CompletedWorkout(
            id: 'old',
            templateId: 'football_log',
            name: 'Football 7×7',
            sport: Sport.football,
            startedAt: at.subtract(const Duration(minutes: 50)),
            finishedAt: at,
            exercises: const [],
          ));
      r.container.read(matchesProvider.notifier).put(
          'old',
          MatchLog(
              type: FootballType.match, date: at, format: '7x7', minutes: 50));
      await r.openSheet(editId: 'old');
      await r.tap('fb-date');
      expect(t.takeException(), isNull);
      expect(find.text('OK'), findsOneWidget);
    });

    testWidgets('Delete removes the workout and the doc', (t) async {
      final (r, id) = await logged(t);
      await r.openSheet(editId: id);
      await r.tap('fb-delete');
      await r.tap('fb-delete-confirm');
      expect(r.history, isEmpty);
      expect(r.matches, isEmpty);
      expect(r.container.read(deletedWorkoutsStoreProvider).ids(), {id});
    });
  });

  group('wiring', () {
    testWidgets('startWorkout on a football plan opens the log sheet',
        (t) async {
      final r = await _rig(t);
      const tpl = WorkoutTemplate(
        id: 'tpl',
        sport: Sport.football,
        name: 'Tuesday drills',
        focus: 'Football',
        estimatedDuration: Duration(minutes: 60),
        exercises: [],
      );
      t.state<_LauncherState>(find.byType(_Launcher)).start(tpl);
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('fb-save')), findsOneWidget);
      expect(r.container.read(activeWorkoutProvider), isNull);
    });

    testWidgets('/workouts/football is the football screen, plans say Log',
        (t) async {
      SharedPreferences.setMockInitialValues({
        AppConstants.keyOnboardingComplete: true,
        'user_name': 'Alex',
      });
      final prefs = await SharedPreferences.getInstance();
      final session = AppSession(prefs);
      final container = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        appSessionProvider.overrideWithValue(session),
        clockProvider.overrideWithValue(() => _now),
      ]);
      addTearDown(container.dispose);
      final router = AppRouter.create(session);
      await t.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: FitrixApp(router: router),
      ));
      await t.pumpAndSettle();
      router.go(AppRouter.sportWorkouts(Sport.football));
      await t.pumpAndSettle();
      expect(find.byType(FootballScreen), findsOneWidget);
      expect(find.text('Start'), findsNothing);
    });
  });

  group('football screen', () {
    testWidgets('lists the log and opens it for editing', (t) async {
      final r = await _rig(t, home: const FootballScreen());
      expect(find.text('Log'), findsWidgets);
      r.container.read(workoutHistoryProvider.notifier).add(CompletedWorkout(
            id: 'g1',
            templateId: 'football_log',
            name: 'Football 7×7',
            sport: Sport.football,
            startedAt: DateTime(2026, 10, 19, 19, 10),
            finishedAt: DateTime(2026, 10, 19, 20),
            exercises: const [],
          ));
      r.container.read(matchesProvider.notifier).put(
            'g1',
            MatchLog(
              type: FootballType.match,
              date: DateTime(2026, 10, 19, 20),
              format: '7x7',
              minutes: 50,
              goalsFor: 3,
              goalsAgainst: 4,
            ),
          );
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('fb-row-g1')), findsOneWidget);
      expect(find.textContaining('3–4'), findsOneWidget);
      await r.tap('fb-row-g1');
      expect(find.byKey(const ValueKey('fb-delete')), findsOneWidget);
    });

    testWidgets('a match logged without a score shows no result', (t) async {
      final r = await _rig(t, home: const FootballScreen());
      await r.tap('fb-log');
      await r.tap('fb-save');
      final id = r.history.single.id;
      final row = find.byKey(ValueKey('fb-row-$id'));
      expect(row, findsOneWidget);
      final texts = t
          .widgetList<Text>(
              find.descendant(of: row, matching: find.byType(Text)))
          .map((w) => w.data ?? '')
          .join(' | ');
      expect(texts, contains('50'));
      expect(texts, isNot(contains('0–0')));
    });

    testWidgets('fits iPhone SE at 1.3 in ru', (t) async {
      final r = await _rig(t,
          size: iPhoneSeSize,
          textScale: 1.3,
          language: 'ru',
          home: const FootballScreen());
      expectNoOverflow(t);
      await r.tap('fb-log');
      expectNoOverflow(t);
      await t.drag(
          find.byType(SingleChildScrollView).last, const Offset(0, -800));
      await t.pumpAndSettle();
      expectNoOverflow(t);
      await r.tap('fb-type-training');
      expectNoOverflow(t);
    });

    testWidgets('the sheet fits iPhone SE at 1.3 in ru, every locale',
        (t) async {
      for (final lang in ['ru', 'uz', 'es', 'en']) {
        final r =
            await _rig(t, size: iPhoneSeSize, textScale: 1.3, language: lang);
        await r.openSheet();
        expectNoOverflow(t, reason: lang);
        await t.drag(
            find.byType(SingleChildScrollView).last, const Offset(0, -1200));
        await t.pumpAndSettle();
        expectNoOverflow(t, reason: lang);
      }
    });
  });

  group('MatchCollection', () {
    test('round trip, bad docs skipped, RPE copied to the workout', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final c = ProviderContainer(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
      addTearDown(c.dispose);
      final log = MatchLog(
        type: FootballType.match,
        date: DateTime.utc(2026, 10, 1, 20),
        format: '7x7',
        minutes: 50,
        position: 'ST',
        rpe: 7,
        goalsFor: 2,
        goalsAgainst: 1,
        goals: 1,
        assists: 1,
        note: 'ok',
        templateId: 'football_log',
      );
      expect(MatchLog.fromJson(log.toJson()).toJson(), log.toJson());

      c.read(matchStoreProvider).put('m1', log);
      final col = MatchCollection(c.read(_refProvider));
      expect(col.kind, 'match');
      final docs = col.read();
      expect(docs.keys, {'m1'});

      SharedPreferences.setMockInitialValues({});
      final other = ProviderContainer(overrides: [
        sharedPreferencesProvider
            .overrideWithValue(await SharedPreferences.getInstance())
      ]);
      addTearDown(other.dispose);
      other.read(workoutHistoryProvider.notifier).add(CompletedWorkout(
            id: 'm1',
            templateId: 'football_log',
            name: 'Football 7×7',
            sport: Sport.football,
            startedAt: DateTime.utc(2026, 10, 1, 19, 10),
            finishedAt: DateTime.utc(2026, 10, 1, 20),
            exercises: const [],
          ));
      MatchCollection(other.read(_refProvider)).apply({
        'm1': docs['m1'],
        'bad': {'nonsense': true}
      });
      expect(other.read(matchStoreProvider).all().keys, {'m1'});
      expect(other.read(workoutHistoryProvider).single.sessionRpe, 7);
      MatchCollection(other.read(_refProvider)).apply({'m1': null});
      expect(other.read(matchStoreProvider).all(), isEmpty);
    });

    test('is synced and clear empties the store', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final c = ProviderContainer(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
      addTearDown(c.dispose);
      final ref = c.read(_refProvider);
      expect(syncedCollections(ref).map((e) => e.kind), contains('match'));
      c.read(matchStoreProvider).put(
          'm1',
          MatchLog(
              type: FootballType.training,
              date: DateTime.utc(2026, 10, 1),
              minutes: 60));
      MatchCollection(ref).clear();
      expect(c.read(matchStoreProvider).all(), isEmpty);
    });
  });
}
