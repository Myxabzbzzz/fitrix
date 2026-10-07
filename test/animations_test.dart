import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitrix/core/navigation/circle_reveal.dart';
import 'package:fitrix/core/router/app_router.dart';
import 'package:fitrix/core/session/app_session.dart';
import 'package:fitrix/core/session/session_providers.dart';
import 'package:fitrix/core/widgets/feature_tile.dart';
import 'package:fitrix/features/chat/data/models/chat_message.dart';
import 'package:fitrix/features/chat/presentation/widgets/chat_entrance.dart';
import 'package:fitrix/features/progress/presentation/widgets/progress_chart.dart';
import 'package:fitrix/features/workouts/data/workout_catalog.dart';
import 'package:fitrix/features/workouts/presentation/providers/workouts_provider.dart';
import 'package:fitrix/features/workouts/presentation/widgets/active_workout_sheet.dart';
import 'package:fitrix/main.dart';

void _phoneSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 2532); // 390 x 844
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

void _reduceMotion(WidgetTester tester) {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
}

/// The real app, past onboarding, on Home.
Future<void> _pumpHome(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({'onboarding_complete': true});
  final prefs = await SharedPreferences.getInstance();
  final session = AppSession(prefs);
  await tester.pumpWidget(FitrixRoot(
    prefs: prefs,
    session: session,
    router: AppRouter.create(session),
  ));
  await tester.pumpAndSettle();
}

/// Just the active workout sheet, with a workout in progress.
Future<ProviderContainer> _pumpSheet(WidgetTester tester) async {
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
      home: Scaffold(body: ActiveWorkoutSheet()),
    ),
  ));
  await tester.pump();
  return container;
}

/// Unmounts everything so the sheet's elapsed-time ticker is disposed.
Future<void> _unmount(WidgetTester tester) =>
    tester.pumpWidget(const SizedBox());

