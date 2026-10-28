import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitrix/features/running/presentation/screens/run_summary_screen.dart';
import 'package:fitrix/core/constants/app_constants.dart';
import 'package:fitrix/core/router/app_router.dart';
import 'package:fitrix/core/session/app_session.dart';
import 'package:fitrix/core/session/session_providers.dart';
import 'package:fitrix/core/time/today_provider.dart';
import 'package:fitrix/features/map/data/routing_service.dart';
import 'package:fitrix/features/running/data/location_source.dart';
import 'package:fitrix/features/running/data/run_store.dart';
import 'package:fitrix/features/running/data/run_track.dart';
import 'package:fitrix/features/running/data/ski_math.dart';
import 'package:fitrix/features/running/presentation/run_recorder.dart';
import 'package:fitrix/features/running/presentation/run_voice.dart';
import 'package:fitrix/features/running/presentation/screens/live_run_screen.dart';
import 'package:fitrix/features/running/presentation/widgets/run_map.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/features/workouts/presentation/providers/workouts_provider.dart';
import 'package:fitrix/main.dart';

import 'support/overflow.dart';

final _t0 = DateTime(2026, 12, 20, 10);
const _mPerDeg = 111319.49;

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

class _Source implements LocationSource {
  StreamController<RunPoint>? _c;
  void emit(RunPoint p) => _c!.add(p);
  @override
  Future<LocationAccess> ensureAccess() async => LocationAccess.granted;
  @override
  Future<bool> reducedAccuracy() async => false;
  @override
  Stream<RunPoint> start() =>
      (_c = StreamController<RunPoint>(sync: true)).stream;
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
  DateTime now = _t0;

  RunRecorder get recorder => container.read(runRecorderProvider.notifier);

  void fix(int sec, double eastM, double northM, [double? alt]) {
    now = _t0.add(Duration(seconds: sec));
    source.emit(RunPoint(
        lat: 41 + northM / _mPerDeg,
        lng: 69 + eastM / (_mPerDeg * cos(41 * pi / 180)),
        alt: alt,
        accuracy: 5,
        at: now));
  }

  Future<void> start(ActivityKind kind) async {
    await recorder.start(kind: kind);
    openLiveRun(router);
    await tester.pumpAndSettle();
  }

  Future<void> tick() => tester.pump(const Duration(seconds: 1));

  String text(String key) =>
      tester.widget<Text>(find.byKey(ValueKey(key))).data!;
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
  late _Rig rig;
  final container = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    appSessionProvider.overrideWithValue(session),
    clockProvider.overrideWithValue(() => rig.now),
    locationSourceProvider.overrideWithValue(source),
    speakerProvider.overrideWithValue(_SilentSpeaker()),
    mapTileProviderProvider.overrideWithValue(_BlankTiles()),
  ]);
  addTearDown(container.dispose);
  final router = AppRouter.create(session);
  rig = _Rig(tester, container, router, source);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: FitrixApp(router: router),
  ));
  await tester.pump();
  return rig;
}

/// Feeds a ski day through the recorder: [descent] of 60 s at 6 m/s losing
/// 100 m, [lift] climbing 0.5 m/s at 2 m/s.
class _Day {
  _Day(this.r);
  final _Rig r;
  int s = 0;
  double e = 0, n = 0, a = 2000;

  void descent() {
    for (var i = 0; i < 60; i++) {
      s++;
      e += 6;
      a -= 100 / 60;
      r.fix(s, e, n, a);
    }
  }

  void lift(int secs) {
    for (var i = 0; i < secs; i++) {
      s++;
      n += 2;
      a += 0.5;
      r.fix(s, e, n, a);
    }
  }

  void stop(int secs) {
    for (var i = 0; i < secs; i++) {
      s++;
      r.fix(s, e, n, a);
    }
  }
}

void _saveSummary(_Rig r, String id, Sport sport, RunDetails d) {
  r.container.read(workoutHistoryProvider.notifier).add(CompletedWorkout(
        id: id,
        templateId: 'x',
        name: 'Saved $id',
        sport: sport,
        startedAt: d.startedAt,
        finishedAt: d.startedAt.add(d.moving),
        exercises: const [],
      ));
  r.container.read(runsProvider.notifier).put(id, d);
}

List<List<double>> _route(int n) => [
      for (var i = 0; i < n; i++) [41 + i * 0.0005, 69 + i * 0.0004]
    ];

