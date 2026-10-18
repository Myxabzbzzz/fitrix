import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitrix/core/constants/app_constants.dart';
import 'package:fitrix/core/router/app_router.dart';
import 'package:fitrix/core/session/session_providers.dart';
import 'package:fitrix/core/theme/app_theme.dart';
import 'package:fitrix/core/time/today_provider.dart';
import 'package:fitrix/features/chat/data/models/chat_action.dart';
import 'package:fitrix/features/chat/data/models/chat_message.dart';
import 'package:fitrix/features/chat/data/repositories/chat_repository.dart';
import 'package:fitrix/features/chat/data/services/chat_api_service.dart';
import 'package:fitrix/features/chat/presentation/providers/chat_provider.dart';
import 'package:fitrix/features/chat/presentation/screens/felix_chat_screen.dart';
import 'package:fitrix/features/chat/presentation/widgets/chat_action_card.dart';
import 'package:fitrix/features/nutrition/data/food_catalog.dart';
import 'package:fitrix/features/nutrition/data/food_log_store.dart';
import 'package:fitrix/features/nutrition/domain/food_match.dart';
import 'package:fitrix/features/nutrition/presentation/providers/nutrition_provider.dart';
import 'package:fitrix/features/progress/data/body_weight_store.dart';
import 'package:fitrix/features/progress/presentation/providers/progress_providers.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

const _food = {
  'type': 'food_log',
  'slot': 'lunch',
  'items': [
    {
      'name': 'chicken breast',
      'grams': 200,
      'kcal': 330,
      'protein': 62,
      'carbs': 0,
      'fat': 7.2
    },
    {
      'name': 'rice',
      'grams': 150,
      'kcal': 195,
      'protein': 4,
      'carbs': 42,
      'fat': 0.5
    },
    {
      'name': 'dragonfruit smoothie',
      'grams': 300,
      'kcal': 180,
      'protein': 3,
      'carbs': 40,
      'fat': 1
    },
  ],
};

class _FakeApi extends ChatApiService {}

late FoodCatalog catalog;

