import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitrix/core/navigation/circle_reveal.dart';
import 'package:fitrix/core/router/app_router.dart';
import 'package:fitrix/core/session/app_session.dart';
import 'package:fitrix/features/home/presentation/screens/home_screen.dart';
import 'package:fitrix/features/transition/presentation/screens/chat_transition_screen.dart';
import 'package:fitrix/features/shell/presentation/main_shell.dart';
import 'package:fitrix/features/workouts/data/workout_catalog.dart';
import 'package:fitrix/features/workouts/presentation/providers/workouts_provider.dart';
import 'package:fitrix/features/workouts/presentation/widgets/active_workout_sheet.dart';
import 'package:fitrix/main.dart';

void _phone(WidgetTester t) {
  t.view.physicalSize = const Size(1170, 2532);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
}

void _reduceMotion(WidgetTester t) {
  t.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
}

Future<ProviderContainer> _home(WidgetTester t) async {
  SharedPreferences.setMockInitialValues({'onboarding_complete': true});
  final prefs = await SharedPreferences.getInstance();
  final session = AppSession(prefs);
  await t.pumpWidget(FitrixRoot(
      prefs: prefs, session: session, router: AppRouter.create(session)));
  await t.pumpAndSettle();
  return ProviderScope.containerOf(t.element(find.byType(HomeScreen)));
}

class _Slot extends StatelessWidget {
  const _Slot(this.visible);
  final bool visible;
  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            height: 48,
            child: BarSlot(
              visible: visible,
              child: const ColoredBox(
                  key: ValueKey('bar'), color: Color(0xFF00FF00)),
            ),
          ),
        ),
      );
}

