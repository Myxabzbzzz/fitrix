import 'package:flutter_test/flutter_test.dart';

import 'package:fitrix/features/running/data/run_track.dart';

final t0 = DateTime.utc(2026, 10, 1, 7);

RunPoint fix(double meters, int sec, {double accuracy = 5, double? alt}) =>
    RunPoint(
      lat: 0,
      lng: meters / 111319.49,
      alt: alt,
      accuracy: accuracy,
      at: t0.add(Duration(seconds: sec)),
    );

/// Fixes every second at [speed] m/s from [fromSec] to [toSec], starting at
/// [fromMeters].
RunTrack cruise(RunTrack track, double speed, int fromSec, int toSec,
    {double fromMeters = 0}) {
  for (var s = fromSec; s <= toSec; s++) {
    track = track.add(fix(fromMeters + (s - fromSec) * speed, s));
  }
  return track;
}

void main() {
  group('speed caps', () {
    test('16.7 m/s is kept by a ride, dropped by a run', () {
      RunTrack go(ActivityProfile p) => RunTrack(startedAt: t0, profile: p)
          .add(fix(0, 0))
          .add(fix(16.7 * 2, 2))
          .add(fix(16.7 * 4, 4));
      expect(go(rideProfile).meters, closeTo(66.8, 1));
      expect(go(runProfile).meters, 0);
    });

    test('25 m/s is kept by a ski day', () {
      final t = RunTrack(startedAt: t0, profile: skiProfile)
          .add(fix(0, 0))
          .add(fix(50, 2));
      expect(t.meters, closeTo(50, 0.5));
    });

    test('a 300 m jump in 2 s is dropped for every kind', () {
      for (final k in ActivityKind.values) {
        final t = RunTrack(startedAt: t0, profile: profileFor(k))
            .add(fix(0, 0))
            .add(fix(300, 2));
        expect(t.meters, 0, reason: '$k');
      }
    });
  });

  group('auto-stop', () {
    // Ride at 8 m/s for 20 s, stand [stop] s (jittery fixes inside the
    // accuracy gate), ride again for 20 s.
    RunTrack ride(int stop, {ActivityProfile p = rideProfile}) {
      var t = cruise(RunTrack(startedAt: t0, profile: p), 8, 0, 20);
      for (var s = 21; s < 20 + stop; s++) {
        t = t.add(fix(160 + (s.isEven ? 1 : -1), s));
      }
      return cruise(t, 8, 20 + stop, 40 + stop, fromMeters: 160);
    }

    test('a 30 s stop counts only the 10 s grace', () {
      final t = ride(30);
      final end = t0.add(const Duration(seconds: 70));
      expect(t.movingTime(end).inSeconds, closeTo(50, 3));
    });

    void nonDecreasing(RunTrack Function(int sec) build, int to) {
      var prev = Duration.zero;
      for (var sec = 0; sec <= to; sec++) {
        final m = build(sec).movingTime(t0.add(Duration(seconds: sec)));
        expect(m, greaterThanOrEqualTo(prev), reason: 'at $sec s');
        prev = m;
      }
    }

    test('moving time never goes backwards across a 30 s stop', () {
      nonDecreasing((sec) {
        var t = RunTrack(startedAt: t0, profile: rideProfile);
        for (var s = 0; s <= sec; s++) {
          final m = s <= 20 ? s * 8.0 : (s < 50 ? 160.0 : 160.0 + (s - 50) * 8);
          t = t.add(fix(m, s));
        }
        return t;
      }, 70);
    });

    test('moving time never goes backwards over sparse slow fixes', () {
      nonDecreasing((sec) {
        var t = RunTrack(startedAt: t0, profile: rideProfile);
        // 2 m/s with 15 m accuracy: a fix is kept only every ~15 s.
        for (var s = 0; s <= sec; s++) {
          t = t.add(fix(s * 2.0, s, accuracy: 15));
        }
        return t;
      }, 120);
    });

    test('moving time never goes backwards across a pause 15 s after a fix',
        () {
      nonDecreasing((sec) {
        var t = cruise(RunTrack(startedAt: t0, profile: rideProfile), 8, 0, 10);
        if (sec >= 25) t = t.pause(t0.add(const Duration(seconds: 25)));
        return t;
      }, 40);
    });

    test('a 5 s stop is included', () {
      final t = ride(5);
      final end = t0.add(const Duration(seconds: 45));
      expect(t.movingTime(end).inSeconds, closeTo(45, 1));
    });

    test('the run profile never auto-stops', () {
      final t = RunTrack(startedAt: t0)
          .add(fix(0, 0))
          .add(fix(10, 3))
          .add(fix(20, 6));
      final end = t0.add(const Duration(seconds: 60));
      expect(t.movingTime(end).inSeconds, 60);
    });

    test('a manual pause is still excluded', () {
      var t = cruise(RunTrack(startedAt: t0, profile: rideProfile), 8, 0, 10);
      t = t.pause(t0.add(const Duration(seconds: 10)));
      t = t.resume(t0.add(const Duration(seconds: 100)));
      t = cruise(t, 8, 101, 110, fromMeters: 80);
      final end = t0.add(const Duration(seconds: 110));
      expect(t.movingTime(end).inSeconds, closeTo(20, 1));
    });
  });

  group('splits', () {
    test('a ride splits every 5 km', () {
      final t =
          cruise(RunTrack(startedAt: t0, profile: rideProfile), 10, 0, 1100);
      expect(t.meters, closeTo(11000, 20));
      final s = t.splits;
      expect(s, hasLength(3));
      expect(s[0].meters, 5000);
      expect(s[0].km, 5);
      expect(s[1].km, 10);
      expect(s[0].time.inSeconds, closeTo(500, 2));
      expect(s[2].meters, closeTo(1000, 20));
      expect(s[2].km, 11);
    });

    test('the last partial ride split never names more than was ridden', () {
      List<RunSplit> at(int secs) =>
          cruise(RunTrack(startedAt: t0, profile: rideProfile), 10, 0, secs)
              .splits;
      final short = at(505); // 5.05 km
      expect(short.map((s) => s.km), [5, 5]);
      expect(short.last.meters, closeTo(50, 15));
      final longer = at(1030); // 10.3 km
      expect(longer.map((s) => s.km), [5, 10, 10]);
      expect(longer.last.meters, closeTo(300, 20));
      expect(at(320).map((s) => s.km), [3]); // 3.2 km
    });
  });

  group('max speed', () {
    test('null before 3 s of track', () {
      final t = RunTrack(startedAt: t0, profile: rideProfile)
          .add(fix(0, 0))
          .add(fix(10, 1));
      expect(t.maxSpeed, isNull);
    });

    test('a single spike is smoothed away', () {
      var t = cruise(RunTrack(startedAt: t0, profile: rideProfile), 8, 0, 10);
      // One second at 25 m/s.
      t = t.add(fix(80 + 25, 11));
      t = cruise(t, 8, 12, 22, fromMeters: 105 + 8);
      expect(t.maxSpeed!, closeTo(8, 0.8));
    });

    test('a steady speed reads as that speed', () {
      final t = cruise(RunTrack(startedAt: t0, profile: skiProfile), 20, 0, 10);
      expect(t.maxSpeed, closeTo(20, 0.2));
    });
  });

  group('elevation loss', () {
    test('mirrors the gain', () {
      var t = RunTrack(startedAt: t0);
      final alts = <double>[100, 100, 110, 110, 90, 90, 95];
      for (var i = 0; i < alts.length; i++) {
        t = t.add(fix(i * 15.0, i * 5, alt: alts[i]));
      }
      expect(t.elevationGain, closeTo(15, 0.01));
      expect(t.elevationLoss, closeTo(20, 0.01));
    });

    test('null without altitudes', () {
      final t = RunTrack(startedAt: t0).add(fix(0, 0)).add(fix(20, 5));
      expect(t.elevationLoss, isNull);
    });
  });

  group('RunDetails', () {
    RunDetails sample({ActivityKind kind = ActivityKind.ride}) => RunDetails(
          startedAt: t0,
          moving: const Duration(minutes: 30),
          elapsed: const Duration(minutes: 35),
          pauses: 1,
          meters: 12000,
          splits: const [
            RunSplit(km: 5, meters: 5000, time: Duration(minutes: 10)),
          ],
          route: const [
            [1.0, 2.0]
          ],
          kind: kind,
          maxSpeed: 14.5,
          elevationLoss: 80,
          indoor: true,
          avgPowerW: 180,
        );

    test('round-trips the new fields', () {
      final back = RunDetails.fromJson(sample().toJson());
      expect(back.kind, ActivityKind.ride);
      expect(back.maxSpeed, 14.5);
      expect(back.elevationLoss, 80);
      expect(back.indoor, isTrue);
      expect(back.avgPowerW, 180);
      expect(back.splits.single.km, 5);
    });

    test('a run writes none of the new keys', () {
      final j = RunDetails(
        startedAt: t0,
        moving: Duration.zero,
        elapsed: Duration.zero,
        pauses: 0,
        meters: 0,
        splits: const [],
        route: const [],
      ).toJson();
      for (final k in [
        'kind',
        'maxSpeed',
        'elevationLoss',
        'indoor',
        'avgPowerW'
      ]) {
        expect(j.containsKey(k), isFalse, reason: k);
      }
    });

    test('an old document without kind parses as a run', () {
      final j = Map<String, Object?>.of(sample(kind: ActivityKind.run).toJson())
        ..remove('kind')
        ..remove('indoor');
      final back = RunDetails.fromJson(j);
      expect(back.kind, ActivityKind.run);
      expect(back.indoor, isFalse);
    });
  });
}
