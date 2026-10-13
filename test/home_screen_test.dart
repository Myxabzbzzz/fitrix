import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitrix/core/router/app_router.dart';
import 'package:fitrix/core/session/session_providers.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/core/widgets/feature_tile.dart';
import 'package:fitrix/features/home/presentation/screens/home_screen.dart';
import 'package:fitrix/features/workouts/data/workout_catalog.dart';
import 'package:fitrix/features/workouts/presentation/providers/workouts_provider.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  bool active = false,
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(container.dispose);
  if (active) {
    container
        .read(activeWorkoutProvider.notifier)
        .start(WorkoutCatalog.defaults.first);
  }
  final router = GoRouter(
    initialLocation: AppRouter.home,
    routes: [
      GoRoute(path: AppRouter.home, builder: (_, __) => const HomeScreen()),
      for (final p in [
        AppRouter.progress,
        AppRouter.nutrition,
        AppRouter.workouts,
        AppRouter.felix,
        AppRouter.shop,
        AppRouter.fitrixMap,
      ])
        GoRoute(path: p, builder: (_, __) => Scaffold(body: Text('page $p'))),
    ],
  );
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  ));
  await tester.pumpAndSettle();
  return container;
}

void main() {
  const tiles = {
    'MY\nPROGRESS': AppRouter.progress,
    'MY\nNUTRITION': AppRouter.nutrition,
    'FELIX': AppRouter.felix,
    'MY\nWORKOUTS': AppRouter.workouts,
    'SHOP': AppRouter.shop,
    'FITRIX\nMAP': AppRouter.fitrixMap,
  };

  for (final e in tiles.entries) {
    testWidgets('tile ${e.value} navigates', (tester) async {
      await _pump(tester);
      await tester.tap(find.text(e.key));
      await tester.pumpAndSettle();
      expect(find.text('page ${e.value}'), findsOneWidget);
    });
  }

  testWidgets('Today card shows the first template and Start starts it',
      (tester) async {
    final container = await _pump(tester);
    final first = WorkoutCatalog.defaults.first;
    expect(find.text('TODAY'), findsOneWidget);
    expect(find.text(first.name), findsOneWidget);
    expect(
      find.text('${first.exercises.length} exercises · about '
          '${first.estimatedDuration.inMinutes} min'),
      findsOneWidget,
    );
    expect(find.text('Continue'), findsNothing);
    await tester.tap(find.text('Start'));
    await tester.pump();
    expect(container.read(activeWorkoutProvider)?.template.id, first.id);
    expect(container.read(activeWorkoutExpandedProvider), isTrue);
  });

  testWidgets('small tile labels fit inside the 64 px tiles', (tester) async {
    await _pump(tester);
    for (final label in ['MY\nPROGRESS', 'MY\nNUTRITION']) {
      final tile = find.ancestor(
          of: find.text(label), matching: find.byType(FeatureTile));
      final tileH = tester.getSize(tile.first).height;
      final textH = tester.getSize(find.text(label)).height;
      expect(textH, lessThanOrEqualTo(tileH - 2 * AppSpacing.sm),
          reason: label);
    }
  });

  testWidgets('with an active workout the button reads Continue',
      (tester) async {
    final container = await _pump(tester, active: true);
    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('Start'), findsNothing);
    await tester.tap(find.text('Continue'));
    await tester.pump();
    expect(container.read(activeWorkoutExpandedProvider), isTrue);
  });

  testWidgets('no overflow at 375x667', (tester) async {
    await _pump(tester, size: const Size(375, 667));
    expect(tester.takeException(), isNull);
    await _pump(tester, size: const Size(375, 667), active: true);
    expect(tester.takeException(), isNull);
  });
}
