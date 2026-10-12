import 'dart:ui' show Color;

import 'package:latlong2/latlong.dart';

import 'graph.dart';

const double metroWaitSec = 240;
const double _metroKmh = 38;
const double _transferMeters = 450;
const Color metroFallbackColor = Color(0xFF8E8E93);

/// Min-heap of (priority, id) pairs.
class MinHeap {
  final List<double> _p = [];
  final List<int> _v = [];

  bool get isNotEmpty => _p.isNotEmpty;

  void push(double p, int v) {
    _p.add(p);
    _v.add(v);
    var i = _p.length - 1;
    while (i > 0) {
      final par = (i - 1) >> 1;
      if (_p[par] <= _p[i]) break;
      _swap(par, i);
      i = par;
    }
  }

  /// Removes the smallest entry; read its priority from [lastPriority].
  int pop() {
    final top = _v[0];
    lastPriority = _p[0];
    final lp = _p.removeLast(), lv = _v.removeLast();
    if (_p.isNotEmpty) {
      _p[0] = lp;
      _v[0] = lv;
      var i = 0;
      for (;;) {
        final l = 2 * i + 1, r = l + 1;
        var m = i;
        if (l < _p.length && _p[l] < _p[m]) m = l;
        if (r < _p.length && _p[r] < _p[m]) m = r;
        if (m == i) break;
        _swap(m, i);
        i = m;
      }
    }
    return top;
  }

  double lastPriority = 0;

  void _swap(int a, int b) {
    final tp = _p[a];
    _p[a] = _p[b];
    _p[b] = tp;
    final tv = _v[a];
    _v[a] = _v[b];
    _v[b] = tv;
  }
}

/// OSM colour strings: 'red', 'blue', 'green' or hex like '#9933FF'. Unknown gives null.
Color? parseMetroColour(String? s) {
  if (s == null) return null;
  final t = s.trim().toLowerCase();
  switch (t) {
    case 'red':
      return const Color(0xFFE53935);
    case 'blue':
      return const Color(0xFF1E88E5);
    case 'green':
      return const Color(0xFF43A047);
  }
  final m = RegExp(r'^#([0-9a-f]{6})$').firstMatch(t) ??
      RegExp(r'^#([0-9a-f]{3})$').firstMatch(t);
  if (m == null) return null;
  var hex = m.group(1)!;
  if (hex.length == 3) hex = hex.split('').map((c) => '$c$c').join();
  return Color(0xFF000000 | int.parse(hex, radix: 16));
}

class MetroStop {
  const MetroStop(this.name, this.lat, this.lon);
  final String name;
  final double lat;
  final double lon;
}

class MetroLine {
  const MetroLine({required this.ref, required this.name, required this.colour, required this.stops});

  factory MetroLine.fromJson(Map<String, dynamic> j) => MetroLine(
        ref: (j['ref'] ?? '') as String,
        name: (j['name'] ?? '') as String,
        colour: parseMetroColour(j['colour'] as String?),
        stops: (j['stops'] as List)
            .map((s) => MetroStop((s[0] ?? '') as String, (s[1] as num).toDouble(),
                (s[2] as num).toDouble()))
            .toList(),
      );

  final String ref;
  final String name;
  final Color? colour;
  final List<MetroStop> stops;
}

class MetroRide {
  const MetroRide({
    required this.line,
    required this.from,
    required this.to,
    required this.stops,
    required this.color,
  });

  /// Line reference, e.g. '1'.
  final String line;
  final String from;
  final String to;
  final int stops;
  final Color color;
}

class RouteLeg {
  const RouteLeg({required this.kind, required this.points, this.lineColor});

  /// 'walk', 'bike', 'car' or 'metro'.
  final String kind;
  final List<LatLng> points;
  final Color? lineColor;
}

class _Station {
  const _Station(this.name, this.lat, this.lon, this.li, this.k);
  final String name;
  final double lat;
  final double lon;
  final int li;
  final int k;
}

class _Link {
  const _Link(this.j, this.t, this.ride);
  final int j;
  final double t;
  final bool ride;
}

/// The metro part of a trip, between the first and last station.
class MetroTrip {
  const MetroTrip({
    required this.firstLat,
    required this.firstLon,
    required this.lastLat,
    required this.lastLon,
    required this.rideSec,
    required this.rides,
    required this.legs,
  });

  final double firstLat, firstLon, lastLat, lastLon;

  /// Time on trains and transfers, without waiting or access walks.
  final double rideSec;
  final List<MetroRide> rides;
  final List<RouteLeg> legs;
}

