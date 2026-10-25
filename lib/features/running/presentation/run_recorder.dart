import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'package:fitrix/core/session/session_providers.dart';
import 'package:fitrix/core/time/today_provider.dart';
import 'package:fitrix/features/language/presentation/providers/language_provider.dart';
import 'package:fitrix/features/running/data/location_source.dart';
import 'package:fitrix/features/running/data/recording_file.dart';
import 'package:fitrix/features/running/data/run_store.dart';
import 'package:fitrix/features/running/data/run_track.dart';
import 'package:fitrix/features/running/data/ski_math.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/features/workouts/presentation/providers/workouts_provider.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

/// Prefs key of the run being recorded, so it survives the app being killed.
const runInProgressKey = 'run_in_progress_v1';

/// Template id of a run started without a plan.
const freeRunTemplateId = 'free_run';

/// How often (at most) the new fixes are appended to the recording file.
const _saveEvery = Duration(seconds: 10);

/// How often (at most, in fix time) a ski day is re-segmented to find the
/// descents that just ended.
const skiScanEvery = Duration(seconds: 30);

/// Without a kept fix after it, a descent is done only after this long (the
/// shortest stop the segmentation splits a descent at).
const skiStopAfter = Duration(minutes: 2);

/// A descent counts as done when it ended this long before the latest fix
/// (a lift or a stop followed it), so a short breather mid-run is not one.
const skiDoneAfter = Duration(seconds: 30);

/// No fix for longer than this means a weak signal.
const gpsStaleAfter = Duration(seconds: 15);

enum RunPhase { idle, running, paused }

/// What the GPS is giving the run: no fix kept yet, fixes too old or too
/// coarse ([gpsStaleAfter], [maxFixAccuracy]), or good ones.
enum GpsStatus { waiting, weak, good }

typedef RunPauseMark = ({DateTime pausedAt, DateTime? resumedAt});

class RunSession {
  RunSession({
    required this.phase,
    required this.track,
    required this.startedAt,
    this.template,
    String? templateId,
    this.pauses = const [],
    this.kind = ActivityKind.run,
  }) : templateId = templateId ?? template?.id;

  final RunPhase phase;
  final RunTrack track;

  /// When Start was tapped.
  final DateTime startedAt;

  /// The plan the run was started from, if any.
  final WorkoutTemplate? template;

  /// [template]'s id; kept for a recovered run whose plan is gone.
  final String? templateId;

  /// Every pause, in order; the last one is open while paused.
  final List<RunPauseMark> pauses;

  /// What is being recorded.
  final ActivityKind kind;

  RunSession copyWith({
    RunPhase? phase,
    RunTrack? track,
    List<RunPauseMark>? pauses,
  }) =>
      RunSession(
        phase: phase ?? this.phase,
        track: track ?? this.track,
        startedAt: startedAt,
        template: template,
        templateId: templateId,
        pauses: pauses ?? this.pauses,
        kind: kind,
      );
}

/// What happened during a run, for the voice.
sealed class RunEvent {
  const RunEvent();
}

class RunStarted extends RunEvent {
  const RunStarted();
}

class RunPaused extends RunEvent {
  const RunPaused();
}

class RunResumed extends RunEvent {
  const RunResumed();
}

class KmReached extends RunEvent {
  const KmReached(this.km, this.total, this.lastKmSecPerKm, this.avgSecPerKm);

  final int km;

  /// Moving time at this kilometre.
  final Duration total;
  final int lastKmSecPerKm;
  final int avgSecPerKm;
}

/// A ride passed another 5 km. Speeds in m/s.
class DistanceReached extends RunEvent {
  const DistanceReached(
      this.meters, this.total, this.lastSplitSpeed, this.avgSpeed);

  /// The split boundary passed (5000, 10000, ...).
  final int meters;

  /// Moving time at this boundary.
  final Duration total;
  final double lastSplitSpeed;
  final double avgSpeed;
}

/// A ski descent ended (a lift or a stop followed it). [index] counts from 1.
class SkiDescentDone extends RunEvent {
  const SkiDescentDone(this.index, this.meters, this.vertical, this.maxSpeed);

  final int index;
  final double meters, vertical;

  /// m/s.
  final double maxSpeed;
}

class RunFinished extends RunEvent {
  const RunFinished(this.meters, this.moving, this.avgSecPerKm);

  final double meters;
  final Duration moving;
  final int? avgSecPerKm;
}

