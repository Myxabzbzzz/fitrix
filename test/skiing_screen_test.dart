import 'dart:async';
import 'dart:convert';

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
import 'package:fitrix/features/running/data/ski_math.dart';
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
    router.go(AppRouter.sportWorkouts(Sport.winterSports));
    await tester.pumpAndSettle();
  }

  Future<void> enter(String key, String text) async {
    final f = find.byKey(ValueKey(key));
    await tester.ensureVisible(f);
    await tester.enterText(f, text);
    await tester.pump();
  }

  /// A ski day with [descents] descents of 100 m vertical each.
  void saveSki(String id, DateTime at, {int descents = 3}) {
    container.read(runsProvider.notifier).put(
          id,
          RunDetails(
            startedAt: at,
            moving: const Duration(hours: 2),
            elapsed: const Duration(hours: 4),
            pauses: 0,
            meters: 1000.0 * descents,
            splits: const [],
            route: const [],
            kind: ActivityKind.ski,
            ski: SkiDay(
              descents: [
                for (var n = 0; n < descents; n++)
                  SkiDescent(
                    start: at.add(Duration(minutes: n * 20)),
                    end: at.add(Duration(minutes: n * 20 + 4)),
                    meters: 1000,
                    vertical: 100,
                    maxSpeed: 12,
                    avgSpeed: 6,
                    routeFrom: 0,
                    routeTo: 0,
                  ),
              ],
              lifts: descents,
              liftTime: const Duration(minutes: 30),
            ),
          ),
        );
    container.read(workoutHistoryProvider.notifier).add(CompletedWorkout(
          id: id,
          templateId: 'free_ski',
          name: 'Ski $id',
          sport: Sport.winterSports,
          startedAt: at,
          finishedAt: at.add(const Duration(hours: 4)),
          exercises: const [],
        ));
  }
}

