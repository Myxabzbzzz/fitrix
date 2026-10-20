import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitrix/core/constants/app_constants.dart';
import 'package:fitrix/core/session/session_providers.dart';
import 'package:fitrix/core/theme/app_theme.dart';
import 'package:fitrix/features/chat/data/models/chat_message.dart';
import 'package:fitrix/features/chat/data/repositories/chat_repository.dart';
import 'package:fitrix/features/chat/presentation/providers/chat_provider.dart';
import 'package:fitrix/features/chat/presentation/screens/felix_chat_screen.dart';
import 'package:fitrix/features/nutrition/data/food_catalog.dart';
import 'package:fitrix/features/nutrition/data/food_log_store.dart';
import 'package:fitrix/features/nutrition/presentation/providers/nutrition_provider.dart';
import 'package:fitrix/features/nutrition/presentation/screens/nutrition_screen.dart';
import 'package:fitrix/features/profile/data/performance_store.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/features/workouts/presentation/providers/workouts_provider.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

import 'support/felix_action_fixtures.dart';

void main() {
  late SharedPreferences prefs;

  Future<void> seed({
    String weight = '75',
    Map<String, dynamic>? action,
    bool applied = false,
  }) async {
    prefs =
        await seedFelixPrefs(weight: weight, action: action, applied: applied);
  }

  group('cards', () {
    late ProviderContainer container;

    Future<void> pumpFelix(
      WidgetTester tester, {
      Locale locale = const Locale('en'),
    }) async {
      tester.view.physicalSize = const Size(375, 667) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      container = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        chatMessagesProvider.overrideWith((ref) => ChatNotifier(ChatRepository(
            FakeFelixApi(),
            prefs: prefs,
            greeting: () => const ['Hi']))),
      ]);
      addTearDown(container.dispose);
      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: FelixChatScreen()),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 500));
    }

    final card = find.byKey(const ValueKey('chat-action-card'));
    final applied = find.byKey(const ValueKey('chat-action-applied'));

    testWidgets('weight delta shows 75 → 78 kg and updates the profile',
        (tester) async {
      await seed(action: weightDeltaAction);
      await pumpFelix(tester);
      expect(find.text('Update weight: 75 → 78 kg'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      expect(prefs.getString(AppConstants.keyUserWeight), '78');
      expect(applied, findsOneWidget);
      expect(find.text('Confirm'), findsNothing);
    });

    testWidgets('weight set replaces the weight', (tester) async {
      await seed(
          action: {'type': 'weight', 'mode': 'set', 'kg': 82.5}, weight: '75');
      await pumpFelix(tester);
      expect(find.text('Update weight: 75 → 82.5 kg'), findsOneWidget);
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      expect(prefs.getString(AppConstants.keyUserWeight), '82.5');
    });

    testWidgets('workout plan creates templates for that sport',
        (tester) async {
      await seed(action: workoutPlanAction);
      await pumpFelix(tester);
      expect(find.text('2 workouts'), findsOneWidget);
      expect(find.text('Upper body'), findsOneWidget);
      expect(find.textContaining('2 exercises · Bench press, Row'),
          findsOneWidget);
      final before = container
          .read(workoutTemplatesProvider)
          .where((t) => t.sport == Sport.gym)
          .length;

      await tester.tap(find.text('Add to My workouts'));
      await tester.pumpAndSettle();

      final gym = container
          .read(workoutTemplatesProvider)
          .where((t) => t.sport == Sport.gym)
          .toList();
      expect(gym.length, before + 2);
      final upper = gym.firstWhere((t) => t.name == 'Upper body');
      expect(upper.exercises.first.name, 'Bench press');
      expect(upper.exercises.first.sets, hasLength(4));
      expect(upper.exercises.first.sets.first.kg, 60);
      expect(upper.exercises.first.sets.first.reps, 8);
      expect(find.text('Added ✓'), findsOneWidget);
      expect(applied, findsOneWidget);
    });

    testWidgets('meal plan is stored and shown on the Nutrition screen',
        (tester) async {
      await seed(action: mealPlanAction);
      await pumpFelix(tester);
      expect(find.text('Add to today’s nutrition'), findsOneWidget);
      expect(find.text('1,220 kcal in total'), findsOneWidget);

      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      final logged = container.read(todayEntriesProvider);
      expect(logged, hasLength(2));
      expect(logged.map((e) => e.slot), [MealSlot.breakfast, MealSlot.lunch]);
      expect(prefs.getString(FoodLogStore.key), contains('Oatmeal'));
      // The profile makes the ring show: sex, age, height next to the weight.
      await prefs.setString(AppConstants.keyUserAge, '30');
      await prefs.setString(AppConstants.keyUserHeight, '175');
      await prefs.setString(performanceProfileKey, '{"sex":"male"}');

      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const NutritionScreen(),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('nutrition-eaten')), findsOneWidget);
      expect(find.text('1,220'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Chicken, rice'), 200,
          scrollable: find.byType(Scrollable).first);
      expect(find.text('Oatmeal, banana'), findsOneWidget);
      expect(find.text('Chicken, rice'), findsOneWidget);
    });

    testWidgets('an applied action cannot be applied again', (tester) async {
      await seed(action: weightDeltaAction, applied: true);
      await pumpFelix(tester);
      expect(card, findsOneWidget);
      expect(applied, findsOneWidget);
      expect(find.text('Confirm'), findsNothing);
      expect(prefs.getString(AppConstants.keyUserWeight), '75');
    });

    testWidgets('applying twice changes the weight only once', (tester) async {
      await seed(action: weightDeltaAction);
      await pumpFelix(tester);
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      expect(prefs.getString(AppConstants.keyUserWeight), '78');
      expect(find.text('Confirm'), findsNothing);
      // Reopened later: still applied, button gone, weight unchanged.
      await pumpFelix(tester);
      expect(applied, findsOneWidget);
      expect(find.text('Confirm'), findsNothing);
      expect(prefs.getString(AppConstants.keyUserWeight), '78');
    });

    testWidgets('delta without a known weight offers no button',
        (tester) async {
      await seed(action: weightDeltaAction, weight: '');
      await pumpFelix(tester);
      expect(find.text('Set your weight first'), findsOneWidget);
      expect(find.text('Confirm'), findsNothing);
    });

    testWidgets('weight title is frozen after apply and after reload',
        (tester) async {
      await seed(action: weightDeltaAction);
      await pumpFelix(tester);
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      expect(prefs.getString(AppConstants.keyUserWeight), '78');
      expect(find.text('Weight updated: 75 → 78 kg'), findsOneWidget);
      expect(find.textContaining('78 → 81'), findsNothing);

      await prefs.setString(AppConstants.keyUserWeight, '90');
      await pumpFelix(tester);
      expect(find.text('Weight updated: 75 → 78 kg'), findsOneWidget);
      expect(applied, findsOneWidget);
    });

    testWidgets('confirm button is at least 44 px tall', (tester) async {
      await seed(action: weightDeltaAction);
      await pumpFelix(tester);
      final button = find.ancestor(
          of: find.text('Confirm'), matching: find.byType(InkWell));
      expect(tester.getSize(button.first).height, greaterThanOrEqualTo(44));
    });

    testWidgets('no saved profile: explanation, no button, none created',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        AppConstants.keyChatHistory:
            ChatMessage.encodeMessages([felixMessage(weightDeltaAction)]),
      });
      prefs = await SharedPreferences.getInstance();
      await pumpFelix(tester);
      expect(find.textContaining('Fill in your profile first'), findsOneWidget);
      expect(find.text('Confirm'), findsNothing);
      expect(prefs.getString(AppConstants.keyUserName), isNull);
    });

    testWidgets('numbers use the locale decimal separator', (tester) async {
      await seed(action: weightDeltaAction, weight: '75.5');
      await pumpFelix(tester, locale: const Locale('ru'));
      expect(find.text('Обновить вес: 75,5 → 78,5 кг'), findsOneWidget);
    });

    testWidgets('Russian strings render without overflow on SE',
        (tester) async {
      await seed(action: workoutPlanAction);
      await pumpFelix(tester, locale: const Locale('ru'));
      expect(find.text('Добавить в мои тренировки'), findsOneWidget);
      expect(find.text('2 тренировки'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