/// Records a run: GPS fixes into a [RunTrack], km events for the voice, and
/// the recording itself under [runInProgressKey] (on start, pause and
/// resume, and at most every 10 s while fixes come in). A recording found
/// there when the app starts is restored, paused.
class RunRecorder extends StateNotifier<RunSession?> {
  RunRecorder({
    required LocationSource source,
    required SharedPreferences prefs,
    required void Function(CompletedWorkout) saveWorkout,
    required void Function(String id, RunDetails details) saveDetails,
    required WorkoutTemplate? Function(String id) templateById,
    required AppLocalizations Function() l10n,
    DateTime Function() now = DateTime.now,
    File? recordingFile,
  })  : _file = recordingFile == null ? null : RecordingFile(recordingFile),
        _source = source,
        _prefs = prefs,
        _saveWorkout = saveWorkout,
        _saveDetails = saveDetails,
        _templateById = templateById,
        _l10n = l10n,
        _now = now,
        super(null) {
    final restored = _restore();
    if (restored == null) {
      // No recording to come back to: a fix file left over (signed out, a
      // different account) is a location trail nobody owns.
      _file?.delete();
    } else {
      _pendingFromLaunch = true;
      state = restored;
      // The descents already done are not announced again.
      if (restored.kind == ActivityKind.ski) {
        final kept = restored.track.kept;
        _scanSki(restored.track, kept.isEmpty ? _now() : kept.last.at,
            emit: false);
      }
    }
  }

  final LocationSource _source;
  final SharedPreferences _prefs;
  final void Function(CompletedWorkout) _saveWorkout;
  final void Function(String id, RunDetails details) _saveDetails;
  final WorkoutTemplate? Function(String id) _templateById;
  final AppLocalizations Function() _l10n;
  final DateTime Function() _now;

  /// Where the fixes are kept while recording. Without it (tests) the fixes
  /// go into the prefs entry with the rest.
  final RecordingFile? _file;

  /// How many of the kept fixes are already in [_file].
  int _flushed = 0;

  final _events = StreamController<RunEvent>.broadcast();
  StreamSubscription<RunPoint>? _sub;
  DateTime? _lastSaved;
  Future<LocationAccess>? _startInFlight;

  /// When the fixes were last started, and the last fix that came in (kept
  /// or not), for [gpsStatus].
  DateTime? _listeningSince, _lastRawFixAt;
  double? _lastRawAccuracy;
  bool _preciseLocationOff = false;
  bool _pendingFromLaunch = false;

  // Ski only: when the day was last scanned for finished descents (fix
  // time), where the next scan starts in the kept fixes (the end of the last
  // descent reported), and how many descents were reported.
  DateTime? _skiScanAt;
  int _skiFrom = 0, _skiDone = 0;

  Stream<RunEvent> get events => _events.stream;

  /// Whether [state] is a run restored at launch that the user has not
  /// resumed, finished or discarded yet.
  bool get hasPendingRun => _pendingFromLaunch && state != null;

  /// Starts a run, ride or ski day (asking for location if needed). Does
  /// nothing and returns [LocationAccess.granted] while something is already
  /// being recorded. While a start is still asking for access, another call
  /// gets that same start's answer (and its recording), never a second one.
  Future<LocationAccess> start({
    ActivityKind kind = ActivityKind.run,
    WorkoutTemplate? template,
  }) {
    if (state != null) return Future.value(LocationAccess.granted);
    return _startInFlight ??=
        _start(kind, template).whenComplete(() => _startInFlight = null);
  }

  Future<LocationAccess> _start(
      ActivityKind kind, WorkoutTemplate? template) async {
    final access = await _source.ensureAccess();
    if (access != LocationAccess.granted || !mounted) return access;
    final at = _now();
    state = RunSession(
      phase: RunPhase.running,
      track: RunTrack(startedAt: at, profile: profileFor(kind)),
      startedAt: at,
      template: template,
      kind: kind,
    );
    _flushed = 0;
    try {
      _file?.reset();
    } catch (_) {
      // Recording goes on; the fixes are appended to what is there.
    }
    _listen();
    _persist();
    _emit(const RunStarted());
    return LocationAccess.granted;
  }

