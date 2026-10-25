import 'package:latlong2/latlong.dart';

import 'run_track.dart';

/// Altitude is median-smoothed over this much time (centred).
const Duration skiSmoothing = Duration(seconds: 30);

/// A turn in altitude counts only after it moved this far (metres).
const double skiHysteresis = 15;

/// Minimum drop of a descent / gain of a lift (metres).
const double skiMinVertical = 30;

/// A lift climbs at least this fast (m/s; slow fixed-grip chairs) ...
const double skiLiftMinClimb = 0.3;

/// ... and moves along the ground no faster than this (m/s; aerial trams).
const double skiLiftMaxSpeed = 12;

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

/// Under this ground speed (m/s) over [_stillWindow] a fix is standing still.
const double _stillSpeed = 0.5;
const Duration _stillWindow = Duration(seconds: 30);

/// Standing still this long is a queue, a hut or lunch (not a pause to breathe).
const Duration _stillMin = Duration(minutes: 2);

/// Holes in a stop up to this long are part of it.
const Duration _stillHole = Duration(seconds: 30);

/// A descent covers at least this much ground ...
const double skiDescentMinMeters = 100;

/// ... at this moving ground speed (m/s).
const double skiDescentMinSpeed = 1.5;

/// A fix-to-fix step at least this fast (m/s) is moving.
const double _movingStep = 1;

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

/// Fixes standing still (under [_stillSpeed] over [_stillWindow]) for longer
/// than [_stillMin]: queues, huts, lunch.
List<bool> _stationary(List<RunPoint> fixes) {
  final n = fixes.length;
  final still = List<bool>.filled(n, false);
  final half = _stillWindow.inMilliseconds ~/ 2;
  var lo = 0, hi = 0;
  for (var i = 0; i < n; i++) {
    final t = fixes[i].at.millisecondsSinceEpoch;
    while (fixes[lo].at.millisecondsSinceEpoch < t - half) {
      lo++;
    }
    if (hi < i) hi = i;
    while (hi + 1 < n && fixes[hi + 1].at.millisecondsSinceEpoch <= t + half) {
      hi++;
    }
    final secs = (fixes[hi].at.millisecondsSinceEpoch -
            fixes[lo].at.millisecondsSinceEpoch) /
        1000;
    still[i] = secs >= _stillWindow.inSeconds / 2 &&
        _step(fixes[lo], fixes[hi]) / secs < _stillSpeed;
  }
  // A short hole (a jittery fix, a step forward in the queue) does not end a
  // stop.
  var h = 0;
  while (h < n) {
    if (still[h]) {
      h++;
      continue;
    }
    var e = h;
    while (e + 1 < n && !still[e + 1]) {
      e++;
    }
    if (h > 0 &&
        e + 1 < n &&
        fixes[e + 1].at.difference(fixes[h - 1].at) <= _stillHole) {
      for (var k = h; k <= e; k++) {
        still[k] = true;
      }
    }
    h = e + 1;
  }
  final out = List<bool>.filled(n, false);
  var i = 0;
  while (i < n) {
    if (!still[i]) {
      i++;
      continue;
    }
    var j = i;
    while (j + 1 < n && still[j + 1]) {
      j++;
    }
    if (fixes[j].at.difference(fixes[i].at) > _stillMin) {
      // The window smears the edges by half its length: take them back.
      var a = i, b = j;
      while (a > 0 &&
          fixes[i].at.difference(fixes[a - 1].at).inMilliseconds <= half) {
        a--;
      }
      while (b + 1 < n &&
          fixes[b + 1].at.difference(fixes[j].at).inMilliseconds <= half) {
        b++;
      }
      for (var k = a; k <= b; k++) {
        out[k] = true;
      }
    }
    i = j + 1;
  }
  return out;
}

/// Time and distance of the fixes [from]..[to], leaving out the steps inside
/// stationary stretches: all of it, and the part moving at >= [_movingStep].
({double secs, double meters, double movingSecs, double movingMeters}) _stats(
    List<RunPoint> fixes, List<bool> still, int from, int to) {
  var secs = 0.0, meters = 0.0, mSecs = 0.0, mMeters = 0.0;
  for (var i = from + 1; i <= to; i++) {
    if (still[i] || still[i - 1]) continue;
    final dt = fixes[i].at.difference(fixes[i - 1].at).inMilliseconds / 1000;
    if (dt <= 0) continue;
    final d = _step(fixes[i - 1], fixes[i]);
    secs += dt;
    meters += d;
    if (d / dt >= _movingStep) {
      mSecs += dt;
      mMeters += d;
    }
  }
  return (secs: secs, meters: meters, movingSecs: mSecs, movingMeters: mMeters);
}

