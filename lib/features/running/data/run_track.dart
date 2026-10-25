import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

import 'activity_kind.dart';
import 'ski_math.dart';

export 'activity_kind.dart';

/// Fixes less accurate than this (metres) are dropped.
const double maxFixAccuracy = 25;

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

  /// Whole km the split ends at (1, 2, 3 for km splits; 5, 10 for 5 km
  /// ones). The last split may be partial (`meters < splitMeters`); a partial
  /// 5 km split is labelled by its real distance (11 km ride: 11).
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
  RunTrack({DateTime? startedAt, ActivityProfile profile = runProfile})
      : this._(
          profile: profile,
          autoMs: 0,
          autoAt: startedAt,
          breaks: const [],
          start: startedAt,
          notBefore: startedAt,
          points: const [],
          meters: 0,
          splits: const [],
          boundaryMeters: 0,
          boundaryMs: 0,
          pausedMs: 0,
          pausedAt: null,
          breakNext: false,
          pending: null,
          finishedAt: null,
        );

  const RunTrack._({
    required this.profile,
    required int autoMs,
    required DateTime? autoAt,
    required List<int> breaks,
    required DateTime? start,
    required DateTime? notBefore,
    required List<RunPoint> points,
    required this.meters,
    required List<RunSplit> splits,
    required double boundaryMeters,
    required int boundaryMs,
    required int pausedMs,
    required DateTime? pausedAt,
    required bool breakNext,
    required RunPoint? pending,
    required DateTime? finishedAt,
  })  : _autoMs = autoMs,
        _autoAt = autoAt,
        _breaks = breaks,
        _start = start,
        _notBefore = notBefore,
        kept = points,
        _done = splits,
        _boundaryMeters = boundaryMeters,
        _boundaryMs = boundaryMs,
        _pausedMs = pausedMs,
        _pausedAt = pausedAt,
        _breakNext = breakNext,
        _pending = pending,
        _finishedAt = finishedAt;

  /// Speed cap, split length and auto-stop for this activity.
  final ActivityProfile profile;

  // Auto-stop only: moving ms banked up to [_autoAt] (the last kept fix, the
  // resume, or the start). Null [_autoAt] while paused.
  final int _autoMs;
  final DateTime? _autoAt;
  // Indexes into [kept] of fixes that start a new segment (after a resume).
  final List<int> _breaks;

  final DateTime? _start;
  // Fixes stamped before this (the start, then the last resume) are the
  // phone's cached location, not where the runner is now.
  final DateTime? _notBefore;
  final List<RunSplit> _done;
  // Distance and moving time at the last full-km boundary.
  final double _boundaryMeters;
  final int _boundaryMs;
  final int _pausedMs;
  final DateTime? _pausedAt;
  final bool _breakNext;
  // The latest good fix the step gate rejected; [finish] counts it.
  final RunPoint? _pending;
  final DateTime? _finishedAt;

  /// Distance so far, metres.
  final double meters;

  /// The fixes that passed the filter.
  final List<RunPoint> kept;

  bool get paused => _pausedAt != null;

  RunPoint? get _last => kept.isEmpty ? null : kept.last;

  static const Object _keep = Object();

  RunTrack _copy({
    int? autoMs,
    Object? autoAt = _keep,
    List<int>? breaks,
    DateTime? start,
    DateTime? notBefore,
    List<RunPoint>? points,
    double? meters,
    List<RunSplit>? splits,
    double? boundaryMeters,
    int? boundaryMs,
    int? pausedMs,
    Object? pausedAt = _keep,
    bool? breakNext,
    Object? pending = _keep,
    DateTime? finishedAt,
  }) =>
      RunTrack._(
        profile: profile,
        autoMs: autoMs ?? _autoMs,
        autoAt: identical(autoAt, _keep) ? _autoAt : autoAt as DateTime?,
        breaks: breaks ?? _breaks,
        start: start ?? _start,
        notBefore: notBefore ?? _notBefore,
        points: points ?? kept,
        meters: meters ?? this.meters,
        splits: splits ?? _done,
        boundaryMeters: boundaryMeters ?? _boundaryMeters,
        boundaryMs: boundaryMs ?? _boundaryMs,
        pausedMs: pausedMs ?? _pausedMs,
        pausedAt:
            identical(pausedAt, _keep) ? _pausedAt : pausedAt as DateTime?,
        breakNext: breakNext ?? _breakNext,
        pending: identical(pending, _keep) ? _pending : pending as RunPoint?,
        finishedAt: finishedAt ?? _finishedAt,
      );

  /// Auto-stop rule for the time between two kept fixes (or a fix and the
  /// clock) [gapMs] apart that covered [meters]: it counts in full when the
  /// average speed is at least 1 m/s; otherwise it is a stop and counts for at
  /// most a 10 s grace, so the clock runs ~10 s into a stop and then freezes.
  /// The same function serves the live tail, the banked gap and pause(), so
  /// moving time never goes backwards.
  static int _autoGapMs(int gapMs, double meters) {
    if (gapMs <= 0) return 0;
    if (meters / (gapMs / 1000) >= 1) return gapMs;
    return math.min(gapMs, 10000);
  }

  int _movingMsAt(DateTime at, DateTime start) {
    if (profile.autoStop) {
      final a = _autoAt;
      if (a == null || !at.isAfter(a)) return _autoMs;
      // Time after the last kept fix: at most the 10 s grace.
      return _autoMs + _autoGapMs(at.difference(a).inMilliseconds, 0);
    }
    return math.max(0, at.difference(start).inMilliseconds - _pausedMs);
  }

  /// Moving time at [now]; frozen at the pause time while paused.
  Duration movingTime(DateTime now) {
    final start = _start ?? kept.firstOrNull?.at;
    if (start == null) return Duration.zero;
    final end = _pausedAt ?? now;
    return Duration(milliseconds: _movingMsAt(end, start));
  }

  RunTrack pause(DateTime at) {
    if (paused) return this;
    if (!profile.autoStop) return _copy(pausedAt: at);
    final start = _start ?? kept.firstOrNull?.at;
    return _copy(
      pausedAt: at,
      autoMs: start == null ? _autoMs : _movingMsAt(at, start),
      autoAt: null,
    );
  }

  RunTrack resume(DateTime at) {
    final since = _pausedAt;
    if (since == null) return this;
    return _copy(
      pausedMs: _pausedMs + at.difference(since).inMilliseconds,
      pausedAt: null,
      breakNext: true,
      notBefore: at,
      autoAt: at,
    );
  }

  RunTrack add(RunPoint p) {
    if (paused || p.accuracy > maxFixAccuracy) return this;
    final notBefore = _notBefore;
    if (notBefore != null && p.at.isBefore(notBefore)) return this;
    final last = _last;
    if (last == null) {
      return _copy(
        start: _start ?? p.at,
        points: [p],
        autoMs: _autoMs + _autoGapMs(_gapFromAnchor(p), 0),
        autoAt: p.at,
      );
    }
    if (p.at.isBefore(last.at)) return this;
    if (_breakNext) {
      // First fix after a resume: a new starting point, no distance.
      return _copy(
        points: [...kept, p],
        breaks: [..._breaks, kept.length],
        breakNext: false,
        pending: null,
        autoMs: _autoMs + _autoGapMs(_gapFromAnchor(p), 0),
        autoAt: p.at,
      );
    }
    final d = _between(last, p);
    final secs = p.at.difference(last.at).inMilliseconds / 1000;
    if (secs > 0 && d / secs > profile.maxSpeed) return this;
    if (d <= 2 * p.accuracy) return _copy(pending: p);
    return _extend(p, d);
  }

  int _gapFromAnchor(RunPoint p) {
    final a = _autoAt;
    if (!profile.autoStop || a == null) return 0;
    return p.at.difference(a).inMilliseconds;
  }

  RunTrack _extend(RunPoint p, double d) {
    final last = _last!;
    final start = _start ?? kept.first.at;
    final total = meters + d;
    var done = _done;
    var bMeters = _boundaryMeters;
    var bMs = _boundaryMs;
    final split = profile.splitMeters;
    final int t0, t1;
    if (profile.autoStop) {
      t0 = _autoMs;
      t1 = _autoMs + _autoGapMs(p.at.difference(last.at).inMilliseconds, d);
    } else {
      t0 = _movingMsAt(last.at, start);
      t1 = _movingMsAt(p.at, start);
    }
    while (bMeters + split <= total) {
      final cross = bMeters + split;
      final f = (cross - meters) / d;
      final tCross = (t0 + (t1 - t0) * f).round();
      done = [
        ...done,
        RunSplit(
          km: _label(done.length + 1),
          meters: split.toDouble(),
          time: Duration(milliseconds: tCross - bMs),
        ),
      ];
      bMeters = cross;
      bMs = tCross;
    }
    return _copy(
      points: [...kept, p],
      meters: total,
      autoMs: t1,
      autoAt: p.at,
      splits: done,
      boundaryMeters: bMeters,
      boundaryMs: bMs,
      pending: null,
    );
  }

  /// Ends the run at [at]: counts the last good fix the step gate held back
  /// (if its speed is plausible) and ends the last split at [at], so the
  /// splits add up to the moving time.
  RunTrack finish(DateTime at) {
    var track = this;
    final p = _pending;
    final last = _last;
    if (!paused && p != null && last != null && !p.at.isBefore(last.at)) {
      final d = _between(last, p);
      final secs = p.at.difference(last.at).inMilliseconds / 1000;
      if (secs <= 0 || d / secs <= profile.maxSpeed) track = _extend(p, d);
    }
    return track._copy(pending: null, finishedAt: at);
  }

  // Whole km a split ends at: 1, 2, 3 for km splits; 5, 10 for 5 km ones. A
  // partial split of a longer split length is labelled by its real distance
  // (11 km ride -> 11), never past the distance covered.
  int _label(int index, {bool partial = false}) {
    final split = profile.splitMeters;
    if (split == 1000) return index;
    if (!partial) return index * split ~/ 1000;
    return math.max((index - 1) * split ~/ 1000 + 1, (meters / 1000).round());
  }

  /// Full splits, then the partial rest (if any distance is left).
  List<RunSplit> get splits {
    final last = _last;
    final start = _start;
    if (last == null || start == null) return _done;
    final rest = meters - _boundaryMeters;
    if (rest <= 0.01) return _done;
    final end = _pausedAt ?? _finishedAt ?? last.at;
    return [
      ..._done,
      RunSplit(
        km: _label(_done.length + 1, partial: true),
        meters: rest,
        time: Duration(
            milliseconds: math.max(0, _movingMsAt(end, start) - _boundaryMs)),
      ),
    ];
  }

  /// Total climb in metres, or null when fewer than 80 % of the kept points
  /// have an altitude. Changes under 3 m are ignored.
  double? get elevationGain => _elevation()?.$1;

  /// Total descent in metres; same rules as [elevationGain].
  double? get elevationLoss => _elevation()?.$2;

  (double, double)? _elevation() {
    if (kept.isEmpty) return null;
    final alts = <double>[
      for (final p in kept)
        if (p.alt != null) p.alt!,
    ];
    if (alts.length < kept.length * 0.8) return null;
    var ref = alts.first;
    var gain = 0.0, loss = 0.0;
    for (final a in alts.skip(1)) {
      if (a - ref >= elevationHysteresis) {
        gain += a - ref;
        ref = a;
      } else if (ref - a >= elevationHysteresis) {
        loss += ref - a;
        ref = a;
      }
    }
    return (gain, loss);
  }

  /// Top speed in m/s: over each stretch of at least 3 s of kept fixes, the
  /// median of its fix-to-fix speeds (the lower middle for an even count), so
  /// one jumpy fix doesn't count. Null when the track is shorter than that.
  double? get maxSpeed => robustMaxSpeed(kept, breaks: _breaks);
}

