import 'package:latlong2/latlong.dart';

import 'run_track.dart';

/// Altitude is median-smoothed over this much time (centred).
const Duration skiSmoothing = Duration(seconds: 30);

/// A turn in altitude counts only after it moved this far (metres).
const double skiHysteresis = 15;

/// Minimum drop of a descent / gain of a lift (metres).
const double skiMinVertical = 30;

/// A lift climbs at least this fast (m/s) ...
const double skiLiftMinClimb = 0.5;

/// ... and moves along the ground no faster than this (m/s).
const double skiLiftMaxSpeed = 8;

const _distance = Distance(roundResult: false);

enum SkiSegmentKind { descent, lift, other }

/// A stretch of the day; [from] and [to] index the fixes (inclusive).
class SkiSegment {
  const SkiSegment(this.kind, this.from, this.to, [this.vertical = 0]);
  final SkiSegmentKind kind;
  final int from, to;

  /// Altitude change of the whole leg (metres, positive), measured between
  /// its smoothed extremes; 0 for "other".
  final double vertical;
}

/// Altitude within this of a leg's end still counts as standing at the end
/// (queue, waiting, noise), so it is trimmed off the leg (metres).
const double _skiTrim = 8;

class SkiDescent {
  const SkiDescent({
    required this.start,
    required this.end,
    required this.meters,
    required this.vertical,
    required this.maxSpeed,
    required this.avgSpeed,
    required this.routeFrom,
    required this.routeTo,
  });

  final DateTime start, end;

  /// Distance along the track, metres.
  final double meters;

  /// Altitude lost, metres (positive).
  final double vertical;

  /// m/s.
  final double maxSpeed, avgSpeed;

  /// Index range into the stored (simplified) route.
  final int routeFrom, routeTo;

  Map<String, Object?> toJson() => {
        'start': start.toUtc().toIso8601String(),
        'end': end.toUtc().toIso8601String(),
        'meters': meters,
        'vertical': vertical,
        'maxSpeed': maxSpeed,
        'avgSpeed': avgSpeed,
        'from': routeFrom,
        'to': routeTo,
      };

  factory SkiDescent.fromJson(Map<String, Object?> j) => SkiDescent(
        start: DateTime.parse(j['start']! as String),
        end: DateTime.parse(j['end']! as String),
        meters: (j['meters']! as num).toDouble(),
        vertical: (j['vertical']! as num).toDouble(),
        maxSpeed: (j['maxSpeed']! as num).toDouble(),
        avgSpeed: (j['avgSpeed']! as num).toDouble(),
        routeFrom: (j['from']! as num).toInt(),
        routeTo: (j['to']! as num).toInt(),
      );
}

class SkiDay {
  const SkiDay({
    required this.descents,
    required this.lifts,
    required this.liftTime,
  });

  final List<SkiDescent> descents;
  final int lifts;
  final Duration liftTime;

  /// Total altitude lost on descents, metres.
  double get verticalDown => descents.fold(0.0, (a, d) => a + d.vertical);

  /// Distance of the descents only, metres.
  double get skiMeters => descents.fold(0.0, (a, d) => a + d.meters);

  double? get maxSpeed => descents.isEmpty
      ? null
      : descents.map((d) => d.maxSpeed).reduce((a, b) => a > b ? a : b);

  /// Distance over time of the descents, m/s.
  double? get avgDescentSpeed {
    final ms = descents.fold<int>(
        0, (a, d) => a + d.end.difference(d.start).inMilliseconds);
    return ms <= 0 ? null : skiMeters / (ms / 1000);
  }

  Map<String, Object?> toJson() => {
        'descents': [for (final d in descents) d.toJson()],
        'lifts': lifts,
        'liftMs': liftTime.inMilliseconds,
      };

