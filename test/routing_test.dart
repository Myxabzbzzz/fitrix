import 'dart:convert';
import 'dart:io';

import 'package:fitrix/core/constants/app_constants.dart';
import 'package:fitrix/core/router/app_router.dart';
import 'package:fitrix/core/session/app_session.dart';
import 'package:fitrix/features/map/routing/router.dart';
import 'package:fitrix/features/nutrition/data/food_catalog.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Every wave-1 screen, by the location the app navigates to. Ids are real
/// entries of the bundled JSON catalogs.
final _wave1Routes = <String>[
  AppRouter.home,
  AppRouter.workouts,
  AppRouter.sportWorkouts(Sport.gym),
  AppRouter.weekPlan,
  AppRouter.recovery,
  AppRouter.exerciseLibrary,
  AppRouter.exercise('bench-press'),
  AppRouter.addExerciseTo(),
  AppRouter.addExerciseTo(replace: true, index: 2),
  AppRouter.workoutComplete,
  AppRouter.programs,
  AppRouter.program('upper-lower-4'),
  AppRouter.programsActive,
  AppRouter.nutrition,
  AppRouter.addFood(MealSlot.lunch),
  AppRouter.foodDetail('chicken_breast', MealSlot.dinner),
  AppRouter.nutritionMicros,
  AppRouter.nutritionTargets,
  AppRouter.progress,
  AppRouter.progressLoad,
  AppRouter.progressRecords,
  AppRouter.progressLift('Bench press'),
  AppRouter.progressWeight,
  AppRouter.me,
  AppRouter.hrZones,
  AppRouter.editProfile,
  AppRouter.connectedApps,
];

/// Where a route may legitimately send an empty app instead.
const _emptyDataRedirects = {
  // Nothing to summarise without a finished workout: it goes home.
  AppRouter.workoutComplete: AppRouter.home,
};

void _appRoutes() {
  for (final theme in ['light', 'dark']) {
    group('every wave-1 route opens on an empty local-only app ($theme)', () {
      for (final location in _wave1Routes) {
        testWidgets(location, (tester) async {
          tester.view.physicalSize = const Size(1170, 2532);
          tester.view.devicePixelRatio = 3;
          addTearDown(tester.view.reset);
          SharedPreferences.setMockInitialValues({
            AppConstants.keyOnboardingComplete: true,
            AppSession.keyThemeMode: theme,
          });
          final prefs = await SharedPreferences.getInstance();
          final session = AppSession(prefs);
          // No auth gateway: signed out, local-only, the real route table.
          final router = AppRouter.create(session);
          await tester.pumpWidget(
              FitrixRoot(prefs: prefs, session: session, router: router));
          await tester.pump();

          router.go(location);
          for (var i = 0; i < 10; i++) {
            await tester.pump(const Duration(milliseconds: 100));
          }

          expect(tester.takeException(), isNull);
          expect(find.byType(ErrorWidget), findsNothing);
          final path = Uri.parse(location).path;
          expect(router.routerDelegate.currentConfiguration.uri.path,
              _emptyDataRedirects[location] ?? path);
          final brightness =
              Theme.of(tester.element(find.byType(Scaffold).last)).brightness;
          expect(
              brightness, theme == 'dark' ? Brightness.dark : Brightness.light);

          // Leave the app idle so nothing is left running at teardown.
          await tester.pumpWidget(const SizedBox());
          await tester.pump(const Duration(seconds: 1));
        });
      }
    });
  }
}

void _backBeforeOpened() {
  // A deep location adds the section page underneath only once the top page
  // has finished opening; going home before that used to trip an assertion
  // in the circle-reveal route.
  testWidgets('going home while a deep page is still opening', (tester) async {
    SharedPreferences.setMockInitialValues(
        {AppConstants.keyOnboardingComplete: true});
    final prefs = await SharedPreferences.getInstance();
    final session = AppSession(prefs);
    final router = AppRouter.create(session);
    await tester
        .pumpWidget(FitrixRoot(prefs: prefs, session: session, router: router));
    await tester.pump();
    router.go(AppRouter.progressLoad);
    await tester.pump();
    router.go(AppRouter.home);
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(tester.takeException(), isNull);
    expect(router.routerDelegate.currentConfiguration.uri.path, AppRouter.home);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}

void main() {
  _appRoutes();
  _backBeforeOpened();

  late RouteGraph graph;
  late RoutePlanner router;
  const me = LatLng(41.3104, 69.2789);
  const pakhtakor = LatLng(41.31549, 69.26028);

  setUpAll(() {
    final json =
        jsonDecode(File('assets/data/route-graph.json').readAsStringSync())
            as Map<String, dynamic>;
    graph = RouteGraph.fromJson(json);
    router = RoutePlanner(graph);
  });

  test('walk to Gogol Alley', () {
    final p =
        router.plan(TravelMode.walk, me, const LatLng(41.31604, 69.28675))!;
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
    expect(
        r.plan(TravelMode.car, b, a)!.meters, closeTo(200, 1)); // detour via C
    expect(r.plan(TravelMode.walk, b, a)!.meters,
        closeTo(100, 1)); // walkers ignore one-way
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