  void pause() {
    final s = state;
    if (s == null || s.phase != RunPhase.running) return;
    final at = _now();
    state = s.copyWith(
      phase: RunPhase.paused,
      track: s.track.pause(at),
      pauses: [...s.pauses, (pausedAt: at, resumedAt: null)],
    );
    _persist();
    _emit(const RunPaused());
  }

  void resume() {
    final s = state;
    if (s == null || s.phase != RunPhase.paused) return;
    final at = _now();
    _pendingFromLaunch = false;
    final open = s.pauses.isEmpty ? null : s.pauses.last;
    state = s.copyWith(
      phase: RunPhase.running,
      track: s.track.resume(at),
      pauses: [
        ...s.pauses.take(s.pauses.length - (open == null ? 0 : 1)),
        if (open != null) (pausedAt: open.pausedAt, resumedAt: at),
      ],
    );
    // A run restored after the app was killed has no fixes coming in yet.
    if (_sub == null) _listen();
    _persist();
    _emit(const RunResumed());
  }

  /// Saves the recording: a workout of the kind's sport and its
  /// [RunDetails] under the same id. Clears the recording. The duration is
  /// the moving time (a run, a ride with auto-stop) or, for a ski day, the
  /// day minus the time on lifts minus manual pauses.
  Future<CompletedWorkout> finish({int? rpe}) async {
    final s = state;
    if (s == null) throw StateError('No run to finish');
    final at = _now();
    final profile = profileFor(s.kind);
    final track = s.track.finish(at);
    final kept = track.kept;

    SkiDay? ski;
    // A ski day's distance is what was skied down, not the lifts.
    var meters = track.meters;
    List<RunPoint> route;
    Duration moving;
    if (s.kind == ActivityKind.ski) {
      final idx = simplifyRouteIndices(kept);
      route = [for (final i in idx) kept[i]];
      ski = skiDayFrom(kept, routeIndexMap(kept.length, idx));
      meters = ski.skiMeters;
      var paused = Duration.zero;
      for (final m in s.pauses) {
        paused += (m.resumedAt ?? at).difference(m.pausedAt);
      }
      moving = at.difference(s.startedAt) - ski.liftTime - paused;
      if (moving.isNegative) moving = Duration.zero;
    } else {
      route = simplifyRoute(kept);
      moving = s.track.movingTime(at);
    }

    final templateId = s.templateId ?? profile.freeTemplateId;
    final workout = CompletedWorkout(
      id: const Uuid().v4(),
      templateId: templateId,
      name:
          s.template?.name ?? defaultActivityName(_l10n(), s.kind, s.startedAt),
      sport: profile.sport,
      startedAt: s.startedAt,
      finishedAt: s.startedAt.add(moving),
      exercises: const [],
      sessionRpe: rpe,
    );
    // Load-bearing: the Health writer reads the distance right after this
    // synchronous pair, so details must be saved with no await between.
    _saveWorkout(workout);
    _saveDetails(
      workout.id,
      RunDetails(
        startedAt: s.startedAt,
        moving: moving,
        elapsed: at.difference(s.startedAt),
        pauses: s.pauses.length,
        meters: meters,
        elevationGain: track.elevationGain,
        splits: track.splits,
        route: [
          for (final p in route) [p.lat, p.lng],
        ],
        rpe: rpe,
        templateId: templateId,
        kind: s.kind,
        // A run's document stays as it always was.
        maxSpeed: s.kind == ActivityKind.run ? null : track.maxSpeed,
        elevationLoss: s.kind == ActivityKind.run ? null : track.elevationLoss,
        ski: ski,
      ),
    );
    await _end();
    _emit(RunFinished(meters, moving,
        s.kind == ActivityKind.run ? paceSecPerKm(meters, moving) : null));
    return workout;
  }

  /// Throws the run away.
  Future<void> discard() => _end();

  /// The time stamp of the last fix (kept or not) since the fixes started.
  DateTime? get lastRawFixAt => _lastRawFixAt;

  /// The accuracy of that fix, in metres.
  double? get lastRawAccuracy => _lastRawAccuracy;

  /// The device gives only approximate location, checked once each time the
  /// fixes start.
  bool get preciseLocationOff => _preciseLocationOff;