RunDetails _rideDetails(
        {bool indoor = false,
        double meters = 15000,
        List<RunSplit> splits = const [
          RunSplit(km: 5, meters: 5000, time: Duration(seconds: 600)),
          RunSplit(km: 10, meters: 5000, time: Duration(seconds: 1000)),
          RunSplit(km: 11, meters: 1000, time: Duration(seconds: 200)),
        ]}) =>
    RunDetails(
      startedAt: _t0,
      moving: const Duration(seconds: 3000),
      elapsed: const Duration(seconds: 3300),
      pauses: 1,
      meters: meters,
      elevationGain: 85,
      splits: splits,
      route: indoor ? const [] : _route(12),
      kind: ActivityKind.ride,
      maxSpeed: 12,
      elevationLoss: 70,
      indoor: indoor,
      avgPowerW: indoor ? 180 : null,
    );

SkiDescent _descent(int n, double meters, double vertical, int from, int to) =>
    SkiDescent(
      start: _t0.add(Duration(minutes: n * 10)),
      end: _t0.add(Duration(minutes: n * 10, seconds: 120 + n * 30)),
      meters: meters,
      vertical: vertical,
      maxSpeed: 10.0 + n,
      avgSpeed: 6,
      routeFrom: from,
      routeTo: to,
    );

RunDetails _skiDetails() => RunDetails(
      startedAt: _t0,
      moving: const Duration(seconds: 5400),
      elapsed: const Duration(seconds: 14400),
      pauses: 0,
      meters: 3600,
      splits: const [],
      route: _route(12),
      kind: ActivityKind.ski,
      ski: SkiDay(
        descents: [
          _descent(1, 1000, 200, 0, 3),
          _descent(2, 1200, 250, 3, 7),
          _descent(3, 1400, 300, 7, 11),
        ],
        lifts: 3,
        liftTime: const Duration(seconds: 3000),
      ),
    );

final _listScrollable = find
    .descendant(of: find.byType(ListView), matching: find.byType(Scrollable))
    .first;

