import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:fitrix/features/running/data/ski_math.dart';
import 'package:fitrix/features/running/data/run_track.dart';

/// One stretch of a synthetic day: [secs] long, altitude changing by [dAlt]
/// in total, moving [speed] m/s north.
class _Leg {
  const _Leg(this.secs, this.dAlt, this.speed);
  final int secs;
  final double dAlt, speed;
}

/// [noise]: uncorrelated +-noise per fix. [walk]: a seeded mean-reverting
/// random walk (correlated, like real GPS altitude drift) bounded by +-walk.
/// Legs with no speed get 1.5 m of position jitter (standing around).
List<RunPoint> _day(List<_Leg> legs,
    {double noise = 0,
    double walk = 0,
    int step = 2,
    double alt0 = 0,
    int seed = 7}) {
  final rnd = math.Random(seed);
  final t0 = DateTime.utc(2026, 1, 10, 9);
  final out = <RunPoint>[];
  var lat = 46.0, alt = alt0, t = 0, w = 0.0, jitter = 0.0;
  RunPoint at() {
    w = (w * 0.98 + (rnd.nextDouble() * 2 - 1) * walk * 0.15)
        .clamp(-walk, walk);
    final j = jitter / 111195;
    return RunPoint(
      lat: lat + (rnd.nextDouble() * 2 - 1) * j,
      lng: 8.0 +
          0.0002 * math.sin((lat - 46.0) * 111195 / 100) +
          (rnd.nextDouble() * 2 - 1) * j,
      alt: alt + w + (noise == 0 ? 0 : (rnd.nextDouble() * 2 - 1) * noise),
      accuracy: 5,
      at: t0.add(Duration(seconds: t)),
    );
  }

  out.add(at());
  for (final l in legs) {
    jitter = l.speed < 0.3 ? 1.5 : 0;
    for (var s = step; s <= l.secs; s += step) {
      lat += l.speed * step / 111195;
      alt += l.dAlt * step / l.secs;
      t += step;
      out.add(at());
    }
  }
  return out;
}

const _flat = _Leg(120, 0, 1);
const _lift = _Leg(300, 300, 4); // 1 m/s up, 4 m/s along
const _descent = _Leg(125, -300, 12);