Future<_Rig> _rig(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  double textScale = 1,
  String language = 'en',
  Map<String, Object> prefsValues = const {},
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
    ...prefsValues,
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
  testWidgets('Start ski day starts a ski session and opens live', (t) async {
    final r = await _rig(t);
    await r.open();
    await t.tap(find.byKey(const ValueKey('ski-start')));
    await t.pumpAndSettle();
    expect(r.location, AppRouter.liveRun);
    expect(r.container.read(runRecorderProvider)!.kind, ActivityKind.ski);
    expect(r.source.starts, 1);
  });

  testWidgets('the gear opens the ski workout settings', (t) async {
    final r = await _rig(t);
    await r.open();
    await t.tap(find.byKey(const ValueKey('ski-settings')));
    await t.pumpAndSettle();
    expect(find.text('Workout settings'), findsOneWidget);
    expect(find.text('Speaks the start, each descent and the finish.'),
        findsOneWidget);
  });

  testWidgets('history lists ski days only, with week totals', (t) async {
    final r = await _rig(t);
    r.saveSki('a', DateTime(2026, 10, 19, 9));
    r.saveSki('b', DateTime(2026, 10, 20, 9), descents: 2);
    r.saveSki('old', DateTime(2026, 10, 5, 9));
    // A winter sports workout without a ski doc is not listed.
    r.container.read(workoutHistoryProvider.notifier).add(CompletedWorkout(
          id: 'x',
          templateId: 't',
          name: 'Other',
          sport: Sport.winterSports,
          startedAt: DateTime(2026, 10, 20, 6),
          finishedAt: DateTime(2026, 10, 20, 7),
          exercises: const [],
        ));
    await r.open();
    expect(find.byKey(const ValueKey('ski-row-a')), findsOneWidget);
    expect(find.byKey(const ValueKey('ski-row-b')), findsOneWidget);
    expect(find.byKey(const ValueKey('ski-row-x')), findsNothing);
    Finder fig(String k, String v) =>
        find.descendant(of: find.byKey(ValueKey(k)), matching: find.text(v));
    expect(fig('ski-week-days', '2'), findsOneWidget);
    expect(fig('ski-week-descents', '5'), findsOneWidget);
    expect(fig('ski-week-vertical', '500'), findsOneWidget);
  });

  testWidgets('a row opens the ski summary', (t) async {
    final r = await _rig(t);
    r.saveSki('a', DateTime(2026, 10, 19, 9));
    await r.open();
    await t.tap(find.byKey(const ValueKey('ski-row-a')));
    await t.pumpAndSettle();
    expect(r.location, AppRouter.runSummary('a'));
  });

  testWidgets('pills route winter sports to this screen', (t) async {
    final r = await _rig(t);
    r.router.go(AppRouter.sportWorkouts(Sport.running));
    await t.pumpAndSettle();
    await t.scrollUntilVisible(find.text('Winter sports'), 100,
        scrollable: find.byWidgetPredicate(
            (w) => w is Scrollable && w.axis == Axis.horizontal));
    await t.ensureVisible(find.text('Winter sports'));
    await t.pumpAndSettle();
    await t.tap(find.text('Winter sports'));
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('ski-start')), findsOneWidget);
  });

  testWidgets('My workouts shows the Winter sports tile', (t) async {
    final r = await _rig(t);
    r.router.go(AppRouter.workouts);
    await t.pumpAndSettle();
    final tile = find.text('WINTER\nSPORTS');
    await t.scrollUntilVisible(tile, 200,
        scrollable: find.byType(Scrollable).first);
    await t.tap(tile);
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('ski-start')), findsOneWidget);
  });

  Finder startOf(String name) => find.descendant(
      of: find
          .ancestor(of: find.text(name), matching: find.byType(Dismissible))
          .first,
      matching: find.text('Start'));

  testWidgets('a planned winterSports Start records a ski day and marks done',
      (t) async {
    final r = await _rig(t);
    r.container
        .read(workoutTemplatesProvider.notifier)
        .add(Sport.winterSports, 'Powder day');
    await r.open();
    await r.scrollTo(startOf('Powder day'));
    await t.tap(startOf('Powder day'));
    await t.pumpAndSettle();
    final tpl = r.container
        .read(workoutTemplatesProvider)
        .firstWhere((x) => x.name == 'Powder day');
    expect(r.location, AppRouter.liveRun);
    final s = r.container.read(runRecorderProvider)!;
    expect(s.kind, ActivityKind.ski);
    expect(s.templateId, tpl.id);
    await r.container.read(weekPlanProvider.notifier).add(PlannedSession(
          id: 'p1',
          day: DateTime(2026, 10, 20),
          sport: Sport.winterSports,
          title: 'Powder day',
          templateId: tpl.id,
          minutes: 120,
          intensity: Intensity.hard,
        ));
    final saved = await _finishRecording(t, r);
    expect(saved.templateId, tpl.id);
    expect(saved.sport, Sport.winterSports);
    expect(r.runs[saved.id]!.kind, ActivityKind.ski);
    final plan = r.container.read(weekPlanProvider).single;
    expect(statusOf(plan, r.history, _now), SessionStatus.done);
  });

  testWidgets('a free ski day fills the open winterSports session', (t) async {
    final r = await _rig(t);
    await r.container.read(weekPlanProvider.notifier).add(PlannedSession(
          id: 'p1',
          day: DateTime(2026, 10, 20),
          sport: Sport.winterSports,
          title: 'Skiing',
          templateId: 'tpl',
          minutes: 120,
          intensity: Intensity.hard,
        ));
    var plan = r.container.read(weekPlanProvider).single;
    expect(statusOf(plan, r.history, _now), SessionStatus.today);
    await r.open();
    await r.tap('ski-start');
    final saved = await _finishRecording(t, r);
    expect(saved.templateId, 'free_ski');
    plan = r.container.read(weekPlanProvider).single;
    expect(statusOf(plan, r.history, _now, plan: [plan]), SessionStatus.done);
  });

  testWidgets('starting a ski day over an unfinished ride asks about the ride',
      (t) async {
    final r = await _rig(t);
    r.container
        .read(workoutTemplatesProvider.notifier)
        .add(Sport.winterSports, 'Powder day');
    await r.container
        .read(runRecorderProvider.notifier)
        .start(kind: ActivityKind.ride);
    await r.open();
    await t.pumpAndSettle();
    for (var i = 0; i < 6 && find.text('Powder day').evaluate().isEmpty; i++) {
      await t.drag(find.byType(ListView).last, const Offset(0, -300));
      await t.pumpAndSettle();
    }
    await r.scrollTo(startOf('Powder day'));
    await t.tap(startOf('Powder day'));
    await t.pumpAndSettle();
    expect(find.text('You have an unfinished ride'), findsOneWidget);
    await t.tap(find.text('Discard and start'));
    await t.pumpAndSettle();
    expect(find.text('Discard this ride?'), findsOneWidget);
    await t.runAsync(
        () => r.container.read(runRecorderProvider.notifier).discard());
  });

  testWidgets('screen and a ski-day dialog fit an SE at 1.3x', (t) async {
    final r = await _rig(t, size: iPhoneSeSize, textScale: 1.3);
    r.saveSki('a', DateTime(2026, 10, 19, 9));
    r.container
        .read(workoutTemplatesProvider.notifier)
        .add(Sport.winterSports, 'Powder day');
    await r.open();
    expectNoOverflow(t);
    r.router.go(AppRouter.workouts);
    await t.pumpAndSettle();
    expectNoOverflow(t);
    r.router.go(AppRouter.runSummary('a'));
    await t.pumpAndSettle();
    await t.scrollUntilVisible(find.byKey(const ValueKey('run-delete')), 200,
        scrollable: find
            .descendant(
                of: find.byType(ListView), matching: find.byType(Scrollable))
            .first);
    await r.scrollTo(find.byKey(const ValueKey('run-delete')));
    await r.tap('run-delete');
    expect(find.text('Delete ski day'), findsOneWidget);
    expect(find.text('Delete this ski day?'), findsOneWidget);
    expectNoOverflow(t);
  });

  testWidgets('the in-progress bar names a ride and a ski day', (t) async {
    final r = await _rig(t);
    final rec = r.container.read(runRecorderProvider.notifier);
    await rec.start(kind: ActivityKind.ride);
    r.router.go(AppRouter.home);
    await t.pumpAndSettle();
    expect(find.text('Ride in progress'), findsOneWidget);
    await t.runAsync(rec.discard);
    await t.pumpAndSettle();
    await rec.start(kind: ActivityKind.ski);
    await t.pumpAndSettle();
    expect(find.text('Ski day in progress'), findsOneWidget);
    expect(find.text('Run in progress'), findsNothing);
    await t.runAsync(rec.discard);
  });

  testWidgets('live discard button and dialog fit an SE at 1.3x, ski day',
      (t) async {
    final r = await _rig(t, size: iPhoneSeSize, textScale: 1.3);
    await r.container
        .read(runRecorderProvider.notifier)
        .start(kind: ActivityKind.ski);
    r.router.go(AppRouter.liveRun);
    await t.pumpAndSettle();
    await t.ensureVisible(find.byKey(const ValueKey('run-discard')));
    await t.pumpAndSettle();
    expect(find.text('Discard ski day'), findsOneWidget);
    await r.tap('run-discard');
    expect(find.text('Discard this ski day?'), findsOneWidget);
    expectNoOverflow(t);
    await t.runAsync(
        () => r.container.read(runRecorderProvider.notifier).discard());
  });

  testWidgets('unfinished-activity dialog fits an SE at 1.3x, ride', (t) async {
    final r = await _rig(t, size: iPhoneSeSize, textScale: 1.3);
    r.container
        .read(workoutTemplatesProvider.notifier)
        .add(Sport.winterSports, 'Powder day');
    await r.container
        .read(runRecorderProvider.notifier)
        .start(kind: ActivityKind.ride);
    await r.open();
    for (var i = 0; i < 6 && find.text('Powder day').evaluate().isEmpty; i++) {
      await t.drag(find.byType(ListView).last, const Offset(0, -300));
      await t.pumpAndSettle();
    }
    await r.scrollTo(startOf('Powder day'));
    await t.tap(startOf('Powder day'));
    await t.pumpAndSettle();
    expect(find.text('You have an unfinished ride'), findsOneWidget);
    expectNoOverflow(t);
    await t.tap(find.text('Discard and start'));
    await t.pumpAndSettle();
    expect(find.text('Discard this ride?'), findsOneWidget);
    expectNoOverflow(t);
    await t.runAsync(
        () => r.container.read(runRecorderProvider.notifier).discard());
  });

  testWidgets('the launch prompt names a restored ski day at 1.3x', (t) async {
    final start = _now.subtract(const Duration(hours: 1));
    await _rig(t, size: iPhoneSeSize, textScale: 1.3, prefsValues: {
      runInProgressKey: jsonEncode({
        'startedAt': start.toUtc().toIso8601String(),
        'templateId': null,
        'kind': 'ski',
        'phase': 'running',
        'points': [
          for (var i = 0; i <= 12; i++)
            [
              41.0 + i * 0.0009,
              69.0,
              null,
              5.0,
              start.add(Duration(seconds: 30 * i)).millisecondsSinceEpoch,
            ],
        ],
        'pauses': <Object>[],
      }),
    });
    expect(find.text('Unfinished ski day · 1.20 km'), findsOneWidget);
    expectNoOverflow(t);
    await t.tap(find.text('Discard'));
    await t.pumpAndSettle();
    expect(find.text('Discard this ski day?'), findsOneWidget);
    expectNoOverflow(t);
    await t.runAsync(() async {});
  });
}
