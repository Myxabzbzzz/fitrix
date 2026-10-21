import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

/// Fixes less accurate than this (metres) are dropped.
const double maxFixAccuracy = 25;

/// A fix implying a faster move than this (m/s) from the last kept fix is
/// dropped.
const double maxRunSpeed = 12;

/// Elevation changes smaller than this (metres) are noise.
const double elevationHysteresis = 3;

const _distance = Distance(roundResult: false);

double _between(RunPoint a, RunPoint b) =>
    _distance(LatLng(a.lat, a.lng), LatLng(b.lat, b.lng));

class RunPoint {
  const RunPoint({
    required this.lat,
    required this.lng,
    this.alt,
    required this.accuracy,
    required this.at,
  });

  final double lat, lng;
  final double? alt;

  /// Horizontal accuracy in metres.
  final double accuracy;
  final DateTime at;
}

class RunSplit {
  const RunSplit({required this.km, required this.meters, required this.time});

  /// 1-based; the last split may be partial (`meters < 1000`).
  final int km;
  final double meters;
  final Duration time;
}

/// The recorded line of a run. Immutable: every change returns a new track.
///
/// A fix is kept only when it is accurate enough, physically possible, and
/// outside twice its own accuracy from the last kept fix, so standing still
/// with a wandering GPS adds no distance. Moving time excludes pauses, and
/// the jump between the pause point and the resume point is not distance.
class RunTrack {
  RunTrack({DateTime? startedAt})
      : this._(
          start: startedAt,
          points: const [],
          count: 0,
          meters: 0,
          splits: const [],
          boundaryMeters: 0,
          boundaryMs: 0,
          pausedMs: 0,
          pausedAt: null,
          breakNext: false,
        );

  const RunTrack._({
    required DateTime? start,
    required List<RunPoint> points,
    required int count,
    required this.meters,
    required List<RunSplit> splits,
    required double boundaryMeters,
    required int boundaryMs,
    required int pausedMs,
    required DateTime? pausedAt,
    required bool breakNext,
  })  : _start = start,
        _points = points,
        _count = count,
        _done = splits,
        _boundaryMeters = boundaryMeters,
        _boundaryMs = boundaryMs,
        _pausedMs = pausedMs,
        _pausedAt = pausedAt,
        _breakNext = breakNext;

  final DateTime? _start;
  // Shared between versions of the track; this version sees the first _count.
  final List<RunPoint> _points;
  final int _count;
  final List<RunSplit> _done;
  // Distance and moving time at the last full-km boundary.
  final double _boundaryMeters;
  final int _boundaryMs;
  final int _pausedMs;
  final DateTime? _pausedAt;
  final bool _breakNext;

  /// Distance so far, metres.
  final double meters;

  bool get paused => _pausedAt != null;

  List<RunPoint> get kept => _points.length == _count
      ? List.unmodifiable(_points)
      : List.unmodifiable(_points.sublist(0, _count));

  RunPoint? get _last => _count == 0 ? null : _points[_count - 1];

  RunTrack _copy({
    DateTime? start,
    List<RunPoint>? points,
    int? count,
    double? meters,
    List<RunSplit>? splits,
    double? boundaryMeters,
    int? boundaryMs,
    int? pausedMs,
    Object? pausedAt = _keep,
    bool? breakNext,
  }) =>
      RunTrack._(
        start: start ?? _start,
        points: points ?? _points,
        count: count ?? _count,
        meters: meters ?? this.meters,
        splits: splits ?? _done,
        boundaryMeters: boundaryMeters ?? _boundaryMeters,
        boundaryMs: boundaryMs ?? _boundaryMs,
        pausedMs: pausedMs ?? _pausedMs,
        pausedAt:
            identical(pausedAt, _keep) ? _pausedAt : pausedAt as DateTime?,
        breakNext: breakNext ?? _breakNext,
      );

  static const Object _keep = Object();

  int _movingMsAt(DateTime at, DateTime start) =>
      math.max(0, at.difference(start).inMilliseconds - _pausedMs);

