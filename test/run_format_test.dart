import 'package:flutter_test/flutter_test.dart';

import 'package:fitrix/features/running/data/run_track.dart';
import 'package:fitrix/features/running/presentation/run_format.dart';

RunPoint _p(double meters, int sec) => RunPoint(
      lat: 0,
      lng: meters / 111319.49,
      accuracy: 5,
      at: DateTime(2026, 10, 1, 7).add(Duration(seconds: sec)),
    );

void main() {
  test('clock and pace formats', () {
    expect(formatClock(const Duration(seconds: 309)), '5:09');
    expect(formatClock(const Duration(seconds: 3909)), '1:05:09');
    expect(formatPace(342), '5:42');
    expect(formatPace(null), noValue);
    expect(formatKm(5420, 'en'), '5.42');
    expect(formatKm(5420, 'ru'), '5,42');
  });

  test('current pace is over the last 200 m', () {
    // 100 m at 8:00/km, then 300 m at 6:00/km.
    var t = RunTrack(startedAt: DateTime(2026, 10, 1, 7));
    final fixes = [
      _p(0, 0),
      _p(100, 48),
      _p(150, 48 + 18),
      _p(200, 48 + 36),
      _p(250, 48 + 54),
      _p(300, 48 + 72),
      _p(350, 48 + 90),
      _p(400, 48 + 108),
    ];
    for (final f in fixes) {
      t = t.add(f);
    }
    expect(currentPaceSecPerKm(t), closeTo(360, 3));
  });

  test('at the start the pace shows after about 100 m or 20 s', () {
    var t = RunTrack(startedAt: DateTime(2026, 10, 1, 7));
    // 4.5 m/s: 3:42/km.
    t = t.add(_p(0, 0)).add(_p(22.5, 5));
    expect(currentPaceSecPerKm(t), isNull, reason: '5 s, 22 m');
    t = t.add(_p(45, 10)).add(_p(67.5, 15));
    expect(currentPaceSecPerKm(t), isNull, reason: '15 s, 67 m');
    t = t.add(_p(90, 20));
    expect(currentPaceSecPerKm(t), closeTo(222, 2), reason: '20 s');

    var walk = RunTrack(startedAt: DateTime(2026, 10, 1, 7));
    walk = walk.add(_p(0, 0)).add(_p(105, 13));
    expect(currentPaceSecPerKm(walk), closeTo(124, 2), reason: '105 m');
  });

  test('standing about for 20 s is not a pace', () {
    var t = RunTrack(startedAt: DateTime(2026, 10, 1, 7));
    t = t.add(_p(0, 0)).add(_p(5, 10)).add(_p(10, 25));
    expect(currentPaceSecPerKm(t), isNull);
  });

  test('after a gap the pace starts again from the fixes after it', () {
    var t = RunTrack(startedAt: DateTime(2026, 10, 1, 7));
    t = t.add(_p(0, 0)).add(_p(100, 36));
    t = t.add(_p(300, 36 + 120));
    expect(currentPaceSecPerKm(t), isNull, reason: 'one fix after the gap');
    t = t.add(_p(350, 36 + 120 + 15)).add(_p(400, 36 + 120 + 30));
    expect(currentPaceSecPerKm(t), closeTo(300, 2));
  });
}
