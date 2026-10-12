import 'dart:convert';
import 'dart:io';

import 'package:fitrix/features/map/routing/router.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  late RouteGraph graph;
  late RoutePlanner router;
  const me = LatLng(41.3104, 69.2789);
  const pakhtakor = LatLng(41.31549, 69.26028);

  setUpAll(() {
    final json = jsonDecode(File('assets/data/route-graph.json').readAsStringSync())
        as Map<String, dynamic>;
    graph = RouteGraph.fromJson(json);
    router = RoutePlanner(graph);
  });

  test('walk to Gogol Alley', () {
    final p = router.plan(TravelMode.walk, me, const LatLng(41.31604, 69.28675))!;
    expect(p.meters, closeTo(1271, 15));
    expect(p.duration.inMinutes, inInclusiveRange(15, 17));
  });

  test('walk to Pakhtakor', () {
    final p = router.plan(TravelMode.walk, me, pakhtakor)!;
    expect(p.meters, closeTo(2588, 30));
  });

  test('metro to Pakhtakor uses line 1, 2 stops, faster than walking', () {
    final all = router.planAll(me, pakhtakor);
    final m = all[TravelMode.metro]!;
    expect(m.rides, hasLength(1));
    expect(m.rides.first.line, '1');
    expect(m.rides.first.from, 'Amir Timur Square');
    expect(m.rides.first.to, 'Pakhtakor');
    expect(m.rides.first.stops, 2);
    expect(m.duration, lessThan(all[TravelMode.walk]!.duration));
    expect(m.walkingIsFaster, isFalse);
    expect(m.legs.any((l) => l.kind == 'metro'), isTrue);
  });

  test('metro to Inside Fit: walking is faster', () {
    final all = router.planAll(me, const LatLng(41.2986, 69.28749));
    expect(all[TravelMode.metro]!.walkingIsFaster, isTrue);
  });

  test('planAll for one destination is fast', () {
    router.planAll(me, pakhtakor); // warm up
    final sw = Stopwatch()..start();
    router.planAll(me, pakhtakor);
    sw.stop();
    // ignore: avoid_print
    print('planAll took ${sw.elapsedMilliseconds} ms');
    expect(sw.elapsedMilliseconds, lessThan(200));
  });

  test('car never goes against a one-way edge', () {
    // A -> B is one-way and short; B-C and C-A are two-way.
    final g = RouteGraph.fromJson({
      'origin': [41.0, 69.0],
      'scale': 100000,
      'classes': ['residential'],
      'nodes': [0, 0, 100, 0, 50, 80],
      'edges': [
        [0, 1, 100.0, <int>[], 0, 1],
        [1, 2, 100.0, <int>[], 0, 0],
        [2, 0, 100.0, <int>[], 0, 0],
      ],
      'metro': <dynamic>[],
    });
    final r = RoutePlanner(g);
    const a = LatLng(41.0, 69.0);
    const b = LatLng(41.0, 69.001);
    expect(r.plan(TravelMode.car, a, b)!.meters, closeTo(100, 1));
    expect(r.plan(TravelMode.car, b, a)!.meters, closeTo(200, 1)); // detour via C
    expect(r.plan(TravelMode.walk, b, a)!.meters, closeTo(100, 1)); // walkers ignore one-way
  });

  test('outside coverage', () {
    const far = LatLng(40.0, 70.0);
    expect(graph.covers(far), isFalse);
    expect(graph.covers(me), isTrue);
    final all = router.planAll(far, far);
    expect(all.values.every((v) => v == null), isTrue);
    expect(all.keys, containsAll(TravelMode.values));
  });

  test('covered start, destination outside coverage: all null', () {
    final all = router.planAll(me, const LatLng(40.0, 70.0));
    expect(all.values.every((v) => v == null), isTrue);
    expect(all.keys, containsAll(TravelMode.values));
  });
}