void main() {
  group('live ride', () {
    testWidgets('shows speed, distance, moving time and average speed',
        (t) async {
      final r = await _rig(t);
      await r.start(ActivityKind.ride);
      for (var i = 0; i <= 20; i++) {
        r.fix(i, i * 10.0, 0);
      }
      await r.tick();
      expect(r.text('ride-speed'), matches(RegExp(r'^36\.\d$')));
      expect(find.text('Speed, km/h'), findsOneWidget);
      expect(r.text('run-distance'), '0.20');
      expect(r.text('run-time'), '0:20');
      expect(r.text('ride-avg-speed'), matches(RegExp(r'^36\.\d$')));
      expect(find.byKey(const ValueKey('run-pace')), findsNothing);
      expectNoOverflow(t);
    });

    testWidgets('speed drops to zero when no fix is kept for a while',
        (t) async {
      final r = await _rig(t);
      await r.start(ActivityKind.ride);
      for (var i = 0; i <= 10; i++) {
        r.fix(i, i * 10.0, 0);
      }
      r.now = _t0.add(const Duration(seconds: 40));
      await r.tick();
      expect(r.text('ride-speed'), '0.0');
    });

    for (final size in [iPhoneSeSize]) {
      testWidgets('fits an iPhone SE at 1.3x, also paused', (t) async {
        final r = await _rig(t, size: size, textScale: 1.3);
        await r.start(ActivityKind.ride);
        for (var i = 0; i <= 20; i++) {
          r.fix(i, i * 10.0, 0);
        }
        await r.tick();
        expectNoOverflow(t);
        r.recorder.pause();
        await r.tick();
        await t.drag(find.byType(SingleChildScrollView), const Offset(0, -600));
        await t.pumpAndSettle();
        expectNoOverflow(t);
      });
    }

    testWidgets('has the workout settings gear', (t) async {
      final r = await _rig(t);
      await r.start(ActivityKind.ride);
      await t.tap(find.byKey(const ValueKey('run-settings')));
      await t.pumpAndSettle();
      expect(find.text('Speaks the start, every 5 km and the finish.'),
          findsOneWidget);
    });
  });

  group('live ski', () {
    testWidgets('moving on the flat is "Moving", not "Descending"', (t) async {
      final r = await _rig(t);
      await r.start(ActivityKind.ski);
      // 5 m/s on the flat at 2000 m.
      for (var i = 0; i <= 20; i++) {
        r.fix(i, i * 5.0, 0, 2000);
      }
      await r.tick();
      expect(r.text('ski-state'), 'Moving');
      expect(r.text('ski-descents'), '0');
    });

    testWidgets('without altitude a fast skier is "Moving" too', (t) async {
      final r = await _rig(t);
      await r.start(ActivityKind.ski);
      for (var i = 0; i <= 20; i++) {
        r.fix(i, i * 5.0, 0);
      }
      await r.tick();
      expect(r.text('ski-state'), 'Moving');
    });

    testWidgets('shows state, descents, vertical, top speed, slope time',
        (t) async {
      final r = await _rig(t);
      await r.start(ActivityKind.ski);
      final d = _Day(r);
      r.fix(0, 0, 0, 2000);
      d.descent();
      await r.tick();
      expect(r.text('ski-state'), 'Descending');
      d.lift(100);
      await r.tick();
      expect(r.text('ski-state'), 'On a lift');
      d.stop(130);
      await r.tick();
      expect(r.text('ski-state'), 'Stopped');
      expect(r.text('ski-descents'), '1');
      expect(int.parse(r.text('ski-vertical')), inInclusiveRange(70, 100));
      expect(find.text('Vertical down, m'), findsOneWidget);
      // About 6 m/s = 21.6 km/h.
      expect(r.text('ski-max-speed'), matches(RegExp(r'^2[12]\.\d$')));
      // The day is 290 s: 100 of them on the lift, then 130 standing (over
      // 2 min, like a queue), so about the minute of the descent is left.
      expect(r.text('ski-slopes-time'), matches(RegExp(r'^1:[0-4]\d$')));
      expect(find.byKey(const ValueKey('run-pace')), findsNothing);
      expectNoOverflow(t);
    });

    testWidgets('fits an iPhone SE at 1.3x', (t) async {
      final r = await _rig(t, size: iPhoneSeSize, textScale: 1.3);
      await r.start(ActivityKind.ski);
      final d = _Day(r);
      r.fix(0, 0, 0, 2000);
      d.descent();
      await r.tick();
      expectNoOverflow(t);
      await t.drag(find.byType(SingleChildScrollView), const Offset(0, -600));
      await t.pumpAndSettle();
      expectNoOverflow(t);
    });
  });

  group('ride summary', () {
    for (final (label, meters, splits, rows) in [
      (
        '5.05 km',
        5050.0,
        const [
          RunSplit(km: 5, meters: 5000, time: Duration(seconds: 600)),
          RunSplit(km: 5, meters: 50, time: Duration(seconds: 6)),
        ],
        ['5', '0.05 km'],
      ),
      (
        '0.8 km',
        800.0,
        const [RunSplit(km: 0, meters: 800, time: Duration(seconds: 100))],
        ['0.80 km'],
      ),
    ]) {
      testWidgets('a $label ride names its last split by its length',
          (t) async {
        final r = await _rig(t, size: iPhoneSeSize, textScale: 1.3);
        _saveSummary(r, 'r1', Sport.cycling,
            _rideDetails(meters: meters, splits: splits));
        r.router.go(AppRouter.runSummary('r1'));
        await t.pumpAndSettle();
        await t.drag(find.byType(ListView), const Offset(0, -2000));
        await t.pumpAndSettle();
        for (final row in rows) {
          expect(find.text(row), findsOneWidget, reason: row);
        }
        expect(find.text('0'), findsNothing);
        expect(
            find.text('5'), rows.contains('5') ? findsOneWidget : findsNothing);
        expectNoOverflow(t);
      });
    }

    testWidgets('speeds, elevation, 5 km splits and the map', (t) async {
      final r = await _rig(t, size: iPhoneSeSize, textScale: 1.3);
      _saveSummary(r, 'r1', Sport.cycling, _rideDetails());
      r.router.go(AppRouter.runSummary('r1'));
      await t.pumpAndSettle();
      expect(find.byType(RunMap), findsOneWidget);
      expect(find.text('18.0'), findsOneWidget); // average, km/h
      expect(find.text('43.2'), findsOneWidget); // max, km/h
      expect(find.text('Avg speed, km/h'), findsOneWidget);
      expect(find.text('Max speed, km/h'), findsOneWidget);
      expect(find.text('15.00'), findsOneWidget);
      expect(find.text('50:00'), findsOneWidget);
      expect(find.text('85 m'), findsOneWidget);
      expect(find.text('30.0 km/h'), findsOneWidget); // 5 km in 10:00
      expect(find.text('18.0 km/h'), findsWidgets);
      expect(find.text('1.00 km'), findsOneWidget); // partial split
      expectNoOverflow(t);
      await t.drag(find.byType(ListView), const Offset(0, -2000));
      await t.pumpAndSettle();
      expectNoOverflow(t);
    });

    testWidgets('an indoor ride has no map; unknown distance is dashes',
        (t) async {
      final r = await _rig(t, size: iPhoneSeSize, textScale: 1.3);
      _saveSummary(
          r, 'r2', Sport.cycling, _rideDetails(indoor: true, meters: 0));
      r.router.go(AppRouter.runSummary('r2'));
      await t.pumpAndSettle();
      expect(find.byType(RunMap), findsNothing);
      expect(find.text('--'), findsWidgets);
      expect(find.text('180'), findsOneWidget);
      expect(find.text('Avg power, W'), findsOneWidget);
      expect(find.text('Avg speed, km/h'), findsNothing);
      expectNoOverflow(t);
    });

    testWidgets('an indoor ride with a distance shows it and the speed',
        (t) async {
      final r = await _rig(t);
      _saveSummary(
          r, 'r3', Sport.cycling, _rideDetails(indoor: true, meters: 30000));
      r.router.go(AppRouter.runSummary('r3'));
      await t.pumpAndSettle();
      expect(find.text('30.00'), findsOneWidget);
      expect(find.text('36.0'), findsOneWidget);
    });

    testWidgets('rating a just-finished ride keeps the ride fields', (t) async {
      final r = await _rig(t);
      _saveSummary(r, 'r4', Sport.cycling, _rideDetails());
      r.router.go(AppRouter.runSummary('r4', justFinished: true));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const ValueKey('runRpe-7')));
      await t.pump();
      await t.tap(find.byKey(const ValueKey('run-save')));
      await t.pumpAndSettle();
      final d = r.container.read(runsProvider)['r4']!;
      expect(d.rpe, 7);
      expect(d.kind, ActivityKind.ride);
      expect(d.maxSpeed, 12);
      expect(d.elevationLoss, 70);
      // The saved ride stays on screen; back goes to Cycling.
      expect(find.byKey(const ValueKey('run-save')), findsNothing);
      await t.tap(find.byKey(const ValueKey('run-close')));
      await t.pumpAndSettle();
      expect(r.router.routerDelegate.currentConfiguration.uri.path,
          AppRouter.sportWorkouts(Sport.cycling));
    });
  });

  group('back gesture after Save', () {
    testWidgets('a back pop from the saved summary lands on the sport screen',
        (t) async {
      final r = await _rig(t);
      _saveSummary(r, 'r5', Sport.cycling, _rideDetails());
      r.router.go(AppRouter.home);
      await t.pumpAndSettle();
      r.router.push(AppRouter.runSummary('r5', justFinished: true));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const ValueKey('run-save')));
      await t.pumpAndSettle();

      // The iOS edge-swipe is only live while the route can be popped.
      final route = ModalRoute.of(t.element(find.byType(RunSummaryScreen)))!;
      expect(route.popGestureEnabled, isTrue);

      // What the iOS edge-swipe and Android back do.
      await Navigator.of(t.element(find.byType(RunSummaryScreen))).maybePop();
      await t.pumpAndSettle();

      expect(r.router.routerDelegate.currentConfiguration.uri.path,
          AppRouter.sportWorkouts(Sport.cycling));
    });
  });

  group('ski summary', () {
    testWidgets('day totals and the descents list', (t) async {
      final r = await _rig(t, size: iPhoneSeSize, textScale: 1.3);
      _saveSummary(r, 's1', Sport.winterSports, _skiDetails());
      r.router.go(AppRouter.runSummary('s1'));
      await t.pumpAndSettle();
      expect(find.byType(RunMap), findsOneWidget);
      expect(find.text('Descents'), findsWidgets);
      expect(find.text('3'), findsWidgets); // descents, lifts
      expect(find.text('3.60'), findsOneWidget); // ski km
      expect(find.text('750'), findsOneWidget); // vertical down
      expect(find.text('46.8'), findsOneWidget); // top speed 13 m/s
      expect(find.text('1:30:00'), findsOneWidget); // time on slopes
      await t.scrollUntilVisible(find.text('Descent 3'), 200,
          scrollable: _listScrollable);
      expect(find.text('Descent 1'), findsOneWidget);
      expect(find.text('Descent 2'), findsOneWidget);
      expectNoOverflow(t);
    });

    testWidgets('tapping a descent shows its stats and highlights it',
        (t) async {
      final r = await _rig(t, size: iPhoneSeSize, textScale: 1.3);
      _saveSummary(r, 's2', Sport.winterSports, _skiDetails());
      r.router.go(AppRouter.runSummary('s2'));
      await t.pumpAndSettle();
      expect(t.widget<RunMap>(find.byType(RunMap)).selected, isNull);
      await t.ensureVisible(find.text('Descent 2'));
      await t.pumpAndSettle();
      await t.tap(find.text('Descent 2'));
      await t.pumpAndSettle();
      expect(t.widget<RunMap>(find.byType(RunMap)).selected, 1);
      expect(find.text('Vertical drop, m'), findsOneWidget);
      expect(find.text('250'), findsWidgets);
      expect(find.text('Duration'), findsOneWidget);
      expect(find.text('3:00'), findsWidgets);
      expectNoOverflow(t);
      await t.ensureVisible(find.text('Descent 3'));
      await t.pumpAndSettle();
      await t.tap(find.text('Descent 3'));
      await t.pumpAndSettle();
      expect(t.widget<RunMap>(find.byType(RunMap)).selected, 2);
      await t.ensureVisible(find.text('Descent 3'));
      await t.pumpAndSettle();
      await t.tap(find.text('Descent 3'));
      await t.pumpAndSettle();
      expect(t.widget<RunMap>(find.byType(RunMap)).selected, isNull);
    });
  });
}