  /// Moving time at [now]; frozen at the pause time while paused.
  Duration movingTime(DateTime now) {
    final start = _start ?? _points.firstOrNull?.at;
    if (start == null) return Duration.zero;
    final end = _pausedAt ?? now;
    return Duration(milliseconds: _movingMsAt(end, start));
  }

  RunTrack pause(DateTime at) => paused ? this : _copy(pausedAt: at);

  RunTrack resume(DateTime at) {
    final since = _pausedAt;
    if (since == null) return this;
    return _copy(
      pausedMs: _pausedMs + at.difference(since).inMilliseconds,
      pausedAt: null,
      breakNext: true,
    );
  }

  RunTrack add(RunPoint p) {
    if (paused || p.accuracy > maxFixAccuracy) return this;
    final last = _last;
    final start = _start ?? p.at;
    final shared =
        _points.length == _count ? _points : _points.sublist(0, _count);
    if (last == null) {
      return _copy(start: start, points: [...shared, p], count: _count + 1);
    }
    if (p.at.isBefore(last.at)) return this;

    final d = _between(last, p);
    final secs = p.at.difference(last.at).inMilliseconds / 1000;
    if (_breakNext) {
      // First fix after a resume: a new starting point, no distance.
      return _copy(points: [...shared, p], count: _count + 1, breakNext: false);
    }
    if (secs > 0 && d / secs > maxRunSpeed) return this;
    if (d <= 2 * p.accuracy) return this;

    var total = meters + d;
    var done = _done;
    var bMeters = _boundaryMeters;
    var bMs = _boundaryMs;
    final t0 = _movingMsAt(last.at, start);
    final t1 = _movingMsAt(p.at, start);
    final from = meters;
    while (bMeters + 1000 <= total) {
      final cross = bMeters + 1000;
      final f = (cross - from) / d;
      final tCross = (t0 + (t1 - t0) * f).round();
      done = [
        ...done,
        RunSplit(
          km: done.length + 1,
          meters: 1000,
          time: Duration(milliseconds: tCross - bMs),
        ),
      ];
      bMeters = cross;
      bMs = tCross;
    }
    return _copy(
      start: start,
      points: [...shared, p],
      count: _count + 1,
      meters: total,
      splits: done,
      boundaryMeters: bMeters,
      boundaryMs: bMs,
    );
  }

  /// Full kilometres, then the partial rest (if any distance is left).
  List<RunSplit> get splits {
    final last = _last;
    final start = _start;
    if (last == null || start == null) return _done;
    final rest = meters - _boundaryMeters;
    if (rest <= 0.01) return _done;
    return [
      ..._done,
      RunSplit(
        km: _done.length + 1,
        meters: rest,
        time: Duration(
            milliseconds:
                math.max(0, _movingMsAt(last.at, start) - _boundaryMs)),
      ),
    ];
  }

  /// Total climb in metres, or null when fewer than 80 % of the kept points
  /// have an altitude. Changes under 3 m are ignored.
  double? get elevationGain {
    if (_count == 0) return null;
    final alts = <double>[
      for (var i = 0; i < _count; i++)
        if (_points[i].alt != null) _points[i].alt!,
    ];
    if (alts.length < _count * 0.8) return null;
    var ref = alts.first;
    var gain = 0.0;
    for (final a in alts.skip(1)) {
      if (a - ref >= elevationHysteresis) {
        gain += a - ref;
        ref = a;
      } else if (ref - a >= elevationHysteresis) {
        ref = a;
      }
    }
    return gain;
  }
}

