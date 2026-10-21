import 'dart:async';

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitrix/core/constants/app_constants.dart';
import 'package:fitrix/core/router/app_router.dart';
import 'package:fitrix/core/session/app_session.dart';
import 'package:fitrix/core/session/session_providers.dart';
import 'package:fitrix/core/time/today_provider.dart';
import 'package:fitrix/features/map/data/routing_service.dart';
import 'package:fitrix/features/plan/data/week_plan.dart';
import 'package:fitrix/features/plan/presentation/providers/week_plan_provider.dart';
import 'package:fitrix/features/running/data/location_source.dart';
import 'package:fitrix/features/running/data/run_store.dart';
import 'package:fitrix/features/running/data/run_track.dart';
import 'package:fitrix/features/running/presentation/run_recorder.dart';
import 'package:fitrix/features/running/presentation/run_voice.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/features/workouts/presentation/providers/workouts_provider.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';
import 'package:fitrix/main.dart';

import 'support/overflow.dart';

final _now = DateTime(2026, 10, 20, 15);

/// 1x1 transparent PNG, so no test touches the network.
final Uint8List _blankPng = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==');

class _BlankTiles extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      MemoryImage(_blankPng);
}

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

class _FakeSource implements LocationSource {
  _FakeSource(this.access);
  final LocationAccess access;
  int starts = 0;
  StreamController<RunPoint>? _c;

  @override
  Future<LocationAccess> ensureAccess() async => access;

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
  final _FakeSource source;

  RunSession? get session => container.read(runRecorderProvider);
  String get location =>
      router.routerDelegate.currentConfiguration.last.matchedLocation;

  Future<void> hold(Duration d) async {
    final g = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey('run-finish'))));
    await tester.pump();
    await tester.pump(d);
    await g.up();
    await settle(tester);
  }
}

/// Lets the futures that complete outside the test's fake clock (a
/// cancelled stream, say) finish, then settles the frames.
Future<void> settle(WidgetTester tester) async {
  await tester
      .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
  await tester.pumpAndSettle();
}

Future<_Rig> _rig(
  WidgetTester tester, {
  LocationAccess access = LocationAccess.granted,
  Size size = const Size(390, 844),
  double textScale = 1,
  String language = 'en',
  Map<String, Object> prefsValues = const {},
  List<Override> Function(SharedPreferences prefs, LocationSource source)?
      overrides,
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
  final source = _FakeSource(access);
  final container = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    appSessionProvider.overrideWithValue(session),
    clockProvider.overrideWithValue(() => _now),
    locationSourceProvider.overrideWithValue(source),
    speakerProvider.overrideWithValue(_SilentSpeaker()),
    mapTileProviderProvider.overrideWithValue(_BlankTiles()),
    ...?overrides?.call(prefs, source),
  ]);
  addTearDown(container.dispose);
  final router = AppRouter.create(session);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: FitrixApp(router: router),
  ));
  await tester.pump();
  return _Rig(tester, container, router, source);
}

WorkoutTemplate _addTemplate(_Rig r, String name) {
  r.container.read(workoutTemplatesProvider.notifier).add(Sport.running, name);
  return r.container
      .read(workoutTemplatesProvider)
      .lastWhere((t) => t.name == name);
}

Future<void> _openRunningList(_Rig r) async {
  r.router.go(AppRouter.sportWorkouts(Sport.running));
  await r.tester.pumpAndSettle();
}

Future<void> _tapStart(_Rig r, String name) async {
  final card = find
      .ancestor(of: find.text(name), matching: find.byType(Dismissible))
      .first;
  await r.tester
      .tap(find.descendant(of: card, matching: find.text('Start')).first);
  await r.tester.pumpAndSettle();
}

Future<void> _startAndFinish(_Rig r, String name) async {
  _addTemplate(r, name);
  await _openRunningList(r);
  await _tapStart(r, name);
  await r.hold(const Duration(milliseconds: 1100));
}

