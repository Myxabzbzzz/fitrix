import 'dart:io';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitrix/core/session/session_providers.dart';
import 'package:fitrix/core/time/today_provider.dart';
import 'package:fitrix/features/running/data/location_source.dart';
import 'package:fitrix/features/running/data/run_store.dart';
import 'package:fitrix/features/running/data/run_track.dart';
import 'package:fitrix/features/running/presentation/run_recorder.dart';
import 'package:fitrix/features/workouts/domain/training_math.dart';

import 'run_recorder_test.dart' show FakeLocationSource, Rig, Clock, t0;

const _mPerDeg = 111319.49;

/// A recorder with its fixes in a temp-dir file, so a "crash" is a new
/// container over the same prefs and file.
Future<Rig> fileRig({
  required File file,
  FakeLocationSource? source,
  Clock? clock,
  bool fresh = true,
}) async {
  if (fresh) SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final s = source ?? FakeLocationSource();
  final c = clock ?? Clock(t0);
  final container = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    locationSourceProvider.overrideWithValue(s),
    clockProvider.overrideWithValue(() => c.now),
    recordingFileProvider.overrideWithValue(file),
  ]);
  addTearDown(container.dispose);
  return Rig(container, s, c);
}

File tempFile() {
  final dir = Directory.systemTemp.createTempSync('fitrix_rec');
  addTearDown(() => dir.deleteSync(recursive: true));
  return File('${dir.path}/rec.fixes');
}

/// Drives a ski day with 1 Hz fixes carrying GPS jitter while standing, the
/// way a phone does.
class Day {
  Day(this.r) : rnd = Random(2);
  final Rig r;
  final Random rnd;
  int s = 0;
  double e = 0, n = 0, a = 2000;

  /// Called every second of the day (a fix or not).
  void Function()? onSecond;

  void fix() {
    final at = t0.add(Duration(seconds: s));
    r.clock.now = at;
    r.source.emit(RunPoint(
        lat: n / _mPerDeg, lng: e / _mPerDeg, alt: a, accuracy: 5, at: at));
    onSecond?.call();
  }

  /// Standing without a fix (the distance filter keeps the phone quiet).
  void quiet(int secs) {
    for (var i = 0; i < secs; i++) {
      s++;
      r.clock.now = t0.add(Duration(seconds: s));
      onSecond?.call();
    }
  }

  void descent() {
    for (var i = 0; i < 60; i++) {
      s++;
      e += 6;
      a -= 100 / 60;
      fix();
    }
  }

  void lift(int secs) {
    for (var i = 0; i < secs; i++) {
      s++;
      n += 2;
      a += 0.5;
      fix();
    }
  }

  void stop(int secs) {
    final e0 = e, n0 = n, a0 = a;
    for (var i = 0; i < secs; i++) {
      s++;
      e = e0 + (rnd.nextDouble() - .5) * 3;
      n = n0 + (rnd.nextDouble() - .5) * 3;
      a = a0 + (rnd.nextDouble() - .5) * 6;
      fix();
    }
    e = e0;
    n = n0;
    a = a0;
  }
}