/// Stations as a tiny graph: rides between neighbours, transfers between lines a short walk apart.
class MetroNetwork {
  MetroNetwork(this.lines) {
    for (var li = 0; li < lines.length; li++) {
      for (var k = 0; k < lines[li].stops.length; k++) {
        final s = lines[li].stops[k];
        _st.add(_Station(s.name, s.lat, s.lon, li, k));
        _adj.add([]);
      }
    }
    for (var i = 0; i < _st.length; i++) {
      for (var j = 0; j < _st.length; j++) {
        if (i == j) continue;
        final a = _st[i], b = _st[j];
        final d = flatM(a.lat, a.lon, b.lat, b.lon);
        if (a.li == b.li && (a.k - b.k).abs() == 1) {
          _adj[i].add(_Link(j, d / kmh(_metroKmh) + 30, true));
        } else if (a.li != b.li && d < _transferMeters) {
          _adj[i].add(_Link(j, d * 1.3 / walkSpeed + 60, false));
        }
      }
    }
  }

  final List<MetroLine> lines;
  final List<_Station> _st = [];
  final List<List<_Link>> _adj = [];

  /// Walking estimate (with detour factor) to a station, seconds.
  static double walkEstimate(LatLng p, double lat, double lon) =>
      flatM(p.latitude, p.longitude, lat, lon) * 1.3 / walkSpeed;

  List<int> _near(LatLng p) {
    final c = <(int, double)>[];
    for (var i = 0; i < _st.length; i++) {
      final d = flatM(p.latitude, p.longitude, _st[i].lat, _st[i].lon);
      if (d < 1800) c.add((i, d));
    }
    c.sort((x, y) => x.$2.compareTo(y.$2));
    return c.take(3).map((e) => e.$1).toList();
  }

  /// Cheapest station path from near [from] to near [to], or null.
  /// The router adds the access walks.
  MetroTrip? plan(LatLng from, LatLng to) {
    final n = _st.length;
    final starts = _near(from), ends = _near(to);
    if (starts.isEmpty || ends.isEmpty) return null;
    final dist = List<double>.filled(n, double.infinity);
    final prev = List<int>.filled(n, -1);
    final heap = MinHeap();
    for (final i in starts) {
      dist[i] = walkEstimate(from, _st[i].lat, _st[i].lon) + metroWaitSec;
      heap.push(dist[i], i);
    }
    while (heap.isNotEmpty) {
      final u = heap.pop();
      final d = heap.lastPriority;
      if (d > dist[u]) continue;
      for (final l in _adj[u]) {
        if (d + l.t < dist[l.j]) {
          dist[l.j] = d + l.t;
          prev[l.j] = u;
          heap.push(dist[l.j], l.j);
        }
      }
    }
    var bestEnd = -1;
    var bestT = double.infinity;
    for (final i in ends) {
      final t = dist[i] + walkEstimate(to, _st[i].lat, _st[i].lon);
      if (t < bestT) {
        bestT = t;
        bestEnd = i;
      }
    }
    if (bestEnd < 0) return null;
    final path = <int>[];
    for (var v = bestEnd; v >= 0; v = prev[v]) {
      path.insert(0, v);
    }
    if (path.length < 2) return null; // same station at both ends

    final rides = <MetroRide>[];
    final legs = <RouteLeg>[];
    var rideSec = 0.0;
    int? curLine;
    String? curFrom, curTo;
    var curStops = 0;
    List<LatLng>? curPts;
    var curIdx = -1;
    void flush() {
      if (curIdx < 0) return;
      final line = lines[curLine!];
      rides[curIdx] = MetroRide(
          line: line.ref,
          from: curFrom!,
          to: curTo!,
          stops: curStops,
          color: line.colour ?? metroFallbackColor);
    }

    for (var k = 1; k < path.length; k++) {
      final a = _st[path[k - 1]], b = _st[path[k]];
      final edge = _adj[path[k - 1]].firstWhere((x) => x.j == path[k]);
      rideSec += edge.t;
      if (edge.ride) {
        if (curLine == null || curLine != a.li) {
          flush();
          curLine = a.li;
          curFrom = a.name;
          curTo = b.name;
          curStops = 1;
          curPts = [LatLng(a.lat, a.lon), LatLng(b.lat, b.lon)];
          rides.add(const MetroRide(
              line: '', from: '', to: '', stops: 0, color: metroFallbackColor));
          curIdx = rides.length - 1;
          legs.add(RouteLeg(kind: 'metro', points: curPts, lineColor: lines[a.li].colour));
        } else {
          curTo = b.name;
          curStops++;
          curPts!.add(LatLng(b.lat, b.lon));
        }
      } else {
        flush();
        curLine = null;
        curIdx = -1;
        legs.add(RouteLeg(
            kind: 'walk', points: [LatLng(a.lat, a.lon), LatLng(b.lat, b.lon)]));
      }
    }
    flush();
    final first = _st[path.first], last = _st[path.last];
    return MetroTrip(
      firstLat: first.lat,
      firstLon: first.lon,
      lastLat: last.lat,
      lastLon: last.lon,
      rideSec: rideSec,
      rides: rides,
      legs: legs,
    );
  }
}
