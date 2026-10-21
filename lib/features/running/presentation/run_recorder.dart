import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'package:fitrix/core/session/session_providers.dart';
import 'package:fitrix/core/time/today_provider.dart';
import 'package:fitrix/features/language/presentation/providers/language_provider.dart';
import 'package:fitrix/features/running/data/location_source.dart';
import 'package:fitrix/features/running/data/run_store.dart';
import 'package:fitrix/features/running/data/run_track.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/features/workouts/presentation/providers/workouts_provider.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

/// Prefs key of the run being recorded, so it survives the app being killed.
const runInProgressKey = 'run_in_progress_v1';

/// Template id of a run started without a plan.
const freeRunTemplateId = 'free_run';

/// How often (at most) the recording is written while fixes come in.
const _saveEvery = Duration(seconds: 10);

enum RunPhase { idle, running, paused }

typedef RunPauseMark = ({DateTime pausedAt, DateTime? resumedAt});

class RunSession {
  RunSession({
    required this.phase,
    required this.track,
    required this.startedAt,
    this.template,
    String? templateId,
    this.pauses = const [],
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
  })  : _source = source,
        _prefs = prefs,
        _saveWorkout = saveWorkout,
        _saveDetails = saveDetails,
        _templateById = templateById,
        _l10n = l10n,
        _now = now,
        super(null) {
    final restored = _restore();
    if (restored != null) {
      _pendingFromLaunch = true;
      state = restored;
    }
  }

  final LocationSource _source;
  final SharedPreferences _prefs;
  final void Function(CompletedWorkout) _saveWorkout;
  final void Function(String id, RunDetails details) _saveDetails;
  final WorkoutTemplate? Function(String id) _templateById;
  final AppLocalizations Function() _l10n;
  final DateTime Function() _now;

  final _events = StreamController<RunEvent>.broadcast();
  StreamSubscription<RunPoint>? _sub;
  DateTime? _lastSaved;
  bool _starting = false;
  bool _pendingFromLaunch = false;

  Stream<RunEvent> get events => _events.stream;

  /// Whether [state] is a run restored at launch that the user has not
  /// resumed, finished or discarded yet.
  bool get hasPendingRun => _pendingFromLaunch && state != null;