  /// [GpsStatus.waiting] until the run has a kept fix; then
  /// [GpsStatus.weak] when the last fix is older than [gpsStaleAfter] (or
  /// none came since the fixes started that long ago) or coarser than
  /// [maxFixAccuracy]. Null without a run, or while the fixes are not
  /// started (a restored run before Resume).
  GpsStatus? gpsStatus() {
    final s = state;
    final since = _lastRawFixAt ?? _listeningSince;
    if (s == null || _sub == null || since == null) return null;
    if (s.track.kept.isEmpty) return GpsStatus.waiting;
    if (_now().difference(since) > gpsStaleAfter) return GpsStatus.weak;
    final accuracy = _lastRawAccuracy;
    if (accuracy != null && accuracy > maxFixAccuracy) return GpsStatus.weak;
    return GpsStatus.good;
  }

  Future<void> _end() async {
    _pendingFromLaunch = false;
    state = null;
    _lastSaved = null;
    _skiScanAt = null;
    _skiFrom = _skiDone = 0;
    _listeningSince = _lastRawFixAt = _lastRawAccuracy = null;
    _preciseLocationOff = false;
    _file?.delete();
    _flushed = 0;
    await _prefs.remove(runInProgressKey);
    await _stopSource();
  }

  void _listen() {
    _listeningSince = _now();
    _lastRawFixAt = _lastRawAccuracy = null;
    final source = _source;
    if (source is KindAwareLocationSource) {
      source.useKind(state?.kind ?? ActivityKind.run);
    }
    _sub = _source.start().listen(_onPoint, onError: (Object _) {});
    _source.reducedAccuracy().then(
      (reduced) {
        if (mounted && _sub != null) _preciseLocationOff = reduced;
      },
      onError: (Object _) {},
    );
  }

  Future<void> _stopSource() async {
    final sub = _sub;
    _sub = null;
    await sub?.cancel();
    await _source.stop();
  }

  void _onPoint(RunPoint p) {
    _lastRawFixAt = p.at;
    _lastRawAccuracy = p.accuracy;
    final s = state;
    if (s == null || s.phase != RunPhase.running) return;
    final track = s.track.add(p);
    // Raw fixes drive the scan too: through a stop no fix is kept.
    if (s.kind == ActivityKind.ski) _scanSki(track, p.at);
    if (identical(track, s.track)) return;
    final before = _fullSplits(s.track);
    state = s.copyWith(track: track);
    _emitSplits(s.kind, before, track);
    _persist(throttled: true);
  }

  static int _fullSplits(RunTrack t) => t.meters ~/ t.profile.splitMeters;

  void _emitSplits(ActivityKind kind, int before, RunTrack track) {
    final after = _fullSplits(track);
    if (after <= before) return;
    final splits = track.splits;
    var totalMs = 0;
    for (var n = 1; n <= after && n <= splits.length; n++) {
      final split = splits[n - 1];
      totalMs += split.time.inMilliseconds;
      if (n <= before) continue;
      switch (kind) {
        case ActivityKind.run:
          _emit(KmReached(
            n,
            Duration(milliseconds: totalMs),
            (split.time.inMilliseconds / 1000).round(),
            (totalMs / 1000 / n).round(),
          ));
        case ActivityKind.ride:
          final secs = split.time.inMilliseconds / 1000;
          final metersDone = n * track.profile.splitMeters;
          _emit(DistanceReached(
            metersDone,
            Duration(milliseconds: totalMs),
            secs > 0 ? split.meters / secs : 0,
            totalMs > 0 ? metersDone / (totalMs / 1000) : 0,
          ));
        case ActivityKind.ski:
          break;
      }
    }
  }

  /// At most every [skiScanEvery] of fix time: segments the day from the end
  /// of the last reported descent and reports the descents that have ended
  /// (a lift or a stop followed them). Cheap enough for a 6-8 h day: it only
  /// looks at the fixes since the last reported descent.
  void _scanSki(RunTrack track, DateTime at, {bool emit = true}) {
    final last = _skiScanAt;
    if (emit && (last == null || at.difference(last) < skiScanEvery)) {
      _skiScanAt ??= at;
      return;
    }
    _skiScanAt = at;
    final kept = track.kept;
    if (_skiFrom >= kept.length - 1) return;
    final tail = _skiFrom == 0 ? kept : kept.sublist(_skiFrom);
    var advance = -1;
    for (final d in skiDayFrom(tail, const []).descents) {
      // Done when kept fixes show movement for a while after it (a lift,
      // the next run). Standing since then is not enough: it may be a
      // breather mid-descent, so that waits for the length of a real stop.
      final moved = tail.last.at.difference(d.end) >= skiDoneAfter;
      if (!moved && at.difference(d.end) < skiStopAfter) continue;
      _skiDone++;
      if (emit) {
        _emit(SkiDescentDone(_skiDone, d.meters, d.vertical, d.maxSpeed));
      }
      advance = tail.indexWhere((p) => !p.at.isBefore(d.end));
    }
    if (advance >= 0) _skiFrom += advance;
  }