void main() {
  test('a 10-minute hut stop mid-descent splits it', () async {
    final r = await fileRig(file: tempFile());
    await r.recorder.start(kind: ActivityKind.ski);
    final d = Day(r)..fix();
    d.descent();
    d.stop(600);
    d.descent();
    d.lift(200);
    d.descent();
    final saved = await r.recorder.finish();
    final ski = r.container.read(runStoreProvider).all()[saved.id]!.ski!;
    expect(ski.descents, hasLength(3));
    expect(ski.lifts, 1);
    expect(ski.descents.first.end.isBefore(ski.descents[1].start), isTrue);
  });

  test('a 4-minute stall on a lift is one lift, not ski time', () async {
    final r = await fileRig(file: tempFile());
    await r.recorder.start(kind: ActivityKind.ski);
    final d = Day(r)..fix();
    d.descent();
    d.lift(100);
    d.stop(240);
    d.lift(100);
    d.descent();
    final saved = await r.recorder.finish();
    final details = r.container.read(runStoreProvider).all()[saved.id]!;
    expect(details.ski!.lifts, 1);
    expect(details.ski!.descents, hasLength(2));
    // The lift is 440 s with the stall (the recorder trims a few seconds).
    expect(details.ski!.liftTime.inSeconds, inInclusiveRange(380, 450));
    expect(saved.duration.inSeconds, inInclusiveRange(110, 190));
    expect(saved.duration + details.ski!.liftTime, Duration(seconds: d.s));
  });

  test('descents are reported while no fix is kept (a stop)', () async {
    final r = await fileRig(file: tempFile());
    final events = <RunEvent>[];
    r.recorder.events.listen(events.add);
    await r.recorder.start(kind: ActivityKind.ski);
    final d = Day(r)..fix();
    d.descent();
    d.stop(120);
    await pumpEventQueue();
    // Nothing was kept for the last two minutes, the descent is still done.
    expect(events.whereType<SkiDescentDone>().map((e) => e.index), [1]);
  });

  test('a ski day saves the distance skied down, not the lifts', () async {
    final r = await fileRig(file: tempFile());
    await r.recorder.start(kind: ActivityKind.ski);
    final d = Day(r)..fix();
    d.descent();
    d.lift(200);
    d.descent();
    final all = r.session!.track.meters;
    final saved = await r.recorder.finish();
    final details = r.container.read(runStoreProvider).all()[saved.id]!;
    expect(details.meters, details.ski!.skiMeters);
    expect(details.meters, lessThan(all - 200));
    expect(details.meters, greaterThan(400));
  });

  for (final rest in [45, 90]) {
    test('a $rest s breather mid-descent is one descent, live too', () async {
      final r = await fileRig(file: tempFile());
      final events = <RunEvent>[];
      r.recorder.events.listen(events.add);
      await r.recorder.start(kind: ActivityKind.ski);
      final d = Day(r)..fix();
      d.descent();
      d.stop(rest);
      d.descent();
      d.lift(200);
      await pumpEventQueue();
      expect(events.whereType<SkiDescentDone>().map((e) => e.index), [1]);
      final saved = await r.recorder.finish();
      final ski = r.container.read(runStoreProvider).all()[saved.id]!.ski!;
      expect(ski.descents, hasLength(1));
    });
  }

  test('a hut stop is reported as two descents live', () async {
    final r = await fileRig(file: tempFile());
    final events = <RunEvent>[];
    r.recorder.events.listen(events.add);
    await r.recorder.start(kind: ActivityKind.ski);
    final d = Day(r)..fix();
    d.descent();
    d.stop(600);
    d.descent();
    d.lift(200);
    await pumpEventQueue();
    expect(events.whereType<SkiDescentDone>().map((e) => e.index), [1, 2]);
  });

  test('live time on slopes never goes back over lifts, queues and lunch',
      () async {
    final r = await fileRig(file: tempFile());
    await r.recorder.start(kind: ActivityKind.ski);
    final d = Day(r)..fix();
    var shown = 0;
    d.onSecond = () {
      final v = r.recorder.skiLive()!.onSlopes.inSeconds;
      expect(v, greaterThanOrEqualTo(shown), reason: 'at ${d.s} s');
      shown = v;
    };
    // How far the clock moved over [f].
    int over(void Function() f) {
      final before = shown;
      f();
      return shown - before;
    }

    expect(over(d.descent), 60);
    // A lift shows only once it climbed for a bit; then the clock stands.
    expect(over(() => d.lift(420)), lessThanOrEqualTo(45));
    expect(over(d.descent), greaterThanOrEqualTo(50));
    expect(over(() => d.stop(600)), lessThanOrEqualTo(10)); // queue
    expect(over(() => d.lift(480)), lessThanOrEqualTo(45));
    expect(over(d.descent), greaterThanOrEqualTo(50));
    expect(over(() => d.quiet(2700)), lessThanOrEqualTo(10)); // lunch
    expect(over(d.descent), greaterThanOrEqualTo(40));
    // A short stop is held back while it lasts, then counted.
    final breather = over(() => d.quiet(40)) + over(d.descent);
    expect(breather, greaterThanOrEqualTo(90));
    expect(over(() => d.lift(360)), lessThanOrEqualTo(45));
    expect(over(d.descent), greaterThanOrEqualTo(50));

    final saved = await r.recorder.finish();
    expect((saved.duration.inSeconds - shown).abs(),
        lessThanOrEqualTo(skiScanEvery.inSeconds));
  });

  test('a ski day leaves a 10-minute queue and a 45-minute lunch out',
      () async {
    Future<(Duration, int)> day({required bool stops}) async {
      final r = await fileRig(file: tempFile());
      await r.recorder.start(kind: ActivityKind.ski);
      final d = Day(r)..fix();
      d.descent();
      if (stops) d.stop(600); // a queue, the phone still giving fixes
      d.lift(300);
      d.descent();
      if (stops) d.quiet(2700); // lunch, no fixes
      d.descent();
      final saved = await r.recorder.finish(rpe: 5);
      final details = r.container.read(runStoreProvider).all()[saved.id]!;
      // The summary, the load and the workout read the same time.
      expect(details.moving, saved.duration);
      expect(saved.finishedAt, saved.startedAt.add(saved.duration));
      expect(saved.load, sessionLoad(5, saved.duration));
      return (saved.duration, d.s);
    }

    final (plain, plainDay) = await day(stops: false);
    final (withStops, stopsDay) = await day(stops: true);
    expect(stopsDay - plainDay, 3300);
    expect(plain.inSeconds, inInclusiveRange(150, 260));
    expect((withStops - plain).inSeconds.abs(), lessThanOrEqualTo(15));
  });

  test('a stop under 2 minutes still counts on a ski day', () async {
    final r = await fileRig(file: tempFile());
    await r.recorder.start(kind: ActivityKind.ski);
    final d = Day(r)..fix();
    d.descent();
    d.lift(300);
    d.descent();
    d.quiet(90);
    d.descent();
    final saved = await r.recorder.finish();
    final ski = r.container.read(runStoreProvider).all()[saved.id]!.ski!;
    expect(saved.duration + ski.liftTime, Duration(seconds: d.s));
  });

  test('a run keeps the standing time; a ride drops it by auto-stop', () async {
    for (final kind in [ActivityKind.run, ActivityKind.ride]) {
      final r = await fileRig(file: tempFile());
      await r.recorder.start(kind: kind);
      final d = Day(r)..fix();
      for (var i = 0; i < 120; i++) {
        d.s++;
        d.e += 3;
        d.fix();
      }
      d.quiet(600);
      for (var i = 0; i < 120; i++) {
        d.s++;
        d.e += 3;
        d.fix();
      }
      final saved = await r.recorder.finish();
      expect(saved.duration.inSeconds,
          kind == ActivityKind.run ? 840 : closeTo(240, 15),
          reason: kind.name);
    }
  });

  test('standing on a ski day keeps a good GPS until it is quiet for long',
      () async {
    final r = await fileRig(file: tempFile());
    await r.recorder.start(kind: ActivityKind.ski);
    final d = Day(r)..fix();
    d.descent();
    expect(r.recorder.gpsStatus(), GpsStatus.good);
    // The distance filter sends nothing while standing.
    d.quiet(5 * 60);
    expect(r.recorder.gpsStatus(), GpsStatus.good);
    d.quiet(skiGpsQuietFor.inSeconds - 5 * 60 + 1);
    expect(r.recorder.gpsStatus(), GpsStatus.weak);
    // A coarse fix is weak at once.
    r.source.emit(
        RunPoint(lat: 0, lng: 0, alt: 2000, accuracy: 80, at: r.clock.now));
    expect(r.recorder.gpsStatus(), GpsStatus.weak);
  });

  test('a ride still shows a weak GPS 15 s after the last fix', () async {
    final r = await fileRig(file: tempFile());
    await r.recorder.start(kind: ActivityKind.ride);
    final d = Day(r)..fix();
    d.descent();
    expect(r.recorder.gpsStatus(), GpsStatus.good);
    d.quiet(gpsStaleAfter.inSeconds + 1);
    expect(r.recorder.gpsStatus(), GpsStatus.weak);
  });
}
