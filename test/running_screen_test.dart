import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitrix/core/constants/app_constants.dart';
import 'package:fitrix/core/router/app_router.dart';
import 'package:fitrix/core/session/app_session.dart';
import 'package:fitrix/core/session/session_providers.dart';
import 'package:fitrix/core/time/today_provider.dart';
import 'package:fitrix/features/running/data/location_source.dart';
import 'package:fitrix/features/running/data/run_store.dart';
import 'package:fitrix/features/running/data/run_track.dart';
import 'package:fitrix/features/running/presentation/run_recorder.dart';
import 'package:fitrix/features/running/presentation/run_voice.dart';
import 'package:fitrix/features/running/presentation/screens/live_run_screen.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/features/workouts/presentation/providers/workouts_provider.dart';
import 'package:fitrix/core/widgets/coach_card.dart';
import 'package:fitrix/main.dart';

import 'support/overflow.dart';

/// A Tuesday; the week started on Monday the 19th.
final _now = DateTime(2026, 10, 20, 15);

class _SilentSpeaker implements Speaker {
  @override
  Future<Set<String>> languages() async => {'en', 'ru', 'uz', 'es'};

  @override
  Future<void> prepare() async {}

  @override
  Future<bool> speak(String text, {required String language}) async => true;

  @override
  Future<void> stop() async {}
}

class _FakeSource implements LocationSource {
  int starts = 0;
  StreamController<RunPoint>? _c;

  @override
  Future<LocationAccess> ensureAccess() async => LocationAccess.granted;

  @override
  Future<bool> reducedAccuracy() async => false;

  @override
  Stream<RunPoint> start() {
    starts++;
    return (_c = StreamController<RunPoint>(sync: true)).stream;
  }

  @override
  Future<void> stop() async {
    await _c?.close();
    _c = null;
  }
}

/// A run saved in prefs by an app that was killed: 12 fixes 100 m apart,
/// 30 s apart, ending an hour ago.
Map<String, Object> _killedRun() {
  final start = _now.subtract(const Duration(hours: 1));
  return {
    runInProgressKey: jsonEncode({
      'startedAt': start.toUtc().toIso8601String(),
      'templateId': null,
      'phase': 'running',
      'points': [
        for (var i = 0; i <= 12; i++)
          [
            41.0 + i * 0.0009,
            69.0,
            null,
            5.0,
            start.add(Duration(seconds: 30 * i)).millisecondsSinceEpoch,
          ],
      ],
      'pauses': <Object>[],
    }),
  };
}

class _Rig {
  _Rig(this.tester, this.container, this.router, this.source);
  final WidgetTester tester;
  final ProviderContainer container;
  final GoRouter router;
  final _FakeSource source;

  RunSession? get session => container.read(runRecorderProvider);
  String get location =>
      router.routerDelegate.currentConfiguration.last.matchedLocation;

  /// How many live run screens are on the stack.
  int get liveScreens => router.routerDelegate.currentConfiguration.matches
      .where((m) => m.matchedLocation == AppRouter.liveRun)
      .length;

  void saveRun(String id, DateTime at, double meters, Duration moving) {
    container.read(workoutHistoryProvider.notifier).add(CompletedWorkout(
          id: id,
          templateId: 'free_run',
          name: 'Run $id',
          sport: Sport.running,
          startedAt: at,
          finishedAt: at.add(moving),
          exercises: const [],
        ));
    container.read(runsProvider.notifier).put(
          id,
          RunDetails(
            startedAt: at,
            moving: moving,
            elapsed: moving,
            pauses: 0,
            meters: meters,
            splits: const [],
            route: const [],
          ),
        );
  }
}

