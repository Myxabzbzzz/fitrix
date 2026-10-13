import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:fitrix/core/widgets/app_button.dart';
import 'package:fitrix/features/content/data/models.dart';
import 'package:fitrix/features/content/providers.dart';
import 'package:fitrix/features/map/data/location.dart';
import 'package:fitrix/features/map/data/routing_service.dart';
import 'package:fitrix/features/map/presentation/map_screen.dart';
import 'package:fitrix/features/map/routing/router.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

/// 1x1 transparent PNG, so no test ever touches the network.
final Uint8List _blankPng = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==');

class BlankTileProvider extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      MemoryImage(_blankPng);
}

class FakeLocation implements LocationSource {
  FakeLocation(this.at);
  final LatLng? at;
  @override
  Future<LatLng?> current() async => at;
}

const _me = LatLng(41.3104, 69.2789);

const _places = [
  Place(
      id: 'a',
      name: 'Alpha Gym',
      kind: 'gyms',
      type: 'Gym',
      lat: 41.3110,
      lon: 69.2760,
      hours: '07:00–23:00'),
  Place(
      id: 'b',
      name: 'Beta Park',
      kind: 'parks',
      type: 'Park',
      lat: 41.3130,
      lon: 69.2800),
  Place(
      id: 'c',
      name: 'Gamma Pool',
      kind: 'pools',
      type: 'Swimming school',
      lat: 41.3090,
      lon: 69.2820),
];

RoutePlan _plan(TravelMode mode, int minutes,
        {List<MetroRide> rides = const [], bool walkingIsFaster = false}) =>
    RoutePlan(
      mode: mode,
      duration: Duration(minutes: minutes),
      meters: 1200,
      rides: rides,
      walkingIsFaster: walkingIsFaster,
      legs: [
        const RouteLeg(kind: 'walk', points: [
          LatLng(41.3104, 69.2789),
          LatLng(41.3120, 69.2790),
        ]),
        if (mode == TravelMode.metro)
          const RouteLeg(
              kind: 'metro',
              lineColor: Color(0xFFD62E2E),
              points: [LatLng(41.3120, 69.2790), LatLng(41.3130, 69.2800)])
        else
          RouteLeg(kind: mode.name, points: const [
            LatLng(41.3120, 69.2790),
            LatLng(41.3130, 69.2800),
          ]),
      ],
    );

class FakeRouting implements RoutingService {
  FakeRouting({this.covered = true, this.gate});
  final bool covered;
  Completer<void>? gate;
  final calls = <LatLng>[];

  @override
  Future<RouteSet> plan(LatLng from, LatLng to) async {
    calls.add(to);
    if (gate != null) await gate!.future;
    if (!covered) {
      return const RouteSet(covered: false, plans: {});
    }
    return RouteSet(covered: true, plans: {
      TravelMode.walk: _plan(TravelMode.walk, 26),
      TravelMode.bike: _plan(TravelMode.bike, 11),
      TravelMode.car: null,
      TravelMode.metro: _plan(TravelMode.metro, 19, rides: const [
        MetroRide(
            line: '1',
            from: 'Amir Timur Square',
            to: 'Pakhtakor',
            stops: 2,
            color: Color(0xFFD62E2E)),
      ], walkingIsFaster: true),
    });
  }
}

Future<void> _pump(
  WidgetTester tester, {
  RoutingService? routing,
  LatLng? location = _me,
  Size size = const Size(390, 844),
  ThemeMode themeMode = ThemeMode.light,
  TileProvider? tiles,
}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      placesProvider.overrideWith((ref) async => _places),
      locationSourceProvider.overrideWithValue(FakeLocation(location)),
      routingServiceProvider.overrideWithValue(routing ?? FakeRouting()),
      mapTileProviderProvider.overrideWithValue(tiles ?? BlankTileProvider()),
      routeClockProvider.overrideWithValue(() => DateTime(2026, 10, 13, 10, 0)),
    ],
    child: MaterialApp(
      themeMode: themeMode,
      theme: ThemeData(brightness: Brightness.light),
      darkTheme: ThemeData(brightness: Brightness.dark),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: MapScreen()),
    ),
  ));
  await tester.pumpAndSettle();
}

Finder get _title => find.byKey(const ValueKey('place-title'));
Finder _mode(String m) => find.byKey(ValueKey('mode-$m'));

