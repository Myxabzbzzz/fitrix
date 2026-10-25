import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitrix/core/session/session_providers.dart';
import 'package:fitrix/features/running/data/location_source.dart';
import 'package:fitrix/features/running/data/run_store.dart';
import 'package:fitrix/features/running/data/run_track.dart';
import 'package:fitrix/features/running/presentation/run_recorder.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';

import 'run_recorder_test.dart' show FakeLocationSource, Rig, rig, t0;

const _mPerDeg = 111319.49;

/// One fix [secs] after the start, [east]/[north] metres from the origin.
void _fix(Rig r, int secs, double east, double north, double? alt) {
  final at = t0.add(Duration(seconds: secs));
  r.clock.now = at;
  r.source.emit(RunPoint(
    lat: north / _mPerDeg,
    lng: east / _mPerDeg,
    alt: alt,
    accuracy: 5,
    at: at,
  ));
}

/// A day: a 60 s descent (100 m down at 6 m/s), a 200 s lift (100 m up at
/// 0.5 m/s, 2 m/s along), a second 60 s descent, 20 s standing. Returns the
/// seconds covered.
int _skiDay(Rig r) {
  var s = 0, e = 0.0, n = 0.0, a = 2000.0;
  _fix(r, s, e, n, a);
  for (var i = 0; i < 60; i++) {
    _fix(r, ++s, e += 6, n, a -= 100 / 60);
  }
  for (var i = 0; i < 200; i++) {
    _fix(r, ++s, e, n += 2, a += 0.5);
  }
  for (var i = 0; i < 60; i++) {
    _fix(r, ++s, e += 6, n, a -= 100 / 60);
  }
  for (var i = 0; i < 20; i++) {
    _fix(r, ++s, e, n, a);
  }
  return s;
}

