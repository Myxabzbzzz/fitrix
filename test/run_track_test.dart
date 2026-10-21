import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:fitrix/features/running/data/run_track.dart';

final t0 = DateTime.utc(2026, 10, 1, 7);

/// A fix on the equator-ish line heading east: [meters] from the origin.
RunPoint eastFix(double meters, int sec,
        {double accuracy = 5, double? alt, double lat = 0}) =>
    RunPoint(
      lat: lat,
      lng: meters / 111319.49,
      alt: alt,
      accuracy: accuracy,
      at: t0.add(Duration(seconds: sec)),
    );

/// Fixes every 5 s at 10 km/h (~13.89 m per fix) up to [meters].
RunTrack run(double meters, {RunTrack? from, int startSec = 0}) {
  var track = from ?? RunTrack(startedAt: t0);
  const step = 10 / 3.6 * 5;
  for (var i = 0; i * step <= meters; i++) {
    track = track.add(eastFix(i * step, startSec + i * 5));
  }
  return track;
}

void main() {
  group('RunTrack', () {
    test('1 km at 10 km/h is about 1000 m and one split', () {
      final track = run(1000);
      expect(track.meters, closeTo(1000, 10));
      expect(track.splits, hasLength(1));
      expect(track.splits.first.km, 1);
    });

    test('standing still with GPS jitter adds almost no distance', () {
      final rnd = Random(7);
      var track = RunTrack(startedAt: t0);
      for (var i = 0; i < 30; i++) {
        final r = 5 + rnd.nextDouble() * 10;
        final a = rnd.nextDouble() * 2 * pi;
        track = track.add(RunPoint(
          lat: r * sin(a) / 111195,
          lng: r * cos(a) / 111195,
          accuracy: 10,
          at: t0.add(Duration(seconds: i)),
        ));
      }
      expect(track.meters, lessThan(15));
    });

    test('drops a fix 300 m off and a fix with accuracy 40 m', () {
      var track = RunTrack(startedAt: t0)
          .add(eastFix(0, 0))
          .add(eastFix(14, 5))
          .add(eastFix(314, 10)) // 300 m in 5 s
          .add(eastFix(28, 15, accuracy: 40))
          .add(eastFix(28, 20));
      expect(track.kept, hasLength(3));
      expect(track.meters, closeTo(28, 1));
    });

    test('a pause is not moving time and its gap is not distance', () {
      var track = run(140); // 11 fixes, last at 50 s
      final before = track.meters;
      track = track.pause(t0.add(const Duration(seconds: 50)));
      expect(track.paused, isTrue);
      expect(track.movingTime(t0.add(const Duration(minutes: 1))),
          const Duration(seconds: 50));
      track = track.resume(t0.add(const Duration(seconds: 170)));
      expect(track.paused, isFalse);
      // Resumed 500 m away: not counted.
      track = track.add(eastFix(640, 175)).add(eastFix(654, 180));
      expect(track.meters, closeTo(before + 14, 1.5));
      expect(track.movingTime(t0.add(const Duration(seconds: 180))),
          const Duration(seconds: 60));
    });

    test('2.4 km gives splits 1, 2 and a partial 400 m summing to moving time',
        () {
      final track = run(2400);
      final splits = track.splits;
      expect(splits.map((s) => s.km), [1, 2, 3]);
      expect(splits[0].meters, 1000);
      expect(splits[1].meters, 1000);
      expect(splits[2].meters, closeTo(track.meters - 2000, 0.01));
      expect(splits[2].meters, lessThan(1000));
      final total = splits.fold(Duration.zero, (a, s) => a + s.time);
      final last = track.kept.last.at;
      expect(
          (total - track.movingTime(last)).inMilliseconds.abs(), lessThan(2));
      expect(splits[0].time.inSeconds, closeTo(360, 8));
    });

    test('elevation gain is null when under 80% of points have altitude', () {
      var track = RunTrack(startedAt: t0);
      for (var i = 0; i < 20; i++) {
        track = track.add(eastFix(i * 14, i * 5, alt: i.isEven ? 100 : null));
      }
      expect(track.elevationGain, isNull);
    });

    test('elevation gain ignores +/-2 m noise and counts real climbs', () {
      var noisy = RunTrack(startedAt: t0);
      for (var i = 0; i < 20; i++) {
        noisy =
            noisy.add(eastFix(i * 14, i * 5, alt: 100 + (i.isEven ? 2 : 0)));
      }
      expect(noisy.elevationGain, 0);

      var climb = RunTrack(startedAt: t0);
      for (var i = 0; i < 20; i++) {
        climb = climb.add(eastFix(i * 14, i * 5, alt: 100.0 + i * 2));
      }
      expect(climb.elevationGain, closeTo(38, 4));
    });

    test('add does not change the track it was called on', () {
      final a = run(100);
      final n = a.kept.length;
      final b = a.add(eastFix(120, 200));
      expect(a.kept, hasLength(n));
      expect(b.kept, hasLength(n + 1));
      final c = a.add(eastFix(130, 201));
      expect(b.kept.last.lng, isNot(c.kept.last.lng));
    });
  });

  group('simplifyRoute', () {
    test('10,000 points shrink to at most 2000, ends kept', () {
      final rnd = Random(3);
      final pts = [
        for (var i = 0; i < 10000; i++)
          RunPoint(
            lat: 0.0005 * sin(i / 300) + rnd.nextDouble() * 1e-5,
            lng: i * 1e-5,
            accuracy: 5,
            at: t0.add(Duration(seconds: i)),
          ),
      ];
      final out = simplifyRoute(pts);
      expect(out.length, lessThanOrEqualTo(2000));
      expect(out.first, same(pts.first));
      expect(out.last, same(pts.last));
    });

    test('short routes are returned unchanged', () {
      final pts = [eastFix(0, 0), eastFix(10, 1)];
      expect(simplifyRoute(pts), pts);
    });
  });

  test('paceSecPerKm', () {
    expect(paceSecPerKm(40, const Duration(seconds: 20)), isNull);
    expect(paceSecPerKm(1000, const Duration(minutes: 6)), 360);
    expect(paceSecPerKm(5000, const Duration(minutes: 25)), 300);
  });

  group('RunDetails', () {
    RunDetails sample(int n) => RunDetails(
          startedAt: t0,
          moving: const Duration(minutes: 30),
          elapsed: const Duration(minutes: 32),
          pauses: 1,
          meters: 5000.4,
          elevationGain: 12,
          splits: [
            const RunSplit(km: 1, meters: 1000, time: Duration(minutes: 6)),
            const RunSplit(km: 2, meters: 412.5, time: Duration(seconds: 150)),
          ],
          route: [
            for (var i = 0; i < n; i++)
              [51.12345 + i * 1e-5, -0.12345 - i * 1e-5],
          ],
          rpe: 7,
          templateId: 'free_run',
        );

    test('round-trips through JSON', () {
      final d = sample(3);
      final back = RunDetails.fromJson(
          jsonDecode(jsonEncode(d.toJson())) as Map<String, Object?>);
      expect(back.toJson(), d.toJson());
      expect(back.startedAt, t0);
      expect(back.moving, d.moving);
      expect(back.splits[1].meters, 412.5);
      expect(back.rpe, 7);
      expect(back.templateId, 'free_run');
      expect(back.route.last, [51.12347, -0.12347]);
    });

    test('optional fields may be absent', () {
      final j = sample(2).toJson()
        ..remove('rpe')
        ..remove('elevationGain')
        ..remove('templateId');
      final d = RunDetails.fromJson(j);
      expect(d.rpe, isNull);
      expect(d.elevationGain, isNull);
      expect(d.templateId, isNull);
    });

    test('a 2000-point route stays under 64 KB', () {
      expect(jsonEncode(sample(2000).toJson()).length, lessThan(64000));
    });
  });
}