void main() {
  testWidgets('Start on a running template opens the live run', (t) async {
    final r = await _rig(t);
    final tpl = _addTemplate(r, 'Easy 5K');
    await _openRunningList(r);
    await _tapStart(r, 'Easy 5K');

    expect(r.location, AppRouter.liveRun);
    expect(r.session!.phase, RunPhase.running);
    expect(r.session!.template!.id, tpl.id);
    expect(find.text('Easy 5K'), findsOneWidget);
    expect(r.container.read(activeWorkoutProvider), isNull);
  });

  testWidgets('denied access: snack with a Settings hint, no navigation',
      (t) async {
    final r = await _rig(t, access: LocationAccess.denied);
    _addTemplate(r, 'Easy 5K');
    await _openRunningList(r);
    await _tapStart(r, 'Easy 5K');

    expect(r.location, isNot(AppRouter.liveRun));
    expect(r.session, isNull);
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('a short press on Finish does nothing; a 1 s hold finishes',
      (t) async {
    final r = await _rig(t);
    _addTemplate(r, 'Easy 5K');
    await _openRunningList(r);
    await _tapStart(r, 'Easy 5K');

    await r.hold(const Duration(milliseconds: 400));
    expect(r.session, isNotNull);
    expect(r.location, AppRouter.liveRun);
    expect(r.container.read(workoutHistoryProvider), isEmpty);

    await r.hold(const Duration(milliseconds: 1100));
    expect(r.session, isNull);
    expect(r.container.read(workoutHistoryProvider), hasLength(1));
    final id = r.container.read(workoutHistoryProvider).single.id;
    expect(r.location, AppRouter.runSummary(id));
    expect(find.byKey(const ValueKey('run-save')), findsOneWidget);
  });

  testWidgets('a 1 s drag that starts on Finish does not finish', (t) async {
    final r = await _rig(t);
    _addTemplate(r, 'Easy 5K');
    await _openRunningList(r);
    await _tapStart(r, 'Easy 5K');

    final g = await t.startGesture(
        t.getCenter(find.byKey(const ValueKey('run-finish'))));
    await t.pump();
    // Sliding up, as in a pocket or a scroll: 4 px every 100 ms.
    for (var i = 0; i < 12; i++) {
      await g.moveBy(const Offset(0, -4));
      await t.pump(const Duration(milliseconds: 100));
    }
    await g.up();
    await settle(t);

    expect(r.session, isNotNull);
    expect(r.location, AppRouter.liveRun);
    expect(r.container.read(workoutHistoryProvider), isEmpty);
  });

  testWidgets('a still hold finishes exactly once', (t) async {
    final r = await _rig(t);
    _addTemplate(r, 'Easy 5K');
    await _openRunningList(r);
    await _tapStart(r, 'Easy 5K');

    await r.hold(const Duration(seconds: 3));
    expect(r.session, isNull);
    expect(r.container.read(workoutHistoryProvider), hasLength(1));
    expect(r.container.read(runsProvider), hasLength(1));
  });

  testWidgets('a failing finish shows a snack and the screen stays usable',
      (t) async {
    final r = await _rig(t,
        overrides: (prefs, source) => [
              runRecorderProvider.overrideWith((ref) => RunRecorder(
                    source: source,
                    prefs: prefs,
                    saveWorkout: (_) => throw Exception('disk full'),
                    saveDetails: (_, __) {},
                    templateById: (_) => null,
                    l10n: () => lookupAppLocalizations(const Locale('en')),
                    now: () => _now,
                  )),
            ]);
    _addTemplate(r, 'Easy 5K');
    await _openRunningList(r);
    await _tapStart(r, 'Easy 5K');

    await r.hold(const Duration(milliseconds: 1100));
    expect(find.text('Couldn’t finish the run. Try again.'), findsOneWidget);
    expect(r.session, isNotNull);
    expect(r.location, AppRouter.liveRun);
    // Not stuck: Pause works and Finish can be held again.
    await t.tap(find.byKey(const ValueKey('run-pause')));
    await t.pump();
    expect(r.session!.phase, RunPhase.paused);
    await r.hold(const Duration(milliseconds: 1100));
    expect(find.text('Couldn’t finish the run. Try again.'), findsOneWidget);
    expect(r.location, AppRouter.liveRun);
  });

  testWidgets('Discard asks first; cancelling keeps the run', (t) async {
    final r = await _rig(t);
    _addTemplate(r, 'Easy 5K');
    await _openRunningList(r);
    await _tapStart(r, 'Easy 5K');

    await t.tap(find.byKey(const ValueKey('run-discard')));
    await t.pumpAndSettle();
    expect(find.text('Discard this run?'), findsOneWidget);
    await t.tap(find.text('Cancel'));
    await t.pumpAndSettle();
    expect(r.session, isNotNull);
    expect(r.location, AppRouter.liveRun);

    await t.tap(find.byKey(const ValueKey('run-discard')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('run-discard-confirm')));
    await settle(t);
    expect(r.session, isNull);
    expect(r.location, isNot(AppRouter.liveRun));
    expect(r.container.read(workoutHistoryProvider), isEmpty);
  });

  testWidgets('Pause and Resume switch the phase', (t) async {
    final r = await _rig(t);
    _addTemplate(r, 'Easy 5K');
    await _openRunningList(r);
    await _tapStart(r, 'Easy 5K');

    await t.tap(find.byKey(const ValueKey('run-pause')));
    await t.pump();
    expect(r.session!.phase, RunPhase.paused);
    await t.tap(find.byKey(const ValueKey('run-pause')));
    await t.pump();
    expect(r.session!.phase, RunPhase.running);
  });

  testWidgets('Save with RPE 7 rates the workout and the run; plan is done',
      (t) async {
    final r = await _rig(t);
    final tpl = _addTemplate(r, 'Easy 5K');
    await r.container.read(weekPlanProvider.notifier).add(PlannedSession(
          id: 'p1',
          day: DateTime(2026, 10, 20),
          sport: Sport.running,
          templateId: tpl.id,
          title: 'Easy 5K',
          minutes: 30,
          intensity: Intensity.easy,
        ));
    await _openRunningList(r);
    await _tapStart(r, 'Easy 5K');
    await r.hold(const Duration(milliseconds: 1100));

    final id = r.container.read(workoutHistoryProvider).single.id;
    await t.tap(find.byKey(const ValueKey('runRpe-7')));
    await t.pump();
    await t.tap(find.byKey(const ValueKey('run-save')));
    await t.pumpAndSettle();

    final w = r.container.read(workoutHistoryProvider).single;
    expect(w.sessionRpe, 7);
    expect(r.container.read(runsProvider)[id]!.rpe, 7);
    expect(
        statusOf(r.container.read(weekPlanProvider).single,
            r.container.read(workoutHistoryProvider), _now),
        SessionStatus.done);
    expect(r.location, isNot(startsWith('/run/')));
  });

  testWidgets('leaving the summary without Save keeps the run', (t) async {
    final r = await _rig(t);
    await _startAndFinish(r, 'Easy 5K');
    r.router.go(AppRouter.home);
    await t.pumpAndSettle();
    expect(r.container.read(workoutHistoryProvider), hasLength(1));
    expect(r.container.read(runsProvider), hasLength(1));
  });

  testWidgets('a saved run opens with Delete, which asks first', (t) async {
    final r = await _rig(t);
    await _startAndFinish(r, 'Easy 5K');
    final id = r.container.read(workoutHistoryProvider).single.id;
    r.router.go(AppRouter.home);
    await t.pumpAndSettle();
    r.router.push(AppRouter.runSummary(id));
    await t.pumpAndSettle();

    expect(find.byKey(const ValueKey('run-save')), findsNothing);
    await t.tap(find.byKey(const ValueKey('run-delete')));
    await t.pumpAndSettle();
    await t.tap(find.text('Cancel'));
    await t.pumpAndSettle();
    expect(r.container.read(workoutHistoryProvider), hasLength(1));

    await t.tap(find.byKey(const ValueKey('run-delete')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('run-delete-confirm')));
    await t.pumpAndSettle();
    expect(r.container.read(workoutHistoryProvider), isEmpty);
    expect(r.container.read(runsProvider), isEmpty);
    expect(r.location, isNot(AppRouter.runSummary(id)));
  });

  testWidgets('the same plan already running just reopens the live run',
      (t) async {
    final r = await _rig(t);
    _addTemplate(r, 'Easy 5K');
    await _openRunningList(r);
    await _tapStart(r, 'Easy 5K');
    r.router.go(AppRouter.sportWorkouts(Sport.running));
    await t.pumpAndSettle();
    await _tapStart(r, 'Easy 5K');
    expect(r.location, AppRouter.liveRun);
    expect(r.source.starts, 1);
  });

  testWidgets('another plan while a run exists: Resume opens the old run',
      (t) async {
    final r = await _rig(t);
    final a = _addTemplate(r, 'Easy 5K');
    _addTemplate(r, 'Tempo');
    await _openRunningList(r);
    await _tapStart(r, 'Easy 5K');
    r.router.go(AppRouter.sportWorkouts(Sport.running));
    await t.pumpAndSettle();
    await _tapStart(r, 'Tempo');

    expect(find.text('You have an unfinished run'), findsOneWidget);
    await t.tap(find.text('Resume'));
    await t.pumpAndSettle();
    expect(r.location, AppRouter.liveRun);
    expect(r.session!.template!.id, a.id);
    expect(r.source.starts, 1);
  });

  testWidgets('another plan: Discard and start confirms, then starts it',
      (t) async {
    final r = await _rig(t);
    _addTemplate(r, 'Easy 5K');
    final b = _addTemplate(r, 'Tempo');
    await _openRunningList(r);
    await _tapStart(r, 'Easy 5K');
    r.router.go(AppRouter.sportWorkouts(Sport.running));
    await t.pumpAndSettle();
    await _tapStart(r, 'Tempo');

    await t.tap(find.text('Discard and start'));
    await t.pumpAndSettle();
    expect(find.text('Discard this run?'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('run-discard-confirm')));
    await settle(t);
    expect(r.session!.template!.id, b.id);
    expect(r.location, AppRouter.liveRun);
    expect(r.source.starts, 2);
  });

  group('SE 375x667, text 1.3, ru', () {
    testWidgets('summary with a route, splits, elevation and rating',
        (t) async {
      final r =
          await _rig(t, size: iPhoneSeSize, textScale: 1.3, language: 'ru');
      final started = DateTime(2026, 10, 20, 7);
      r.container.read(workoutHistoryProvider.notifier).add(CompletedWorkout(
            id: 'w1',
            templateId: 'free_run',
            name: 'Утренняя пробежка',
            sport: Sport.running,
            startedAt: started,
            finishedAt: started.add(const Duration(hours: 1, minutes: 5)),
            exercises: const [],
            sessionRpe: 7,
          ));
      r.container.read(runsProvider.notifier).put(
            'w1',
            RunDetails(
              startedAt: started,
              moving: const Duration(hours: 1, minutes: 5, seconds: 9),
              elapsed: const Duration(hours: 1, minutes: 12),
              pauses: 12,
              meters: 10420,
              elevationGain: 1234,
              splits: [
                for (var k = 1; k <= 10; k++)
                  RunSplit(
                      km: k,
                      meters: 1000,
                      time: const Duration(minutes: 6, seconds: 20)),
                const RunSplit(
                    km: 11,
                    meters: 420,
                    time: Duration(minutes: 2, seconds: 40)),
              ],
              route: const [
                [41.3100, 69.2700],
                [41.3120, 69.2740],
                [41.3150, 69.2760],
              ],
              rpe: 7,
              templateId: 'free_run',
            ),
          );
      r.router.push(AppRouter.runSummary('w1'));
      await t.pumpAndSettle();
      expect(find.byType(FlutterMap), findsOneWidget);
      expect(find.textContaining('OpenStreetMap'), findsOneWidget);
      expect(find.text('10,42'), findsOneWidget);
      expectNoOverflow(t);
      await t.drag(find.byType(ListView), const Offset(0, -2000));
      await t.pumpAndSettle();
      expectNoOverflow(t);
    });

    testWidgets('live run, running and paused', (t) async {
      final r =
          await _rig(t, size: iPhoneSeSize, textScale: 1.3, language: 'ru');
      _addTemplate(r, 'Лёгкая пробежка');
      await _openRunningList(r);
      await t.ensureVisible(find.text('Начать').first);
      await t.pumpAndSettle();
      await r.tester.tap(find.text('Начать').first);
      await t.pumpAndSettle();
      expect(r.location, AppRouter.liveRun);
      expectNoOverflow(t);
      await t.tap(find.byKey(const ValueKey('run-pause')));
      await t.pumpAndSettle();
      expectNoOverflow(t);
    });

    testWidgets('summary, after finish and opened later', (t) async {
      final r =
          await _rig(t, size: iPhoneSeSize, textScale: 1.3, language: 'ru');
      _addTemplate(r, 'Лёгкая пробежка');
      await _openRunningList(r);
      await t.ensureVisible(find.text('Начать').first);
      await t.pumpAndSettle();
      await r.tester.tap(find.text('Начать').first);
      await t.pumpAndSettle();
      await r.hold(const Duration(milliseconds: 1100));
      expect(r.location, startsWith('/run/'));
      expectNoOverflow(t);
      final id = r.container.read(workoutHistoryProvider).single.id;
      r.router.go(AppRouter.home);
      await t.pumpAndSettle();
      r.router.push(AppRouter.runSummary(id));
      await t.pumpAndSettle();
      expectNoOverflow(t);
    });
  });
}
