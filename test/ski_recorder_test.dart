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

  void fix() {
    final at = t0.add(Duration(seconds: s));
    r.clock.now = at;
    r.source.emit(RunPoint(
        lat: n / _mPerDeg, lng: e / _mPerDeg, alt: a, accuracy: 5, at: at));
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
}
