import 'package:fitrix/core/constants/app_constants.dart';
import 'package:fitrix/core/router/app_router.dart';
import 'package:fitrix/core/session/app_session.dart';
import 'package:fitrix/features/football/presentation/football_screen.dart';
import 'package:fitrix/features/running/presentation/screens/running_screen.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/overflow.dart';

void main() {
  Future<void> open(WidgetTester tester,
      {double textScale = 1, String language = 'en'}) async {
    tester.view.physicalSize = iPhoneSeSize * 3;
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    SharedPreferences.setMockInitialValues({
      AppConstants.keyOnboardingComplete: true,
      AppConstants.keyLanguage: language,
    });
    final prefs = await SharedPreferences.getInstance();
    final session = AppSession(prefs);
    final router = AppRouter.create(session);
    await tester
        .pumpWidget(FitrixRoot(prefs: prefs, session: session, router: router));
    await tester.pump();
    router.go(AppRouter.workouts);
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Finder tile(Sport sport) => find.byKey(ValueKey('sport-tile-${sport.name}'));

  Future<void> tapTile(WidgetTester tester, Sport sport) async {
    await tester.scrollUntilVisible(tile(sport), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(tile(sport));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(tile(sport));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('My workouts has a tile for each of the six sports',
      (tester) async {
    await open(tester);
    for (final sport in Sport.values) {
      await tester.scrollUntilVisible(tile(sport), 200,
          scrollable: find.byType(Scrollable).first);
      expect(tile(sport), findsOneWidget, reason: sport.name);
    }
    // Sports without 3D art carry their icon instead.
    expect(
        find.descendant(
            of: tile(Sport.football),
            matching: find.byIcon(Icons.sports_soccer)),
        findsOneWidget);
  });

  testWidgets('the Running tile opens the Running screen', (tester) async {
    await open(tester);
    await tapTile(tester, Sport.running);
    expect(find.byType(RunningScreen), findsOneWidget);
  });

  testWidgets('the Football tile opens the Football screen', (tester) async {
    await open(tester);
    await tapTile(tester, Sport.football);
    expect(find.byType(FootballScreen), findsOneWidget);
  });

  testWidgets('SE, text 1.3, ru: the six tiles fit', (tester) async {
    await open(tester, textScale: 1.3, language: 'ru');
    await expectNoOverflowWhileScrolling(
        tester, find.byType(Scrollable).first, -1200,
        settle: false);
  });
}