List<SkiSegment> _segment(List<RunPoint> fixes, List<double> smooth) {
  final n = fixes.length;
  if (n == 0) return const [];
  if (smooth.isEmpty || n < 2) {
    return [SkiSegment(SkiSegmentKind.other, 0, n - 1)];
  }
  final still = _stationary(fixes);

  // The series without the stationary stretches. Altitude wandering while
  // standing (drift, a lift base slightly higher) is not climbing: whatever
  // the stretch moved the altitude by is taken out of what follows.
  final idx = <int>[];
  final v = <double>[];
  var offset = 0.0;
  for (var i = 0; i < n; i++) {
    if (still[i]) continue;
    if (idx.isNotEmpty && i - idx.last > 1) offset = smooth[i] - v.last;
    idx.add(i);
    v.add(smooth[i] - offset);
  }
  final m = idx.length;
  if (m < 2) return [SkiSegment(SkiSegmentKind.other, 0, n - 1)];

  // Direction changes with hysteresis.
  final pivots = <_Pivot>[];
  var dir = 0; // 0 unknown, 1 up, -1 down
  var maxV = v[0], maxF = 0, maxL = 0;
  var minV = v[0], minF = 0, minL = 0;
  for (var k = 1; k < m; k++) {
    final x = v[k];
    if (x > maxV) {
      maxV = x;
      maxF = maxL = k;
    } else if (x == maxV) {
      maxL = k;
    }
    if (x < minV) {
      minV = x;
      minF = minL = k;
    } else if (x == minV) {
      minL = k;
    }
    if (dir != -1 && x <= maxV - skiHysteresis) {
      pivots.add(_Pivot(maxF, maxL, true));
      dir = -1;
      minV = x;
      minF = minL = k;
    } else if (dir != 1 && x >= minV + skiHysteresis) {
      pivots.add(_Pivot(minF, minL, false));
      dir = 1;
      maxV = x;
      maxF = maxL = k;
    }
  }

  final cores = <SkiSegment>[];

  // A leg between two extremes (indexes into the series): cut where the
  // altitude last was within the band of the start and first reached the
  // band of the end, then decide what it is.
  void leg(int k0, int k1, bool up) {
    if (k1 <= k0) return;
    final rise = (v[k1] - v[k0]).abs();
    if (rise < skiMinVertical) return;
    var a = k1;
    while (a > k0 && (v[a] - v[k0]).abs() > _skiTrim) {
      a--;
    }
    var b = a;
    while (b < k1 && (v[b] - v[k1]).abs() > _skiTrim) {
      b++;
    }
    if (b <= a) return;
    final gaps = [
      for (var k = a; k < b; k++)
        if (idx[k + 1] - idx[k] > 1) k,
    ];
    if (!up) {
      // A stop (queue, hut, lunch) inside a descent splits it: the stop is
      // "other", and each part must be a descent on its own.
      var pa = a;
      for (final g in [...gaps, b]) {
        final pb = g == b ? b : g;
        final r = ((pb == b ? v[k1] : v[pb]) - (pa == a ? v[k0] : v[pa])).abs();
        if (pb > pa && r >= skiMinVertical) {
          final from = idx[pa], to = idx[pb];
          final st = _stats(fixes, still, from, to);
          if (st.movingSecs > 0 &&
              st.movingMeters >= skiDescentMinMeters &&
              st.movingMeters / st.movingSecs >= skiDescentMinSpeed) {
            cores.add(SkiSegment(SkiSegmentKind.descent, from, to, r));
          }
        }
        pa = g + 1;
      }
      return;
    }
    // A lift that stalls keeps going afterwards: stops inside it stay in it,
    // but a bit left on the far side of a stop that barely changed altitude
    // belongs to the stop (queue, waiting).
    var rise2 = rise;
    if (gaps.isNotEmpty) {
      var g0 = 0, g1 = gaps.length - 1;
      while (g0 <= g1 && (v[gaps[g0]] - v[a]).abs() < skiHysteresis) {
        a = gaps[g0] + 1;
        g0++;
      }
      while (g1 >= g0 && (v[b] - v[gaps[g1] + 1]).abs() < skiHysteresis) {
        b = gaps[g1];
        g1--;
      }
      if (b <= a) return;
      rise2 = (v[b] - v[a]).abs();
      if (rise2 < skiMinVertical) return;
    }
    final from = idx[a], to = idx[b];
    final st = _stats(fixes, still, from, to);
    if (st.secs > 0 &&
        rise2 / st.secs >= skiLiftMinClimb &&
        st.meters / st.secs <= skiLiftMaxSpeed) {
      cores.add(SkiSegment(SkiSegmentKind.lift, from, to, rise2));
    }
  }

  var start = 0;
  for (final p in pivots) {
    leg(start, p.first, p.peak);
    start = p.last;
  }
  if (dir != 0) leg(start, dir == 1 ? maxF : minF, dir == 1);

  // Everything between the cores is "other".
  final out = <SkiSegment>[];
  var at = 0;
  for (final c in cores) {
    if (c.from > at) out.add(SkiSegment(SkiSegmentKind.other, at, c.from));
    out.add(c);
    at = c.to;
  }
  if (at < n - 1) out.add(SkiSegment(SkiSegmentKind.other, at, n - 1));
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
  final still = fixes.isEmpty ? const <bool>[] : _stationary(fixes);
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
      final st = _stats(fixes, still, s.from, s.to);
      final meters = st.movingMeters;
      final avg = st.movingSecs > 0 ? meters / st.movingSecs : 0.0;
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