void main() {
  test('a ride is saved as cycling with auto-stop duration', () async {
    final r = await rig();
    await r.recorder.start(kind: ActivityKind.ride);
    expect(r.session!.kind, ActivityKind.ride);
    // 100 s at 6 m/s, 60 s standing, 50 s at 6 m/s.
    var e = 0.0, s = 0;
    for (var i = 0; i <= 20; i++) {
      _fix(r, s, e, 0, null);
      s += 5;
      e += 30;
    }
    for (var i = 0; i < 12; i++) {
      _fix(r, s, e, 0, null);
      s += 5;
    }
    for (var i = 0; i < 10; i++) {
      e += 30;
      _fix(r, s, e, 0, null);
      s += 5;
    }
    final saved = await r.recorder.finish();
    await pumpEventQueue();

    expect(saved.sport, Sport.cycling);
    expect(saved.templateId, 'free_ride');
    expect(saved.name, 'Morning ride');
    expect(saved.duration.inSeconds, inInclusiveRange(135, 165));
    final d = r.container.read(runStoreProvider).all()[saved.id]!;
    expect(d.kind, ActivityKind.ride);
    expect(d.maxSpeed, closeTo(6, 1));
    expect(d.moving, saved.duration);
    expect(d.elapsed.inSeconds, greaterThan(200));
  });

  test('a ride says DistanceReached every 5 km, not KmReached', () async {
    final r = await rig();
    final events = <RunEvent>[];
    r.recorder.events.listen(events.add);
    await r.recorder.start(kind: ActivityKind.ride);
    // 20 m/s, a fix every 5 s: 6 km in 300 s.
    for (var i = 0; i <= 60; i++) {
      _fix(r, i * 5, i * 100.0, 0, null);
    }
    await pumpEventQueue();
    expect(events.whereType<KmReached>(), isEmpty);
    final d = events.whereType<DistanceReached>().single;
    expect(d.meters, 5000);
    expect(d.total.inSeconds, closeTo(250, 6));
    expect(d.lastSplitSpeed, closeTo(20, 1));
    expect(d.avgSpeed, closeTo(20, 1));
  });

  test('a ski day: duration without lift time, descents saved', () async {
    final r = await rig();
    final events = <RunEvent>[];
    r.recorder.events.listen(events.add);
    await r.recorder.start(kind: ActivityKind.ski);
    final secs = _skiDay(r);
    await pumpEventQueue();

    // The first descent is done once the lift shows; the last one is not.
    final done = events.whereType<SkiDescentDone>().toList();
    expect(done.map((e) => e.index), [1]);
    expect(done.single.vertical, closeTo(100, 25));
    expect(done.single.meters, closeTo(300, 40));
    expect(done.single.maxSpeed, closeTo(6, 1));

    final saved = await r.recorder.finish();
    await pumpEventQueue();
    expect(saved.sport, Sport.winterSports);
    expect(saved.templateId, 'free_ski');
    expect(saved.name, 'Ski day');
    final d = r.container.read(runStoreProvider).all()[saved.id]!;
    expect(d.kind, ActivityKind.ski);
    expect(d.ski!.descents, hasLength(2));
    expect(d.ski!.lifts, 1);
    expect(d.ski!.liftTime.inSeconds, greaterThan(150));
    expect(saved.duration, Duration(seconds: secs) - d.ski!.liftTime);
    expect(saved.duration.inSeconds, lessThan(secs - 150));
    expect(d.ski!.descents.last.routeTo, lessThan(d.route.length));
  });

  test('manual pauses are taken off a ski day', () async {
    final r = await rig();
    await r.recorder.start(kind: ActivityKind.ski);
    _fix(r, 0, 0, 0, 2000);
    _fix(r, 10, 60, 0, 1999);
    r.clock.now = t0.add(const Duration(seconds: 10));
    r.recorder.pause();
    r.clock.now = t0.add(const Duration(minutes: 10, seconds: 10));
    r.recorder.resume();
    _fix(r, 620, 120, 0, 1998);
    final saved = await r.recorder.finish();
    expect(saved.duration.inSeconds, closeTo(20, 1));
  });

  test('a recording from before this wave restores as a run', () async {
    SharedPreferences.setMockInitialValues({
      runInProgressKey: jsonEncode({
        'startedAt': t0.toUtc().toIso8601String(),
        'templateId': null,
        'phase': 'running',
        'points': [
          [0.0, 0.0, null, 5.0, t0.millisecondsSinceEpoch],
          [0.0, 0.0001, null, 5.0, t0.millisecondsSinceEpoch + 5000],
        ],
        'pauses': <Object>[],
      }),
    });
    final r = await rig(fresh: false);
    expect(r.session!.kind, ActivityKind.run);
    expect(r.session!.phase, RunPhase.paused);
  });

  test('a ski recording restores as a ski day and is saved under it', () async {
    final first = await rig();
    await first.recorder.start(kind: ActivityKind.ski);
    _fix(first, 0, 0, 0, 2000);
    _fix(first, 40, 240, 0, 1990);
    final raw =
        (await SharedPreferences.getInstance()).getString(runInProgressKey)!;
    expect(jsonDecode(raw)['kind'], 'ski');

    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      locationSourceProvider.overrideWithValue(first.source),
    ]);
    addTearDown(c.dispose);
    final restored = c.read(runRecorderProvider)!;
    expect(restored.kind, ActivityKind.ski);
    expect(restored.track.profile.kind, ActivityKind.ski);
    expect(restored.track.kept, hasLength(2));
  });

  test('a run never writes a kind', () async {
    final r = await rig();
    await r.recorder.start();
    final raw =
        (await SharedPreferences.getInstance()).getString(runInProgressKey)!;
    expect(jsonDecode(raw).containsKey('kind'), isFalse);
  });

  group('platform settings', () {
    test('Android notification text follows the kind', () {
      String title(ActivityKind k) =>
          (GeolocatorLocationSource.settingsForPlatform(TargetPlatform.android,
                  kind: k) as AndroidSettings)
              .foregroundNotificationConfig!
              .notificationTitle;
      expect(title(ActivityKind.run), 'Recording your run');
      expect(title(ActivityKind.ride), 'Recording your ride');
      expect(title(ActivityKind.ski), 'Recording your ski day');
    });

    test('only ski gets a distance filter', () {
      for (final p in [TargetPlatform.android, TargetPlatform.iOS]) {
        int filter(ActivityKind k) =>
            GeolocatorLocationSource.settingsForPlatform(p, kind: k)
                .distanceFilter;
        expect(filter(ActivityKind.run), 0);
        expect(filter(ActivityKind.ride), 0);
        expect(filter(ActivityKind.ski), inInclusiveRange(1, 5));
      }
    });
  });

  test('the recorder tells the source what it records', () async {
    final src = _KindSource();
    final r = await rig(source: src);
    await r.recorder.start(kind: ActivityKind.ride);
    expect(src.kinds, [ActivityKind.ride]);
  });
}

class _KindSource extends FakeLocationSource
    implements KindAwareLocationSource {
  final kinds = <ActivityKind>[];
  @override
  void useKind(ActivityKind kind) => kinds.add(kind);
}