  void _emit(RunEvent e) {
    if (!_events.isClosed) _events.add(e);
  }

  /// Saves the recording. With a [_file] the entry in the prefs is a small
  /// header (written when something other than fixes changes) and only the
  /// fixes kept since the last time are appended to the file, at most every
  /// [_saveEvery] while fixes come in.
  void _persist({bool throttled = false}) {
    final s = state;
    if (s == null) return;
    final now = _now();
    final last = _lastSaved;
    if (throttled && last != null && now.difference(last) < _saveEvery) {
      return;
    }
    _lastSaved = now;
    final file = _file;
    if (file == null) {
      _prefs.setString(runInProgressKey, jsonEncode(_toJson(s)));
      return;
    }
    try {
      final kept = s.track.kept;
      if (kept.length > _flushed) {
        file.append(kept.skip(_flushed), s.startedAt);
        _flushed = kept.length;
      }
    } catch (_) {
      // Disk full or gone: the header still says there was a recording.
    }
    if (!throttled) _prefs.setString(runInProgressKey, jsonEncode(_toJson(s)));
  }

  Map<String, Object?> _toJson(RunSession s) => {
        'startedAt': s.startedAt.toUtc().toIso8601String(),
        'templateId': s.templateId,
        // A run has no kind, as before this was added.
        if (s.kind != ActivityKind.run) 'kind': s.kind.name,
        'phase': s.phase.name,
        if (_file == null)
          // [lat, lng, alt, accuracy, ms since epoch]
          'points': [
            for (final p in s.track.kept)
              [p.lat, p.lng, p.alt, p.accuracy, p.at.millisecondsSinceEpoch],
          ],
        'pauses': [
          for (final m in s.pauses)
            [
              m.pausedAt.toUtc().toIso8601String(),
              if (m.resumedAt != null) m.resumedAt!.toUtc().toIso8601String(),
            ],
        ],
      };