  /// Starts a run (asking for location if needed). Does nothing and returns
  /// [LocationAccess.granted] while a run is already being recorded.
  Future<LocationAccess> start({WorkoutTemplate? template}) async {
    if (state != null || _starting) return LocationAccess.granted;
    _starting = true;
    try {
      final access = await _source.ensureAccess();
      if (access != LocationAccess.granted || !mounted) return access;
      final at = _now();
      state = RunSession(
        phase: RunPhase.running,
        track: RunTrack(startedAt: at),
        startedAt: at,
        template: template,
      );
      _listen();
      _persist();
      _emit(const RunStarted());
      return LocationAccess.granted;
    } finally {
      _starting = false;
    }
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

  /// Saves the run: a running workout (duration = moving time) and its
  /// [RunDetails] under the same id. Clears the recording.
  Future<CompletedWorkout> finish({int? rpe}) async {
    final s = state;
    if (s == null) throw StateError('No run to finish');
    final at = _now();
    final moving = s.track.movingTime(at);
    final track = s.track.finish(at);
    final templateId = s.templateId ?? freeRunTemplateId;
    final workout = CompletedWorkout(
      id: const Uuid().v4(),
      templateId: templateId,
      name: s.template?.name ?? defaultRunName(_l10n(), s.startedAt),
      sport: Sport.running,
      startedAt: s.startedAt,
      finishedAt: s.startedAt.add(moving),
      exercises: const [],
      sessionRpe: rpe,
    );
    _saveWorkout(workout);
    _saveDetails(
      workout.id,
      RunDetails(
        startedAt: s.startedAt,
        moving: moving,
        elapsed: at.difference(s.startedAt),
        pauses: s.pauses.length,
        meters: track.meters,
        elevationGain: track.elevationGain,
        splits: track.splits,
        route: [
          for (final p in simplifyRoute(track.kept)) [p.lat, p.lng],
        ],
        rpe: rpe,
        templateId: templateId,
      ),
    );
    await _end();
    _emit(RunFinished(track.meters, moving, paceSecPerKm(track.meters, moving)));
    return workout;
  }

  /// Throws the run away.
  Future<void> discard() => _end();

  Future<void> _end() async {
    _pendingFromLaunch = false;
    state = null;
    _lastSaved = null;
    await _prefs.remove(runInProgressKey);
    await _stopSource();
  }

  void _listen() {
    _sub = _source.start().listen(_onPoint, onError: (Object _) {});
  }

  Future<void> _stopSource() async {
    final sub = _sub;
    _sub = null;
    await sub?.cancel();
    await _source.stop();
  }

  void _onPoint(RunPoint p) {
    final s = state;
    if (s == null || s.phase != RunPhase.running) return;
    final track = s.track.add(p);
    if (identical(track, s.track)) return;
    final kmBefore = _fullKm(s.track);
    state = s.copyWith(track: track);
    _emitKms(kmBefore, track);
    _persist(throttled: true);
  }

  static int _fullKm(RunTrack t) => t.meters ~/ 1000;

  void _emitKms(int before, RunTrack track) {
    final after = _fullKm(track);
    if (after <= before) return;
    final splits = track.splits;
    for (var km = before + 1; km <= after && km <= splits.length; km++) {
      var totalMs = 0;
      for (final split in splits.take(km)) {
        totalMs += split.time.inMilliseconds;
      }
      _emit(KmReached(
        km,
        Duration(milliseconds: totalMs),
        (splits[km - 1].time.inMilliseconds / 1000).round(),
        (totalMs / 1000 / km).round(),
      ));
    }
  }

  void _emit(RunEvent e) {
    if (!_events.isClosed) _events.add(e);
  }

  void _persist({bool throttled = false}) {
    final s = state;
    if (s == null) return;
    final now = _now();
    final last = _lastSaved;
    if (throttled && last != null && now.difference(last) < _saveEvery) {
      return;
    }
    _lastSaved = now;
    _prefs.setString(runInProgressKey, jsonEncode(_toJson(s)));
  }

  static Map<String, Object?> _toJson(RunSession s) => {
        'startedAt': s.startedAt.toUtc().toIso8601String(),
        'templateId': s.templateId,
        'phase': s.phase.name,
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
      final points = [
        for (final p in j['points'] as List)
          RunPoint(
            lat: ((p as List)[0] as num).toDouble(),
            lng: (p[1] as num).toDouble(),
            alt: (p[2] as num?)?.toDouble(),
            accuracy: (p[3] as num).toDouble(),
            at: DateTime.fromMillisecondsSinceEpoch((p[4] as num).toInt()),
          ),
      ];
      final pauses = <RunPauseMark>[
        for (final m in j['pauses'] as List)
          (
            pausedAt: DateTime.parse((m as List)[0] as String).toLocal(),
            resumedAt: m.length > 1
                ? DateTime.parse(m[1] as String).toLocal()
                : null,
          ),
      ];

      // A fix stamped after a pause was added after the resume (fixes are
      // stamped before they are delivered), so this order is the original.
      var track = RunTrack(startedAt: startedAt);
      var i = 0;
      for (final m in pauses) {
        while (i < points.length && !points[i].at.isAfter(m.pausedAt)) {
          track = track.add(points[i++]);
        }
        track = track.pause(m.pausedAt);
        if (m.resumedAt == null) break;
        track = track.resume(m.resumedAt!);
      }
      while (i < points.length) {
        track = track.add(points[i++]);
      }

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
      return RunSession(
        phase: RunPhase.paused,
        track: track,
        startedAt: startedAt,
        template: templateId == null ? null : _templateById(templateId),
        templateId: templateId,
        pauses: pauses,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    // The app going away is not the run ending: the recording stays saved.
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

final runRecorderProvider =
    StateNotifierProvider<RunRecorder, RunSession?>((ref) {
  return RunRecorder(
    source: ref.read(locationSourceProvider),
    prefs: ref.read(sharedPreferencesProvider),
    saveWorkout: (w) => ref.read(workoutHistoryProvider.notifier).add(w),
    saveDetails: (id, d) => ref.read(runsProvider.notifier).put(id, d),
    templateById: (id) => ref
        .read(workoutTemplatesProvider)
        .where((t) => t.id == id)
        .firstOrNull,
    l10n: () =>
        lookupAppLocalizations(Locale(ref.read(selectedLanguageProvider))),
    now: ref.read(clockProvider),
  );
});

/// A run found in [runInProgressKey] at launch (restored, paused) until the
/// user resumes, finishes or discards it.
final pendingRunProvider = Provider<RunSession?>((ref) {
  final session = ref.watch(runRecorderProvider);
  return ref.read(runRecorderProvider.notifier).hasPendingRun ? session : null;
});