void main() {
  setUpAll(() async {
    final raw =
        jsonDecode(File(FoodCatalog.assetPath).readAsStringSync()) as List;
    catalog = FoodCatalog([
      for (final f in raw) Food.fromJson(f as Map<String, dynamic>),
    ]);
  });

  group('parsing', () {
    Map<String, dynamic> withItem(Map<String, dynamic> item) => {
          'type': 'food_log',
          'slot': null,
          'items': [item],
        };
    const ok = {
      'name': 'egg',
      'grams': 50,
      'kcal': 78,
      'protein': 6,
      'carbs': 0.5,
      'fat': 5
    };

    test('valid food_log parses', () {
      final a = ChatAction.tryParse(_food) as FoodLogAction;
      expect(a.slot, MealSlot.lunch);
      expect(a.items, hasLength(3));
      expect(a.items.first.name, 'chicken breast');
      expect(a.items.first.grams, 200);
      expect(a.items.first.fat, 7.2);
      expect((ChatAction.tryParse(withItem(ok)) as FoodLogAction).slot, isNull);
    });

    test('invalid food_log is dropped', () {
      expect(ChatAction.tryParse({'type': 'food_log', 'items': []}), isNull);
      expect(ChatAction.tryParse({'type': 'food_log'}), isNull);
      for (final bad in [
        {...ok, 'name': ' '},
        {...ok, 'grams': 0},
        {...ok, 'grams': 3001},
        {...ok, 'kcal': 3001},
        {...ok, 'kcal': -1},
        {...ok, 'protein': 501},
        {...ok, 'fat': -1},
        {...ok, 'grams': 'x'},
      ]) {
        expect(ChatAction.tryParse(withItem(bad)), isNull, reason: '$bad');
      }
      expect(
          ChatAction.tryParse({
            'type': 'food_log',
            'items': List.filled(16, ok),
          }),
          isNull);
    });

    test('workout plan keeps when and days; old plans still parse', () {
      Map<String, dynamic> plan(Map<String, dynamic> extra) => {
            'type': 'workout_plan',
            'sport': 'gym',
            'templates': [
              {
                'name': 'A',
                'exercises': [
                  {'name': 'Row', 'sets': 3, 'reps': 8}
                ]
              },
              {
                'name': 'B',
                'exercises': [
                  {'name': 'Squat', 'sets': 3, 'reps': 8}
                ]
              },
            ],
            ...extra,
          };
      final a = ChatAction.tryParse(plan({
        'when': 'week',
        'days': ['mon', 'bogus']
      })) as WorkoutPlanAction;
      expect(a.when, 'week');
      expect(a.days, ['mon', null]);
      final old = ChatAction.tryParse(plan({})) as WorkoutPlanAction;
      expect(old.when, isNull);
      expect(old.days, isEmpty);
    });
  });

  group('food match', () {
    test('matches by name, local name and token containment', () {
      expect(matchFood('chicken breast', catalog)?.id, 'chicken_breast');
      expect(matchFood('Chicken', catalog)?.id, 'chicken_breast');
      expect(matchFood('rice', catalog)?.id, 'rice_cooked');
      expect(matchFood('Guruch', catalog)?.id, 'rice_cooked');
      expect(matchFood('рис', catalog)?.id, 'rice_cooked');
      expect(matchFood('плов', catalog)?.name.toLowerCase(), contains('plov'));
      expect(matchFood('dragonfruit smoothie', catalog), isNull);
      expect(matchFood('   ', catalog), isNull);
      expect(matchFood('banana', catalog)?.id, 'banana');
      expect(matchFood('kefir', catalog)?.id, 'kefir');
      expect(matchFood('cottage cheese', catalog)?.id, 'cottage_cheese');
    });

    test('ambiguous names are not guessed', () {
      expect(matchFood('cheese', catalog), isNull);
      expect(matchFood('oil', catalog), isNull);
    });

    test('oats mean the cooked porridge unless dry or raw', () {
      expect(matchFood('oats', catalog)?.id, 'oatmeal_cooked');
      expect(matchFood('oatmeal', catalog)?.id, 'oatmeal_cooked');
      expect(matchFood('porridge', catalog)?.id, 'oatmeal_cooked');
      expect(matchFood('dry oats', catalog)?.id, 'oats_dry');
      expect(matchFood('raw oats', catalog)?.id, 'oats_dry');
    });

    test('plurals, cooking words and synonyms reach the base food', () {
      expect(matchFood('eggs', catalog)?.id, 'egg_boiled');
      expect(matchFood('fried egg', catalog)?.id, 'egg_boiled');
      expect(matchFood('pilaf', catalog)?.id, 'tashkent_plov');
      expect(matchFood('boiled rice', catalog)?.id, 'rice_cooked');
      expect(
          matchFood('grilled chicken breast', catalog)?.id, 'chicken_breast');
      expect(matchFood('курица', catalog)?.id, 'chicken_breast');
    });

    test('slotForTime boundaries', () {
      MealSlot at(int h, int m) => slotForTime(DateTime(2026, 10, 18, h, m));
      expect(at(10, 59), MealSlot.breakfast);
      expect(at(11, 0), MealSlot.lunch);
      expect(at(15, 59), MealSlot.lunch);
      expect(at(16, 0), MealSlot.dinner);
      expect(at(20, 59), MealSlot.dinner);
      expect(at(21, 0), MealSlot.snack);
    });

    test('entryFor scales catalog values; unmatched keeps Felix numbers', () {
      final a = ChatAction.tryParse(_food) as FoodLogAction;
      final at = DateTime(2026, 10, 18, 13);
      final chicken = catalog.byId('chicken_breast')!;
      final e = entryFor(a.items[0], chicken, MealSlot.lunch, at);
      expect(e.kcal, (165 * 200 / 100).round());
      expect(e.protein, closeTo(62, 1e-9));
      expect(e.estimate, isFalse);
      expect(e.foodId, 'chicken_breast');
      final u = entryFor(a.items[2], null, MealSlot.snack, at);
      expect(u.kcal, 180);
      expect(u.estimate, isTrue);
      expect(u.foodId, isNull);
      expect(u.name, 'dragonfruit smoothie');
      expect(FoodEntry.fromJson(u.toJson() as Map<String, dynamic>).estimate,
          isTrue);
    });
  });

  group('BodyWeightStore.remove', () {
    test('removes that weigh-in only', () async {
      SharedPreferences.setMockInitialValues({});
      final store = BodyWeightStore(await SharedPreferences.getInstance());
      await store.add(WeighIn(at: DateTime(2026, 10, 16, 8), kg: 80));
      await store.add(WeighIn(at: DateTime(2026, 10, 18, 8), kg: 81.4));
      await store.remove(DateTime(2026, 10, 18, 8));
      expect(store.all().map((w) => w.kg), [80]);
    });
  });

  group('cards', () {
    late SharedPreferences prefs;
    late ProviderContainer container;

    Future<void> seed(Map<String, dynamic> action,
        {String weight = '78.4'}) async {
      SharedPreferences.setMockInitialValues({
        AppConstants.keyUserName: 'Ann',
        AppConstants.keyUserWeight: weight,
        AppConstants.keyChatHistory: ChatMessage.encodeMessages([
          ChatMessage(
            id: 'm1',
            content: 'Okay.',
            sender: MessageSender.assistant,
            timestamp: DateTime(2026, 10, 18, 12),
            action: ChatAction.tryParse(action),
          ),
        ]),
      });
      prefs = await SharedPreferences.getInstance();
    }

    var routed = <String>[];

    Future<void> pumpFelix(WidgetTester tester, {double scale = 1}) async {
      tester.view.physicalSize = const Size(375, 667) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      routed = [];
      container = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        clockProvider.overrideWithValue(() => DateTime(2026, 10, 18, 13, 30)),
        foodCatalogProvider.overrideWith((ref) async => catalog),
        chatMessagesProvider.overrideWith((ref) => ChatNotifier(
            ChatRepository(_FakeApi(), prefs: prefs, greeting: const ['Hi']))),
      ]);
      addTearDown(container.dispose);
      final router = GoRouter(routes: [
        GoRoute(
            path: '/',
            builder: (_, __) => const Scaffold(body: FelixChatScreen())),
        GoRoute(
            path: AppRouter.nutrition,
            builder: (_, __) {
              routed.add(AppRouter.nutrition);
              return const Scaffold(body: Text('nutrition-page'));
            }),
        GoRoute(
            path: AppRouter.editProfile,
            builder: (_, __) {
              routed.add(AppRouter.editProfile);
              return const Scaffold(body: Text('edit-page'));
            }),
      ]);
      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 500));
    }

    final today = DateTime(2026, 10, 18);

    testWidgets('food card shows rows and total, adds, undoes, opens',
        (tester) async {
      await seed(_food);
      await pumpFelix(tester);
      expect(find.text('Log to Lunch'), findsOneWidget);
      expect(find.text('Chicken breast, cooked'), findsOneWidget);
      expect(find.text('≈ dragonfruit smoothie'), findsOneWidget);
      // 330 + 195 + 180 from catalog: 330, 195, and Felix's 180.
      final total = (165 * 2).round() + (130 * 1.5).round() + 180;
      expect(find.textContaining('Add to My nutrition · $total kcal'),
          findsOneWidget);

      await tester.tap(find.textContaining('Add to My nutrition'));
      await tester.pumpAndSettle();
      final entries = container.read(foodLogStoreProvider).day(today);
      expect(entries, hasLength(3));
      expect(entries.map((e) => e.slot).toSet(), {MealSlot.lunch});
      expect(entries[0].kcal, 330);
      expect(entries[1].kcal, 195);
      expect(entries[2].kcal, 180);
      expect(entries[2].estimate, isTrue);
      expect(find.text('Added to Lunch'), findsOneWidget);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(container.read(foodLogStoreProvider).day(today), isEmpty);
      expect(find.textContaining('Add to My nutrition'), findsOneWidget);

      await tester.tap(find.textContaining('Add to My nutrition'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(routed, [AppRouter.nutrition]);
    });

    testWidgets('slot defaults to the time of day and can be changed',
        (tester) async {
      await seed({..._food, 'slot': null});
      await pumpFelix(tester); // 13:30 -> lunch
      expect(find.text('Log to Lunch'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('food-slot-picker')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dinner').last);
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Add to My nutrition'));
      await tester.pumpAndSettle();
      final entries = container.read(foodLogStoreProvider).day(today);
      expect(entries.map((e) => e.slot).toSet(), {MealSlot.dinner});
    });

    testWidgets('"I gained 3 kg" at 78.4 logs 81.4 and undo restores',
        (tester) async {
      await seed({'type': 'weight', 'mode': 'delta', 'kg': 3});
      await pumpFelix(tester);
      expect(find.text('Update weight: 78.4 → 81.4 kg'), findsOneWidget);
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      expect(prefs.getString(AppConstants.keyUserWeight), '81.4');
      var weighIns = container.read(bodyWeightStoreProvider).all();
      expect(weighIns.map((w) => w.kg), [81.4]);
      expect(weighIns.single.at, DateTime(2026, 10, 18, 13, 30));

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(prefs.getString(AppConstants.keyUserWeight), '78.4');
      weighIns = container.read(bodyWeightStoreProvider).all();
      expect(weighIns, isEmpty);
      expect(container.read(bodyWeightProvider), isEmpty);
    });

    testWidgets('undo brings back a same-day weigh-in that was replaced',
        (tester) async {
      await seed({'type': 'weight', 'mode': 'set', 'kg': 80});
      await pumpFelix(tester);
      await container
          .read(bodyWeightStoreProvider)
          .add(WeighIn(at: DateTime(2026, 10, 18, 7), kg: 78.4));
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      expect(
          container.read(bodyWeightStoreProvider).all().map((w) => w.kg), [80]);
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(container.read(bodyWeightStoreProvider).all().map((w) => w.kg),
          [78.4]);
    });

    testWidgets('"set" with no profile weight applies, logs, and undo reverts',
        (tester) async {
      await seed({'type': 'weight', 'mode': 'set', 'kg': 82}, weight: '');
      await pumpFelix(tester);
      expect(find.text('Set your weight first'), findsNothing);
      expect(find.text('Update weight to 82 kg'), findsOneWidget);
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      expect(prefs.getString(AppConstants.keyUserWeight), '82');
      expect(
          container.read(bodyWeightStoreProvider).all().map((w) => w.kg), [82]);
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(prefs.getString(AppConstants.keyUserWeight) ?? '', '');
      expect(container.read(bodyWeightStoreProvider).all(), isEmpty);
    });

    testWidgets('no profile weight asks to set it first', (tester) async {
      await seed({'type': 'weight', 'mode': 'delta', 'kg': 3}, weight: '');
      await pumpFelix(tester);
      expect(find.text('Set your weight first'), findsOneWidget);
      expect(find.text('Confirm'), findsNothing);
      await tester.tap(find.text('Set weight'));
      await tester.pumpAndSettle();
      expect(routed, [AppRouter.editProfile]);
    });

    // The card alone: the chat header has its own layout at 1.3 text.
    for (final action in [
      _food,
      {'type': 'weight', 'mode': 'delta', 'kg': 3},
      {'type': 'weight', 'mode': 'delta', 'kg': 3, 'noWeight': true},
    ]) {
      for (final applied in [false, true]) {
        testWidgets(
            '${action['type']} card fits SE at 1.3 text '
            '(${applied ? 'added' : 'ask'})', (tester) async {
          final noWeight = action['noWeight'] == true;
          await seed(action, weight: noWeight ? '' : '78.4');
          tester.view.physicalSize = const Size(375, 667) * 3;
          tester.view.devicePixelRatio = 3;
          addTearDown(tester.view.reset);
          final container = ProviderContainer(overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            clockProvider
                .overrideWithValue(() => DateTime(2026, 10, 18, 13, 30)),
            foodCatalogProvider.overrideWith((ref) async => catalog),
          ]);
          addTearDown(container.dispose);
          await tester.pumpWidget(UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: const TextScaler.linear(1.3)),
                child: child!,
              ),
              home: Scaffold(
                body: SingleChildScrollView(
                  child: ChatActionCard(
                    message: ChatMessage(
                      id: 'x',
                      content: 'Okay.',
                      sender: MessageSender.assistant,
                      timestamp: DateTime(2026, 10, 18, 12),
                      action: ChatAction.tryParse(action),
                      actionApplied: applied && !noWeight,
                      appliedResult: applied
                          ? {
                              'at': DateTime(2026, 10, 18, 13, 30)
                                  .microsecondsSinceEpoch,
                              'count': 3,
                              'slot': 1,
                              'from': 78.4,
                              'to': 81.4,
                            }
                          : null,
                    ),
                    onApplied: (_) {},
                  ),
                ),
              ),
            ),
          ));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        });
      }
    }
  });
}