/// Top speed in m/s of the fixes [from]..[to] (default all). The speed at a
/// fix is the displacement over the shortest stretch of at least 3 s ending
/// there (endpoint distance over time, so position jitter does not add up
/// like it does fix to fix); the top speed is the highest *median* of the
/// speeds of the neighbouring stretches (as many as a bad fix can touch, and
/// then some), so one jumpy fix is rejected. [breaks] are indexes of fixes
/// that start a new segment (no speed across them). Null when no stretch of
/// 3 s exists.
double? robustMaxSpeed(List<RunPoint> kept,
    {List<int> breaks = const [], int from = 0, int? to}) {
  final end = to ?? kept.length - 1;
  if (end - from < 1) return null;
  final w = List<double?>.filled(end - from + 1, null);
  final len = List<int>.filled(end - from + 1, 0);
  var j = from;
  var segStart = from;
  var breakAt = 0;
  while (breakAt < breaks.length && breaks[breakAt] <= from) {
    breakAt++;
  }
  for (var i = from + 1; i <= end; i++) {
    if (breakAt < breaks.length && breaks[breakAt] == i) {
      segStart = i;
      breakAt++;
      continue;
    }
    if (j < segStart) j = segStart;
    while (j + 1 < i &&
        kept[i].at.difference(kept[j + 1].at).inMilliseconds >= 3000) {
      j++;
    }
    final ms = kept[i].at.difference(kept[j].at).inMilliseconds;
    if (ms < 3000) continue;
    w[i - from] = _between(kept[j], kept[i]) / (ms / 1000);
    len[i - from] = i - j + 1;
  }
  double? best;
  for (var i = 1; i < w.length; i++) {
    if (w[i] == null) continue;
    final block = <double>[];
    for (var m = i; m >= 1 && block.length < 4 * len[i] + 1; m--) {
      final x = w[m];
      if (x == null) break;
      block.add(x);
    }
    block.sort();
    final med = block[(block.length - 1) ~/ 2];
    if (best == null || med > best) best = med;
  }
  return best;
}

