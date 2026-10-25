import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitrix/core/session/session_providers.dart';
import 'package:fitrix/core/time/today_provider.dart';
import 'package:fitrix/features/language/presentation/providers/language_provider.dart';
import 'package:fitrix/features/running/data/location_source.dart';
import 'package:fitrix/features/running/data/run_store.dart';
import 'package:fitrix/features/running/data/run_track.dart';
import 'package:fitrix/features/running/presentation/run_recorder.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/features/workouts/presentation/providers/workouts_provider.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

/// 07:00 local, so the default name is the morning one.
final t0 = DateTime(2026, 10, 1, 7);

class FakeLocationSource implements LocationSource {
  FakeLocationSource([this.access = LocationAccess.granted]);

  final LocationAccess access;
  StreamController<RunPoint>? _controller;
  int starts = 0;
  int stops = 0;

  bool get listening => _controller?.hasListener ?? false;

  @override
  Future<LocationAccess> ensureAccess() async => access;

  @override
  Future<bool> reducedAccuracy() async => false;

  @override
  Stream<RunPoint> start() {
    starts++;
    _controller = StreamController<RunPoint>(sync: true);
    return _controller!.stream;
  }

  @override
  Future<void> stop() async {
    stops++;
    await _controller?.close();
    _controller = null;
  }

  void emit(RunPoint p) => _controller!.add(p);
}

/// Answers [ensureAccess] with [next] (a future the test completes).
class _GatedSource extends FakeLocationSource {
  _GatedSource(this.next);
  Future<LocationAccess> next;

  @override
  Future<LocationAccess> ensureAccess() => next;
}

class Rig {
  Rig(this.container, this.source, this.clock);

  final ProviderContainer container;
  final FakeLocationSource source;
  final Clock clock;

  RunRecorder get recorder => container.read(runRecorderProvider.notifier);
  RunSession? get session => container.read(runRecorderProvider);

  /// Fixes every 5 s at 10 km/h heading east, from [fromMeters] to
  /// [toMeters]; the clock follows the fixes.
  void runTo(double toMeters, {double fromMeters = 0}) {
    const step = 10 / 3.6 * 5;
    final startAt = clock.now;
    for (var i = 0; fromMeters + i * step <= toMeters; i++) {
      final at = startAt.add(Duration(seconds: i * 5));
      clock.now = at;
      source.emit(RunPoint(
        lat: 0,
        lng: (fromMeters + i * step) / 111319.49,
        accuracy: 5,
        at: at,
      ));
    }
  }
}

class Clock {
  Clock(this.now);
  DateTime now;
}

Future<Rig> rig({
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
  ]);
  addTearDown(container.dispose);
  return Rig(container, s, c);
}

const runTemplate = WorkoutTemplate(
  id: 'tpl_easy',
  sport: Sport.running,
  name: 'Easy 5K',
  focus: 'Easy',
  estimatedDuration: Duration(minutes: 30),
  exercises: [],
);

