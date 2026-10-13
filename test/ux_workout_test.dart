import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitrix/core/session/session_providers.dart';
import 'package:fitrix/core/widgets/workout_card.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/features/workouts/data/workout_catalog.dart';
import 'package:fitrix/features/workouts/presentation/providers/workouts_provider.dart';
import 'package:fitrix/features/workouts/presentation/screens/sport_workouts_screen.dart';
import 'package:fitrix/features/workouts/presentation/widgets/active_workout_sheet.dart';
import 'package:fitrix/features/workouts/presentation/widgets/edit_workout_sheet.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

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
      await tester.tapAt(
          tester.getTopRight(find.byKey(ActiveWorkoutSheet.captionKey)) +
              const Offset(40, 4));
      await tester.pumpAndSettle();
      expect(_fieldFocused(), isFalse);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('check still toggles while a field is focused', (tester) async {
      await pumpSheet(tester);
      final c = ProviderScope.containerOf(
          tester.element(find.byType(ActiveWorkoutSheet)));
      expect(c.read(activeWorkoutProvider)!.completedSets, 0);
      await tester.tap(find.byType(TextField).first);
      await tester.pumpAndSettle();
      expect(_fieldFocused(), isTrue);

      await tester.tap(find.byIcon(Icons.check).first);
      await tester.pumpAndSettle();
      expect(c.read(activeWorkoutProvider)!.completedSets, 1);
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
      expect(find.bySemanticsLabel(RegExp('Edit workout')), findsWidgets);
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
        _size(tester, const Size(375, 667));
        final c = await _container();
        await tester.pumpWidget(_app(
            c, const SportWorkoutsScreen(sport: Sport.gym),
            locale: Locale(code)));
        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.edit_outlined), findsWidgets);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
