import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:fitrix/features/chat/data/models/chat_action.dart';
import 'package:fitrix/features/chat/data/services/chat_api_service.dart';
import 'package:fitrix/features/nutrition/data/food_catalog.dart';
import 'package:fitrix/features/nutrition/data/food_log_store.dart';
import 'package:fitrix/features/nutrition/domain/food_match.dart';

import 'support/felix_action_fixtures.dart';

void main() {
  late FoodCatalog catalog;
  setUpAll(() => catalog = loadFoodCatalog());

  group('parsing', () {
    test('valid actions parse, invalid ones are dropped', () {
      expect(ChatAction.tryParse(weightDeltaAction), isA<WeightAction>());
      expect(ChatAction.tryParse(workoutPlanAction), isA<WorkoutPlanAction>());
      expect(ChatAction.tryParse(mealPlanAction), isA<MealPlanAction>());
      expect(ChatAction.tryParse({'type': 'weight', 'mode': 'x', 'kg': 1}),
          isNull);
      expect(ChatAction.tryParse({'type': 'workout_plan', 'sport': 'golf'}),
          isNull);
      expect(ChatAction.tryParse({'type': 'meal_plan', 'meals': []}), isNull);
      expect(ChatAction.tryParse('nope'), isNull);
    });

    test('weight result: delta from current, rounded and clamped', () {
      const delta = WeightAction(isSet: false, kg: 3);
      expect(delta.resultFrom(75), 78);
      expect(const WeightAction(isSet: false, kg: 0.26).resultFrom(75), 75.3);
      expect(delta.resultFrom(null), isNull);
      expect(const WeightAction(isSet: false, kg: -50).resultFrom(30), 20);
      expect(const WeightAction(isSet: true, kg: 82.04).resultFrom(null), 82);
      expect(const WeightAction(isSet: true, kg: 500).resultFrom(70), 400);
    });

    test('out-of-range values are rejected, not clamped', () {
      Map<String, dynamic> w(String mode, num kg) =>
          {'type': 'weight', 'mode': mode, 'kg': kg};
      expect(ChatAction.tryParse(w('set', 19.9)), isNull);
      expect(ChatAction.tryParse(w('set', 400.1)), isNull);
      expect(ChatAction.tryParse(w('set', 20)), isNotNull);
      expect(ChatAction.tryParse(w('delta', 50.1)), isNull);
      expect(ChatAction.tryParse(w('delta', -50.1)), isNull);
      expect(ChatAction.tryParse(w('delta', -50)), isNotNull);

      Map<String, dynamic> plan(List<Map<String, dynamic>> exercises) => {
            'type': 'workout_plan',
            'sport': 'gym',
            'templates': [
              {'name': 'A', 'exercises': exercises},
            ],
          };
      Map<String, dynamic> ex(Map<String, dynamic> extra) =>
          {'name': 'Lift', 'sets': 3, 'reps': 8, ...extra};
      for (final bad in [
        {'sets': 11},
        {'sets': 0},
        {'reps': 101},
        {'reps': 0},
        {'kg': 501},
        {'kg': -1},
      ]) {
        expect(ChatAction.tryParse(plan([ex(bad)])), isNull, reason: '$bad');
      }
      final mixed = ChatAction.tryParse(plan([
        ex({'sets': 11}),
        ex({})
      ])) as WorkoutPlanAction;
      expect(mixed.templates.single.exercises, hasLength(1));

      Map<String, dynamic> meals(num kcal) => {
            'type': 'meal_plan',
            'meals': [
              {'name': 'Lunch', 'items': 'x', 'kcal': kcal},
              {'name': 'Dinner', 'items': 'y', 'kcal': 500},
            ],
          };
      expect((ChatAction.tryParse(meals(3001)) as MealPlanAction).meals,
          hasLength(1));
      expect((ChatAction.tryParse(meals(-1)) as MealPlanAction).meals,
          hasLength(1));
      expect(
          ChatAction.tryParse({
            'type': 'meal_plan',
            'meals': [
              {'name': 'x', 'kcal': 9999}
            ]
          }),
          isNull);
    });

    test('strings are cut by characters, not UTF-16 units', () {
      final action = ChatAction.tryParse({
        'type': 'meal_plan',
        'meals': [
          {'name': '😀' * 150, 'items': 'x', 'kcal': 100}
        ]
      }) as MealPlanAction;
      expect(action.meals.single.name, '😀' * 100);
    });

    test('ChatApiService reads the action event before done', () async {
      HttpOverrides.global = null;
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      server.listen((request) async {
        await utf8.decoder.bind(request).join();
        request.response.headers.contentType =
            ContentType('application', 'x-ndjson', charset: 'utf-8');
        for (final event in [
          {'delta': 'Hi'},
          {'action': weightDeltaAction},
          {
            'action': {'type': 'bogus'}
          },
          {'done': true},
        ]) {
          request.response.write('${jsonEncode(event)}\n');
        }
        await request.response.close();
      });
      final api = ChatApiService(
          baseUrl: 'http://${server.address.host}:${server.port}');
      final actions = <ChatAction>[];
      final chunks =
          await api.streamMessage('hi', 'c', onAction: actions.add).toList();
      expect(chunks, ['Hi']);
      expect(actions, hasLength(1));
      expect((actions.single as WeightAction).kg, 3);
    });
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
      final a = ChatAction.tryParse(foodLogAction) as FoodLogAction;
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

    test('oat milk is not porridge; oats with milk still is', () {
      expect(matchFood('oat milk', catalog)?.id, isNot('oatmeal_cooked'));
      expect(matchFood('oat milk', catalog)?.id, isNot('oats_dry'));
      expect(matchFood('oats with milk', catalog)?.id, 'oatmeal_cooked');
      expect(matchFood('oatmeal with milk', catalog)?.id, 'oatmeal_cooked');
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
      final a = ChatAction.tryParse(foodLogAction) as FoodLogAction;
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
}
