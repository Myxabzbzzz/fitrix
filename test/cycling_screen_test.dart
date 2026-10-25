import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitrix/core/constants/app_constants.dart';
import 'package:fitrix/core/router/app_router.dart';
import 'package:fitrix/core/session/app_session.dart';
import 'package:fitrix/core/session/session_providers.dart';
import 'package:fitrix/core/time/today_provider.dart';
import 'package:fitrix/features/plan/data/week_plan.dart';
import 'package:fitrix/features/plan/presentation/providers/week_plan_provider.dart';
import 'package:fitrix/features/running/data/location_source.dart';
import 'package:fitrix/features/running/data/run_store.dart';
import 'package:fitrix/features/running/data/run_track.dart';
import 'package:fitrix/features/running/presentation/run_recorder.dart';
import 'package:fitrix/features/running/presentation/run_voice.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/features/workouts/domain/training_math.dart';
import 'package:fitrix/features/workouts/presentation/providers/workouts_provider.dart';
import 'package:fitrix/main.dart';

import 'support/overflow.dart';

/// A Tuesday afternoon.
final _now = DateTime(2026, 10, 20, 15, 30);

class _SilentSpeaker implements Speaker {
  @override
  Future<Set<String>> languages() async => {'en', 'ru', 'uz', 'es'};
  @override
  Future<void> prepare() async {}
  @override
  Future<bool> speak(String text, {required String language}) async => true;
  @override
  Future<void> stop() async {}
}

class _Source implements LocationSource {
  int starts = 0;
  StreamController<RunPoint>? _c;
  void emit(RunPoint p) => _c!.add(p);
  @override
  Future<LocationAccess> ensureAccess() async => LocationAccess.granted;
  @override
  Future<bool> reducedAccuracy() async => false;
  @override
  Stream<RunPoint> start() {
    starts++;
    return (_c = StreamController<RunPoint>(sync: true)).stream;
  }

  @override
  Future<void> stop() async {
    await _c?.close();
    _c = null;
  }
}

class _Rig {
  _Rig(this.tester, this.container, this.router, this.source);
  final WidgetTester tester;
  final ProviderContainer container;
  final GoRouter router;
  final _Source source;

  List<CompletedWorkout> get history => container.read(workoutHistoryProvider);
  Map<String, RunDetails> get runs => container.read(runsProvider);
  String get location =>
      router.routerDelegate.currentConfiguration.last.matchedLocation;

  Future<void> tap(String key) async {
    final f = find.byKey(ValueKey(key));
    await tester.ensureVisible(f);
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  /// Scrolls [f] clear of the tab bar that floats over the list's end.
  Future<void> scrollTo(Finder f) async {
    await tester.ensureVisible(f);
    await tester.drag(find.byType(ListView).first, const Offset(0, -150));
    await tester.pumpAndSettle();
  }

  Future<void> open() async {
    router.go(AppRouter.sportWorkouts(Sport.cycling));
    await tester.pumpAndSettle();
  }

  Future<void> enter(String key, String text) async {
    final f = find.byKey(ValueKey(key));
    await tester.ensureVisible(f);
    await tester.enterText(f, text);
    await tester.pump();
  }

  void saveRide(String id, DateTime at, double meters, Duration moving,
      {bool indoor = false, int? power}) {
    container.read(runsProvider.notifier).put(
          id,
          RunDetails(
            startedAt: at,
            moving: moving,
            elapsed: moving,
            pauses: 0,
            meters: meters,
            splits: const [],
            route: const [],
            kind: ActivityKind.ride,
            indoor: indoor,
            avgPowerW: power,
          ),
        );
    container.read(workoutHistoryProvider.notifier).add(CompletedWorkout(
          id: id,
          templateId: indoor ? 'indoor_ride' : 'free_ride',
          name: 'Ride $id',
          sport: Sport.cycling,
          startedAt: at,
          finishedAt: at.add(moving),
          exercises: const [],
        ));
  }
}

Future<_Rig> _rig(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  double textScale = 1,
  String language = 'en',
}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  SharedPreferences.setMockInitialValues({
    AppConstants.keyOnboardingComplete: true,
    'user_name': 'Alex',
    'language': language,
  });
  final prefs = await SharedPreferences.getInstance();
  final session = AppSession(prefs);
  final source = _Source();
  final container = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    appSessionProvider.overrideWithValue(session),
    clockProvider.overrideWithValue(() => _now),
    locationSourceProvider.overrideWithValue(source),
    speakerProvider.overrideWithValue(_SilentSpeaker()),
  ]);
  addTearDown(container.dispose);
  final router = AppRouter.create(session);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: FitrixApp(router: router),
  ));
  await tester.pumpAndSettle();
  return _Rig(tester, container, router, source);
}

