import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitrix/core/session/session_providers.dart';
import 'package:fitrix/features/workouts/data/workout_catalog.dart';
import 'package:fitrix/features/workouts/presentation/providers/workouts_provider.dart';
import 'package:fitrix/features/workouts/presentation/widgets/active_workout_sheet.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

void _phoneSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

Future<ProviderContainer> _pumpExpanded(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(container.dispose);
  container
      .read(activeWorkoutProvider.notifier)
      .start(WorkoutCatalog.defaults.first);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: ActiveWorkoutSheet()),
    ),
  ));
  await tester.pump();
  container.read(activeWorkoutExpandedProvider.notifier).state = true;
  await tester.pumpAndSettle();
  return container;
}

Future<void> _unmount(WidgetTester tester) =>
    tester.pumpWidget(const SizedBox());

void main() {
  const fillKey = ValueKey('activeWorkoutProgressFill');
  const trackKey = ValueKey('activeWorkoutProgressTrack');
  const captionKey = ValueKey('activeWorkoutSetsCaption');

  testWidgets('sheet surface: 32 top radius, 69x2 handle', (tester) async {
    _phoneSize(tester);
    await _pumpExpanded(tester);
    final box =
        tester.widget<Container>(find.byKey(ActiveWorkoutSheet.surfaceKey));
    final deco = box.decoration! as BoxDecoration;
    expect(deco.borderRadius,
        const BorderRadius.vertical(top: Radius.circular(32)));
    expect(tester.getSize(find.byKey(ActiveWorkoutSheet.handleKey)),
        const Size(69, 2));
    await _unmount(tester);
  });

  testWidgets('expanded timer is 44 w600 tabular', (tester) async {
    _phoneSize(tester);
    await _pumpExpanded(tester);
    final text = tester.widget<Text>(find.descendant(
      of: find.byKey(ActiveWorkoutSheet.timerKey),
      matching: find.byType(Text),
    ));
    expect(text.style!.fontSize, 44);
    expect(text.style!.fontWeight, FontWeight.w600);
    expect(
        text.style!.fontFeatures, contains(const FontFeature.tabularFigures()));
    await _unmount(tester);
  });

  testWidgets('toggling a set updates caption and progress width',
      (tester) async {
    _phoneSize(tester);
    final container = await _pumpExpanded(tester);
    final total = container.read(activeWorkoutProvider)!.totalSets;
    expect(tester.widget<Text>(find.byKey(captionKey)).data,
        'Set 1 of $total · 0.0 t lifted');
    expect(tester.getSize(find.byKey(fillKey)).width, 0);

    await tester.tap(find.byIcon(Icons.check).first);
    await tester.pump();
    await tester.tap(find.text('Skip')); // end the rest so it can settle
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(find.byKey(captionKey)).data,
        startsWith('Set 2 of $total'));
    final ratio = tester.getSize(find.byKey(fillKey)).width /
        tester.getSize(find.byKey(trackKey)).width;
    expect(ratio, closeTo(1 / total, 0.001));
    await _unmount(tester);
  });

  testWidgets('check button is 32x32 and only the toggled one pops',
      (tester) async {
    _phoneSize(tester);
    await _pumpExpanded(tester);
    final first = find.byKey(const ValueKey('set-0-0'));
    final second = find.byKey(const ValueKey('set-0-1'));
    final checkBox = find.descendant(
        of: first, matching: find.byKey(ActiveWorkoutSheet.checkKey));
    expect(tester.getSize(checkBox), const Size(32, 32));

    await tester.tap(find.byIcon(Icons.check).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    double scaleIn(Finder row) => tester
        .widget<ScaleTransition>(find
            .descendant(of: row, matching: find.byType(ScaleTransition))
            .first)
        .scale
        .value;
    expect(scaleIn(first), lessThan(1.0));
    expect(scaleIn(second), 1.0);
    await tester.tap(find.text('Skip')); // end the rest so it can settle
    await tester.pumpAndSettle();
    expect(scaleIn(first), 1.0);
    await _unmount(tester);
  });

  testWidgets('reduced motion: no running animations after one pump',
      (tester) async {
    _phoneSize(tester);
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await _pumpExpanded(tester);
    await tester.tap(find.byIcon(Icons.check).first);
    await tester.pump();
    // The rest countdown it starts is a ticker; skip it to see the rest.
    await tester.tap(find.text('Skip'));
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);
    await _unmount(tester);
  });
}
