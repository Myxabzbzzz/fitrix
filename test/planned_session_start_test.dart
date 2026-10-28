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

PlannedSession _session(Sport sport, {String id = 'p1', String? title}) =>
    PlannedSession(
      id: id,
      day: DateTime(2026, 10, 20),
      sport: sport,
      title: title ?? sport.label,
      minutes: 40,
      intensity: Intensity.normal,
    );

void main() {
  SessionStatus status(_Rig r) =>
      statusOf(r.container.read(weekPlanProvider).single, r.history, _now,
          plan: r.container.read(weekPlanProvider));

  Future<void> openHome(_Rig r) async {
    r.router.go(AppRouter.home);
    await r.tester.pumpAndSettle();
  }

  Future<void> openPlan(_Rig r) async {
    r.router.go(AppRouter.weekPlan);
    await r.tester.pumpAndSettle();
  }

  group('Home: today\'s session without a plan has a Start button', () {
    testWidgets('a run opens the GPS recorder; the saved run marks it done',
        (t) async {
      final r = await _rig(t);
      await r.container
          .read(weekPlanProvider.notifier)
          .add(_session(Sport.running));
      await openHome(r);

      await r.tap('home-today-start');

      expect(r.location, AppRouter.liveRun);
      expect(r.container.read(runRecorderProvider)!.kind, ActivityKind.run);
      expect(status(r), SessionStatus.today);
      final saved = await _finishRecording(t, r);
      expect(saved.sport, Sport.running);
      expect(status(r), SessionStatus.done);
    });

    testWidgets('a gym session opens an empty live log of that sport',
        (t) async {
      final r = await _rig(t);
      await r.container
          .read(weekPlanProvider.notifier)
          .add(_session(Sport.gym, title: 'Upper body'));
      await openHome(r);

      await r.tap('home-today-start');

      final active = r.container.read(activeWorkoutProvider)!;
      expect(active.template.sport, Sport.gym);
      expect(active.template.name, 'Upper body');
      expect(active.exercises, isEmpty);
      final log = r.container.read(activeWorkoutProvider.notifier);
      log.addExercises(['Bench press']);
      log.toggleSet(0, 0);
      log.finish();
      await t.pumpAndSettle();
      expect(status(r), SessionStatus.done);
    });
  });

  group('Week plan: today\'s session without a plan has a Start button', () {
    testWidgets('a ride asks Outdoor or Indoor; Outdoor records a free ride',
        (t) async {
      final r = await _rig(t);
      await r.container
          .read(weekPlanProvider.notifier)
          .add(_session(Sport.cycling));
      await openPlan(r);

      await r.tap('plan-start-p1');
      expect(find.byKey(const ValueKey('ride-choice-indoor')), findsOneWidget);
      await r.tap('ride-choice-outdoor');

      expect(r.location, AppRouter.liveRun);
      expect(r.container.read(runRecorderProvider)!.kind, ActivityKind.ride);
      await _finishRecording(t, r);
      expect(status(r), SessionStatus.done);
    });

    testWidgets('Indoor opens the ride log; saving marks it done', (t) async {
      final r = await _rig(t);
      await r.container
          .read(weekPlanProvider.notifier)
          .add(_session(Sport.cycling));
      await openPlan(r);

      await r.tap('plan-start-p1');
      await r.tap('ride-choice-indoor');
      await r.tap('ride-save');

      expect(r.history.single.sport, Sport.cycling);
      expect(status(r), SessionStatus.done);
    });

    testWidgets('a ski day opens the GPS recorder as a ski day', (t) async {
      final r = await _rig(t);
      await r.container
          .read(weekPlanProvider.notifier)
          .add(_session(Sport.winterSports));
      await openPlan(r);

      await r.tap('plan-start-p1');

      expect(r.location, AppRouter.liveRun);
      expect(r.container.read(runRecorderProvider)!.kind, ActivityKind.ski);
      await _finishRecording(t, r);
      expect(status(r), SessionStatus.done);
    });

    testWidgets('football opens the match log; saving marks it done',
        (t) async {
      final r = await _rig(t);
      await r.container
          .read(weekPlanProvider.notifier)
          .add(_session(Sport.football));
      await openPlan(r);

      await r.tap('plan-start-p1');
      await r.tap('fb-save');

      expect(r.history.single.sport, Sport.football);
      expect(status(r), SessionStatus.done);
    });

    testWidgets('a fitness session starts an empty fitness log', (t) async {
      final r = await _rig(t);
      await r.container
          .read(weekPlanProvider.notifier)
          .add(_session(Sport.fitness));
      await openPlan(r);

      await r.tap('plan-start-p1');

      final active = r.container.read(activeWorkoutProvider)!;
      expect(active.template.sport, Sport.fitness);
      expect(active.exercises, isEmpty);
    });
  });

  testWidgets('SE, text 1.3, ru: Home card and plan row with Start fit',
      (t) async {
    final r = await _rig(t, size: iPhoneSeSize, textScale: 1.3, language: 'ru');
    await r.container.read(weekPlanProvider.notifier).add(_session(
        Sport.football,
        title: 'Товарищеский матч с длинным названием'));
    await openHome(r);
    await t.ensureVisible(find.byKey(const ValueKey('home-today-start')));
    await t.pumpAndSettle();
    expectNoOverflow(t);
    await openPlan(r);
    expect(find.byKey(const ValueKey('plan-start-p1')), findsOneWidget);
    expectNoOverflow(t);
  });
}
