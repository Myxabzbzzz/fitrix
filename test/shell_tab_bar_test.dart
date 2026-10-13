import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitrix/core/session/session_providers.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/features/shell/presentation/main_shell.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

Future<GoRouter> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final router = GoRouter(
    initialLocation: '/t0',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => MainShell(navigationShell: shell),
        branches: [
          for (var i = 0; i < 5; i++)
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/t$i',
                builder: (_, __) => Center(child: Text('page $i')),
              ),
            ]),
        ],
      ),
    ],
  );
  await tester.pumpWidget(ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    child: MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  ));
  await tester.pumpAndSettle();
  return router;
}

void main() {
  testWidgets('five tab semantics labels are present', (tester) async {
    await _pump(tester);
    for (final l in ['Discover', 'Shop', 'Home', 'Felix', 'Profile']) {
      expect(find.bySemanticsLabel(l), findsWidgets, reason: l);
    }
  });

  testWidgets('the current tab is exposed as selected', (tester) async {
    final handle = tester.ensureSemantics();
    final router = await _pump(tester);
    router.go('/t2');
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(find.bySemanticsLabel('Home').first),
      matchesSemantics(
          label: 'Home',
          isSelected: true,
          hasSelectedState: true,
          hasTapAction: true,
          hasFocusAction: true,
          isFocusable: true),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Shop').first),
      matchesSemantics(
          label: 'Shop',
          isSelected: false,
          hasSelectedState: true,
          hasTapAction: true,
          hasFocusAction: true,
          isFocusable: true),
    );
    handle.dispose();
  });

  testWidgets('tapping each tab switches to its branch', (tester) async {
    final router = await _pump(tester);
    final labels = ['Discover', 'Shop', 'Home', 'Felix', 'Profile'];
    for (var i = 4; i >= 0; i--) {
      await tester.tap(find.bySemanticsLabel(labels[i]).first);
      await tester.pumpAndSettle();
      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        '/t$i',
      );
    }
  });

  testWidgets('Felix tab shows avatar image', (tester) async {
    await _pump(tester);
    final img = find.byWidgetPredicate((w) =>
        w is Image &&
        w.image is AssetImage &&
        (w.image as AssetImage).assetName == 'assets/images/felix_avatar.png');
    expect(img, findsOneWidget);
  });

  testWidgets('selected Felix tab has accent ring, unselected does not',
      (tester) async {
    await _pump(tester);
    final ring = find.byKey(const ValueKey('felix-ring'));
    Color? ringColor() {
      final box = tester.widget<DecoratedBox>(ring);
      final d = box.decoration as BoxDecoration;
      return (d.border as Border?)?.top.color;
    }

    final avatar = find.byWidgetPredicate((w) =>
        w is Image &&
        w.image is AssetImage &&
        (w.image as AssetImage).assetName == 'assets/images/felix_avatar.png');
    // 28 px outer circle, 24 px image inside the 2 px ring, both states.
    expect(tester.getSize(ring), const Size(28, 28));
    expect(tester.getSize(avatar), const Size(24, 24));
    expect(ringColor(), Colors.transparent);
    await tester.tap(find.bySemanticsLabel('Felix').first);
    await tester.pumpAndSettle();
    final accent =
        AppPalette.of(tester.element(find.byKey(const ValueKey('felix-ring'))))
            .accent;
    expect(ringColor(), accent);
    expect(tester.getSize(ring), const Size(28, 28));
    expect(tester.getSize(avatar), const Size(24, 24));
  });
}