void main() {
  group('bar slot (run bar)', () {
    testWidgets('slides up and fades in, then slides down and goes', (t) async {
      await t.pumpWidget(const _Slot(false));
      expect(find.byKey(const ValueKey('bar')), findsNothing);

      await t.pumpWidget(const _Slot(true));
      await t.pump(const Duration(milliseconds: 100));
      final slide = t.widget<SlideTransition>(find.byType(SlideTransition));
      expect(slide.position.value.dy, inExclusiveRange(0, 1));
      final fade = t.widget<FadeTransition>(find.byType(FadeTransition));
      expect(fade.opacity.value, inExclusiveRange(0, 1));
      await t.pumpAndSettle();
      expect(
          t
              .widget<SlideTransition>(find.byType(SlideTransition))
              .position
              .value,
          Offset.zero);

      await t.pumpWidget(const _Slot(false));
      await t.pump(const Duration(milliseconds: 100));
      expect(find.byKey(const ValueKey('bar')), findsOneWidget,
          reason: 'still sliding away');
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('bar')), findsNothing);
    });

    testWidgets('reduced motion: shows and hides at once', (t) async {
      _reduceMotion(t);
      await t.pumpWidget(const _Slot(false));
      await t.pumpWidget(const _Slot(true));
      await t.pump();
      expect(
          t
              .widget<SlideTransition>(find.byType(SlideTransition))
              .position
              .value,
          Offset.zero);
      await t.pumpWidget(const _Slot(false));
      await t.pump();
      expect(find.byKey(const ValueKey('bar')), findsNothing);
    });
  });

  group('gym mini bar', () {
    testWidgets(
        'slides up as a workout starts and the page makes room smoothly, '
        'and slides away when it is discarded', (t) async {
      _phone(t);
      final c = await _home(t);
      final full = t.getSize(find.byType(HomeScreen)).height;

      c.read(activeWorkoutExpandedProvider.notifier).state = false;
      c
          .read(activeWorkoutProvider.notifier)
          .start(WorkoutCatalog.defaults.first);
      await t.pump();
      await t.pump(const Duration(milliseconds: 120));

      final mid = t.getSize(find.byType(HomeScreen)).height;
      expect(mid,
          inExclusiveRange(full - ActiveWorkoutSheet.collapsedHeight, full),
          reason: 'the inset animates, no 64 px jump');
      final surface = find.byKey(ActiveWorkoutSheet.surfaceKey);
      final restTop = full - ActiveWorkoutSheet.collapsedHeight;
      expect(t.getTopLeft(surface).dy, greaterThan(restTop),
          reason: 'still sliding up');

      await t.pump(const Duration(milliseconds: 400));
      expect(t.getSize(find.byType(HomeScreen)).height,
          full - ActiveWorkoutSheet.collapsedHeight);
      expect(t.getTopLeft(surface).dy, closeTo(restTop, 0.5));

      c.read(activeWorkoutProvider.notifier).discard();
      await t.pump();
      await t.pump(const Duration(milliseconds: 120));
      expect(surface, findsOneWidget, reason: 'sliding away');
      await t.pump(const Duration(milliseconds: 400));
      expect(surface, findsNothing);
      expect(t.getSize(find.byType(HomeScreen)).height, full);
    });

    testWidgets('reduced motion: appears and goes at once', (t) async {
      _phone(t);
      _reduceMotion(t);
      final c = await _home(t);
      final full = t.getSize(find.byType(HomeScreen)).height;
      c.read(activeWorkoutExpandedProvider.notifier).state = false;
      c
          .read(activeWorkoutProvider.notifier)
          .start(WorkoutCatalog.defaults.first);
      await t.pump();
      await t.pump();
      expect(t.getSize(find.byType(HomeScreen)).height,
          full - ActiveWorkoutSheet.collapsedHeight);
      c.read(activeWorkoutProvider.notifier).discard();
      await t.pump();
      await t.pump();
      expect(find.byKey(ActiveWorkoutSheet.surfaceKey), findsNothing);
    });
  });

  testWidgets(
      'circle reveal covers the far top corner before the page is fully '
      'faded in', (t) async {
    _phone(t);
    final controller = AnimationController(
        vsync: const TestVSync(), duration: const Duration(seconds: 1));
    addTearDown(controller.dispose);
    await t.pumpWidget(MaterialApp(
      home: CircleRevealTransition(
        animation: controller,
        // A tile low on the right, like the Today card's Start.
        origin: const Offset(340, 600),
        child: const ColoredBox(color: Color(0xFFFFFFFF)),
      ),
    ));
    // When the content has faded in (0.9), the top-left corner is inside.
    controller.value = 0.85;
    await t.pump();
    final clip = t.widget<ClipPath>(find.descendant(
        of: find.byType(CircleRevealTransition),
        matching: find.byType(ClipPath)));
    final path = clip.clipper!.getClip(t.getSize(find.byType(ClipPath)));
    expect(path.contains(const Offset(1, 1)), isTrue);
  });

  testWidgets('the live screen slides up and closes by sliding down',
      (t) async {
    _phone(t);
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, __) => const Text('below')),
      GoRoute(
        path: '/live',
        pageBuilder: (context, state) =>
            slideUpPage(context, state, const Text('live', key: Key('live'))),
      ),
    ]);
    await t.pumpWidget(MaterialApp.router(routerConfig: router));
    router.push('/live');
    await t.pump();
    await t.pump(const Duration(milliseconds: 120));
    var at = t.getTopLeft(find.byKey(const Key('live')));
    expect(at.dx, 0, reason: 'no sideways slide');
    expect(at.dy, greaterThan(100), reason: 'coming up from below');
    await t.pumpAndSettle();
    expect(t.getTopLeft(find.byKey(const Key('live'))).dy, lessThan(100));

    router.pop();
    await t.pump();
    await t.pump(const Duration(milliseconds: 120));
    at = t.getTopLeft(find.byKey(const Key('live')));
    expect(at.dx, 0);
    expect(at.dy, greaterThan(100), reason: 'going down');
    await t.pumpAndSettle();
    expect(find.byKey(const Key('live')), findsNothing);
  });

  testWidgets(
      'end of onboarding: Home cross-fades in over the transition screen, '
      'which stays until then (iOS)', (t) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    _phone(t);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final session = AppSession(prefs);
    final router = AppRouter.create(session);
    await t
        .pumpWidget(FitrixRoot(prefs: prefs, session: session, router: router));
    await t.pump();
    router.go(AppRouter.transition);
    await t.pump();
    await t.pump(const Duration(seconds: 1));
    expect(find.byType(ChatTransitionScreen), findsOneWidget);

    // What "I am ready" does at the end of the white circle.
    await session.completeOnboarding();
    await t.pump();
    await t.pump(const Duration(milliseconds: 120));

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(ChatTransitionScreen), findsOneWidget,
        reason: 'stays under Home while it fades in: no blank frame');
    final fades = t
        .widgetList<FadeTransition>(find.ancestor(
            of: find.byType(MainShell), matching: find.byType(FadeTransition)))
        .map((f) => f.opacity.value)
        .toList();
    expect(fades.any((v) => v > 0 && v < 1), isTrue, reason: '$fades');
    expect(t.getTopLeft(find.byType(MainShell)).dx, 0,
        reason: 'a cross-fade, not a slide from the side');

    await t.pumpAndSettle();
    expect(find.byType(ChatTransitionScreen), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('a page pushed over the app still moves the app the iOS way',
      (t) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    _phone(t);
    SharedPreferences.setMockInitialValues({'onboarding_complete': true});
    final prefs = await SharedPreferences.getInstance();
    final session = AppSession(prefs);
    final router = AppRouter.create(session);
    await t
        .pumpWidget(FitrixRoot(prefs: prefs, session: session, router: router));
    await t.pumpAndSettle();
    router.push(AppRouter.runSummary('nope'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 150));
    expect(t.getTopLeft(find.byType(MainShell)).dx, lessThan(0),
        reason: 'parallax under the incoming page');
    await t.pumpAndSettle();
    debugDefaultTargetPlatformOverride = null;
  });
}