void main() {
  group('active workout sheet', () {
    double sheetHeight(WidgetTester tester) =>
        tester.getSize(find.byKey(ActiveWorkoutSheet.surfaceKey)).height;
    final header = find.byKey(ActiveWorkoutSheet.headerKey);
    const collapsed = ActiveWorkoutSheet.collapsedHeight;
    const expanded = 844.0 - 12; // screen height - top inset (0) - 12

    testWidgets('follows the finger and snaps by position on release',
        (tester) async {
      _phoneSize(tester);
      final container = await _pumpSheet(tester);
      expect(sheetHeight(tester), collapsed);

      // Drag up a little: the sheet tracks the finger, no animation.
      final gesture = await tester.startGesture(tester.getCenter(header));
      await gesture.moveBy(const Offset(0, -30));
      await gesture.moveBy(const Offset(0, -100));
      await tester.pump();
      final dragged = sheetHeight(tester);
      expect(dragged, greaterThan(collapsed + 99));
      expect(dragged, lessThanOrEqualTo(collapsed + 130));

      // Released below halfway without speed: snaps back closed.
      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final settling = sheetHeight(tester);
      expect(settling, lessThan(dragged));
      expect(settling, greaterThan(collapsed));
      await tester.pumpAndSettle();
      expect(sheetHeight(tester), collapsed);
      expect(container.read(activeWorkoutExpandedProvider), isFalse);

      // Dragged past halfway: snaps open.
      await tester.drag(header, const Offset(0, -500));
      await tester.pumpAndSettle();
      expect(sheetHeight(tester), expanded);
      expect(container.read(activeWorkoutExpandedProvider), isTrue);
      expect(find.text('Biceps curl'), findsOneWidget);

      await _unmount(tester);
    });

    testWidgets('a quick fling snaps by direction; tap still toggles',
        (tester) async {
      _phoneSize(tester);
      final container = await _pumpSheet(tester);

      // A short but fast flick up opens it.
      await tester.fling(header, const Offset(0, -60), 1500);
      await tester.pumpAndSettle();
      expect(sheetHeight(tester), expanded);
      expect(container.read(activeWorkoutExpandedProvider), isTrue);

      // ...and a short fast flick down closes it.
      await tester.fling(header, const Offset(0, 60), 1500);
      await tester.pumpAndSettle();
      expect(sheetHeight(tester), collapsed);

      await tester.tap(header);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      expect(sheetHeight(tester), inExclusiveRange(collapsed, expanded));
      await tester.pumpAndSettle();
      expect(sheetHeight(tester), expanded);

      await tester.tap(header);
      await tester.pumpAndSettle();
      expect(sheetHeight(tester), collapsed);
      expect(container.read(activeWorkoutExpandedProvider), isFalse);

      await _unmount(tester);
    });

    testWidgets('checking off a set pops the check and taps haptics',
        (tester) async {
      _phoneSize(tester);
      final haptics = <Object?>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            haptics.add(call.arguments);
          }
          return null;
        },
      );
      addTearDown(() => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null));

      final container = await _pumpSheet(tester);
      container.read(activeWorkoutExpandedProvider.notifier).state = true;
      await tester.pumpAndSettle();

      final check = find.byIcon(Icons.check).first;
      final scale = find.ancestor(
        of: check,
        matching: find.byType(ScaleTransition),
      );
      await tester.tap(check);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));

      expect(haptics, ['HapticFeedbackType.lightImpact']);
      expect(
        container.read(activeWorkoutProvider)!.exercises[0].sets[0].done,
        isTrue,
      );
      expect(
          tester.widget<ScaleTransition>(scale.first).scale.value, isNot(1.0));

      await tester.pumpAndSettle();
      expect(tester.widget<ScaleTransition>(scale.first).scale.value, 1.0);

      await _unmount(tester);
    });

    testWidgets('reduced motion: toggles without animating', (tester) async {
      _phoneSize(tester);
      _reduceMotion(tester);
      await _pumpSheet(tester);

      await tester.tap(header);
      await tester.pump();
      expect(sheetHeight(tester), expanded);
      expect(tester.hasRunningAnimations, isFalse);

      await tester.tap(header);
      await tester.pump();
      expect(sheetHeight(tester), collapsed);

      await _unmount(tester);
    });
  });

  group('chat bubble entrance', () {
    ChatMessage msg(String id, {String content = 'hi', bool user = false}) =>
        ChatMessage(
          id: id,
          content: content,
          sender: user ? MessageSender.user : MessageSender.assistant,
          timestamp: DateTime(2026, 10, 6),
        );

    Future<ValueNotifier<List<ChatMessage>>> pumpChat(
      WidgetTester tester,
      List<ChatMessage> history,
    ) async {
      final messages = ValueNotifier(history);
      addTearDown(messages.dispose);
      final tracker = ChatEntranceTracker();
      // Mirrors how both chat screens build their message lists.
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ValueListenableBuilder(
            valueListenable: messages,
            builder: (context, list, _) {
              tracker.sync(list);
              return ListView.builder(
                itemCount: list.length,
                itemBuilder: (context, i) => ChatEntrance(
                  key: ValueKey(list[i].id),
                  message: list[i],
                  delay: tracker.take(list[i]),
                  child: Text(list[i].content),
                ),
              );
            },
          ),
        ),
      ));
      return messages;
    }

    /// A bubble that never animates has no Opacity wrapper at all.
    double opacityOf(WidgetTester tester, String id) {
      final opacity = find.descendant(
        of: find.byKey(ValueKey(id)),
        matching: find.byType(Opacity),
      );
      if (opacity.evaluate().isEmpty) return 1;
      return tester.widget<Opacity>(opacity.first).opacity;
    }

    testWidgets('history shows at once; new messages animate in once',
        (tester) async {
      final messages = await pumpChat(tester, [msg('a'), msg('b')]);

      // Loaded history: fully visible on the very first frame.
      expect(opacityOf(tester, 'a'), 1);
      expect(opacityOf(tester, 'b'), 1);
      expect(tester.hasRunningAnimations, isFalse);

      // A user message and the (empty, streaming) reply are inserted.
      messages.value = [
        ...messages.value,
        msg('c', user: true),
        msg('d', content: ''),
      ];
      await tester.pump();
      expect(opacityOf(tester, 'c'), 0);
      expect(opacityOf(tester, 'd'), 0);
      expect(opacityOf(tester, 'b'), 1, reason: 'old bubbles stay put');

      await tester.pump(const Duration(milliseconds: 150));
      expect(opacityOf(tester, 'c'), inExclusiveRange(0, 1));
      expect(opacityOf(tester, 'd'), lessThan(opacityOf(tester, 'c')),
          reason: 'the reply is staggered after the user message');

      await tester.pumpAndSettle();
      expect(opacityOf(tester, 'c'), 1);
      expect(opacityOf(tester, 'd'), 1);

      // Streaming tokens into the reply must not replay its entrance.
      for (final text in ['Hel', 'Hello', 'Hello!']) {
        messages.value = [
          for (final m in messages.value)
            m.id == 'd' ? m.copyWith(content: text) : m,
        ];
        await tester.pump();
        expect(opacityOf(tester, 'd'), 1);
        expect(tester.hasRunningAnimations, isFalse);
      }
      expect(find.text('Hello!'), findsOneWidget);
    });

    test('a new scope (chat topic) is treated as history', () {
      final tracker = ChatEntranceTracker()..sync([msg('a')], scope: 1);
      tracker.sync([msg('a'), msg('b')], scope: 1);
      expect(tracker.take(msg('b')), Duration.zero);
      expect(tracker.take(msg('b')), isNull, reason: 'consumed');

      tracker.sync([msg('x'), msg('y')], scope: 2);
      expect(tracker.take(msg('x')), isNull);
      expect(tracker.take(msg('y')), isNull);
    });

    testWidgets('reduced motion: new messages appear at once', (tester) async {
      _reduceMotion(tester);
      final messages = await pumpChat(tester, [msg('a')]);
      messages.value = [...messages.value, msg('b')];
      await tester.pump();
      expect(opacityOf(tester, 'b'), 1);
      expect(tester.hasRunningAnimations, isFalse);
    });
  });

  group('charts', () {
    Future<void> pumpChart(WidgetTester tester) => tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ProgressChart(
                title: 'Weight',
                values: [70, 72, 75],
                xLabels: ['1', '2', '3'],
                minY: 60,
                maxY: 80,
              ),
            ),
          ),
        );

    double drawn(WidgetTester tester) {
      final paint = tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .firstWhere(
              (p) => p.painter.runtimeType.toString() == '_ChartPainter');
      return ((paint.painter as dynamic).progress as Animation<double>).value;
    }

    testWidgets('the line draws in when the chart appears', (tester) async {
      await pumpChart(tester);
      expect(drawn(tester), 0);
      await tester.pump(const Duration(milliseconds: 150));
      expect(drawn(tester), inExclusiveRange(0, 1));
      await tester.pumpAndSettle();
      expect(drawn(tester), 1);
    });

    testWidgets('reduced motion: the line is drawn at once', (tester) async {
      _reduceMotion(tester);
      await pumpChart(tester);
      expect(drawn(tester), 1);
      expect(tester.hasRunningAnimations, isFalse);
    });
  });

  group('navigation', () {
    final nutritionTile = find.text('MY\nNUTRI\nTION');

    testWidgets('a Home tile presses in and reveals its section in a circle',
        (tester) async {
      _phoneSize(tester);
      await _pumpHome(tester);

      // Press feedback.
      final press = await tester.startGesture(tester.getCenter(nutritionTile));
      await tester.pump(const Duration(milliseconds: 200));
      final scale = tester.widget<AnimatedScale>(find
          .ancestor(of: nutritionTile, matching: find.byType(AnimatedScale))
          .first);
      expect(scale.scale, FeatureTile.pressedScale);
      final tileCenter = tester.getCenter(nutritionTile.hitTestable());
      await press.up();

      // Mid-transition: the circle grows from the tapped tile.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.byType(CircleRevealTransition), findsOneWidget);
      final origin = RevealOrigins.of(AppRouter.nutrition)!;
      final tileBox = tester.getRect(find
          .ancestor(of: nutritionTile, matching: find.byType(FeatureTile))
          .first);
      expect(tileBox.contains(origin), isTrue);
      expect((origin - tileCenter).distance, lessThan(tileBox.longestSide));

      await tester.pumpAndSettle();
      expect(find.text('My Nutrition'), findsOneWidget);
      expect(find.text('FELIX'), findsNothing);

      // Back shrinks it into the tile again.
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(CircleRevealTransition), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('FELIX'), findsOneWidget);
      expect(find.text('My Nutrition'), findsNothing);
    });

    group('swipe back from the left edge', () {
      Future<void> openNutrition(WidgetTester tester) async {
        _phoneSize(tester);
        await _pumpHome(tester);
        await tester.tap(nutritionTile);
        await tester.pumpAndSettle();
        expect(find.text('My Nutrition'), findsOneWidget);
      }

      testWidgets('iOS: the section follows the finger and closes',
          (tester) async {
        await openNutrition(tester);

        final drag = await tester.startGesture(const Offset(5, 400));
        await drag.moveBy(const Offset(40, 0));
        await drag.moveBy(const Offset(100, 0));
        await tester.pump();
        // Home shows underneath while the section slides right.
        expect(find.text('FELIX'), findsOneWidget);
        expect(find.text('My Nutrition'), findsOneWidget);
        expect(tester.getTopLeft(find.text('My Nutrition')).dx,
            greaterThan(100));
        await drag.moveBy(const Offset(120, 0));
        await drag.up();
        await tester.pumpAndSettle();

        expect(find.text('My Nutrition'), findsNothing);
        expect(find.text('FELIX'), findsOneWidget);
        expect(AppRouter.router.routerDelegate.currentConfiguration.uri.path,
            AppRouter.home);
      }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

      testWidgets('iOS: a short, slow swipe slides back into place',
          (tester) async {
        await openNutrition(tester);
        await tester.timedDragFrom(const Offset(5, 400), const Offset(80, 0),
            const Duration(seconds: 1));
        await tester.pumpAndSettle();

        expect(find.text('My Nutrition'), findsOneWidget);
        expect(tester.getTopLeft(find.text('My Nutrition')).dx, lessThan(100));
        expect(AppRouter.router.routerDelegate.currentConfiguration.uri.path,
            AppRouter.nutrition);

        // And it still works afterwards.
        await tester.dragFrom(const Offset(5, 400), const Offset(300, 0));
        await tester.pumpAndSettle();
        expect(find.text('My Nutrition'), findsNothing);
      }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

      testWidgets('iOS: a swipe away from the edge does nothing',
          (tester) async {
        await openNutrition(tester);
        await tester.dragFrom(const Offset(120, 400), const Offset(250, 0));
        await tester.pumpAndSettle();
        expect(find.text('My Nutrition'), findsOneWidget);
      }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

      testWidgets('Android keeps its own system back gesture only',
          (tester) async {
        await openNutrition(tester);
        expect(find.byKey(const Key('back-swipe-edge')), findsNothing);
        await tester.dragFrom(const Offset(5, 400), const Offset(300, 0));
        await tester.pumpAndSettle();
        expect(find.text('My Nutrition'), findsOneWidget);
      }, variant: TargetPlatformVariant.only(TargetPlatform.android));
    });

    testWidgets('reduced motion: sections open without a reveal',
        (tester) async {
      _phoneSize(tester);
      _reduceMotion(tester);
      await _pumpHome(tester);

      await tester.tap(nutritionTile);
      await tester.pump();
      await tester.pump();
      expect(find.byType(CircleRevealTransition), findsNothing);
      expect(find.text('My Nutrition'), findsOneWidget);
      expect(find.text('FELIX'), findsNothing);
    });

    testWidgets('switching tabs cross-fades briefly', (tester) async {
      _phoneSize(tester);
      await _pumpHome(tester);

      await tester.tap(find.bySemanticsLabel('Profile'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 90));
      // Mid-fade both tabs are on stage.
      expect(find.text('FELIX'), findsOneWidget);
      expect(find.text('About me'), findsWidgets);

      await tester.pumpAndSettle();
      expect(find.text('FELIX'), findsNothing);
      expect(find.text('About me'), findsWidgets);
    });

    testWidgets('reduced motion: tabs switch instantly', (tester) async {
      _phoneSize(tester);
      _reduceMotion(tester);
      await _pumpHome(tester);

      await tester.tap(find.bySemanticsLabel('Profile'));
      await tester.pump();
      expect(find.text('FELIX'), findsNothing);
    });
  });
}