/// Feeds a minute of moving fixes to the open recording and finishes it.
Future<CompletedWorkout> _finishRecording(WidgetTester t, _Rig r) async {
  for (var i = 0; i <= 12; i++) {
    r.source.emit(RunPoint(
        lat: 41 + i * 0.0001,
        lng: 69,
        accuracy: 5,
        at: _now.add(Duration(seconds: i * 5))));
  }
  return (await t.runAsync(
      () => r.container.read(runRecorderProvider.notifier).finish()))!;
}

void main() {
  group('screen', () {
    testWidgets('Start ride starts a ride and opens the live screen',
        (t) async {
      final r = await _rig(t);
      await r.open();
      await t.tap(find.byKey(const ValueKey('cy-start')));
      await t.pumpAndSettle();
      expect(r.location, AppRouter.liveRun);
      expect(r.container.read(runRecorderProvider)!.kind, ActivityKind.ride);
      expect(r.source.starts, 1);
    });

    testWidgets('the gear opens the ride workout settings', (t) async {
      final r = await _rig(t);
      await r.open();
      await t.tap(find.byKey(const ValueKey('cy-settings')));
      await t.pumpAndSettle();
      expect(find.text('Workout settings'), findsOneWidget);
      expect(find.text('Speaks the start, every 5 km and the finish.'),
          findsOneWidget);
    });

    testWidgets('history lists rides only, with week totals', (t) async {
      final r = await _rig(t);
      r.saveRide(
          'a', DateTime(2026, 10, 18, 7), 20000, const Duration(minutes: 60));
      r.saveRide('b', DateTime(2026, 10, 20, 7), 31500,
          const Duration(hours: 1, minutes: 30));
      r.saveRide(
          'c', DateTime(2026, 10, 19, 18), 0, const Duration(minutes: 45),
          indoor: true);
      // A run is not a ride.
      r.container.read(workoutHistoryProvider.notifier).add(CompletedWorkout(
            id: 'run',
            templateId: 'free_run',
            name: 'Run',
            sport: Sport.running,
            startedAt: DateTime(2026, 10, 20, 6),
            finishedAt: DateTime(2026, 10, 20, 7),
            exercises: const [],
          ));
      r.container.read(runsProvider.notifier).put(
          'run',
          RunDetails(
            startedAt: DateTime(2026, 10, 20, 6),
            moving: const Duration(hours: 1),
            elapsed: const Duration(hours: 1),
            pauses: 0,
            meters: 10000,
            splits: const [],
            route: const [],
          ));
      await r.open();
      expect(find.byKey(const ValueKey('cy-row-a')), findsOneWidget);
      expect(find.byKey(const ValueKey('cy-row-b')), findsOneWidget);
      expect(find.byKey(const ValueKey('cy-row-c')), findsOneWidget);
      expect(find.byKey(const ValueKey('cy-row-run')), findsNothing);
      expect(find.byKey(const ValueKey('run-row-run')), findsNothing);
      expect(
          find.descendant(
              of: find.byKey(const ValueKey('cy-week-km')),
              matching: find.text('31.50')),
          findsOneWidget);
      expect(
          find.descendant(
              of: find.byKey(const ValueKey('cy-week-rides')),
              matching: find.text('2')),
          findsOneWidget);
    });

    testWidgets('the indoor row shows the power unit in the app language',
        (t) async {
      final r = await _rig(t, language: 'ru');
      r.saveRide(
          'c', DateTime(2026, 10, 19, 18), 0, const Duration(minutes: 45),
          indoor: true, power: 180);
      await r.open();
      expect(find.textContaining('180 Вт'), findsOneWidget);
    });

    testWidgets('an outdoor row opens the summary', (t) async {
      final r = await _rig(t);
      r.saveRide(
          'b', DateTime(2026, 10, 20, 7), 31500, const Duration(hours: 1));
      await r.open();
      await t.tap(find.byKey(const ValueKey('cy-row-b')));
      await t.pumpAndSettle();
      expect(r.location, AppRouter.runSummary('b'));
    });

    testWidgets('pills route cycling to this screen from Running', (t) async {
      final r = await _rig(t);
      r.router.go(AppRouter.sportWorkouts(Sport.running));
      await t.pumpAndSettle();
      await t.tap(find.text('Cycling'));
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('cy-start')), findsOneWidget);
    });
  });

  group('indoor ride log', () {
    Future<void> openLog(_Rig r) async {
      await r.open();
      await r.tap('cy-log');
    }

    testWidgets('saves a cycling workout with indoor details', (t) async {
      final r = await _rig(t);
      await openLog(r);
      await r.tap('ride-minutes-plus');
      await r.tap('ride-rpe-7');
      await r.enter('ride-km', '25,5');
      await r.enter('ride-power', '180');
      await r.enter('ride-note', 'Trainer, intervals');
      await r.tap('ride-save');

      final w = r.history.single;
      expect(w.sport, Sport.cycling);
      expect(w.templateId, 'indoor_ride');
      expect(w.duration, const Duration(minutes: 50));
      expect(w.sessionRpe, 7);
      expect(w.load, sessionLoad(7, const Duration(minutes: 50)));
      expect(w.finishedAt, _now);
      final d = r.runs[w.id]!;
      expect(d.indoor, isTrue);
      expect(d.kind, ActivityKind.ride);
      expect(d.meters, 25500);
      expect(d.avgPowerW, 180);
      expect(d.moving, const Duration(minutes: 50));
      expect(d.rpe, 7);
      expect(d.note, 'Trainer, intervals');
      expect(d.route, isEmpty);
      expect(d.toJson()['note'], 'Trainer, intervals');
      unawaited(r.router.push(AppRouter.runSummary(w.id)));
      await t.pumpAndSettle();
      expect(find.text('Trainer, intervals'), findsOneWidget);
      r.router.pop();
      await t.pumpAndSettle();
      expect(find.byKey(ValueKey('cy-row-${w.id}')), findsOneWidget);
    });

    testWidgets('distance and power are optional', (t) async {
      final r = await _rig(t);
      await openLog(r);
      await r.tap('ride-save');
      final d = r.runs[r.history.single.id]!;
      expect(d.meters, 0);
      expect(d.avgPowerW, isNull);
      expect(d.note, isNull);
      expect(d.toJson().containsKey('note'), isFalse);
    });

    testWidgets('a planned session is marked done by the log', (t) async {
      final r = await _rig(t);
      await r.container.read(weekPlanProvider.notifier).add(PlannedSession(
            id: 'p1',
            day: DateTime(2026, 10, 20),
            sport: Sport.cycling,
            title: 'Cycling',
            minutes: 60,
            intensity: Intensity.normal,
          ));
      await openLog(r);
      await r.tap('ride-save');
      final plan = r.container.read(weekPlanProvider).single;
      expect(statusOf(plan, r.history, _now), SessionStatus.done);
    });

    testWidgets('a past date finishes at 20:00 of that day', (t) async {
      final r = await _rig(t);
      await openLog(r);
      await r.tap('ride-date');
      await t.tap(find.text('19'));
      await t.tap(find.text('OK'));
      await t.pumpAndSettle();
      await r.tap('ride-save');
      expect(r.history.single.finishedAt, DateTime(2026, 10, 19, 20));
    });

    Future<(_Rig, String)> logged(WidgetTester t) async {
      final r = await _rig(t);
      await openLog(r);
      await r.tap('ride-rpe-8');
      await r.enter('ride-km', '10');
      await r.tap('ride-save');
      return (r, r.history.single.id);
    }

    testWidgets('editing the RPE keeps the id and updates the doc', (t) async {
      final (r, id) = await logged(t);
      await t.tap(find.byKey(ValueKey('cy-row-$id')));
      await t.pumpAndSettle();
      expect(
          t
              .widget<TextField>(find.byKey(const ValueKey('ride-km')))
              .controller!
              .text,
          '10');
      await r.tap('ride-rpe-5');
      await r.tap('ride-save');
      expect(r.history.single.id, id);
      expect(r.history.single.sessionRpe, 5);
      expect(r.runs[id]!.rpe, 5);
      expect(r.runs[id]!.meters, 10000);
    });

    testWidgets('editing the minutes replaces the workout', (t) async {
      final (r, id) = await logged(t);
      await t.tap(find.byKey(ValueKey('cy-row-$id')));
      await t.pumpAndSettle();
      await r.tap('ride-minutes-plus');
      await r.tap('ride-save');
      final w = r.history.single;
      expect(w.id, isNot(id));
      expect(w.duration, const Duration(minutes: 50));
      expect(r.runs.keys, {w.id});
      expect(r.runs[w.id]!.indoor, isTrue);
    });

    testWidgets('delete removes the workout and its doc', (t) async {
      final (r, id) = await logged(t);
      await t.tap(find.byKey(ValueKey('cy-row-$id')));
      await t.pumpAndSettle();
      await r.tap('ride-delete');
      await r.tap('ride-delete-confirm');
      expect(r.history, isEmpty);
      expect(r.runs, isEmpty);
    });
  });

  group('planned session and free ride', () {
    testWidgets('Start on a planned cycling workout asks Outdoor or Indoor',
        (t) async {
      final r = await _rig(t);
      r.container
          .read(workoutTemplatesProvider.notifier)
          .add(Sport.cycling, 'Hill repeats');
      await r.open();
      Finder start() => find.descendant(
          of: find
              .ancestor(
                  of: find.text('Hill repeats'),
                  matching: find.byType(Dismissible))
              .first,
          matching: find.text('Start'));
      await r.scrollTo(start());
      await t.tap(start());
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('ride-choice-outdoor')), findsOneWidget);
      expect(find.byKey(const ValueKey('ride-choice-indoor')), findsOneWidget);

      // Outdoor: records a ride under the template.
      await r.tap('ride-choice-outdoor');
      final tpl = r.container
          .read(workoutTemplatesProvider)
          .firstWhere((x) => x.name == 'Hill repeats');
      expect(r.location, AppRouter.liveRun);
      final s = r.container.read(runRecorderProvider)!;
      expect(s.kind, ActivityKind.ride);
      expect(s.templateId, tpl.id);
      await r.container.read(weekPlanProvider.notifier).add(PlannedSession(
            id: 'po',
            day: DateTime(2026, 10, 20),
            sport: Sport.cycling,
            title: 'Hill repeats',
            templateId: tpl.id,
            minutes: 60,
            intensity: Intensity.normal,
          ));
      final saved = await _finishRecording(t, r);
      expect(saved.templateId, tpl.id);
      expect(r.runs[saved.id]!.kind, ActivityKind.ride);
      final outdoor = r.container.read(weekPlanProvider).single;
      expect(statusOf(outdoor, r.history, _now), SessionStatus.done);
      await r.container.read(weekPlanProvider.notifier).remove('po');
      r.container.read(workoutHistoryProvider.notifier).remove(saved.id);
      r.container.read(runsProvider.notifier).remove(saved.id);

      // Indoor: logs under the template, so the plan marks it done.
      r.router.go(AppRouter.sportWorkouts(Sport.cycling));
      await t.pumpAndSettle();
      await r.container.read(weekPlanProvider.notifier).add(PlannedSession(
            id: 'p1',
            day: DateTime(2026, 10, 20),
            sport: Sport.cycling,
            title: 'Hill repeats',
            templateId: tpl.id,
            minutes: 60,
            intensity: Intensity.normal,
          ));
      for (var i = 0; i < 8 && start().evaluate().isEmpty; i++) {
        await t.drag(find.byType(ListView).last, const Offset(0, -300));
        await t.pumpAndSettle();
      }
      await r.scrollTo(start());
      await t.tap(start());
      await t.pumpAndSettle();
      await r.tap('ride-choice-indoor');
      await r.tap('ride-save');
      expect(r.history.single.templateId, tpl.id);
      expect(r.history.single.name, 'Hill repeats');
      final plan = r.container.read(weekPlanProvider).single;
      expect(statusOf(plan, r.history, _now), SessionStatus.done);
    });

    testWidgets('a free ride and an indoor log fill the open cycling session',
        (t) async {
      final r = await _rig(t);
      await r.container.read(weekPlanProvider.notifier).add(PlannedSession(
            id: 'p1',
            day: DateTime(2026, 10, 20),
            sport: Sport.cycling,
            title: 'Cycling',
            templateId: 'tpl',
            minutes: 60,
            intensity: Intensity.normal,
          ));
      var plan = r.container.read(weekPlanProvider).single;
      expect(statusOf(plan, r.history, _now), SessionStatus.today);
      r.saveRide(
          'b', DateTime(2026, 10, 20, 7), 20000, const Duration(hours: 1));
      plan = r.container.read(weekPlanProvider).single;
      expect(statusOf(plan, r.history, _now, plan: [plan]), SessionStatus.done);
    });
  });

  group('small screen', () {
    testWidgets('screen, sheet and choice fit an SE at 1.3x', (t) async {
      final r = await _rig(t, size: iPhoneSeSize, textScale: 1.3);
      r.container
          .read(workoutTemplatesProvider.notifier)
          .add(Sport.cycling, 'Hill repeats');
      r.saveRide(
          'a', DateTime(2026, 10, 18, 7), 20000, const Duration(minutes: 60));
      await r.open();
      expectNoOverflow(t);
      await r.tap('cy-log');
      expectNoOverflow(t);
      await r.enter('ride-note', 'Some words');
      expectNoOverflow(t);
      await r.tap('ride-save');
      final start = find.descendant(
          of: find
              .ancestor(
                  of: find.text('Hill repeats'),
                  matching: find.byType(Dismissible))
              .first,
          matching: find.text('Start'));
      await r.scrollTo(start);
      await t.tap(start);
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('ride-choice-outdoor')), findsOneWidget);
      expectNoOverflow(t);
    });
  });
}
