import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:fitrix/features/map/data/location.dart';

void main() {
  final now = DateTime(2026, 10, 20, 12);
  const here = LatLng(41.31, 69.28), there = LatLng(41.33, 69.30);

  test('a recent last known fix is used at once, without waiting on the GPS',
      () async {
    var asked = false;
    final fix = await quickFix(
      lastKnown: () async =>
          (at: here, time: now.subtract(const Duration(minutes: 3))),
      fresh: (_) {
        asked = true;
        return Completer<LatLng>().future; // never arrives
      },
      now: () => now,
    );
    expect(fix, here);
    expect(asked, isFalse);
  });

  test('an old or missing last fix waits at most 5 s for a fresh one',
      () async {
    Duration? limit;
    final fix = await quickFix(
      lastKnown: () async =>
          (at: here, time: now.subtract(const Duration(hours: 2))),
      fresh: (l) async {
        limit = l;
        return there;
      },
      now: () => now,
    );
    expect(fix, there);
    expect(limit, const Duration(seconds: 5));

    final none = await quickFix(
      lastKnown: () async => null,
      fresh: (_) async => throw TimeoutException('no fix'),
      now: () => now,
    );
    expect(none, isNull);
  });

  test('no fresh fix in time falls back to the old last known one', () async {
    final fix = await quickFix(
      lastKnown: () async =>
          (at: here, time: now.subtract(const Duration(hours: 2))),
      fresh: (_) async => throw TimeoutException('no fix'),
      now: () => now,
    );
    expect(fix, here);
  });
}