void main() {
  test('km events in order; finish saves the workout and its details',
      () async {
    final r = await rig();
    final events = <RunEvent>[];
    r.recorder.events.listen(events.add);

    expect(await r.recorder.start(), LocationAccess.granted);
    expect(r.session!.phase, RunPhase.running);
    expect(r.source.listening, isTrue);
    expect(
        r.container.read(sharedPreferencesProvider).getString(runInProgressKey),
        isNotNull);

    r.runTo(2100);
    await pumpEventQueue();
    final kms = events.whereType<KmReached>().toList();
    expect(kms.map((e) => e.km), [1, 2]);
    // 10 km/h is 6:00 /km.
    expect(kms[0].total.inSeconds, closeTo(360, 3));
    expect(kms[0].lastKmSecPerKm, closeTo(360, 3));
    expect(kms[1].total.inSeconds, closeTo(720, 6));
    expect(kms[1].lastKmSecPerKm, closeTo(360, 3));
    expect(kms[1].avgSecPerKm, closeTo(360, 3));

    r.clock.now = r.clock.now.add(const Duration(seconds: 2));
    final moving = r.session!.track.movingTime(r.clock.now);
    final saved = await r.recorder.finish(rpe: 7);
    await pumpEventQueue();

    final history = r.container.read(workoutHistoryProvider);
    expect(history.single.id, saved.id);
    expect(saved.sport, Sport.running);
    expect(saved.templateId, 'free_run');
    expect(saved.name, 'Morning run');
    expect(saved.startedAt, t0);
    expect(saved.duration, moving);
    expect(saved.sessionRpe, 7);

    final details = r.container.read(runStoreProvider).all()[saved.id]!;
    expect(details.meters, closeTo(2100, 25));
    expect(details.moving, moving);
    expect(details.rpe, 7);
    expect(details.splits.where((s) => s.meters == 1000), hasLength(2));
    expect(details.route, isNotEmpty);
    expect(r.container.read(runsProvider).keys, [saved.id]);

    expect(
        r.container.read(sharedPreferencesProvider).getString(runInProgressKey),
        isNull);
    expect(r.session, isNull);
    expect(r.source.stops, greaterThan(0));
    expect(r.source.listening, isFalse);

    expect(events.first, isA<RunStarted>());
    final finished = events.last as RunFinished;
    expect(finished.meters, closeTo(2100, 25));
    expect(finished.moving, moving);
    expect(finished.avgSecPerKm, closeTo(360, 5));
  });

  test('a run started from a template is saved under its id', () async {
    final r = await rig();
    await r.recorder.start(template: runTemplate);
    expect(r.session!.template!.id, 'tpl_easy');
    r.runTo(300);
    final saved = await r.recorder.finish();
    expect(saved.templateId, 'tpl_easy');
    expect(saved.name, 'Easy 5K');
    expect(saved.sessionRpe, isNull);
    expect(r.container.read(runStoreProvider).all()[saved.id]!.templateId,
        'tpl_easy');
  });

  test('the default name follows the start hour, in the app language',
      () async {
    final r = await rig(clock: Clock(DateTime(2026, 10, 1, 19, 30)));
    await r.container.read(selectedLanguageProvider.notifier).setLanguage('ru');
    await r.recorder.start();
    final saved = await r.recorder.finish();
    expect(
        saved.name, lookupAppLocalizations(const Locale('ru')).runNameEvening);
    expect(saved.name,
        isNot(lookupAppLocalizations(const Locale('en')).runNameEvening));
  });

  group('two quick starts', () {
    for (final access in [LocationAccess.granted, LocationAccess.denied]) {
      test('$access: both get the first start\'s answer, one session',
          () async {
        final gate = Completer<LocationAccess>();
        final r = await rig(source: _GatedSource(gate.future));
        final first = r.recorder.start(template: runTemplate);
        final second = r.recorder.start();
        gate.complete(access);
        expect(await second, access);
        expect(await first, access);
        expect(r.source.starts, access == LocationAccess.granted ? 1 : 0);
        expect(r.session?.template?.id,
            access == LocationAccess.granted ? runTemplate.id : null);
      });
    }

    test('a start after a denied one asks again', () async {
      final gate = Completer<LocationAccess>();
      final source = _GatedSource(gate.future);
      final r = await rig(source: source);
      gate.complete(LocationAccess.denied);
      expect(await r.recorder.start(), LocationAccess.denied);
      source.next = Future.value(LocationAccess.granted);
      expect(await r.recorder.start(), LocationAccess.granted);
      expect(r.source.starts, 1);
    });
  });

  for (final access in [
    LocationAccess.denied,
    LocationAccess.deniedForever,
    LocationAccess.serviceOff,
  ]) {
    test('$access: start reports it, no session, no location stream', () async {
      final r = await rig(source: FakeLocationSource(access));
      expect(await r.recorder.start(), access);
      expect(r.session, isNull);
      expect(r.source.starts, 0);
      expect(
          r.container
              .read(sharedPreferencesProvider)
              .getString(runInProgressKey),
          isNull);
    });
  }

  test('moving time comes from the clock, not from fixes', () async {
    final r = await rig();
    await r.recorder.start();
    r.clock.now = t0.add(const Duration(minutes: 3));
    r.recorder.pause();
    r.clock.now = t0.add(const Duration(minutes: 5));
    r.recorder.resume();
    r.clock.now = t0.add(const Duration(minutes: 6));
    final saved = await r.recorder.finish();
    expect(saved.duration, const Duration(minutes: 4));
    expect(saved.finishedAt, t0.add(const Duration(minutes: 4)));
    final details = r.container.read(runStoreProvider).all()[saved.id]!;
    expect(details.elapsed, const Duration(minutes: 6));
    expect(details.pauses, 1);
  });

  test('pause and resume emit events and ignore fixes while paused', () async {
    final r = await rig();
    final events = <RunEvent>[];
    r.recorder.events.listen(events.add);
    await r.recorder.start();
    r.runTo(500);
    r.recorder.pause();
    expect(r.session!.phase, RunPhase.paused);
    final meters = r.session!.track.meters;
    r.runTo(1500, fromMeters: 500);
    expect(r.session!.track.meters, meters);
    r.recorder.resume();
    expect(r.session!.phase, RunPhase.running);
    await pumpEventQueue();
    expect(
        events.map((e) => e.runtimeType), [RunStarted, RunPaused, RunResumed]);
  });

  test('killed after 600 m and a pause: the run comes back and continues',
      () async {
    final r = await rig();
    await r.recorder.start(template: runTemplate);
    r.runTo(615);
    final metersBefore = r.session!.track.meters;
    expect(metersBefore, greaterThanOrEqualTo(600));
    r.clock.now = r.clock.now.add(const Duration(seconds: 1));
    r.recorder.pause();
    final movingBefore = r.session!.track.movingTime(r.clock.now);
    r.container.dispose(); // the app is killed

    final clock = Clock(r.clock.now.add(const Duration(minutes: 20)));
    final source = FakeLocationSource();
    final r2 = await rig(source: source, clock: clock, fresh: false);
    r2.container
        .read(workoutTemplatesProvider.notifier)
        .applySynced(const [runTemplate], const []);

    final pending = r2.container.read(pendingRunProvider);
    expect(pending, isNotNull);
    expect(pending!.phase, RunPhase.paused);
    expect(pending.track.meters, closeTo(metersBefore, 0.001));
    expect(pending.startedAt, t0);
    expect(pending.template?.id, 'tpl_easy');
    expect(pending.track.movingTime(clock.now), movingBefore);
    expect(r2.session!.track.meters, pending.track.meters);
    expect(source.starts, 0);

    r2.recorder.resume();
    expect(source.listening, isTrue);
    expect(r2.container.read(pendingRunProvider), isNull);
    r2.runTo(900, fromMeters: 620);
    expect(r2.session!.track.meters, closeTo(metersBefore + 280, 20));

    final saved = await r2.recorder.finish();
    expect(saved.templateId, 'tpl_easy');
    expect(saved.startedAt, t0);
  });

  test('killed while running: restored paused at the last saved fix', () async {
    final r = await rig();
    await r.recorder.start();
    r.runTo(600); // 216 s of fixes, saved at least every 10 s
    r.container.dispose();

    final clock = Clock(r.clock.now.add(const Duration(hours: 2)));
    final r2 = await rig(clock: clock, fresh: false);
    final pending = r2.container.read(pendingRunProvider)!;
    expect(pending.phase, RunPhase.paused);
    expect(pending.track.meters, greaterThan(550));
    // The two hours while the app was dead are not moving time.
    expect(pending.track.movingTime(clock.now).inSeconds,
        inInclusiveRange(200, 216));
  });

  test('a restored ride saved without Resume finishes as a ride', () async {
    final r = await rig();
    await r.recorder.start(kind: ActivityKind.ride);
    r.runTo(600);
    r.container.dispose();

    final r2 = await rig(
        clock: Clock(r.clock.now.add(const Duration(hours: 1))), fresh: false);
    final events = <RunEvent>[];
    r2.recorder.events.listen(events.add);
    await r2.recorder.finish();
    await pumpEventQueue();
    expect((events.last as RunFinished).kind, ActivityKind.ride);
  });

  test('GPS status: raw fixes, a restored run before Resume, finish', () async {
    final r = await rig();
    await r.recorder.start();
    expect(r.recorder.gpsStatus(), GpsStatus.waiting);
    r.source.emit(RunPoint(lat: 0, lng: 0, accuracy: 80, at: t0));
    expect(r.recorder.lastRawFixAt, t0);
    expect(r.recorder.lastRawAccuracy, 80);
    expect(r.recorder.gpsStatus(), GpsStatus.waiting);
    r.runTo(100);
    expect(r.recorder.gpsStatus(), GpsStatus.good);
    r.container.dispose();

    final clock = Clock(r.clock.now.add(const Duration(hours: 2)));
    final r2 = await rig(clock: clock, fresh: false);
    expect(r2.session, isNotNull);
    expect(r2.recorder.gpsStatus(), isNull);
    r2.recorder.resume();
    expect(r2.recorder.gpsStatus(), GpsStatus.good);
    clock.now = clock.now.add(const Duration(seconds: 16));
    expect(r2.recorder.gpsStatus(), GpsStatus.weak);
    await r2.recorder.finish();
    expect(r2.recorder.gpsStatus(), isNull);
    expect(r2.recorder.lastRawFixAt, isNull);
  });

  test('a corrupt recovery entry is ignored', () async {
    SharedPreferences.setMockInitialValues({runInProgressKey: '{"nope":1'});
    final r = await rig(fresh: false);
    expect(r.container.read(pendingRunProvider), isNull);
    expect(r.session, isNull);
  });

  test('discard leaves nothing behind', () async {
    final r = await rig();
    await r.recorder.start();
    r.runTo(800);
    await r.recorder.discard();
    expect(r.session, isNull);
    expect(r.container.read(workoutHistoryProvider), isEmpty);
    expect(r.container.read(runStoreProvider).all(), isEmpty);
    expect(
        r.container.read(sharedPreferencesProvider).getString(runInProgressKey),
        isNull);
    expect(r.source.listening, isFalse);
  });

  test('the recovery entry has the agreed shape', () async {
    final r = await rig();
    await r.recorder.start(template: runTemplate);
    r.runTo(100);
    r.recorder.pause();
    final j = jsonDecode(r.container
        .read(sharedPreferencesProvider)
        .getString(runInProgressKey)!) as Map<String, dynamic>;
    expect(j.keys,
        containsAll(['startedAt', 'templateId', 'phase', 'points', 'pauses']));
    expect(j['templateId'], 'tpl_easy');
    expect(j['phase'], 'paused');
    expect(j['points'], isNotEmpty);
    expect((j['pauses'] as List).single, hasLength(1));
  });
}