/// Reduces [points] to at most [maxPoints] (Douglas-Peucker with a growing
/// tolerance), always keeping the first and the last.
List<RunPoint> simplifyRoute(List<RunPoint> points, {int maxPoints = 2000}) {
  if (points.length <= maxPoints || points.length < 3) return points;
  return [
    for (final i in simplifyRouteIndices(points, maxPoints: maxPoints))
      points[i],
  ];
}

/// The indexes into [points] that [simplifyRoute] keeps (ascending, first and
/// last included).
List<int> simplifyRouteIndices(List<RunPoint> points, {int maxPoints = 2000}) {
  if (points.length <= maxPoints || points.length < 3) {
    return List<int>.generate(points.length, (i) => i);
  }
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
    if (idx.length <= maxPoints) return idx;
    tol *= 1.5;
  }
  // Pathological input: an even sample.
  final step = (points.length - 1) / (maxPoints - 1);
  return [
    for (var i = 0; i < maxPoints; i++) (i * step).round(),
  ];
}

/// Seconds per kilometre, or null when [meters] is under 50.
int? paceSecPerKm(double meters, Duration time) {
  if (meters < 50) return null;
  return (time.inMilliseconds / 1000 / (meters / 1000)).round();
}

/// Google encoded polyline (precision 5) of `[[lat, lng], ...]`.
String encodePolyline(List<List<double>> points) {
  final out = StringBuffer();
  var pLat = 0, pLng = 0;
  void put(int v) {
    var n = v < 0 ? ~(v << 1) : v << 1;
    while (n >= 0x20) {
      out.writeCharCode((0x20 | (n & 0x1f)) + 63);
      n >>= 5;
    }
    out.writeCharCode(n + 63);
  }

  for (final p in points) {
    final lat = (p[0] * 1e5).round(), lng = (p[1] * 1e5).round();
    put(lat - pLat);
    put(lng - pLng);
    pLat = lat;
    pLng = lng;
  }
  return out.toString();
}

