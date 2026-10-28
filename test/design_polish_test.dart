// Layout checks for the fixes from the screenshot tour: nothing overflows on
// an iPhone SE at text scale 1.3, key buttons keep their full Russian label
// on a 393 pt iPhone, and sheets cover the tab bar.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitrix/core/router/app_router.dart';
import 'package:fitrix/core/session/session_providers.dart';
import 'package:fitrix/core/theme/app_theme.dart';
import 'package:fitrix/features/chat/data/models/assistant_topic.dart';
import 'package:fitrix/features/checkin/presentation/widgets/checkin_sheet.dart';
import 'package:fitrix/features/language/presentation/screens/language_screen.dart';
import 'package:fitrix/features/plan/presentation/widgets/add_session_sheet.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/features/workouts/data/workout_catalog.dart';
import 'package:fitrix/features/workouts/presentation/providers/workouts_provider.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

import 'support/overflow.dart';
import 'tour/tour_harness.dart';

/// iPhone 15/16 logical size.
const proSize = Size(393, 852);

Future<void> setScreen(WidgetTester t, Size size) async {
  t.view.physicalSize = size * 3;
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
}

/// [child] inside a localized MaterialApp at [scale].
Widget localized(Widget child,
        {String lang = 'ru',
        double scale = 1,
        List<Override> overrides = const [],
        SharedPreferences? prefs}) =>
    ProviderScope(
      overrides: [
        if (prefs != null) sharedPreferencesProvider.overrideWithValue(prefs),
        ...overrides,
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        locale: Locale(lang),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, c) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: c!,
        ),
        home: child,
      ),
    );

/// Expects the [Text] showing [label] to be drawn whole and at full size:
/// no ellipsis, and not shrunk by a scale-down FittedBox.
void expectFullLabel(WidgetTester t, String label) {
  final f = find.text(label);
  expect(f, findsWidgets, reason: label);
  final para = t.renderObject<RenderParagraph>(f.first);
  expect(para.didExceedMaxLines, isFalse, reason: '$label is cut short');
  RenderObject? o = para.parent;
  while (o != null && o is! RenderFittedBox) {
    o = o.parent;
  }
  if (o is RenderFittedBox) {
    expect(o.size.width, greaterThanOrEqualTo(para.size.width - 0.5),
        reason: '$label is shrunk to fit');
  }
}

/// Expects the label [text] of an ElevatedButton to be laid out at its
/// full line height and drawn inside the button: a fixed button height
/// clips descenders without reporting an overflow.
void expectButtonLabelUnclipped(WidgetTester t, String text) {
  final label = find.text(text).first;
  final para = t.renderObject<RenderParagraph>(label);
  final style = para.text.style!;
  final lineHeight = para.textScaler.scale(style.fontSize!) * style.height!;
  expect(para.size.height, greaterThanOrEqualTo(lineHeight - 1),
      reason: '"$text" squeezed by its button');
  final button = t.getRect(
      find.ancestor(of: label, matching: find.byType(ElevatedButton)).first);
  final rect = t.getRect(label);
  expect(button.top <= rect.top && rect.bottom <= button.bottom, isTrue,
      reason: '"$text" drawn outside its button');
}