Future<_Rig> _rig(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  double textScale = 1,
  String language = 'en',
  Map<String, Object> prefsValues = const {},
}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  SharedPreferences.setMockInitialValues({
    AppConstants.keyOnboardingComplete: true,
    'user_name': 'Alex',
    'language': language,
    ...prefsValues,
  });
  final prefs = await SharedPreferences.getInstance();
  final session = AppSession(prefs);
  final source = _FakeSource();
  final container = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    appSessionProvider.overrideWithValue(session),
    clockProvider.overrideWithValue(() => _now),
    locationSourceProvider.overrideWithValue(source),
    speakerProvider.overrideWithValue(_SilentSpeaker()),
  ]);
  addTearDown(container.dispose);
  final router = AppRouter.create(session);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: FitrixApp(router: router),
  ));
  await tester.pumpAndSettle();
  return _Rig(tester, container, router, source);
}

Future<void> _settle(WidgetTester tester) async {
  await tester
      .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
  await tester.pumpAndSettle();
}

Future<void> _openRunning(_Rig r) async {
  r.router.go(AppRouter.sportWorkouts(Sport.running));
  await r.tester.pumpAndSettle();
}

void main() {
  group('history and week', () {
    testWidgets('lists saved runs newest first with distance, time, pace',
        (t) async {
      final r = await _rig(t);
      r.saveRun(
          'a', DateTime(2026, 10, 18, 7), 5000, const Duration(minutes: 28));
      r.saveRun('b', DateTime(2026, 10, 20, 7), 6220,
          const Duration(minutes: 30, seconds: 12));
      await _openRunning(r);

      expect(find.text('6.22 km · 30:12 · 4:51 /km'), findsOneWidget);
      expect(find.text('5.00 km · 28:00 · 5:36 /km'), findsOneWidget);
      expect(
        t.getTopLeft(find.text('6.22 km · 30:12 · 4:51 /km')).dy,
        lessThan(t.getTopLeft(find.text('5.00 km · 28:00 · 5:36 /km')).dy),
      );
    });

    testWidgets('this week counts only runs since Monday', (t) async {
      final r = await _rig(t);
      r.saveRun(
          'a', DateTime(2026, 10, 20, 7), 5000, const Duration(minutes: 28));
      r.saveRun(
          'b', DateTime(2026, 10, 19, 7), 3000, const Duration(minutes: 17));
      r.saveRun(
          'old', DateTime(2026, 10, 18, 7), 10000, const Duration(minutes: 60));
      await _openRunning(r);

      expect(find.byKey(const ValueKey('run-week-km')), findsOneWidget);
      expect(
          find.descendant(
              of: find.byKey(const ValueKey('run-week-km')),
              matching: find.text('8.00')),
          findsOneWidget);
      expect(
          find.descendant(
              of: find.byKey(const ValueKey('run-week-runs')),
              matching: find.text('2 runs')),
          findsOneWidget);
    });

    testWidgets('tap opens the summary; Delete removes run and history',
        (t) async {
      final r = await _rig(t);
      r.saveRun('b', DateTime(2026, 10, 20, 7), 6220,
          const Duration(minutes: 30, seconds: 12));
      await _openRunning(r);

      await t.tap(find.text('6.22 km · 30:12 · 4:51 /km'));
      await t.pumpAndSettle();
      expect(r.location, AppRouter.runSummary('b'));

      await t.tap(find.byKey(const ValueKey('run-delete')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const ValueKey('run-delete-confirm')));
      await t.pumpAndSettle();

      expect(r.container.read(workoutHistoryProvider), isEmpty);
      expect(r.container.read(runsProvider), isEmpty);
      expect(r.location, AppRouter.sportWorkouts(Sport.running));
      expect(find.text('6.22 km · 30:12 · 4:51 /km'), findsNothing);
      expect(find.text('No runs yet. The runs you record will show up here.'),
          findsOneWidget);
    });
  });

  group('Start run', () {
    testWidgets('starts a free run and opens the live screen', (t) async {
      final r = await _rig(t);
      await _openRunning(r);
      await t.tap(find.byKey(const ValueKey('run-start')));
      await t.pumpAndSettle();
      expect(r.location, AppRouter.liveRun);
      expect(r.session!.phase, RunPhase.running);
      expect(r.source.starts, 1);
    });

    testWidgets('with a run already on, it reopens it and starts no second',
        (t) async {
      final r = await _rig(t);
      await _openRunning(r);
      await t.tap(find.byKey(const ValueKey('run-start')));
      await t.pumpAndSettle();
      r.router.pop();
      await t.pumpAndSettle();
      expect(r.location, AppRouter.sportWorkouts(Sport.running));

      await t.tap(find.byKey(const ValueKey('run-start')));
      await t.pumpAndSettle();
      expect(r.location, AppRouter.liveRun);
      expect(r.source.starts, 1);
    });

    testWidgets('a double tap on Start run opens one live screen', (t) async {
      final r = await _rig(t);
      await _openRunning(r);
      await t.tap(find.byKey(const ValueKey('run-start')));
      await t.tap(find.byKey(const ValueKey('run-start')));
      await t.pumpAndSettle();
      expect(r.liveScreens, 1);
      expect(r.source.starts, 1);
      r.router.pop();
      await t.pumpAndSettle();
      expect(r.location, AppRouter.sportWorkouts(Sport.running));
    });

    testWidgets('the workouts grid starts a running template', (t) async {
      final r = await _rig(t);
      r.container
          .read(workoutTemplatesProvider.notifier)
          .add(Sport.running, 'Easy 5K');
      await _openRunning(r);
      expect(find.text('Workouts'), findsOneWidget);
      final card = find
          .ancestor(
              of: find.text('Easy 5K'), matching: find.byType(Dismissible))
          .first;
      await t.tap(find.descendant(of: card, matching: find.text('Start')));
      await t.pumpAndSettle();
      expect(r.location, AppRouter.liveRun);
      expect(r.session!.template!.name, 'Easy 5K');
    });
  });

  group('run in progress bar', () {
    testWidgets('shows above the tabs while a run exists; tap returns to it',
        (t) async {
      final r = await _rig(t);
      expect(find.byKey(const ValueKey('run-bar')), findsNothing);
      await _openRunning(r);
      await t.tap(find.byKey(const ValueKey('run-start')));
      await t.pumpAndSettle();
      // Leave the live screen with its arrow: the run keeps recording.
      r.router.pop();
      await t.pumpAndSettle();

      expect(find.text('Run in progress'), findsOneWidget);
      expect(find.text(' · 0.00 km'), findsOneWidget);
      expect(find.text('Return'), findsOneWidget);
      await t.tap(find.byKey(const ValueKey('run-bar')));
      await t.pumpAndSettle();
      expect(r.location, AppRouter.liveRun);
      expect(r.session, isNotNull);
    });

    testWidgets('a double tap on the bar opens one live screen', (t) async {
      final r = await _rig(t);
      await _openRunning(r);
      await t.tap(find.byKey(const ValueKey('run-start')));
      await t.pumpAndSettle();
      r.router.pop();
      await t.pumpAndSettle();

      await t.tap(find.byKey(const ValueKey('run-bar')));
      await t.tap(find.byKey(const ValueKey('run-bar')));
      await t.pumpAndSettle();
      expect(r.liveScreens, 1);
      // Opening it again while it is on top changes nothing.
      openLiveRun(r.router);
      await t.pumpAndSettle();
      expect(r.liveScreens, 1);
      r.router.pop();
      await t.pumpAndSettle();
      expect(r.location, AppRouter.sportWorkouts(Sport.running));
    });

    testWidgets('shows for a restored run too, and coexists with the gym bar',
        (t) async {
      final r = await _rig(t, prefsValues: _killedRun());
      // The launch prompt is in the way; leave the run as it is.
      await t.tap(find.text('Resume'));
      await t.pumpAndSettle();
      r.router.pop();
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('run-bar')), findsOneWidget);

      final gym = r.container
          .read(workoutTemplatesProvider)
          .firstWhere((w) => w.sport == Sport.gym);
      r.container.read(activeWorkoutProvider.notifier).start(gym);
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('run-bar')), findsOneWidget);
      expect(find.byKey(const ValueKey('activeWorkoutSheetSurface')),
          findsOneWidget);
      expect(
        t.getRect(find.byKey(const ValueKey('run-bar'))).bottom,
        lessThanOrEqualTo(t
                .getRect(
                    find.byKey(const ValueKey('activeWorkoutSheetSurface')))
                .top +
            0.5),
      );
      expectNoOverflow(t);
    });

    testWidgets('gone once the run is discarded', (t) async {
      final r = await _rig(t);
      await _openRunning(r);
      await t.tap(find.byKey(const ValueKey('run-start')));
      await t.pumpAndSettle();
      r.router.pop();
      await t.pumpAndSettle();
      await t.runAsync(
          () => r.container.read(runRecorderProvider.notifier).discard());
      await _settle(t);
      expect(find.byKey(const ValueKey('run-bar')), findsNothing);
    });
  });

  group('unfinished run at launch', () {
    testWidgets('asks once; Resume opens the live run with the old distance',
        (t) async {
      final r = await _rig(t, prefsValues: _killedRun());
      expect(find.text('Unfinished run · 1.20 km'), findsOneWidget);

      await t.tap(find.text('Resume'));
      await t.pumpAndSettle();
      expect(r.location, AppRouter.liveRun);
      expect(find.text('1.20'), findsWidgets);

      r.router.go(AppRouter.home);
      await t.pumpAndSettle();
      expect(find.textContaining('Unfinished run'), findsNothing);
    });

    testWidgets('Save finishes the run and opens its summary', (t) async {
      final r = await _rig(t, prefsValues: _killedRun());
      await t.tap(find.text('Save'));
      await _settle(t);

      final saved = r.container.read(workoutHistoryProvider);
      expect(saved, hasLength(1));
      expect(r.session, isNull);
      expect(r.location, AppRouter.runSummary(saved.single.id));
      expect(r.container.read(runsProvider)[saved.single.id]!.meters,
          greaterThan(1100));
    });

    testWidgets('Discard asks first; Cancel keeps the run', (t) async {
      final r = await _rig(t, prefsValues: _killedRun());
      await t.tap(find.text('Discard'));
      await t.pumpAndSettle();
      expect(find.text('Discard this run?'), findsOneWidget);
      await t.tap(find.text('Cancel'));
      await t.pumpAndSettle();
      expect(r.session, isNotNull);

      // Back at the choice, not lost.
      expect(find.text('Unfinished run · 1.20 km'), findsOneWidget);
      await t.tap(find.text('Resume'));
      await t.pumpAndSettle();
      expect(r.location, AppRouter.liveRun);
    });

    testWidgets('Discard confirmed throws the run away', (t) async {
      final r = await _rig(t, prefsValues: _killedRun());
      await t.tap(find.text('Discard'));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const ValueKey('run-discard-confirm')));
      await _settle(t);
      expect(r.session, isNull);
      expect(r.container.read(workoutHistoryProvider), isEmpty);
      expect(find.byKey(const ValueKey('run-bar')), findsNothing);
    });

    testWidgets('no prompt without a restored run', (t) async {
      await _rig(t);
      expect(find.textContaining('Unfinished run'), findsNothing);
    });
  });

  testWidgets('the Felix coach card is on the Running screen', (t) async {
    final r = await _rig(t);
    await _openRunning(r);
    await t.scrollUntilVisible(find.byType(CoachCard), 300,
        scrollable: find.byType(Scrollable).last);
    expect(find.byType(CoachCard), findsOneWidget);
    expect(find.text('Ask'), findsOneWidget);
    expect(find.textContaining('RUNNING'), findsWidgets);
  });

  group('run bar distance with the real Inter font, SE, text 1.3', () {
    Future<void> loadInter(WidgetTester t) => t.runAsync(() async {
          final loader = FontLoader('Inter');
          for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
            loader.addFont(rootBundle.load('assets/fonts/Inter-$w.ttf'));
          }
          await loader.load();
        });

    for (final lang in ['ru', 'uz', 'en', 'es']) {
      testWidgets('$lang: the km value is never cut', (t) async {
        await loadInter(t);
        await _rig(t,
            size: iPhoneSeSize,
            textScale: 1.3,
            language: lang,
            prefsValues: _killedRun());
        // Dismiss the launch prompt by resuming, then leave the live run.
        await t.tap(find.byType(TextButton).last);
        await t.pumpAndSettle();
        Navigator.of(t.element(find.byType(Scaffold).first)).maybePop();
        await t.pumpAndSettle();
        final distance = find.byKey(const ValueKey('run-bar-distance'));
        expect(distance, findsOneWidget);
        final text = t.widget<Text>(distance);
        final render = t.renderObject<RenderParagraph>(distance);
        expect(render.didExceedMaxLines, isFalse);
        expect(text.data, contains('1'));
        // The whole text is laid out on one line inside the screen.
        expect(t.getRect(distance).right, lessThanOrEqualTo(375));
        expectNoOverflow(t);
      });
    }
  });

  group('run bar label with the real Inter font, 375 wide, text 1.0', () {
    for (final lang in ['en', 'es', 'ru', 'uz']) {
      testWidgets('$lang: the label and Return are not cut', (t) async {
        await t.runAsync(() async {
          final loader = FontLoader('Inter');
          for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
            loader.addFont(rootBundle.load('assets/fonts/Inter-$w.ttf'));
          }
          await loader.load();
        });
        await _rig(t,
            size: const Size(375, 812),
            language: lang,
            prefsValues: _killedRun());
        await t.tap(find.byType(TextButton).last);
        await t.pumpAndSettle();
        Navigator.of(t.element(find.byType(Scaffold).first)).maybePop();
        await t.pumpAndSettle();
        final bar = find.byKey(const ValueKey('run-bar'));
        for (final f in [
          find.descendant(
              of: bar, matching: find.byKey(const ValueKey('run-bar-return'))),
          find.descendant(
              of: bar,
              matching: find.byKey(const ValueKey('run-bar-distance'))),
          find.descendant(
              of: bar,
              matching: find.byWidgetPredicate((w) =>
                  w is Text &&
                  w.maxLines == 1 &&
                  w.key == null &&
                  w.overflow == TextOverflow.ellipsis)),
        ]) {
          expect(t.renderObject<RenderParagraph>(f.first).didExceedMaxLines,
              isFalse);
        }
        expectNoOverflow(t);
      });
    }
  });

  group('workout settings', () {
    testWidgets('the gear next to Start opens the run voice setting, SE x1.3',
        (t) async {
      final r =
          await _rig(t, size: iPhoneSeSize, textScale: 1.3, language: 'ru');
      await _openRunning(r);
      await t.tap(find.byKey(const ValueKey('run-settings')));
      await t.pumpAndSettle();
      expect(find.text('Настройки тренировки'), findsOneWidget);
      expect(
          t
              .widget<Switch>(
                  find.byKey(const ValueKey('activity-voice-toggle')))
              .value,
          true);
      expectNoOverflow(t);
    });
  });

  group('SE 375x667, text 1.3, ru', () {
    testWidgets('running screen with history and a run in progress', (t) async {
      final r =
          await _rig(t, size: iPhoneSeSize, textScale: 1.3, language: 'ru');
      for (var i = 0; i < 6; i++) {
        r.saveRun('r$i', DateTime(2026, 10, 20 - i, 7), 10420.0 + i,
            Duration(hours: 1, minutes: 5, seconds: i));
      }
      r.container
          .read(workoutTemplatesProvider.notifier)
          .add(Sport.running, 'Длинная воскресная пробежка');
      await _openRunning(r);
      expectNoOverflow(t);
      await t.tap(find.byKey(const ValueKey('run-start')));
      await t.pumpAndSettle();
      r.router.pop();
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('run-bar')), findsOneWidget);
      expectNoOverflow(t);
      await expectNoOverflowWhileScrolling(
          t, find.byType(ListView).first, -600);
    });

    testWidgets('the launch prompt', (t) async {
      await _rig(t,
          size: iPhoneSeSize,
          textScale: 1.3,
          language: 'ru',
          prefsValues: _killedRun());
      expect(find.textContaining('Незавершённая пробежка'), findsOneWidget);
      expectNoOverflow(t);
    });
  });
}
