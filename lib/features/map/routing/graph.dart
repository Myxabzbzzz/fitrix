import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart' show AssetBundle;
import 'package:latlong2/latlong.dart';

import 'metro.dart';

/// How a street graph edge is travelled. `metro` is planned separately.
enum TravelMode { walk, bike, car, metro }

const double metersPerDeg = 111320;
double kmh(double v) => v / 3.6;

/// Walking pace (4.8 km/h) in m/s.
final double walkSpeed = kmh(4.8);

/// Equirectangular distance in meters (same formula as the prototype).
double flatM(double aLat, double aLon, double bLat, double bLon) {
  final k = math.cos((aLat + bLat) * math.pi / 360);
  return math.sqrt(math.pow((bLat - aLat) * metersPerDeg, 2) +
      math.pow((bLon - aLon) * metersPerDeg * k, 2));
}

const Map<String, double> _carKmh = {
  'trunk': 50,
  'primary': 40,
  'secondary': 35,
  'tertiary': 30,
  'link': 30,
  'unclassified': 25,
  'residential': 20,
  'living_street': 10,
  'service': 12,
};

/// One street segment between two junction nodes.
class RouteEdge {
  const RouteEdge(this.a, this.b, this.meters, this.mid, this.cls, this.oneway);

  final int a;
  final int b;
  final double meters;

  /// Intermediate shape points, flat [x, y, ...] quantised integers.
  final List<int> mid;
  final int cls;

  /// 0 two-way, 1 only a to b, -1 only b to a.
  final int oneway;
}

class RouteGraph {
  RouteGraph._({
    required this.originLat,
    required this.originLon,
    required this.scale,
    required this.classes,
    required this.edges,
    required this.lat,
    required this.lon,
    required this.adj,
    required this.lines,
  }) {
    for (final m in const [TravelMode.walk, TravelMode.bike, TravelMode.car]) {
      _main[m] = _largestComponent(m);
    }
  }

  final double originLat;
  final double originLon;
  final double scale;
  final List<String> classes;
  final List<RouteEdge> edges;
  final Float64List lat;
  final Float64List lon;
  final List<List<int>> adj;
  final List<MetroLine> lines;
  final Map<TravelMode, Uint8List> _main = {};

  static Future<RouteGraph> load(AssetBundle bundle,
      {String path = 'assets/data/route-graph.json'}) async {
    final text = await bundle.loadString(path);
    return RouteGraph.fromJson(jsonDecode(text) as Map<String, dynamic>);
  }

  factory RouteGraph.fromJson(Map<String, dynamic> g) {
    final origin = (g['origin'] as List).map((e) => (e as num).toDouble()).toList();
    final scale = (g['scale'] as num).toDouble();
    final flat = g['nodes'] as List;
    final n = flat.length ~/ 2;
    final lat = Float64List(n), lon = Float64List(n);
    for (var i = 0; i < n; i++) {
      lon[i] = origin[1] + (flat[2 * i] as num) / scale;
      lat[i] = origin[0] + (flat[2 * i + 1] as num) / scale;
    }
    final edges = <RouteEdge>[];
    final adj = List<List<int>>.generate(n, (_) => <int>[]);
    for (final raw in g['edges'] as List) {
      final e = raw as List;
      final edge = RouteEdge(
        (e[0] as num).toInt(),
        (e[1] as num).toInt(),
        (e[2] as num).toDouble(),
        (e[3] as List).map((v) => (v as num).toInt()).toList(growable: false),
        (e[4] as num).toInt(),
        (e[5] as num).toInt(),
      );
      adj[edge.a].add(edges.length);
      adj[edge.b].add(edges.length);
      edges.add(edge);
    }
    return RouteGraph._(
      originLat: origin[0],
      originLon: origin[1],
      scale: scale,
      classes: (g['classes'] as List).cast<String>(),
      edges: edges,
      lat: lat,
      lon: lon,
      adj: adj,
      lines: ((g['metro'] as List?) ?? const [])
          .map((l) => MetroLine.fromJson(l as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Speed in m/s for a mode on an edge class; 0 means not allowed.
  double speedOf(TravelMode mode, int cls) {
    final c = classes[cls];
    switch (mode) {
      case TravelMode.walk:
        return walkSpeed;
      case TravelMode.bike:
        if (c == 'steps') return 0;
        return const ['footway', 'path', 'pedestrian', 'track'].contains(c)
            ? kmh(9)
            : kmh(15);
      case TravelMode.car:
        final v = _carKmh[c];
        return v == null ? 0 : kmh(v);
      case TravelMode.metro:
        return 0;
    }
  }

  /// May [e] be travelled from node [u]? One-way streets bind bikes and cars, never pedestrians.
  bool allowed(TravelMode mode, RouteEdge e, int u) {
    if (speedOf(mode, e.cls) == 0) return false;
    if (mode == TravelMode.walk || e.oneway == 0) return true;
    if (mode == TravelMode.bike &&
        const ['footway', 'path', 'pedestrian'].contains(classes[e.cls])) {
      return true;
    }
    return e.oneway == 1 ? e.a == u : e.b == u;
  }

  Uint8List _largestComponent(TravelMode mode) {
    final n = lat.length;
    final comp = Int32List(n)..fillRange(0, n, -1);
    var best = -1, bestSize = 0, c = 0;
    for (var st = 0; st < n; st++) {
      if (comp[st] >= 0 || !adj[st].any((ei) => speedOf(mode, edges[ei].cls) != 0)) {
        continue;
      }
      final stack = <int>[st];
      comp[st] = c;
      var size = 0;
      while (stack.isNotEmpty) {
        final u = stack.removeLast();
        size++;
        for (final ei in adj[u]) {
          final e = edges[ei];
          if (speedOf(mode, e.cls) == 0) continue;
          final v = e.a == u ? e.b : e.a;
          if (comp[v] < 0) {
            comp[v] = c;
            stack.add(v);
          }
        }
      }
      if (size > bestSize) {
        bestSize = size;
        best = c;
      }
      c++;
    }
    final out = Uint8List(n);
    for (var i = 0; i < n; i++) {
      out[i] = comp[i] == best ? 1 : 0;
    }
    return out;
  }

  /// Whether [node] is in the largest connected component for [mode].
  bool inMain(TravelMode mode, int node) => _main[mode]![node] == 1;

  /// Nearest main-component node for [mode], or -1 when the graph has none.
  int nearestNode(TravelMode mode, double pLat, double pLon) {
    final ok = _main[mode]!;
    var best = -1;
    var bd = double.infinity;
    for (var i = 0; i < lat.length; i++) {
      if (ok[i] == 0) continue;
      final d = flatM(pLat, pLon, lat[i], lon[i]);
      if (d < bd) {
        bd = d;
        best = i;
      }
    }
    return best;
  }

  /// True when [p] is within 600 m of a walkable main-component node.
  bool covers(LatLng p) {
    final i = nearestNode(TravelMode.walk, p.latitude, p.longitude);
    if (i < 0) return false;
    return flatM(p.latitude, p.longitude, lat[i], lon[i]) <= 600;
  }
}