void main() {
  group('language screen', () {
    testWidgets('scrolls instead of overflowing on SE at text scale 1.3',
        (t) async {
      await setScreen(t, iPhoneSeSize);
      SharedPreferences.setMockInitialValues({'language': 'ru'});
      final prefs = await SharedPreferences.getInstance();
      await t.pumpWidget(
          localized(const LanguageScreen(), scale: 1.3, prefs: prefs));
      await t.pumpAndSettle();
      expectNoOverflow(t);
      await t.scrollUntilVisible(find.text('Продолжить'), 100,
          scrollable: find.byType(Scrollable).first);
      expect(find.text('Продолжить').hitTestable(), findsOneWidget);
    });

    testWidgets('language buttons are tall enough for their label', (t) async {
      await setScreen(t, proSize);
      SharedPreferences.setMockInitialValues({'language': 'ru'});
      final prefs = await SharedPreferences.getInstance();
      await t.pumpWidget(localized(const LanguageScreen(), prefs: prefs));
      await t.pumpAndSettle();
      for (final label in ['Русский', 'English', 'Español']) {
        final para = t.renderObject<RenderParagraph>(find.text(label));
        // One line of headingS (16 × 1.4): any less and descenders are cut.
        expect(para.size.height, greaterThanOrEqualTo(22),
            reason: '$label is squeezed by its button');
      }
    });
  });

  group('key buttons keep their full Russian label at 393 pt', () {
    testWidgets('live gym', (t) async {
      final r = await pumpTour(t, proRuLight);
      r.container
          .read(activeWorkoutProvider.notifier)
          .start(WorkoutCatalog.defaults.first);
      r.container.read(activeWorkoutExpandedProvider.notifier).state = true;
      await r.go(AppRouter.home);
      expectFullLabel(t, 'Упражнение');
      expectFullLabel(t, 'Завершить');
      expectNoOverflow(t);
    });

    testWidgets('workout complete', (t) async {
      final r = await pumpTour(t, proRuLight);
      final w = WorkoutCatalog.defaults.first;
      r.container.read(pendingCompletedWorkoutProvider.notifier).state =
          CompletedWorkout(
        templateId: w.id,
        name: w.name,
        sport: w.sport,
        startedAt: tourNow.subtract(const Duration(minutes: 70)),
        finishedAt: tourNow,
        exercises: w.exercises,
      );
      await r.go(AppRouter.workoutComplete);
      expectFullLabel(t, 'Не сохранять');
      expectFullLabel(t, 'Сохранить');
      expectNoOverflow(t);
    });

    testWidgets('program detail and its start sheet', (t) async {
      final r = await pumpTour(t, proRuLight);
      await r.go(AppRouter.program('upper-lower-4'));
      expectFullLabel(t, 'Спросить Felix');
      expectFullLabel(t, 'Начать');
      await r.tapKey('program-start');
      expectFullLabel(t, 'Другая дата');
      expectNoOverflow(t);
    });

    testWidgets('exercise detail', (t) async {
      final r = await pumpTour(t, proRuLight);
      await r.go(AppRouter.exercise('bench-press'));
      expectFullLabel(t, 'Спросить');
      expectFullLabel(t, 'Добавить');
      expectNoOverflow(t);
    });

    testWidgets('Felix plan card', (t) async {
      final r = await pumpTour(t, proRuLight);
      await r.go(AppRouter.felixChat(AssistantTopic.gym));
      expectFullLabel(t, 'Добавить план');
      expectNoOverflow(t);
    });
  });

  group('sheets and the menu cover the tab bar', () {
    testWidgets('check-in sheet opens on the root navigator', (t) async {
      final r = await pumpTour(t, proRuLight, seed: const Seed(checkIn: false));
      await r.go(AppRouter.home);
      showCheckInSheet(r.context);
      await r.settle();
      final inSheet = t.element(find.byType(BottomSheet));
      expect(Navigator.of(inSheet),
          same(Navigator.of(inSheet, rootNavigator: true)));
    });

    testWidgets('week plan sheet opens on the root navigator', (t) async {
      final r = await pumpTour(t, proRuLight);
      await r.go(AppRouter.weekPlan);
      showAddSessionSheet(r.context);
      await r.settle();
      final inSheet = t.element(find.byType(BottomSheet));
      expect(Navigator.of(inSheet),
          same(Navigator.of(inSheet, rootNavigator: true)));
    });

    testWidgets('Home menu runs the full height of the screen', (t) async {
      final r = await pumpTour(t, proRuLight);
      await r.go(AppRouter.home);
      await t.tap(find.byIcon(Icons.menu).first);
      await r.settle();
      expect(t.getRect(find.byType(Drawer)).bottom, proRuLight.size.height);
    });
  });

  testWidgets('add exercise without a workout explains and offers the library',
      (t) async {
    final r = await pumpTour(t, proRuLight);
    await r.go(AppRouter.addExerciseTo());
    expect(find.text('Тренировка не идёт'), findsOneWidget);
    await r.tapKey('add-exercise-open-library');
    expect(r.router.routerDelegate.currentConfiguration.uri.path,
        AppRouter.exerciseLibrary);
  });

  testWidgets('live gym timer counts from the app clock', (t) async {
    final r = await pumpTour(t, proRuLight);
    r.container
        .read(activeWorkoutProvider.notifier)
        .start(WorkoutCatalog.defaults.first);
    r.container.read(activeWorkoutExpandedProvider.notifier).state = true;
    r.now = tourNow.add(const Duration(minutes: 12, seconds: 5));
    await r.go(AppRouter.home);
    await t.pump(const Duration(seconds: 1));
    expect(find.text('12:05'), findsOneWidget);
  });

  testWidgets('live gym weights use the Russian decimal comma', (t) async {
    final r = await pumpTour(t, proRuLight);
    r.container
        .read(activeWorkoutProvider.notifier)
        .start(WorkoutCatalog.defaults.first);
    r.container.read(activeWorkoutExpandedProvider.notifier).state = true;
    await r.go(AppRouter.home);
    expect(find.textContaining('36,5'), findsWidgets);
    expect(find.textContaining('36.5'), findsNothing);
  });

  group('no overflow on an iPhone SE at text scale 1.3', () {
    for (final (name, location) in [
      ('home', AppRouter.home),
      ('my workouts', AppRouter.workouts),
      ('gym', AppRouter.sportWorkouts(Sport.gym)),
      ('program', AppRouter.program('upper-lower-4')),
      ('progress', AppRouter.progress),
      ('training load', AppRouter.progressLoad),
      ('nutrition', AppRouter.nutrition),
      ('micronutrients', AppRouter.nutritionMicros),
      ('targets', AppRouter.nutritionTargets),
      ('recovery', AppRouter.recovery),
      ('ski summary', AppRouter.runSummary('ski-1')),
      ('ride summary', AppRouter.runSummary('ride-1')),
      ('profile', AppRouter.me),
    ]) {
      testWidgets(name, (t) async {
        final r = await pumpTour(t, seRuScaled);
        await r.go(location);
        expectNoOverflow(t, reason: name);
      });
    }

    testWidgets('home before the check-in', (t) async {
      final r = await pumpTour(t, seRuScaled, seed: Seed.empty);
      await r.go(AppRouter.home);
      expectNoOverflow(t);
    });

    testWidgets('live gym', (t) async {
      final r = await pumpTour(t, seRuScaled);
      r.container
          .read(activeWorkoutProvider.notifier)
          .start(WorkoutCatalog.defaults.first);
      r.container.read(activeWorkoutExpandedProvider.notifier).state = true;
      await r.go(AppRouter.home);
      expectNoOverflow(t);
    });
  });

  group('elevated button labels are not clipped at SE ×1.3', () {
    testWidgets('intro', (t) async {
      final r = await pumpTour(t, seRuScaled,
          seed: const Seed(onboarded: false, profile: false));
      await r.go(AppRouter.intro);
      expectButtonLabelUnclipped(t, 'Начать путь');
    });

    testWidgets('onboarding profile', (t) async {
      final r =
          await pumpTour(t, seRuScaled, seed: const Seed(onboarded: false));
      await r.go(AppRouter.profile);
      await t.scrollUntilVisible(find.text('Продолжить'), 200,
          scrollable: find.byType(Scrollable).first);
      await r.settle();
      expectButtonLabelUnclipped(t, 'Продолжить');
    });

    testWidgets('sign in', (t) async {
      final r = await pumpTour(t, seRuScaled,
          seed: const Seed(onboarded: false, profile: false), auth: true);
      await r.go(AppRouter.signIn);
      expectButtonLabelUnclipped(t, 'Получить код');
    });

    testWidgets('edit workout sheet', (t) async {
      final r = await pumpTour(t, seRuScaled);
      await r.go(AppRouter.sportWorkouts(Sport.gym));
      await t.longPress(find.text('Legs').first);
      await r.settle();
      expectButtonLabelUnclipped(t, 'Сохранить');
    });
  });

  testWidgets('weight sheet button sits above the home indicator', (t) async {
    final r = await pumpTour(t, proRuLight);
    await r.go(AppRouter.progressWeight);
    final add = find.byIcon(Icons.add);
    await t.ensureVisible(add.last);
    await t.tap(add.last);
    await r.settle();
    final save = t.getRect(find.byKey(const ValueKey('weight-save')));
    final bottomInset = t.view.viewPadding.bottom / t.view.devicePixelRatio;
    expect(bottomInset, greaterThan(0));
    expect(
        save.bottom, lessThanOrEqualTo(proRuLight.size.height - bottomInset));
  });
}