  factory SkiDay.fromJson(Map<String, Object?> j) => SkiDay(
        descents: [
          for (final d in (j['descents'] as List? ?? const []))
            SkiDescent.fromJson((d as Map).cast<String, Object?>()),
        ],
        lifts: (j['lifts'] as num?)?.toInt() ?? 0,
        liftTime: Duration(milliseconds: (j['liftMs'] as num?)?.toInt() ?? 0),
      );
}

/// Altitude per fix, median-smoothed over [skiSmoothing]; fixes without one
/// take the nearest earlier (or first known) value. Empty when none has one.
List<double> _smoothedAltitude(List<RunPoint> fixes) {
  final raw = List<double?>.generate(fixes.length, (i) => fixes[i].alt);
  final first = raw.indexWhere((a) => a != null);
  if (first < 0) return const [];
  var prev = raw[first]!;
  final alt = List<double>.filled(fixes.length, 0);
  for (var i = 0; i < raw.length; i++) {
    prev = raw[i] ?? prev;
    alt[i] = prev;
  }
  final half = skiSmoothing.inMilliseconds ~/ 2;
  final out = List<double>.filled(fixes.length, 0);
  var lo = 0, hi = 0;
  for (var i = 0; i < fixes.length; i++) {
    final t = fixes[i].at.millisecondsSinceEpoch;
    while (fixes[lo].at.millisecondsSinceEpoch < t - half) {
      lo++;
    }
    if (hi < i) hi = i;
    while (hi + 1 < fixes.length &&
        fixes[hi + 1].at.millisecondsSinceEpoch <= t + half) {
      hi++;
    }
    final w = alt.sublist(lo, hi + 1)..sort();
    out[i] = w[(w.length - 1) ~/ 2];
  }
  return out;
}

class _Pivot {
  _Pivot(this.first, this.last, this.peak);
  final int first, last;
  final bool peak;
}

List<SkiSegment> _segment(List<RunPoint> fixes, List<double> alt) {
  final n = fixes.length;
  if (n == 0) return const [];
  if (alt.isEmpty || n < 2) {
    return [SkiSegment(SkiSegmentKind.other, 0, n - 1)];
  }

  // Direction changes with hysteresis on the smoothed altitude.
  final pivots = <_Pivot>[];
  var dir = 0; // 0 unknown, 1 up, -1 down
  var maxV = alt[0], maxF = 0, maxL = 0;
  var minV = alt[0], minF = 0, minL = 0;
  for (var i = 1; i < n; i++) {
    final v = alt[i];
    if (v > maxV) {
      maxV = v;
      maxF = maxL = i;
    } else if (v == maxV) {
      maxL = i;
    }
    if (v < minV) {
      minV = v;
      minF = minL = i;
    } else if (v == minV) {
      minL = i;
    }
    if (dir != -1 && v <= maxV - skiHysteresis) {
      pivots.add(_Pivot(maxF, maxL, true));
      dir = -1;
      minV = v;
      minF = minL = i;
    } else if (dir != 1 && v >= minV + skiHysteresis) {
      pivots.add(_Pivot(minF, minL, false));
      dir = 1;
      maxV = v;
      maxF = maxL = i;
    }
  }

  final out = <SkiSegment>[];
  void add(SkiSegmentKind k, int from, int to, [double rise = 0]) {
    if (to > from) out.add(SkiSegment(k, from, to, rise));
  }

  // A leg from [from] to [to] (its extremes): trims the flat bits at both
  // ends, then decides what it is.
  void leg(int from, int to, bool up) {
    if (to <= from) return;
    final rise = (alt[to] - alt[from]).abs();
    var a = from, b = to;
    while (a < b && (alt[a + 1] - alt[from]).abs() <= _skiTrim) {
      a++;
    }
    while (b > a && (alt[b - 1] - alt[to]).abs() <= _skiTrim) {
      b--;
    }
    var kind = SkiSegmentKind.other;
    final secs = fixes[b].at.difference(fixes[a].at).inMilliseconds / 1000;
    if (rise >= skiMinVertical && b > a) {
      if (!up) {
        kind = SkiSegmentKind.descent;
      } else if (secs > 0 && rise / secs >= skiLiftMinClimb) {
        var meters = 0.0;
        for (var i = a + 1; i <= b; i++) {
          meters += _step(fixes[i - 1], fixes[i]);
        }
        if (meters / secs <= skiLiftMaxSpeed) kind = SkiSegmentKind.lift;
      }
    }
    if (kind == SkiSegmentKind.other) {
      add(kind, from, to);
      return;
    }
    add(SkiSegmentKind.other, from, a);
    add(kind, a, b, rise);
    add(SkiSegmentKind.other, b, to);
  }

  var start = 0;
  for (final p in pivots) {
    // The leg ends at the first fix of the extreme; the flat bit around it
    // (queue at the bottom, waiting at the top) is "other".
    leg(start, p.first, p.peak);
    add(SkiSegmentKind.other, p.first, p.last);
    start = p.last;
  }
  if (dir == 0) {
    add(SkiSegmentKind.other, 0, n - 1);
  } else {
    final end = dir == 1 ? maxF : minF;
    leg(start, end, dir == 1);
    add(SkiSegmentKind.other, end, n - 1);
  }
  return out;
}

