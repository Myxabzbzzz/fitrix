// Swipe to delete (with undo) and pull to refresh on the workout list.
// Swipe back from the edge is tested with the other navigation animations
// in animations_test.dart.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitrix/core/session/session_providers.dart';
import 'package:fitrix/core/sync/sync_providers.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/features/workouts/presentation/providers/workouts_provider.dart';
import 'package:fitrix/features/workouts/presentation/screens/sport_workouts_screen.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

import 'support/in_memory_remote_store.dart';

Future<ProviderContainer> _pumpGym(
  WidgetTester tester, {
  InMemoryRemoteStore? remote,
}) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    if (remote != null) ...[
      remoteStoreProvider.overrideWithValue(remote),
      syncUserIdProvider.overrideWithValue('u1'),
    ],
  ]);
  addTearDown(container.dispose);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: SportWorkoutsScreen(sport: Sport.gym),
    ),
  ));
  await tester.pumpAndSettle();
  return container;
}

/// Unmounts and disposes the container, so the sync engine's poll and
/// retry timers are cancelled before the test ends.
Future<void> _stopSync(WidgetTester tester, ProviderContainer container) async {
  await tester.pumpWidget(const SizedBox());
  container.dispose();
}

List<String> _gymPlans(ProviderContainer container) => [
      for (final p in container.read(workoutsForSportProvider(Sport.gym)))
        p.name
    ];

void main() {
  group('swipe to delete', () {
    testWidgets('swiping a plan left deletes it; Undo puts it back in place',
        (tester) async {
      final container = await _pumpGym(tester);
      final before = _gymPlans(container);
      expect(before, contains('Legs'));

      await tester.drag(find.text('Legs'), const Offset(-400, 0));
      await tester.pumpAndSettle();
      expect(find.text('Legs'), findsNothing);
      expect(_gymPlans(container), isNot(contains('Legs')));
      expect(find.text('“Legs” deleted'), findsOneWidget);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(find.text('Legs'), findsOneWidget);
      expect(_gymPlans(container), before);
    });

    testWidgets("today's workout card can be swiped away too", (tester) async {
      final container = await _pumpGym(tester);
      final today = _gymPlans(container).first;

      await tester.drag(find.text(today).first, const Offset(-400, 0));
      await tester.pumpAndSettle();
      expect(_gymPlans(container), isNot(contains(today)));
    });

    testWidgets('a short or rightward swipe deletes nothing', (tester) async {
      final container = await _pumpGym(tester);
      final before = _gymPlans(container);

      await tester.drag(find.text('Legs'), const Offset(-30, 0));
      await tester.drag(find.text('Legs'), const Offset(300, 0));
      await tester.pumpAndSettle();
      expect(_gymPlans(container), before);
    });
  });

  group('pull to refresh', () {
    testWidgets('pulling the list down syncs right away', (tester) async {
      final remote = InMemoryRemoteStore();
      final container = await _pumpGym(tester, remote: remote);
      final requests = remote.requests;

      await tester.fling(
          find.byType(GridView), const Offset(0, 400), 1000);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(remote.requests, greaterThan(requests));
      expect(remote.plansOf('u1'), isNotEmpty);
      await _stopSync(tester, container);
    });

    testWidgets('offline: says the sync failed', (tester) async {
      final remote = InMemoryRemoteStore()..online = false;
      final container = await _pumpGym(tester, remote: remote);

      await tester.fling(
          find.byType(GridView), const Offset(0, 400), 1000);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));

      expect(find.textContaining("Couldn't sync"), findsOneWidget);
      await _stopSync(tester, container);
    });

    testWidgets('without an account there is nothing to refresh',
        (tester) async {
      await _pumpGym(tester);
      expect(find.byType(RefreshIndicator), findsNothing);
    });
  });
}