void main() {
  group('segmentSki', () {
    test('a lift then a descent', () {
      final fixes = _day([_flat, _lift, _flat, _descent, _flat]);
      final day = skiDayFrom(fixes, List.generate(fixes.length, (i) => i));
      expect(day.lifts, 1);
      expect(day.descents, hasLength(1));
      expect(day.descents.single.vertical, closeTo(300, 5));
      expect(day.descents.single.maxSpeed, closeTo(12, 0.5));
      expect(day.descents.single.avgSpeed, closeTo(12, 0.7));
      expect(day.descents.single.meters, closeTo(1500, 60));
      expect(day.skiMeters, day.descents.single.meters);
      expect(day.verticalDown, day.descents.single.vertical);
      final kinds = segmentSki(fixes).map((s) => s.kind).toList();
      expect(kinds.where((k) => k == SkiSegmentKind.lift), hasLength(1));
      expect(kinds.where((k) => k == SkiSegmentKind.descent), hasLength(1));
    });

    test('noisy GPS altitude gives the same split', () {
      final fixes = _day([_flat, _lift, _flat, _descent, _flat], noise: 10);
      final day = skiDayFrom(fixes, List.generate(fixes.length, (i) => i));
      expect(day.lifts, 1);
      expect(day.descents, hasLength(1));
      expect(day.descents.single.vertical, closeTo(300, 25));
    });

    test('three laps are three descents and three lifts', () {
      for (final noise in [0.0, 10.0]) {
        final fixes = _day(
          [
            for (var i = 0; i < 3; i++) ...[_flat, _lift, _flat, _descent]
          ],
          noise: noise,
        );
        final day = skiDayFrom(fixes, List.generate(fixes.length, (i) => i));
        expect(day.descents, hasLength(3), reason: 'noise $noise');
        expect(day.lifts, 3, reason: 'noise $noise');
        expect(day.verticalDown, closeTo(900, 60));
        expect(day.maxSpeed, closeTo(12, 0.5));
        expect(day.avgDescentSpeed, closeTo(12, noise == 0 ? 1 : 2));
        expect(day.liftTime.inSeconds, closeTo(900, 120));
      }
    });

    test('a flat traverse or queue is other', () {
      final fixes = _day([const _Leg(900, 0, 3), const _Leg(600, 0, 0.1)]);
      final seg = segmentSki(fixes);
      expect(seg.every((s) => s.kind == SkiSegmentKind.other), isTrue);
      final day = skiDayFrom(fixes, List.generate(fixes.length, (i) => i));
      expect(day.descents, isEmpty);
      expect(day.lifts, 0);
      expect(day.maxSpeed, isNull);
      expect(day.avgDescentSpeed, isNull);
    });

    test('a short 20 m dip does not count', () {
      final fixes = _day([
        _flat,
        const _Leg(20, -20, 6),
        _flat,
        const _Leg(20, 20, 2),
        _flat,
      ]);
      final day = skiDayFrom(fixes, List.generate(fixes.length, (i) => i));
      expect(day.descents, isEmpty);
      expect(day.lifts, 0);
    });

    test('a slow climb or a fast climb is not a lift', () {
      // 300 m at 0.2 m/s (walking up) and at 20 m/s along (a road).
      for (final up in [const _Leg(1500, 300, 1), const _Leg(60, 300, 20)]) {
        final fixes = _day([_flat, up, _flat]);
        final day = skiDayFrom(fixes, List.generate(fixes.length, (i) => i));
        expect(day.lifts, 0, reason: '${up.secs}s');
        expect(day.descents, isEmpty);
      }
    });

    test('fixes without altitude segment to nothing', () {
      final fixes = [
        for (var i = 0; i < 20; i++)
          RunPoint(
              lat: 46,
              lng: 8,
              accuracy: 5,
              at: DateTime.utc(2026, 1, 1).add(Duration(seconds: i * 2))),
      ];
      expect(skiDayFrom(fixes, List.generate(20, (i) => i)).descents, isEmpty);
      expect(segmentSki(const []), isEmpty);
    });

    test('a 6 h day segments quickly', () {
      final legs = <_Leg>[];
      for (var i = 0; i < 24; i++) {
        legs.addAll(const [
          _Leg(300, 0, 0.2),
          _Leg(600, 300, 4),
          _Leg(120, 0, 1),
          _Leg(300, -300, 12),
        ]);
      }
      final fixes = _day(legs, noise: 10, step: 1);
      expect(fixes.length, greaterThan(21000));
      final sw = Stopwatch()..start();
      final day = skiDayFrom(fixes, List.generate(fixes.length, (i) => i));
      sw.stop();
      expect(day.descents, hasLength(24));
      expect(sw.elapsedMilliseconds, lessThan(10000));
    });
  });

  group('everyday ski days', () {
    SkiDay run(List<RunPoint> f) =>
        skiDayFrom(f, List.generate(f.length, (i) => i));
    const lap = [_flat, _lift, _flat, _descent];

    for (final q in [600, 1200]) {
      test('${q ~/ 60}-minute queues over 20 laps keep the lifts', () {
        for (final walk in [4.0, 9.0]) {
          final fixes = _day(
            [
              for (var i = 0; i < 20; i++) ...[_Leg(q, 0, 0), ...lap]
            ],
            walk: walk,
          );
          final day = run(fixes);
          expect(day.lifts, greaterThanOrEqualTo(19), reason: 'walk $walk');
          expect(day.lifts, lessThanOrEqualTo(20));
          // No phantom descents out of the queues.
          expect(day.descents.length, inInclusiveRange(19, 20));
          for (final d in day.descents) {
            expect(d.end.difference(d.start).inSeconds, lessThan(400));
            expect(d.vertical, closeTo(300, 30));
          }
        }
      });
    }

    test('a lift base above the run end with a 4-minute queue', () {
      for (final up in [10.0, 14.0]) {
        final fixes = _day(
          [
            for (var i = 0; i < 6; i++) ...[
              _Leg(10, up, 1.5),
              const _Leg(240, 0, 0),
              _lift,
              _flat,
              _Leg(125, -300 - up, 12),
            ]
          ],
          walk: 5,
        );
        final day = run(fixes);
        expect(day.lifts, 6, reason: 'up $up');
        expect(day.descents, hasLength(6), reason: 'up $up');
      }
    });

    for (final stop in [300, 600]) {
      test('a ${stop ~/ 60}-minute stop mid-run is one descent', () {
        final fixes = _day([
          _flat,
          _lift,
          _flat,
          const _Leg(60, -150, 12),
          _Leg(stop, 0, 0),
          const _Leg(60, -150, 12),
          _flat,
        ], walk: 5);
        final day = run(fixes);
        expect(day.descents, hasLength(1));
        expect(day.descents.single.avgSpeed, closeTo(12, 2));
        expect(day.descents.single.vertical, closeTo(300, 25));
        expect(day.lifts, 1);
      });
    }

    test('a 40-minute hut stop mid-run is not a 1 m/s run', () {
      final fixes = _day([
        _flat,
        _lift,
        _flat,
        const _Leg(60, -150, 12),
        const _Leg(2400, 0, 0),
        const _Leg(60, -150, 12),
        _flat,
      ], walk: 6);
      final day = run(fixes);
      expect(day.descents.length, inInclusiveRange(1, 2));
      for (final d in day.descents) {
        expect(d.avgSpeed, greaterThan(8));
      }
      expect(day.verticalDown, closeTo(300, 30));
    });

    test('altitude drifting 35 m during lunch is not a descent', () {
      final fixes = _day([
        ...lap,
        const _Leg(3600, 35, 0),
        ...lap.map((l) => l.dAlt == -300 ? const _Leg(125, -335, 12) : l),
      ], walk: 5);
      final day = run(fixes);
      expect(day.lifts, 2);
      expect(day.descents, hasLength(2));
      for (final d in day.descents) {
        expect(d.end.difference(d.start).inSeconds, lessThan(400));
      }
    });

    test('a slow fixed-grip chair and a tram are lifts', () {
      for (final l in [const _Leg(750, 300, 1.8), const _Leg(120, 300, 10)]) {
        final fixes = _day([_flat, l, _flat, _descent, _flat], walk: 9);
        final day = run(fixes);
        expect(day.lifts, 1, reason: '${l.secs}s');
        expect(day.descents, hasLength(1));
      }
    });

    test('standing around with drifting altitude gives no descent', () {
      final fixes = _day([const _Leg(1800, -40, 0)], walk: 6);
      expect(run(fixes).descents, isEmpty);
    });
  });

  group('route indices', () {
    test('simplifyRouteIndices matches simplifyRoute', () {
      final fixes = _day([
        for (var i = 0; i < 3; i++) ...[_lift, _descent]
      ]);
      final idx = simplifyRouteIndices(fixes, maxPoints: 40);
      final pts = simplifyRoute(fixes, maxPoints: 40);
      expect(idx.length, pts.length);
      expect([for (final i in idx) fixes[i]], pts);
      expect(idx.first, 0);
      expect(idx.last, fixes.length - 1);
      expect(simplifyRouteIndices(fixes, maxPoints: 5000),
          List.generate(fixes.length, (i) => i));
    });

    test('descent ranges point into the simplified route', () {
      final fixes = _day([
        for (var i = 0; i < 3; i++) ...[_flat, _lift, _flat, _descent]
      ]);
      final idx = simplifyRouteIndices(fixes, maxPoints: 30);
      final map = routeIndexMap(fixes.length, idx);
      expect(map, hasLength(fixes.length));
      final day = skiDayFrom(fixes, map);
      expect(day.descents, hasLength(3));
      var prevTo = -1;
      for (final d in day.descents) {
        expect(d.routeFrom, lessThan(d.routeTo));
        expect(d.routeFrom, greaterThanOrEqualTo(prevTo));
        expect(d.routeTo, lessThan(idx.length));
        prevTo = d.routeTo;
        // The route point sits near the descent's start in time.
        final p = fixes[idx[d.routeFrom]];
        expect(p.at.difference(d.start).inSeconds.abs(), lessThan(120));
      }
    });
  });

  group('SkiDay json', () {
    test('round trips', () {
      final fixes = _day([_flat, _lift, _flat, _descent, _flat]);
      final day = skiDayFrom(fixes, List.generate(fixes.length, (i) => i));
      final back = SkiDay.fromJson(day.toJson());
      expect(back.lifts, day.lifts);
      expect(back.liftTime, day.liftTime);
      expect(back.descents, hasLength(1));
      final a = back.descents.single, b = day.descents.single;
      expect(a.start, b.start);
      expect(a.end, b.end);
      expect(a.meters, b.meters);
      expect(a.vertical, b.vertical);
      expect(a.maxSpeed, b.maxSpeed);
      expect(a.avgSpeed, b.avgSpeed);
      expect(a.routeFrom, b.routeFrom);
      expect(a.routeTo, b.routeTo);
    });

    test('RunDetails carries ski only when set', () {
      RunDetails mk(SkiDay? ski) => RunDetails(
            startedAt: DateTime.utc(2026, 1, 10),
            moving: const Duration(hours: 3),
            elapsed: const Duration(hours: 5),
            pauses: 0,
            meters: 0,
            splits: const [],
            route: const [],
            kind: ActivityKind.ski,
            ski: ski,
          );
      expect(mk(null).toJson().containsKey('ski'), isFalse);
      final fixes = _day([_flat, _lift, _flat, _descent, _flat]);
      final day = skiDayFrom(fixes, List.generate(fixes.length, (i) => i));
      final json = mk(day).toJson();
      expect(json['ski'], isNotNull);
      final back = RunDetails.fromJson(json);
      expect(back.ski!.descents, hasLength(1));
      expect(back.ski!.lifts, 1);
      expect(RunDetails.fromJson(mk(null).toJson()).ski, isNull);
    });
  });
}
