import 'dart:typed_data';

import 'package:latlong2/latlong.dart';

import 'graph.dart';
import 'metro.dart';

export 'graph.dart' show RouteGraph, TravelMode;
export 'metro.dart' show MetroRide, RouteLeg;

const double parkSec = 120;

class RoutePlan {
  const RoutePlan({
    required this.mode,
    required this.duration,
    required this.meters,
    required this.legs,
    this.rides = const [],
    this.walkingIsFaster = false,
  });

  final TravelMode mode;
  final Duration duration;
  final double meters;
  final List<RouteLeg> legs;
  final List<MetroRide> rides;

  /// Metro only: the plain walk is no slower than the metro trip.
  final bool walkingIsFaster;

  RoutePlan _withWalkingFaster() => RoutePlan(
        mode: mode,
        duration: duration,
        meters: meters,
        legs: legs,
        rides: rides,
        walkingIsFaster: true,
      );
}

class _Astar {
  const _Astar(this.pts, this.sec, this.meters);
  final List<LatLng> pts;
  final double sec;
  final double meters;
}

class _Street {
  const _Street(this.sec, this.meters, this.pts);
  final double sec;
  final double meters;
  final List<LatLng> pts;
}

class RoutePlanner {
  RoutePlanner(this.graph) : _metro = MetroNetwork(graph.lines);

  final RouteGraph graph;
  final MetroNetwork _metro;

  static double _vmax(TravelMode m) => switch (m) {
        TravelMode.walk => walkSpeed,
        TravelMode.bike => kmh(16),
        TravelMode.car => kmh(50),
        TravelMode.metro => walkSpeed,
      };

  RoutePlan? plan(TravelMode mode, LatLng from, LatLng to) {
    if (!graph.covers(from) || !graph.covers(to)) return null;
    return _plan(mode, from, to);
  }

  RoutePlan? _plan(TravelMode mode, LatLng from, LatLng to) {
    if (mode == TravelMode.metro) return _metroPlan(from, to);
    final r = _street(mode, from, to);
    if (r == null) return null;
    return RoutePlan(
      mode: mode,
      duration: _dur(r.sec),
      meters: r.meters,
      legs: [RouteLeg(kind: mode.name, points: r.pts)],
    );
  }

  Map<TravelMode, RoutePlan?> planAll(LatLng from, LatLng to) {
    final out = <TravelMode, RoutePlan?>{};
    final covered = graph.covers(from) && graph.covers(to);
    for (final m in TravelMode.values) {
      out[m] = covered ? _plan(m, from, to) : null;
    }
    final metro = out[TravelMode.metro], walk = out[TravelMode.walk];
    if (metro != null && walk != null && metro.duration >= walk.duration) {
      out[TravelMode.metro] = metro._withWalkingFaster();
    }
    return out;
  }

  Duration _dur(double sec) => Duration(milliseconds: (sec * 1000).round());

  /// A*: cost is travel time in seconds; the heuristic is straight distance at the mode's top speed.
  _Astar? _astar(TravelMode mode, int s, int t) {
    final n = graph.lat.length;
    final g = Float64List(n)..fillRange(0, n, double.infinity);
    final via = Int32List(n)..fillRange(0, n, -1);
    final closed = Uint8List(n);
    final vmax = _vmax(mode);
    double h(int i) =>
        flatM(graph.lat[i], graph.lon[i], graph.lat[t], graph.lon[t]) / vmax;
    final heap = MinHeap();
    g[s] = 0;
    heap.push(h(s), s);
    while (heap.isNotEmpty) {
      final u = heap.pop();
      if (closed[u] == 1) continue;
      closed[u] = 1;
      if (u == t) break;
      for (final ei in graph.adj[u]) {
        final e = graph.edges[ei];
        if (!graph.allowed(mode, e, u)) continue;
        final v = e.a == u ? e.b : e.a;
        final ng = g[u] + e.meters / graph.speedOf(mode, e.cls);
        if (ng < g[v]) {
          g[v] = ng;
          via[v] = ei;
          heap.push(ng + h(v), v);
        }
      }
    }
    if (!g[t].isFinite) return null;
    final pts = <LatLng>[LatLng(graph.lat[t], graph.lon[t])];
    var meters = 0.0;
    for (var v = t; v != s;) {
      final e = graph.edges[via[v]];
      final u = e.a == v ? e.b : e.a;
      final mid = <LatLng>[];
      for (var i = 0; i < e.mid.length; i += 2) {
        mid.add(LatLng(graph.originLat + e.mid[i + 1] / graph.scale,
            graph.originLon + e.mid[i] / graph.scale));
      }
      // Collected backwards: from v towards u, so reverse the a->b shape when u is a.
      pts.addAll(e.a == u ? mid.reversed : mid);
      pts.add(LatLng(graph.lat[u], graph.lon[u]));
      meters += e.meters;
      v = u;
    }
    return _Astar(pts.reversed.toList(), g[t], meters);
  }

  _Street? _street(TravelMode mode, LatLng from, LatLng to) {
    final s = graph.nearestNode(mode, from.latitude, from.longitude);
    final t = graph.nearestNode(mode, to.latitude, to.longitude);
    if (s < 0 || t < 0) return null;
    final r = _astar(mode, s, t);
    if (r == null) return null;
    final a = r.pts.first, b = r.pts.last;
    final access = flatM(from.latitude, from.longitude, a.latitude, a.longitude) +
        flatM(to.latitude, to.longitude, b.latitude, b.longitude);
    final sec = r.sec + access / walkSpeed + (mode == TravelMode.car ? parkSec : 0);
    return _Street(sec, r.meters + access, [from, ...r.pts, to]);
  }

  /// Walk to a nearby station, wait, ride (with transfers), walk to the place.
  RoutePlan? _metroPlan(LatLng from, LatLng to) {
    final trip = _metro.plan(from, to);
    if (trip == null) return null;
    final firstPt = LatLng(trip.firstLat, trip.firstLon);
    final lastPt = LatLng(trip.lastLat, trip.lastLon);
    final w1 = _street(TravelMode.walk, from, firstPt);
    final w2 = _street(TravelMode.walk, lastPt, to);
    final legs = <RouteLeg>[
      if (w1 != null) RouteLeg(kind: 'walk', points: w1.pts),
      ...trip.legs,
      if (w2 != null) RouteLeg(kind: 'walk', points: w2.pts),
    ];
    final sec = (w1?.sec ?? MetroNetwork.walkEstimate(from, trip.firstLat, trip.firstLon)) +
        metroWaitSec +
        trip.rideSec +
        (w2?.sec ?? MetroNetwork.walkEstimate(to, trip.lastLat, trip.lastLon));
    return RoutePlan(
      mode: TravelMode.metro,
      duration: _dur(sec),
      meters: (w1?.meters ?? 0) + (w2?.meters ?? 0),
      legs: legs,
      rides: trip.rides,
    );
  }
}
