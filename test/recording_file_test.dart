import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitrix/features/running/data/location_source.dart';
import 'package:fitrix/features/running/data/recording_file.dart';
import 'package:fitrix/features/running/data/run_track.dart';
import 'package:fitrix/features/running/presentation/run_recorder.dart';

import 'ski_recorder_test.dart' show fileRig, tempFile;
import 'run_recorder_test.dart' show Clock, FakeLocationSource, Rig, t0;

const _mPerDeg = 111319.49;

void _emit(FakeLocationSource src, Clock c, int secs, double east) {
  final at = t0.add(Duration(seconds: secs));
  c.now = at;
  src.emit(RunPoint(lat: 0, lng: east / _mPerDeg, accuracy: 5, at: at));
}

void main() {
  _moreTests();
  for (final kind in [ActivityKind.ride, ActivityKind.ski]) {
    test('$kind: killed mid-way, every flushed fix comes back', () async {
      final file = tempFile();
      final r = await fileRig(file: file);
      await r.recorder.start(kind: kind);
      for (var i = 0; i <= 60; i++) {
        _emit(r.source, r.clock, i * 2, i * 20.0);
      }
      final kept = r.session!.track.kept;
      final lines = file.readAsLinesSync();
      // Written at most every 10 s of fixes: the file lags, never leads.
      expect(lines.length, inInclusiveRange(kept.length - 6, kept.length));
      final header = jsonDecode(
          (await SharedPreferences.getInstance()).getString(runInProgressKey)!);
      expect(header.containsKey('points'), isFalse);
      r.container.dispose();

      final r2 = await fileRig(
          file: file,
          fresh: false,
          clock: Clock(t0.add(const Duration(hours: 1))));
      final back = r2.session!;
      expect(back.kind, kind);
      expect(back.phase, RunPhase.paused);
      expect(back.track.kept.length, lines.length);
      expect(back.track.kept.first.at, kept.first.at);
      expect(back.track.meters, greaterThan(1000));
    });
  }

  test('a paused session has all its fixes in the file', () async {
    final file = tempFile();
    final r = await fileRig(file: file);
    await r.recorder.start();
    for (var i = 0; i <= 12; i++) {
      _emit(r.source, r.clock, i * 2, i * 20.0);
    }
    r.recorder.pause();
    final n = r.session!.track.kept.length;
    expect(file.readAsLinesSync(), hasLength(n));
    r.container.dispose();
    final r2 = await fileRig(file: file, fresh: false);
    expect(r2.session!.track.kept, hasLength(n));
  });

  test('a cut-off last line is skipped, and recording goes on cleanly',
      () async {
    final file = tempFile();
    final r = await fileRig(file: file);
    await r.recorder.start();
    for (var i = 0; i <= 12; i++) {
      _emit(r.source, r.clock, i * 2, i * 20.0);
    }
    r.recorder.pause();
    final n = r.session!.track.kept.length;
    r.container.dispose();
    file.writeAsStringSync('[0.0,0.00', mode: FileMode.append);

    final src = FakeLocationSource();
    final clock = Clock(t0.add(const Duration(minutes: 10)));
    final r2 =
        await fileRig(file: file, fresh: false, source: src, clock: clock);
    expect(r2.session!.track.kept, hasLength(n));
    r2.recorder.resume();
    _emit(src, clock, 600, 1000);
    _emit(src, clock, 610, 1100);
    r2.recorder.pause();
    r2.container.dispose();

    final r3 = await fileRig(file: file, fresh: false);
    expect(r3.session!.track.kept.length, greaterThan(n));
    expect(file.readAsLinesSync().length, r3.session!.track.kept.length);
  });

  test('a recording in the old prefs format restores and moves to the file',
      () async {
    final start = t0;
    SharedPreferences.setMockInitialValues({
      runInProgressKey: jsonEncode({
        'startedAt': start.toUtc().toIso8601String(),
        'templateId': null,
        'kind': 'ski',
        'phase': 'running',
        'points': [
          for (var i = 0; i <= 10; i++)
            [
              0.0,
              i * 20 / _mPerDeg,
              2000.0 - i,
              5.0,
              t0.add(Duration(seconds: i * 5)).millisecondsSinceEpoch
            ],
        ],
        'pauses': <Object>[],
      }),
    });
    final file = tempFile();
    final r = await fileRig(file: file, fresh: false);
    expect(r.session!.kind, ActivityKind.ski);
    expect(r.session!.track.kept, hasLength(11));
    expect(file.readAsLinesSync(), hasLength(11));
    final header = jsonDecode(
        (await SharedPreferences.getInstance()).getString(runInProgressKey)!);
    expect(header.containsKey('points'), isFalse);
    expect(header['kind'], 'ski');
    r.container.dispose();
    final r2 = await fileRig(file: file, fresh: false);
    expect(r2.session!.track.kept, hasLength(11));
  });

  test('finish and discard delete the file; a new start begins empty',
      () async {
    final file = tempFile();
    final r = await fileRig(file: file);
    await r.recorder.start();
    for (var i = 0; i <= 12; i++) {
      _emit(r.source, r.clock, i * 2, i * 20.0);
    }
    r.recorder.pause();
    expect(file.existsSync(), isTrue);
    await r.recorder.discard();
    expect(file.existsSync(), isFalse);
    await r.recorder.start();
    expect(file.readAsStringSync(), isEmpty);
    await r.recorder.finish();
    expect(file.existsSync(), isFalse);
  });

  test('an 8 h day restores quickly', () async {
    final file = tempFile();
    final rec = RecordingFile(file);
    final fixes = [
      for (var i = 0; i < 28800; i++)
        RunPoint(
            lat: 0,
            lng: i * 12 / _mPerDeg,
            alt: 2000.0 + i % 50,
            accuracy: 5,
            at: t0.add(Duration(seconds: i))),
    ];
    rec.append(fixes, t0);
    SharedPreferences.setMockInitialValues({
      runInProgressKey: jsonEncode({
        'startedAt': t0.toUtc().toIso8601String(),
        'templateId': null,
        'kind': 'ski',
        'phase': 'running',
        'pauses': <Object>[],
      }),
    });
    final sw = Stopwatch()..start();
    final r = await fileRig(file: file, fresh: false);
    sw.stop();
    expect(r.session!.track.kept.length, greaterThan(28000));
    // A copy of the list per fix took well over this; loose for slow CI.
    expect(sw.elapsedMilliseconds, lessThan(3000));
  });

  test('resuming a restored ski day tells the source it is skiing', () async {
    final file = tempFile();
    final r = await fileRig(file: file);
    await r.recorder.start(kind: ActivityKind.ski);
    _emit(r.source, r.clock, 0, 0);
    _emit(r.source, r.clock, 10, 100);
    r.recorder.pause();
    r.container.dispose();

    final src = _KindSource();
    final r2 = await fileRig(file: file, fresh: false, source: src);
    r2.recorder.resume();
    expect(src.kinds, [ActivityKind.ski]);
  });
}