  /// Rebuilds the saved run by replaying its fixes and pauses into a fresh
  /// track. A run that was still running when the app died is paused at
  /// its last saved moment, so the time the app was dead isn't moving time.
  RunSession? _restore() {
    final raw = _prefs.getString(runInProgressKey);
    if (raw == null) return null;
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      final startedAt = DateTime.parse(j['startedAt'] as String).toLocal();
      final kind =
          ActivityKind.values.asNameMap()[j['kind']] ?? ActivityKind.run;
      // A header has its fixes in the file; a payload with 'points' is the
      // old format (or no file is set up) and carries them itself.
      final legacy = j['points'] is List;
      final List<RunPoint> points;
      var damaged = false;
      if (legacy) {
        points = [
          for (final p in j['points'] as List)
            RunPoint(
              lat: ((p as List)[0] as num).toDouble(),
              lng: (p[1] as num).toDouble(),
              alt: (p[2] as num?)?.toDouble(),
              accuracy: (p[3] as num).toDouble(),
              at: DateTime.fromMillisecondsSinceEpoch((p[4] as num).toInt()),
            ),
        ];
      } else {
        final read = _file?.read(startedAt);
        if (read == null) return null;
        points = read.fixes;
        damaged = read.damaged;
      }
      final pauses = <RunPauseMark>[
        for (final m in j['pauses'] as List)
          (
            pausedAt: DateTime.parse((m as List)[0] as String).toLocal(),
            resumedAt:
                m.length > 1 ? DateTime.parse(m[1] as String).toLocal() : null,
          ),
      ];

      // A fix stamped after a pause was added after the resume (fixes are
      // stamped before they are delivered), so this order is the original.
      var track = RunTrack(startedAt: startedAt, profile: profileFor(kind));
      var i = 0;
      for (final m in pauses) {
        var to = i;
        while (to < points.length && !points[to].at.isAfter(m.pausedAt)) {
          to++;
        }
        track = track.addAll(points.getRange(i, to)).pause(m.pausedAt);
        i = to;
        if (m.resumedAt == null) break;
        track = track.resume(m.resumedAt!);
      }
      track = track.addAll(points.skip(i));

      if (!track.paused) {
        var lastAlive = startedAt;
        for (final t in [
          if (points.isNotEmpty) points.last.at,
          if (pauses.isNotEmpty && pauses.last.resumedAt != null)
            pauses.last.resumedAt!,
        ]) {
          if (t.isAfter(lastAlive)) lastAlive = t;
        }
        track = track.pause(lastAlive);
        pauses.add((pausedAt: lastAlive, resumedAt: null));
      }

      final templateId = j['templateId'] as String?;
      // Bring the file in line with what was restored (a cut-off line, or
      // the old format moving over) so new fixes append to it cleanly.
      final file = _file;
      if (file != null) {
        if (legacy || damaged || track.kept.length != points.length) {
          try {
            file.rewrite(track.kept, startedAt);
          } catch (_) {
            // The original file is left as it was.
          }
        }
        _flushed = track.kept.length;
        if (legacy) {
          final header = RunSession(
            phase: RunPhase.paused,
            track: track,
            startedAt: startedAt,
            templateId: templateId,
            pauses: pauses,
            kind: kind,
          );
          _prefs.setString(runInProgressKey, jsonEncode(_toJson(header)));
        }
      }
      return RunSession(
        phase: RunPhase.paused,
        track: track,
        startedAt: startedAt,
        template: templateId == null ? null : _templateById(templateId),
        templateId: templateId,
        pauses: pauses,
        kind: kind,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    // The app going away is not the run ending: the recording stays saved,
    // with the fixes since the last write (unless the entry was cleared, as
    // on sign-out).
    final s = state;
    final file = _file;
    if (s != null && file != null && _prefs.containsKey(runInProgressKey)) {
      try {
        final kept = s.track.kept;
        if (kept.length > _flushed) {
          file.append(kept.skip(_flushed), s.startedAt);
          _flushed = kept.length;
        }
      } catch (_) {}
    }
    _sub?.cancel();
    _sub = null;
    _source.stop();
    _events.close();
    super.dispose();
  }
}

/// "Morning run", "Evening run"… by the local hour the run started.
String defaultRunName(AppLocalizations l10n, DateTime startedAt) {
  final h = startedAt.toLocal().hour;
  if (h >= 5 && h < 12) return l10n.runNameMorning;
  if (h >= 12 && h < 17) return l10n.runNameAfternoon;
  if (h >= 17 && h < 22) return l10n.runNameEvening;
  return l10n.runNameNight;
}

/// "Morning ride", "Ski day"... by the kind and the local hour it started.
String defaultActivityName(
    AppLocalizations l10n, ActivityKind kind, DateTime startedAt) {
  switch (kind) {
    case ActivityKind.run:
      return defaultRunName(l10n, startedAt);
    case ActivityKind.ski:
      return l10n.skiDayName;
    case ActivityKind.ride:
      final h = startedAt.toLocal().hour;
      if (h >= 5 && h < 12) return l10n.rideNameMorning;
      if (h >= 12 && h < 17) return l10n.rideNameAfternoon;
      if (h >= 17 && h < 22) return l10n.rideNameEvening;
      return l10n.rideNameNight;
  }
}

final runRecorderProvider =
    StateNotifierProvider<RunRecorder, RunSession?>((ref) {
  return RunRecorder(
    source: ref.read(locationSourceProvider),
    prefs: ref.read(sharedPreferencesProvider),
    saveWorkout: (w) => ref.read(workoutHistoryProvider.notifier).add(w),
    saveDetails: (id, d) => ref.read(runsProvider.notifier).put(id, d),
    templateById: (id) =>
        ref.read(workoutTemplatesProvider).where((t) => t.id == id).firstOrNull,
    l10n: () =>
        lookupAppLocalizations(Locale(ref.read(selectedLanguageProvider))),
    now: ref.read(clockProvider),
    recordingFile: ref.read(recordingFileProvider),
  );
});

/// Where the fixes of the recording in progress are kept; null (tests) keeps
/// them in the prefs entry.
final recordingFileProvider = Provider<File?>((ref) => null);

/// A run found in [runInProgressKey] at launch (restored, paused) until the
/// user resumes, finishes or discards it.
final pendingRunProvider = Provider<RunSession?>((ref) {
  final session = ref.watch(runRecorderProvider);
  return ref.read(runRecorderProvider.notifier).hasPendingRun ? session : null;
});
