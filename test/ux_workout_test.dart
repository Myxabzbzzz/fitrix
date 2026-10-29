import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitrix/core/session/session_providers.dart';
import 'package:fitrix/core/widgets/workout_card.dart';
import 'package:fitrix/features/exercises/data/exercise_catalog.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/features/workouts/data/workout_catalog.dart';
import 'package:fitrix/features/workouts/presentation/providers/workouts_provider.dart';
import 'package:fitrix/features/workouts/presentation/screens/sport_workouts_screen.dart';
import 'package:fitrix/features/workouts/presentation/widgets/active_workout_sheet.dart';
import 'package:fitrix/features/workouts/presentation/widgets/edit_workout_sheet.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';
import 'package:fitrix/core/i18n/catalog_overlay.dart';
import 'support/catalog_fixtures.dart';
import 'support/overflow.dart';

Future<ProviderContainer> _container() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final c = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
  addTearDown(c.dispose);
  return c;
}

Widget _app(ProviderContainer c, Widget home, {Locale? locale}) =>
    UncontrolledProviderScope(
      container: c,
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    );

void _size(WidgetTester tester, Size logical) {
  tester.view.physicalSize = logical * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

bool _fieldFocused() {
  final ctx = FocusManager.instance.primaryFocus?.context;
  return ctx != null && ctx.findAncestorWidgetOfExactType<TextField>() != null;
}

void main() {
  group('keyboard dismiss in the active workout', () {
    Future<void> pumpSheet(WidgetTester tester) async {
      _size(tester, const Size(390, 844));
      final c = await _container();
      c
          .read(activeWorkoutProvider.notifier)
          .start(WorkoutCatalog.defaults.first);
      await tester
          .pumpWidget(_app(c, const Scaffold(body: ActiveWorkoutSheet())));
      await tester.pump();
      c.read(activeWorkoutExpandedProvider.notifier).state = true;
      await tester.pumpAndSettle();
    }

    final doneFinder = find.text('Done');

    testWidgets('focusing a kg field shows Done; Done unfocuses',
        (tester) async {
      await pumpSheet(tester);
      expect(doneFinder, findsNothing);
      await tester.tap(find.byType(TextField).first);
      await tester.pumpAndSettle();
      expect(_fieldFocused(), isTrue);
      expect(doneFinder, findsOneWidget);

      await tester.tap(doneFinder);
      await tester.pumpAndSettle();
      expect(_fieldFocused(), isFalse);
      expect(doneFinder, findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('tapping empty space unfocuses', (tester) async {
      await pumpSheet(tester);
      await tester.tap(find.byType(TextField).first);
      await tester.pumpAndSettle();
      expect(_fieldFocused(), isTrue);

      // The caption above the progress bar is inert list space.
      // The caption is wider now, so tap in the gap on its left instead.
      await tester.tapAt(
          tester.getTopLeft(find.byKey(ActiveWorkoutSheet.captionKey)) +
              const Offset(-10, 4));
      await tester.pumpAndSettle();
      expect(_fieldFocused(), isFalse);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets(
        'check toggles while a field is focused and closes the keyboard',
        (tester) async {
      await pumpSheet(tester);
      final c = ProviderScope.containerOf(
          tester.element(find.byType(ActiveWorkoutSheet)));
      expect(c.read(activeWorkoutProvider)!.completedSets, 0);
      await tester.tap(find.byType(TextField).first);
      await tester.pumpAndSettle();
      expect(_fieldFocused(), isTrue);

      await tester.tap(find.byIcon(Icons.check).first);
      // The rest bar (now shown) ticks, so no pumpAndSettle.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(c.read(activeWorkoutProvider)!.completedSets, 1);
      expect(_fieldFocused(), isFalse);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('focused bottom field ends above the Done bar', (tester) async {
      await pumpSheet(tester);
      // Only the current exercise is expanded now, so give it enough sets
      // for the list to scroll.
      final c = ProviderScope.containerOf(
          tester.element(find.byType(ActiveWorkoutSheet)));
      for (var i = 0; i < 10; i++) {
        c.read(activeWorkoutProvider.notifier).addSet(0);
      }
      await tester.pumpAndSettle();
      tester.view.viewInsets = const FakeViewPadding(bottom: 900);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      final scrollable = tester.state<ScrollableState>(find.descendant(
          of: find.byKey(const ValueKey('table')),
          matching: find.byType(Scrollable).first));

      // The list stops above the Finish button now (it only gets the full
      // height while a field is focused), so measure against the list.
      final tableRect = tester.getRect(find.descendant(
          of: find.byKey(const ValueKey('table')),
          matching: find.byType(ListView)));
      // Lowest field inside the viewport, scrolled flush with its bottom edge
      // so only scrollPadding can lift it clear of the Done bar.
      Finder lowest() => find
          .byType(TextField)
          .evaluate()
          .map((e) => find.byElementPredicate((x) => x == e))
          .where((f) => tester.getRect(f).bottom <= tableRect.bottom)
          .last;
      final pos = scrollable.position;
      pos.jumpTo(pos.pixels + 40);
      await tester.pumpAndSettle();
      final before = tester.getRect(lowest()).bottom;
      pos.jumpTo(pos.pixels + before - (tableRect.bottom - 2));
      await tester.pumpAndSettle();
      final last = lowest();
      expect(tester.getRect(last).bottom, greaterThan(tableRect.bottom - 44));
      await tester.tap(last);
      await tester.pumpAndSettle();
      expect(_fieldFocused(), isTrue);
      final bar = find.byKey(const ValueKey('keyboardDone'));
      expect(bar, findsOneWidget);
      expect(tester.getRect(last).bottom,
          lessThanOrEqualTo(tester.getTopLeft(bar).dy));
      expect(tester.getBottomLeft(bar).dy, 844 - 300);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('exercise list dismisses the keyboard on drag', (tester) async {
      await pumpSheet(tester);
      final list = tester.widget<ListView>(find.descendant(
          of: find.byKey(const ValueKey('table')),
          matching: find.byType(ListView)));
      expect(list.keyboardDismissBehavior,
          ScrollViewKeyboardDismissBehavior.onDrag);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('edit button on the workout card', () {
    testWidgets('icon opens the edit sheet for that template', (tester) async {
      _size(tester, const Size(375, 667));
      final c = await _container();
      await tester
          .pumpWidget(_app(c, const SportWorkoutsScreen(sport: Sport.gym)));
      await tester.pumpAndSettle();

      final edit = find.byKey(const ValueKey('workoutCardEdit'));
      expect(edit, findsWidgets);
      expect(tester.getSize(edit.first).width, greaterThanOrEqualTo(44));
      expect(find.bySemanticsLabel(RegExp('Edit workout, ')), findsWidgets);
      final title =
          tester.widget<WorkoutCard>(find.byType(WorkoutCard).at(1)).title;
      await tester.tap(edit.at(1));
      await tester.pumpAndSettle();
      expect(find.byType(EditWorkoutSheet), findsOneWidget);
      expect(find.widgetWithText(TextField, title), findsOneWidget);
    });

    testWidgets('absent when onEdit is null', (tester) async {
      await tester.pumpWidget(const MaterialApp(
          home: Scaffold(
              body: SizedBox(
                  width: 160,
                  child: WorkoutCard(title: 'A', dayLabel: 'Mon')))));
      expect(find.byKey(const ValueKey('workoutCardEdit')), findsNothing);
      expect(find.byIcon(Icons.edit_outlined), findsNothing);
    });

    for (final code in ['en', 'ru']) {
      testWidgets('SE size no overflow ($code)', (tester) async {
        _size(tester, iPhoneSeSize);
        final c = await _container();
        await tester.pumpWidget(_app(
            c, const SportWorkoutsScreen(sport: Sport.gym),
            locale: Locale(code)));
        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.edit_outlined), findsWidgets);
        expectNoOverflow(tester);
      });
    }
  });

  group('starter workouts in Russian (catalog overlay)', () {
    late ExerciseCatalog catalog;
    setUpAll(() async => catalog = await ExerciseCatalog.load(rootBundle));

    Future<ProviderContainer> ru() async {
      SharedPreferences.setMockInitialValues({'language': 'ru'});
      final prefs = await SharedPreferences.getInstance();
      final c = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        exerciseCatalogProvider.overrideWith((ref) async => catalog),
        catalogBundleProvider.overrideWithValue(
            FixtureBundle.locale('ru', {'workout_catalog': ruWorkoutCatalog})),
      ]);
      addTearDown(c.dispose);
      // In the app the overlay is in long before a sheet opens.
      await c.read(catalogOverlayLoaderProvider.future);
      return c;
    }

    WorkoutTemplate legs(ProviderContainer c) =>
        c.read(workoutTemplatesProvider).firstWhere((t) => t.id == 'gym-legs');

    testWidgets('read translated; saving unchanged keeps the English name',
        (tester) async {
      _size(tester, iPhoneSeSize);
      final c = await ru();
      await tester.pumpWidget(_app(
          c, const SportWorkoutsScreen(sport: Sport.gym),
          locale: const Locale('ru')));
      await tester.pumpAndSettle();
      expect(
          find.byWidgetPredicate((w) => w is WorkoutCard && w.title == 'Ноги'),
          findsOneWidget);

      await tester.pumpWidget(_app(
          c, Scaffold(body: EditWorkoutSheet(template: legs(c))),
          locale: const Locale('ru')));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextField, 'Ноги'), findsOneWidget);
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      expect(legs(c).name, 'Legs');
      expect(legs(c).exercises.first.name, 'Squat');
    });

    testWidgets('a renamed starter workout keeps the user\'s name',
        (tester) async {
      _size(tester, iPhoneSeSize);
      final c = await ru();
      await tester.pumpWidget(_app(
          c, Scaffold(body: EditWorkoutSheet(template: legs(c))),
          locale: const Locale('ru')));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.widgetWithText(TextField, 'Ноги'), 'Мои ноги');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      expect(legs(c).name, 'Мои ноги');
      // Save popped the sheet's only route: start a fresh app.
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(_app(
          c, const SportWorkoutsScreen(sport: Sport.gym),
          locale: const Locale('ru')));
      await tester.pumpAndSettle();
      expect(
          find.byWidgetPredicate(
              (w) => w is WorkoutCard && w.title == 'Мои ноги'),
          findsOneWidget);
    });

    testWidgets(
        'a typed exercise that reads like a catalog lift is stored in English',
        (tester) async {
      _size(tester, iPhoneSeSize);
      final c = await ru();
      await tester.pumpWidget(_app(
          c, Scaffold(body: EditWorkoutSheet(template: legs(c))),
          locale: const Locale('ru')));
      await tester.pumpAndSettle();
      Future<void> add(String text) async {
        await tester.enterText(find.byType(TextField).last, text);
        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();
      }

      await add('жим ЛЁЖА');
      await add('Подъем на носки');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      final names = [for (final e in legs(c).exercises) e.name];
      expect(names, contains('Bench press'));
      expect(names, isNot(contains('жим ЛЁЖА')));
      // Not a catalog name: stored as typed.
      expect(names, contains('Подъем на носки'));
    });

    testWidgets('a renamed starter with its translated name stays English',
        (tester) async {
      _size(tester, iPhoneSeSize);
      final c = await ru();
      await tester.pumpWidget(_app(
          c, Scaffold(body: EditWorkoutSheet(template: legs(c))),
          locale: const Locale('ru')));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Ноги'), ' ноги ');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      expect(legs(c).name, 'Legs');
    });
  });
}