List<List<double>> decodePolyline(String encoded) {
  final out = <List<double>>[];
  var i = 0, lat = 0, lng = 0;
  int next() {
    var shift = 0, result = 0;
    int b;
    do {
      b = encoded.codeUnitAt(i++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    return (result & 1) != 0 ? ~(result >> 1) : result >> 1;
  }

  while (i < encoded.length) {
    lat += next();
    lng += next();
    out.add([lat / 1e5, lng / 1e5]);
  }
  return out;
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
    required List<List<double>> route,
    this.rpe,
    this.templateId,
    this.kind = ActivityKind.run,
    this.maxSpeed,
    this.elevationLoss,
    this.indoor = false,
    this.avgPowerW,
    this.ski,
  }) : _route = route;

  final DateTime startedAt;
  final Duration moving, elapsed;
  final int pauses;
  final double meters;
  final double? elevationGain;
  final List<RunSplit> splits;

  final List<List<double>> _route;

  /// `[[lat, lng], ...]`, simplified, 5 decimals. Stored as an encoded
  /// polyline so a long run stays under the server's 64 KB limit.
  List<List<double>> get route => _route;
  final int? rpe;
  final String? templateId;

  /// What was recorded; a document without it is a run.
  final ActivityKind kind;

  /// Top speed, m/s.
  final double? maxSpeed;
  final double? elevationLoss;

  /// A ride on a trainer: [meters] is the entered km x 1000, or 0 when
  /// unknown.
  final bool indoor;
  final int? avgPowerW;

  /// Descents and lifts of a ski day.
  final SkiDay? ski;

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
        'polyline': encodePolyline(route),
        if (rpe != null) 'rpe': rpe,
        if (templateId != null) 'templateId': templateId,
        if (kind != ActivityKind.run) 'kind': kind.name,
        if (maxSpeed != null) 'maxSpeed': maxSpeed,
        if (elevationLoss != null) 'elevationLoss': elevationLoss,
        if (indoor) 'indoor': true,
        if (avgPowerW != null) 'avgPowerW': avgPowerW,
        if (ski != null) 'ski': ski!.toJson(),
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
        route: _routeFrom(j),
        rpe: (j['rpe'] as num?)?.toInt(),
        templateId: j['templateId'] as String?,
        kind: ActivityKind.values.asNameMap()[j['kind']] ?? ActivityKind.run,
        maxSpeed: (j['maxSpeed'] as num?)?.toDouble(),
        elevationLoss: (j['elevationLoss'] as num?)?.toDouble(),
        indoor: j['indoor'] == true,
        avgPowerW: (j['avgPowerW'] as num?)?.toInt(),
        ski: j['ski'] is Map
            ? SkiDay.fromJson((j['ski']! as Map).cast<String, Object?>())
            : null,
      );
}

List<List<double>> _routeFrom(Map<String, Object?> j) {
  final poly = j['polyline'];
  if (poly is String) return decodePolyline(poly);
  // Older docs kept the points as an array.
  final old = j['route'];
  if (old is List) {
    return [
      for (final p in old)
        [((p as List)[0] as num).toDouble(), (p[1] as num).toDouble()],
    ];
  }
  return const [];
}