double _step(RunPoint a, RunPoint b) =>
    _distance(LatLng(a.lat, a.lng), LatLng(b.lat, b.lng));

/// Splits a ski day into descents, lifts and the rest. Segments are in time
/// order and share their boundary fix.
List<SkiSegment> segmentSki(List<RunPoint> fixes) =>
    _segment(fixes, _smoothedAltitude(fixes));

/// For each of [fixCount] fixes, the position in the simplified route (whose
/// kept fix indexes are [kept], ascending) of the kept fix nearest to it.
List<int> routeIndexMap(int fixCount, List<int> kept) {
  if (kept.isEmpty) return List<int>.filled(fixCount, 0);
  final out = List<int>.filled(fixCount, 0);
  var k = 0;
  for (var i = 0; i < fixCount; i++) {
    while (k + 1 < kept.length && kept[k + 1] <= i) {
      k++;
    }
    final next = k + 1 < kept.length ? kept[k + 1] : null;
    out[i] = next != null && next - i < i - kept[k] ? k + 1 : k;
  }
  return out;
}

/// The day's descents with their stats and the lift count and time.
/// [keptIndexMap] maps a fix index to its simplified-route index (see
/// [routeIndexMap]); an empty or short map falls back to the fix index.
SkiDay skiDayFrom(List<RunPoint> fixes, List<int> keptIndexMap) {
  final alt = _smoothedAltitude(fixes);
  final segs = _segment(fixes, alt);
  int route(int i) => keptIndexMap.isEmpty
      ? i
      : keptIndexMap[i.clamp(0, keptIndexMap.length - 1)];
  final descents = <SkiDescent>[];
  var lifts = 0;
  var liftMs = 0;
  for (final s in segs) {
    final a = fixes[s.from], b = fixes[s.to];
    final ms = b.at.difference(a.at).inMilliseconds;
    if (s.kind == SkiSegmentKind.lift) {
      lifts++;
      liftMs += ms;
    } else if (s.kind == SkiSegmentKind.descent) {
      var meters = 0.0;
      for (var i = s.from + 1; i <= s.to; i++) {
        meters += _step(fixes[i - 1], fixes[i]);
      }
      final avg = ms > 0 ? meters / (ms / 1000) : 0.0;
      descents.add(SkiDescent(
        start: a.at,
        end: b.at,
        meters: meters,
        vertical: s.vertical,
        maxSpeed: robustMaxSpeed(fixes, from: s.from, to: s.to) ?? avg,
        avgSpeed: avg,
        routeFrom: route(s.from),
        routeTo: route(s.to),
      ));
    }
  }
  return SkiDay(
    descents: descents,
    lifts: lifts,
    liftTime: Duration(milliseconds: liftMs),
  );
}