/// Reduces [points] to at most [maxPoints] (Douglas-Peucker with a growing
/// tolerance), always keeping the first and the last.
List<RunPoint> simplifyRoute(List<RunPoint> points, {int maxPoints = 2000}) {
  if (points.length <= maxPoints || points.length < 3) return points;
  final lat0 = points.first.lat * math.pi / 180;
  const mPerDeg = 111195.0;
  final xs = [for (final p in points) p.lng * mPerDeg * math.cos(lat0)];
  final ys = [for (final p in points) p.lat * mPerDeg];

  List<int> pass(double tol) {
    final keep = List<bool>.filled(points.length, false);
    keep[0] = keep[points.length - 1] = true;
    final stack = <(int, int)>[(0, points.length - 1)];
    while (stack.isNotEmpty) {
      final (a, b) = stack.removeLast();
      var worst = -1.0;
      var at = -1;
      final dx = xs[b] - xs[a], dy = ys[b] - ys[a];
      final len = math.sqrt(dx * dx + dy * dy);
      for (var i = a + 1; i < b; i++) {
        final d = len == 0
            ? math.sqrt(math.pow(xs[i] - xs[a], 2) + math.pow(ys[i] - ys[a], 2))
            : ((xs[i] - xs[a]) * dy - (ys[i] - ys[a]) * dx).abs() / len;
        if (d > worst) {
          worst = d;
          at = i;
        }
      }
      if (at != -1 && worst > tol) {
        keep[at] = true;
        stack.add((a, at));
        stack.add((at, b));
      }
    }
    return [
      for (var i = 0; i < keep.length; i++)
        if (keep[i]) i,
    ];
  }

  var tol = 1.0;
  for (var i = 0; i < 40; i++) {
    final idx = pass(tol);
    if (idx.length <= maxPoints) return [for (final j in idx) points[j]];
    tol *= 1.5;
  }
  // Pathological input: an even sample.
  final step = (points.length - 1) / (maxPoints - 1);
  return [
    for (var i = 0; i < maxPoints; i++) points[(i * step).round()],
  ];
}

/// Seconds per kilometre, or null when [meters] is under 50.
int? paceSecPerKm(double meters, Duration time) {
  if (meters < 50) return null;
  return (time.inMilliseconds / 1000 / (meters / 1000)).round();
}

/// The `run` document (id = the workout id).
class RunDetails {
  const RunDetails({
    required this.startedAt,
    required this.moving,
    required this.elapsed,
    required this.pauses,
    required this.meters,
    this.elevationGain,
    required this.splits,
    required this.route,
    this.rpe,
    this.templateId,
  });

  final DateTime startedAt;
  final Duration moving, elapsed;
  final int pauses;
  final double meters;
  final double? elevationGain;
  final List<RunSplit> splits;

  /// `[[lat, lng], ...]`, simplified, 5 decimals.
  final List<List<double>> route;
  final int? rpe;
  final String? templateId;

  Map<String, Object?> toJson() => {
        'startedAt': startedAt.toUtc().toIso8601String(),
        'movingMs': moving.inMilliseconds,
        'elapsedMs': elapsed.inMilliseconds,
        'pauses': pauses,
        'meters': meters,
        if (elevationGain != null) 'elevationGain': elevationGain,
        'splits': [
          for (final s in splits)
            {'km': s.km, 'meters': s.meters, 'ms': s.time.inMilliseconds},
        ],
        'route': [
          for (final p in route) [_dp5(p[0]), _dp5(p[1])],
        ],
        if (rpe != null) 'rpe': rpe,
        if (templateId != null) 'templateId': templateId,
      };

  factory RunDetails.fromJson(Map<String, Object?> j) => RunDetails(
        startedAt: DateTime.parse(j['startedAt']! as String),
        moving: Duration(milliseconds: (j['movingMs']! as num).toInt()),
        elapsed: Duration(milliseconds: (j['elapsedMs']! as num).toInt()),
        pauses: (j['pauses']! as num).toInt(),
        meters: (j['meters']! as num).toDouble(),
        elevationGain: (j['elevationGain'] as num?)?.toDouble(),
        splits: [
          for (final s in j['splits']! as List)
            RunSplit(
              km: ((s as Map)['km']! as num).toInt(),
              meters: (s['meters']! as num).toDouble(),
              time: Duration(milliseconds: (s['ms']! as num).toInt()),
            ),
        ],
        route: [
          for (final p in j['route']! as List)
            [
              ((p as List)[0] as num).toDouble(),
              (p[1] as num).toDouble(),
            ],
        ],
        rpe: (j['rpe'] as num?)?.toInt(),
        templateId: j['templateId'] as String?,
      );
}

double _dp5(double v) => (v * 100000).round() / 100000;
