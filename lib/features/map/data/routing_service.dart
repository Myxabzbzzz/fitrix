import 'dart:convert';
import 'dart:isolate';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_map/flutter_map.dart' show TileProvider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../routing/router.dart';

/// All four travel modes for one trip. [covered] is false when either end
/// is outside the street data (then [plans] is empty).
class RouteSet {
  const RouteSet({required this.covered, required this.plans});
  final bool covered;
  final Map<TravelMode, RoutePlan?> plans;
}

abstract class RoutingService {
  Future<RouteSet> plan(LatLng from, LatLng to);
}

/// Plans routes off the UI isolate. The graph JSON is bundled with the app.
class IsolateRoutingService implements RoutingService {
  IsolateRoutingService({Future<String> Function()? loadJson})
      : _loadJson = loadJson ??
            (() => rootBundle.loadString('assets/data/route-graph.json'));

  final Future<String> Function() _loadJson;
  Future<String>? _json;

  @override
  Future<RouteSet> plan(LatLng from, LatLng to) async {
    final loading = _json ??= _loadJson();
    final String json;
    try {
      json = await loading;
    } catch (_) {
      _json = null; // retry the load next time
      rethrow;
    }
    return Isolate.run(() => planRoutes(json, from, to));
  }
}

/// Synchronous planning; [IsolateRoutingService] runs it in a worker isolate.
RouteSet planRoutes(String graphJson, LatLng from, LatLng to) {
  final graph =
      RouteGraph.fromJson(jsonDecode(graphJson) as Map<String, dynamic>);
  if (!graph.covers(from) || !graph.covers(to)) {
    return const RouteSet(covered: false, plans: {});
  }
  return RouteSet(covered: true, plans: RoutePlanner(graph).planAll(from, to));
}

final routingServiceProvider =
    Provider<RoutingService>((ref) => IsolateRoutingService());

/// Tile source override point (tests inject an offline provider); null uses
/// the default network provider.
final mapTileProviderProvider = Provider<TileProvider?>((ref) => null);

/// "Now", for arrival times.
final routeClockProvider = Provider<DateTime Function()>((ref) => DateTime.now);