void _recordAndPause(Rig r, {int n = 12}) {
  for (var i = 0; i <= n; i++) {
    _emit(r.source, r.clock, i * 2, i * 20.0);
  }
  r.recorder.pause();
}

void _moreTests() {
  test('a failed rewrite keeps the restored session and the original file',
      () async {
    final file = tempFile();
    final r = await fileRig(file: file);
    await r.recorder.start();
    _recordAndPause(r);
    final n = r.session!.track.kept.length;
    r.container.dispose();
    file.writeAsStringSync('[0.0,0.00', mode: FileMode.append);
    final before = file.readAsStringSync();
    // The temp file cannot be made: a directory sits in its place.
    Directory('${file.path}.tmp').createSync();

    final r2 = await fileRig(file: file, fresh: false);
    expect(r2.session!.track.kept, hasLength(n));
    expect(file.readAsStringSync(), before);
  });

  test('a file that cannot be reset does not stop the recording', () async {
    final dir = Directory.systemTemp.createTempSync('fitrix_rec');
    addTearDown(() => dir.deleteSync(recursive: true));
    final blocker = File('${dir.path}/blocker')..writeAsStringSync('x');
    final r = await fileRig(file: File('${blocker.path}/rec.fixes'));
    await r.recorder.start();
    expect(r.session, isNotNull);
    expect(r.source.listening, isTrue);
  });

  test('a fix file with no recording behind it is deleted at launch', () async {
    final file = tempFile();
    final r = await fileRig(file: file);
    await r.recorder.start();
    _recordAndPause(r);
    r.container.dispose();
    expect(file.existsSync(), isTrue);
    // Signed out: the prefs are cleared, the new scope starts.
    SharedPreferences.setMockInitialValues({});
    final r2 = await fileRig(file: file);
    expect(r2.session, isNull);
    expect(file.existsSync(), isFalse);
  });

  for (final header in ['{"startedAt": "not a date"', '{"startedAt": 7}']) {
    test('a header that cannot be restored keeps the fixes aside: $header',
        () async {
      final file = tempFile();
      final r = await fileRig(file: file);
      await r.recorder.start(kind: ActivityKind.ski);
      _recordAndPause(r);
      r.container.dispose();
      final fixes = file.readAsStringSync();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(runInProgressKey, header);
      // An older broken recording is replaced.
      File('${file.path}.broken').writeAsStringSync('older');

      final r2 = await fileRig(file: file, fresh: false);
      expect(r2.session, isNull);
      expect(r2.recorder.hasPendingRun, isFalse);
      expect(file.existsSync(), isFalse);
      expect(File('${file.path}.broken').readAsStringSync(), fixes);
      expect(prefs.getString(runInProgressKey), isNull);
      expect(prefs.getString('$runInProgressKey.broken'), header);

      // The next launch starts clean and a new recording works.
      r2.container.dispose();
      final r3 = await fileRig(file: file, fresh: false);
      expect(r3.session, isNull);
      expect(File('${file.path}.broken').readAsStringSync(), fixes);
      await r3.recorder.start();
      expect(r3.session, isNotNull);

      // Signed out: the kept header is gone, so are the fixes kept aside.
      r3.container.dispose();
      final r4 = await fileRig(file: file);
      expect(r4.session, isNull);
      expect(File('${file.path}.broken').existsSync(), isFalse);
    });
  }

  test('setAside moves the file beside, replacing an older one', () {
    final file = tempFile()..writeAsStringSync('new');
    final aside = File('${file.path}.broken')..writeAsStringSync('old');
    RecordingFile(file).setAside();
    expect(file.existsSync(), isFalse);
    expect(aside.readAsStringSync(), 'new');
    // Nothing to move: the older copy goes, it is another recording's.
    RecordingFile(file).setAside();
    expect(aside.existsSync(), isFalse);
  });

  test('a broken header without a fix file leaves no older fixes beside it',
      () async {
    final file = tempFile();
    final aside = File('${file.path}.broken')..writeAsStringSync('older');
    SharedPreferences.setMockInitialValues({runInProgressKey: '{"nope":1'});
    final r = await fileRig(file: file, fresh: false);
    expect(r.session, isNull);
    expect(file.existsSync(), isFalse);
    expect(aside.existsSync(), isFalse);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(brokenRunKey), '{"nope":1');
    expect(prefs.getString(runInProgressKey), isNull);
  });

  test('closing the app writes the fixes not written yet', () async {
    final file = tempFile();
    final r = await fileRig(file: file);
    await r.recorder.start();
    for (var i = 0; i <= 3; i++) {
      _emit(r.source, r.clock, i * 2, i * 20.0);
    }
    final kept = r.session!.track.kept.length;
    expect(file.readAsLinesSync().length, lessThan(kept));
    r.container.dispose();
    expect(file.readAsLinesSync(), hasLength(kept));
  });

  test('closing after the entry was cleared leaves no trail', () async {
    final file = tempFile();
    final r = await fileRig(file: file);
    await r.recorder.start();
    for (var i = 0; i <= 3; i++) {
      _emit(r.source, r.clock, i * 2, i * 20.0);
    }
    await (await SharedPreferences.getInstance()).remove(runInProgressKey);
    final lines = file.readAsLinesSync().length;
    r.container.dispose();
    expect(file.readAsLinesSync(), hasLength(lines));
  });
}

class _KindSource extends FakeLocationSource
    implements KindAwareLocationSource {
  final kinds = <ActivityKind>[];
  @override
  void useKind(ActivityKind kind) => kinds.add(kind);
}