void main() {
  group('planRoutes (real engine, bundled graph)', () {
    final json = File('assets/data/route-graph.json').readAsStringSync();

    test('central Tashkent is covered and all modes are planned', () {
      final r = planRoutes(json, _me, const LatLng(41.31549, 69.26028));
      expect(r.covered, isTrue);
      expect(r.plans[TravelMode.walk], isNotNull);
      expect(r.plans[TravelMode.metro]!.rides, isNotEmpty);
    });

    test('far away is not covered', () {
      final r = planRoutes(json, _me, const LatLng(40.0, 70.0));
      expect(r.covered, isFalse);
      expect(r.plans, isEmpty);
    });
  });

  testWidgets('shows pins for places and attribution; first place selected',
      (tester) async {
    await _pump(tester);
    expect(find.byType(FlutterMap), findsOneWidget);
    expect(find.text('© OpenStreetMap contributors'), findsOneWidget);
    expect(find.byKey(const ValueKey('pin-a')), findsOneWidget);
    expect(find.byKey(const ValueKey('pin-b')), findsOneWidget);
    expect(tester.widget<Text>(_title).data, 'Alpha Gym');
    expect(tester.takeException(), isNull);
  });

  testWidgets('tiles are requested with the FITRIX user agent',
      (tester) async {
    final provider = BlankTileProvider();
    await _pump(tester, tiles: provider);
    final layer = tester.widget<TileLayer>(find.byType(TileLayer));
    expect(layer.urlTemplate, 'https://tile.openstreetmap.org/{z}/{x}/{y}.png');
    expect(provider.headers['User-Agent'], contains('com.elibayev.fitrix'));
  });

  testWidgets('selecting a pin updates the card', (tester) async {
    await _pump(tester);
    await tester.tap(find.byKey(const ValueKey('pin-b')));
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(_title).data, 'Beta Park');
    expect(find.text('Hours not listed'), findsOneWidget);
  });

  testWidgets('mode buttons show … while computing, then durations',
      (tester) async {
    final gate = Completer<void>();
    await _pump(tester, routing: FakeRouting(gate: gate));
    for (final m in ['walk', 'bike', 'car', 'metro']) {
      expect(find.descendant(of: _mode(m), matching: find.text('…')),
          findsOneWidget);
    }
    gate.complete();
    await tester.pumpAndSettle();
    expect(find.descendant(of: _mode('walk'), matching: find.text('26 min')),
        findsOneWidget);
    expect(find.descendant(of: _mode('bike'), matching: find.text('11 min')),
        findsOneWidget);
    expect(find.descendant(of: _mode('car'), matching: find.text('—')),
        findsOneWidget);
    expect(find.descendant(of: _mode('metro'), matching: find.text('19 min')),
        findsOneWidget);
    // Summary of the default (walk) mode, with the arrival time.
    expect(find.text('26 min · arrive 10:26'), findsOneWidget);
  });

  testWidgets('metro shows rides with line colour dot and walking hint',
      (tester) async {
    await _pump(tester);
    await tester.tap(_mode('metro'));
    await tester.pumpAndSettle();
    expect(find.text('19 min · arrive 10:19'), findsOneWidget);
    expect(find.textContaining('Amir Timur Square → Pakhtakor, 2 stops'),
        findsOneWidget);
    expect(find.textContaining('walking is faster here'), findsOneWidget);
    final dot = tester.widget<Container>(find.byKey(const ValueKey('line-dot-0')));
    expect((dot.decoration as BoxDecoration).color, const Color(0xFFD62E2E));
  });

  testWidgets('a mode without a route says so', (tester) async {
    await _pump(tester);
    await tester.tap(_mode('car'));
    await tester.pumpAndSettle();
    expect(find.text('No route for this mode'), findsOneWidget);
    final button =
        tester.widget<AppButton>(find.byKey(const ValueKey('route-toggle')));
    expect(button.onPressed, isNull);
  });

  testWidgets('outside coverage shows the coverage text and disables modes',
      (tester) async {
    await _pump(tester, routing: FakeRouting(covered: false));
    expect(find.text('Routes cover central Tashkent'), findsOneWidget);
    final gesture = tester.widget<InkWell>(find.descendant(
        of: _mode('walk'), matching: find.byType(InkWell)));
    expect(gesture.onTap, isNull);
    expect(find.text('Show route'), findsOneWidget);
  });

  testWidgets('Show route draws legs and toggles to Hide route',
      (tester) async {
    await _pump(tester);
    expect(find.byType(PolylineLayer), findsNothing);
    await tester.tap(find.text('Show route'));
    await tester.pumpAndSettle();
    expect(find.text('Hide route'), findsOneWidget);
    expect(find.byType(PolylineLayer), findsOneWidget);
    await tester.tap(find.text('Hide route'));
    await tester.pumpAndSettle();
    expect(find.byType(PolylineLayer), findsNothing);
    expect(find.text('Show route'), findsOneWidget);
  });

  testWidgets('route hides when another place is selected', (tester) async {
    await _pump(tester);
    await tester.tap(find.text('Show route'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('pin-b')));
    await tester.pumpAndSettle();
    expect(find.byType(PolylineLayer), findsNothing);
    expect(find.text('Show route'), findsOneWidget);
  });

  testWidgets('filter pills narrow the pins', (tester) async {
    await _pump(tester);
    await tester.tap(find.text('Parks'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('pin-a')), findsNothing);
    expect(find.byKey(const ValueKey('pin-b')), findsOneWidget);
    expect(tester.widget<Text>(_title).data, 'Beta Park');
  });

  testWidgets('location available: me dot, no caption', (tester) async {
    await _pump(tester);
    expect(find.byKey(const ValueKey('me-dot')), findsOneWidget);
    expect(find.text('Location off: showing central Tashkent'), findsNothing);
  });

  testWidgets('location unavailable: caption and fallback position',
      (tester) async {
    final routing = FakeRouting();
    await _pump(tester, location: null, routing: routing);
    expect(find.text('Location off: showing central Tashkent'), findsOneWidget);
    expect(find.byKey(const ValueKey('me-dot')), findsNothing);
    expect(routing.calls, isNotEmpty);
  });

  testWidgets('dark theme wraps tiles in a colour filter', (tester) async {
    await _pump(tester, themeMode: ThemeMode.dark);
    expect(
        find.descendant(
            of: find.byType(FlutterMap),
            matching: find.byType(ColorFiltered)),
        findsWidgets);
  });

  testWidgets('SE size: no overflow, card stays above the bottom edge',
      (tester) async {
    await _pump(tester, size: const Size(375, 667));
    await tester.tap(_mode('metro'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final bottom = tester.getBottomLeft(find.byKey(const ValueKey('place-card'))).dy;
    expect(bottom, lessThanOrEqualTo(667));
  });
}
