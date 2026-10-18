import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitrix/core/router/app_router.dart';
import 'package:fitrix/core/session/session_providers.dart';
import 'package:fitrix/core/time/today_provider.dart';
import 'package:fitrix/features/nutrition/data/food_catalog.dart';
import 'package:fitrix/features/nutrition/data/food_log_store.dart';
import 'package:fitrix/features/nutrition/data/micronutrients.dart';
import 'package:fitrix/features/nutrition/data/nutrition_targets.dart';
import 'package:fitrix/features/nutrition/presentation/providers/nutrition_provider.dart';
import 'package:fitrix/features/nutrition/presentation/screens/add_food_screen.dart';
import 'package:fitrix/features/nutrition/presentation/screens/food_detail_screen.dart';
import 'package:fitrix/features/nutrition/presentation/screens/micros_screen.dart';
import 'package:fitrix/features/nutrition/presentation/screens/nutrition_screen.dart';
import 'package:fitrix/features/nutrition/presentation/screens/targets_screen.dart';
import 'package:fitrix/features/profile/data/performance_store.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';
import 'support/overflow.dart';

List<Food> _foods() {
  final raw = jsonDecode(File('assets/data/foods.json').readAsStringSync())
      as List<dynamic>;
  return [for (final f in raw) Food.fromJson(f as Map<String, dynamic>)];
}

final _catalog = FoodCatalog(_foods());

FoodEntry _entry(String id, DateTime at,
        {MealSlot slot = MealSlot.lunch,
        int kcal = 500,
        Map<String, double> micros = const {},
        String? foodId,
        double protein = 20}) =>
    FoodEntry(
      id: id,
      at: at,
      slot: slot,
      foodId: foodId,
      name: id,
      grams: 100,
      kcal: kcal,
      protein: protein,
      carbs: 10,
      fat: 5,
      micros: micros,
    );

const _profile = <String, Object>{
  'user_name': 'Alex',
  'user_age': '26',
  'user_weight': '78.4',
  'user_height': '181',
  performanceProfileKey: '{"sex":"male"}',
};

void main() {
  group('targetsFor', () {
    test('male 26, 78.4 kg, 181 cm, 7.6 h, lean bulk', () {
      final t = targetsFor(
        sex: Sex.male,
        age: 26,
        weightKg: 78.4,
        heightCm: 181,
        trainingHoursPerWeek: 7.6,
        goal: Goal.leanBulk,
      )!;
      expect(t.bmr, 1790);
      expect(t.activity, 1.725);
      expect(t.tdee, 3088);
      expect(t.kcal, 3400);
      expect(t.protein, 141);
      expect(t.fat, 78);
      expect(t.carbs, 534);
      expect(t.waterMl, 3100);
    });

    test('training day adds 500 ml of water', () {
      final t = targetsFor(
        sex: Sex.male,
        age: 26,
        weightKg: 78.4,
        heightCm: 181,
        trainingHoursPerWeek: 3,
        goal: Goal.maintain,
        trainingDay: true,
      )!;
      expect(t.waterMl, 3600);
    });

    test('missing height or sex gives null', () {
      expect(
          targetsFor(
              sex: Sex.male,
              age: 26,
              weightKg: 78,
              heightCm: null,
              trainingHoursPerWeek: 3,
              goal: Goal.maintain),
          isNull);
      expect(
          targetsFor(
              sex: null,
              age: 26,
              weightKg: 78,
              heightCm: 180,
              trainingHoursPerWeek: 3,
              goal: Goal.maintain),
          isNull);
    });

    test('female BMR uses -161; activity bands; goal factors', () {
      Targets f(double h, Goal g) => targetsFor(
          sex: Sex.female,
          age: 30,
          weightKg: 60,
          heightCm: 165,
          trainingHoursPerWeek: h,
          goal: g)!;
      // 600 + 1031.25 - 150 - 161 = 1320
      expect(f(3, Goal.maintain).bmr, 1320);
      expect(f(0.5, Goal.maintain).activity, 1.2);
      expect(f(1, Goal.maintain).activity, 1.375);
      expect(f(3, Goal.maintain).activity, 1.375);
      expect(f(4, Goal.maintain).activity, 1.55);
      expect(f(8, Goal.maintain).activity, 1.725);
      expect(f(12, Goal.maintain).activity, 1.9);
      final m = f(3, Goal.maintain), l = f(3, Goal.loseFat);
      expect(m.kcal % 50, 0);
      expect(l.kcal, lessThan(m.kcal));
      expect((l.kcal / m.tdee - 0.85).abs(), lessThan(0.01));
    });
  });

  group('micro targets', () {
    test('men 19-30 and women 31-50', () {
      final m = microTargets(Sex.male, 26);
      expect(m['magnesium_mg'], 400);
      expect(m['vitD_mcg'], 15);
      expect(m['iron_mg'], 8);
      expect(m['sodium_mg'], 2300);
      expect(m.keys.toSet(), microKeys.toSet());
      final w = microTargets(Sex.female, 35);
      expect(w['iron_mg'], 18);
      expect(w['magnesium_mg'], 320);
    });

    test('status: low under 60 %, high only for sodium', () {
      expect(microStatus('calcium_mg', 500, 1000), MicroStatus.low);
      expect(microStatus('calcium_mg', 600, 1000), MicroStatus.ok);
      expect(microStatus('iron_mg', 30, 8), MicroStatus.ok);
      expect(microStatus('sodium_mg', 2301, 2300), MicroStatus.high);
      expect(microStatus('sodium_mg', 2300, 2300), MicroStatus.ok);
    });
  });

  group('food catalog', () {
    final foods = _foods();
    test('at least 80 foods, ids unique, 15+ Uzbek flagged estimates', () {
      expect(foods.length, greaterThanOrEqualTo(80));
      expect(foods.map((f) => f.id).toSet().length, foods.length);
      final uz = foods.where((f) => f.uzbek).toList();
      expect(uz.length, greaterThanOrEqualTo(15));
      expect(uz.every((f) => f.estimate), isTrue);
    });

    test('values are sane', () {
      for (final f in foods) {
        expect(f.kcal, greaterThanOrEqualTo(0), reason: f.id);
        expect(f.protein, greaterThanOrEqualTo(0), reason: f.id);
        expect(f.carbs, greaterThanOrEqualTo(0), reason: f.id);
        expect(f.fat, greaterThanOrEqualTo(0), reason: f.id);
        expect(f.fibre, greaterThanOrEqualTo(0), reason: f.id);
        // Atwater check; fibre makes very light vegetables read a little off.
        final a = 4 * f.protein + 4 * f.carbs + 9 * f.fat;
        final tol = a * 0.15 > 10 ? a * 0.15 : 10;
        expect((f.kcal - a).abs(), lessThanOrEqualTo(tol), reason: f.id);
        expect(f.portions, isNotEmpty, reason: f.id);
        for (final p in f.portions) {
          expect(p.grams, greaterThan(0), reason: f.id);
        }
        expect(f.micros.keys.toSet(), microKeys.toSet(), reason: f.id);
        expect(f.micros.values.every((v) => v >= 0), isTrue, reason: f.id);
      }
    });

    test('Tashkent plov matches the mock', () {
      final p = foods.firstWhere((f) => f.id == 'tashkent_plov');
      expect(p.kcal, 206);
      expect(p.portions.first.grams, 350);
      expect(p.localName, 'Toshkent oshi · Плов ташкентский');
    });

    test('every Uzbek dish on the mock is present', () {
      final names = foods.map((f) => f.name).toList();
      for (final n in [
        'Tashkent plov',
        'Samarkand plov',
        'Plov with chickpeas',
        'Chicken plov',
        'Wedding plov (to‘y oshi)',
        'Achichuk salad',
        'Non (flatbread)',
      ]) {
        expect(names, contains(n));
      }
      for (final id in [
        'lagman', 'manti', 'shurpa', 'somsa', 'shashlik_chicken',
        'shashlik_beef', 'chuchvara', 'dimlama', 'mastava', 'norin', 'qatiq',
        'suzma', //
      ]) {
        expect(foods.any((f) => f.id == id && f.uzbek), isTrue, reason: id);
      }
    });

    test('search covers name and localName', () {
      expect(_catalog.search('plov').length, greaterThanOrEqualTo(5));
      expect(
          _catalog.search('плов').any((f) => f.id == 'tashkent_plov'), isTrue);
      expect(
          _catalog.search('oshi').any((f) => f.id == 'wedding_plov'), isTrue);
      expect(_catalog.search('plov', category: 'dairy'), isEmpty);
    });
  });

  group('FoodLogStore', () {
    late SharedPreferences prefs;
    var now = DateTime(2026, 10, 17, 12);
    setUp(() async {
      now = DateTime(2026, 10, 17, 12);
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });
    FoodLogStore store() => FoodLogStore(prefs, now: () => now);

    test('add, remove and persist', () async {
      final s = store();
      await s.add(_entry('a', DateTime(2026, 10, 17, 9)));
      await s.add(_entry('b', DateTime(2026, 10, 17, 13)));
      expect(s.day(DateTime(2026, 10, 17)).map((e) => e.id), ['a', 'b']);
      await s.remove('a');
      expect(store().day(DateTime(2026, 10, 17)).map((e) => e.id), ['b']);
    });

    test('an entry at 23:59 is not in the next day', () async {
      final s = store();
      await s.add(_entry('late', DateTime(2026, 10, 17, 23, 59)));
      expect(s.day(DateTime(2026, 10, 18)), isEmpty);
      expect(s.day(DateTime(2026, 10, 17)), hasLength(1));
    });

    test('water adds up per day', () async {
      final s = store();
      await s.addWater(DateTime(2026, 10, 17), 250);
      await s.addWater(DateTime(2026, 10, 17), 500);
      expect(s.waterMl(DateTime(2026, 10, 17)), 750);
      expect(s.waterMl(DateTime(2026, 10, 18)), 0);
      expect(store().waterMl(DateTime(2026, 10, 17)), 750);
    });

    test('keeps 30 days', () async {
      final s = store();
      await s.add(_entry('old', DateTime(2026, 9, 10, 12)));
      await s.add(_entry('edge', DateTime(2026, 9, 18, 12)));
      await s.add(_entry('new', DateTime(2026, 10, 17, 12)));
      final again = store();
      expect(again.day(DateTime(2026, 9, 10)), isEmpty);
      expect(again.day(DateTime(2026, 9, 18)), hasLength(1));
      expect(again.day(DateTime(2026, 10, 17)), hasLength(1));
    });

    test('a corrupt entry is skipped, the rest load', () async {
      await prefs.setString(
          'food_log_v1',
          jsonEncode({
            'entries': [
              {'id': 'bad'},
              'nope',
              _entry('ok', DateTime(2026, 10, 17, 8)).toJson(),
            ],
            'water': {'2026-10-17': 250, 'x': 'y'},
          }));
      final s = store();
      expect(s.day(DateTime(2026, 10, 17)).map((e) => e.id), ['ok']);
      expect(s.waterMl(DateTime(2026, 10, 17)), 250);
      await prefs.setString('food_log_v1', '{not json');
      expect(store().day(DateTime(2026, 10, 17)), isEmpty);
    });

    test('migrates nutrition_today_v1 once, kcal only, slots by order',
        () async {
      await prefs.setString(
          'nutrition_today_v1',
          jsonEncode({
            'date': '2026-10-17',
            'meals': [
              {'name': 'A', 'items': 'Oatmeal', 'kcal': 400},
              {'name': 'B', 'items': 'Chicken', 'kcal': 600},
              {'name': 'C', 'items': 'Nuts', 'kcal': 200},
              {'name': 'D', 'items': 'Fish', 'kcal': 500},
            ],
          }));
      final s = store();
      final day = s.day(DateTime(2026, 10, 17));
      expect(day.map((e) => e.kcal), [400, 600, 200, 500]);
      expect(day.map((e) => e.slot), [
        MealSlot.breakfast,
        MealSlot.lunch,
        MealSlot.snack,
        MealSlot.dinner,
      ]);
      expect(day.first.name, 'Oatmeal');
      // Second start: no duplicates, even after the user removed one.
      await s.remove(day.first.id);
      expect(store().day(DateTime(2026, 10, 17)), hasLength(3));
    });

    test('replaceDay swaps that day only', () async {
      final s = store();
      await s.add(_entry('y', DateTime(2026, 10, 16, 12)));
      await s.add(_entry('t', DateTime(2026, 10, 17, 12)));
      await s.addWater(DateTime(2026, 10, 17), 250);
      await s.replaceDay(
          DateTime(2026, 10, 17), [_entry('n', DateTime(2026, 10, 17, 13))]);
      expect(s.day(DateTime(2026, 10, 17)).map((e) => e.id), ['n']);
      expect(s.day(DateTime(2026, 10, 16)).map((e) => e.id), ['y']);
      expect(s.waterMl(DateTime(2026, 10, 17)), 250);
    });
  });

  // ---- screens ----
  Future<ProviderContainer> pump(
    WidgetTester tester,
    Widget screen, {
    Map<String, Object> values = _profile,
    DateTime? now,
    double textScale = 1,
    bool se = true,
    ProviderContainer? existing,
  }) async {
    if (se) {
      tester.view.physicalSize = const Size(375, 667) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
    }
    SharedPreferences.setMockInitialValues(values);
    final prefs = await SharedPreferences.getInstance();
    final clock = now ?? DateTime(2026, 10, 17, 12);
    final container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      clockProvider.overrideWithValue(() => clock),
    ]);
    addTearDown(container.dispose);
    // Asset loading needs real async time.
    await tester.runAsync(() => container.read(foodCatalogProvider.future));
    final router = GoRouter(initialLocation: '/', routes: [
      GoRoute(path: '/', builder: (_, __) => screen),
      GoRoute(
          path: AppRouter.editProfile,
          builder: (_, __) => const Scaffold(body: Text('route edit'))),
      GoRoute(
          path: AppRouter.nutritionTargets,
          builder: (_, __) => const Scaffold(body: Text('route targets'))),
      GoRoute(
          path: AppRouter.nutritionMicros,
          builder: (_, __) => const Scaffold(body: Text('route micros'))),
      GoRoute(
          path: AppRouter.nutritionAdd,
          builder: (_, __) => const Scaffold(body: Text('route add'))),
    ]);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MediaQuery(
        data: MediaQueryData(
          size: const Size(375, 667),
          textScaler: TextScaler.linear(textScale),
        ),
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    ));
    await tester.pumpAndSettle();
    return container;
  }

  Future<void> reveal(WidgetTester t, Finder f) async {
    await t.scrollUntilVisible(f, 200,
        scrollable: find.byType(Scrollable).first);
    await t.ensureVisible(f);
    await t.pumpAndSettle();
  }

  Text eaten(WidgetTester t) =>
      t.widget<Text>(find.byKey(const ValueKey('nutrition-eaten')));

  group('Nutrition screen', () {
    testWidgets('ring starts at 0 and follows a logged plov', (t) async {
      final c = await pump(t, const NutritionScreen());
      final target = c.read(targetsProvider)!;
      expect(eaten(t).data, '0');
      expect(
          find.textContaining('${target.kcal}'.substring(0, 1)), findsWidgets);

      final plov = _catalog.byId('tashkent_plov')!;
      await c.read(foodLogProvider.notifier).add(FoodEntry.fromFood(
            plov,
            grams: 350,
            slot: MealSlot.lunch,
            at: DateTime(2026, 10, 17, 12),
            id: 'p1',
          ));
      await t.pumpAndSettle();
      expect(eaten(t).data, '721');
      expect(t.takeException(), isNull);
    });

    testWidgets('water +250 ml updates the row', (t) async {
      final c = await pump(t, const NutritionScreen());
      await reveal(t, find.text('+250 ml'));
      await t.tap(find.text('+250 ml'));
      await t.pumpAndSettle();
      expect(c.read(todayWaterProvider), 250);
      expect(find.textContaining('0.3 of'), findsOneWidget);
    });

    testWidgets('dinner idea: after 15:00 and 30 g behind, not before',
        (t) async {
      await pump(t, const NutritionScreen(),
          now: DateTime(2026, 10, 17, 14, 59));
      expect(find.byKey(const ValueKey('dinner-idea')), findsNothing);
      await t.pumpWidget(const SizedBox());
      await pump(t, const NutritionScreen(), now: DateTime(2026, 10, 17, 15));
      await reveal(t, find.byKey(const ValueKey('dinner-idea')));
      expect(find.byKey(const ValueKey('dinner-idea')), findsOneWidget);
    });

    testWidgets('Add to dinner logs the idea', (t) async {
      final c = await pump(t, const NutritionScreen(),
          now: DateTime(2026, 10, 17, 16));
      await reveal(t, find.text('Add to dinner'));
      await t.tap(find.text('Add to dinner'));
      await t.pumpAndSettle();
      final day = c.read(todayEntriesProvider);
      expect(day, hasLength(1));
      expect(day.single.slot, MealSlot.dinner);
      expect(day.single.protein, greaterThan(20));
    });

    testWidgets('over target says "n kcal over", not "Goal reached"',
        (t) async {
      final c = await pump(t, const NutritionScreen());
      final target = c.read(targetsProvider)!.kcal;
      await c
          .read(foodLogProvider.notifier)
          .add(_entry('big', DateTime(2026, 10, 17, 9), kcal: target + 800));
      await t.pumpAndSettle();
      expect(find.text('800 kcal over'), findsOneWidget);
      expect(find.text('Goal reached for today'), findsNothing);
    });

    testWidgets('within 50 kcal of the target says "Goal reached"', (t) async {
      for (final delta in [-50, 0, 50]) {
        final c = await pump(t, const NutritionScreen());
        final target = c.read(targetsProvider)!.kcal;
        await c.read(foodLogProvider.notifier).add(
            _entry('e$delta', DateTime(2026, 10, 17, 9), kcal: target + delta));
        await t.pumpAndSettle();
        expect(find.text('Goal reached for today'), findsOneWidget,
            reason: 'delta $delta');
        expect(find.textContaining('kcal over'), findsNothing);
        await t.pumpWidget(const SizedBox());
      }
      final c = await pump(t, const NutritionScreen());
      final target = c.read(targetsProvider)!.kcal;
      await c
          .read(foodLogProvider.notifier)
          .add(_entry('u', DateTime(2026, 10, 17, 9), kcal: target - 51));
      await t.pumpAndSettle();
      expect(find.text('51 kcal'), findsOneWidget);
    });

    testWidgets('incomplete profile shows the card instead of the ring',
        (t) async {
      await pump(t, const NutritionScreen(), values: {'user_name': 'Alex'});
      expect(find.byKey(const ValueKey('nutrition-complete-profile')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('calorie-ring')), findsNothing);
      await t.tap(find.byKey(const ValueKey('nutrition-complete-profile')));
      await t.pumpAndSettle();
      expect(find.text('route edit'), findsOneWidget);
    });

    for (final scale in [1.0, 1.3]) {
      testWidgets('SE, text x$scale: no overflow', (t) async {
        final c = await pump(t, const NutritionScreen(),
            textScale: scale, now: DateTime(2026, 10, 17, 16));
        await c.read(foodLogProvider.notifier).add(_entry(
            'x', DateTime(2026, 10, 17, 9),
            slot: MealSlot.breakfast, kcal: 520));
        await t.pumpAndSettle();
        await t.drag(find.byType(Scrollable).first, const Offset(0, -2000));
        await t.pumpAndSettle();
        expectNoOverflow(t);
      });
    }
  });

  group('Add food', () {
    testWidgets('search, quick-add logs the first portion to the slot',
        (t) async {
      final c = await pump(t, const AddFoodScreen(slot: MealSlot.dinner));
      await t.enterText(find.byType(TextField), 'plov');
      await t.pumpAndSettle();
      expect(find.textContaining('Tashkent plov'), findsWidgets);
      await t.tap(find.byKey(const ValueKey('quick-add-tashkent_plov')).first);
      await t.pumpAndSettle();
      final day = c.read(todayEntriesProvider);
      expect(day.single.slot, MealSlot.dinner);
      expect(day.single.grams, 350);
      expect(day.single.kcal, 721);
    });

    testWidgets('Recent lists foods logged in the last 7 days', (t) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final s = FoodLogStore(prefs, now: () => DateTime(2026, 10, 17, 12));
      await s.add(_entry('r', DateTime(2026, 10, 12, 12), foodId: 'achichuk'));
      await s.add(_entry('o', DateTime(2026, 10, 1, 12), foodId: 'qatiq'));
      expect(s.recentFoodIds(DateTime(2026, 10, 17), days: 7), ['achichuk']);
    });

    for (final scale in [1.0, 1.3]) {
      testWidgets('SE, text x$scale: no overflow', (t) async {
        await pump(t, const AddFoodScreen(slot: MealSlot.dinner),
            textScale: scale);
        await t.enterText(find.byType(TextField), 'plov');
        await t.pumpAndSettle();
        expectNoOverflow(t);
      });
    }
  });

  group('Food detail', () {
    testWidgets('portion pills change the numbers; add logs the entry',
        (t) async {
      final c = await pump(t,
          const FoodDetailScreen(id: 'tashkent_plov', slot: MealSlot.dinner));
      expect(find.text('Add to dinner · 721 kcal'), findsOneWidget);
      await t.drag(find.text('1 plate'), const Offset(-300, 0));
      await t.pumpAndSettle();
      await t.tap(find.text('100 g'));
      await t.pumpAndSettle();
      expect(find.text('Add to dinner · 206 kcal'), findsOneWidget);
      await t.tap(find.text('Add to dinner · 206 kcal'));
      await t.pumpAndSettle();
      expect(c.read(todayEntriesProvider).single.grams, 100);
    });

    testWidgets('warns when fat would pass the target', (t) async {
      final c = await pump(t,
          const FoodDetailScreen(id: 'tashkent_plov', slot: MealSlot.dinner));
      final target = c.read(targetsProvider)!;
      await c.read(foodLogProvider.notifier).add(FoodEntry(
          id: 'f',
          at: DateTime(2026, 10, 17, 9),
          slot: MealSlot.breakfast,
          name: 'fatty',
          grams: 100,
          kcal: 300,
          protein: 5,
          carbs: 5,
          fat: target.fat - 5.0,
          micros: const {}));
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('fat-warning')), findsOneWidget);
    });

    for (final scale in [1.0, 1.3]) {
      testWidgets('SE, text x$scale: no overflow', (t) async {
        await pump(t,
            const FoodDetailScreen(id: 'tashkent_plov', slot: MealSlot.dinner),
            textScale: scale);
        await t.drag(find.byType(Scrollable).first, const Offset(0, -2000));
        await t.pumpAndSettle();
        expectNoOverflow(t);
      });
    }
  });

  group('Micronutrients', () {
    testWidgets('low vitamin D shows with Low chip; filters work', (t) async {
      final c = await pump(t, const MicrosScreen());
      await c.read(foodLogProvider.notifier).add(_entry(
          'm', DateTime(2026, 10, 17, 9),
          micros: {'vitD_mcg': 2.3, 'calcium_mg': 380, 'sodium_mg': 3400}));
      await t.pumpAndSettle();
      expect(find.text('Vitamin D'), findsOneWidget);
      expect(find.text('Low'), findsWidgets);
      expect(find.text('High'), findsOneWidget);
      expect(find.text('Vitamin C'), findsNothing);
      await t.drag(find.text('Athlete essentials'), const Offset(-200, 0));
      await t.pumpAndSettle();
      await t.tap(find.text('Vitamins'));
      await t.pumpAndSettle();
      expect(find.text('Vitamin C'), findsOneWidget);
      expect(find.text('Calcium'), findsNothing);
      expect(find.textContaining('Shop'), findsNothing);
    });

    testWidgets('in season now lists October fruit with local names',
        (t) async {
      await pump(t, const MicrosScreen());
      await t.drag(find.byType(Scrollable).first, const Offset(0, -3000));
      await t.pumpAndSettle();
      expect(find.text('Pomegranate'), findsOneWidget);
      expect(find.textContaining('Anor'), findsOneWidget);
    });

    testWidgets('vitamin D card after low days', (t) async {
      final c = await pump(t, const MicrosScreen());
      for (var d = 0; d < 7; d++) {
        await c.read(foodLogProvider.notifier).add(_entry(
            'v$d', DateTime(2026, 10, 17 - d, 9),
            micros: {'vitD_mcg': 2}));
      }
      await t.pumpAndSettle();
      await reveal(t, find.byKey(const ValueKey('vitd-card')));
      expect(find.byKey(const ValueKey('vitd-card')), findsOneWidget);
    });

    for (final scale in [1.0, 1.3]) {
      testWidgets('SE, text x$scale: no overflow', (t) async {
        final c = await pump(t, const MicrosScreen(), textScale: scale);
        await c.read(foodLogProvider.notifier).add(_entry(
            'm', DateTime(2026, 10, 17, 9),
            micros: {'vitD_mcg': 2.3, 'sodium_mg': 3400}));
        await t.pumpAndSettle();
        for (var i = 0; i < 3; i++) {
          await t.drag(find.byType(Scrollable).at(2), const Offset(-300, 0));
          await t.pumpAndSettle();
        }
        await t.tap(find.text('All 12'));
        await t.pumpAndSettle();
        await t.drag(find.byType(Scrollable).first, const Offset(0, -3000));
        await t.pumpAndSettle();
        expectNoOverflow(t);
      });
    }
  });

  group('Targets screen', () {
    testWidgets('shows the maths, saves goal and per-kg factors', (t) async {
      final c = await pump(t, const TargetsScreen());
      expect(find.text('1,790'), findsOneWidget);
      await t.drag(find.text('Maintain'), const Offset(-300, 0));
      await t.pumpAndSettle();
      await t.tap(find.text('Lean bulk'));
      await t.pumpAndSettle();
      await reveal(t, find.byKey(const ValueKey('protein-plus')));
      await t.tap(find.byKey(const ValueKey('protein-plus')));
      await t.pumpAndSettle();
      expect(find.text('1.9'), findsOneWidget);
      await t.tap(find.text('Save targets'));
      await t.pumpAndSettle();
      final s = c.read(nutritionSettingsProvider);
      expect(s.goal, Goal.leanBulk);
      expect(s.proteinPerKg, closeTo(1.9, 1e-9));
      final raw = jsonDecode((await SharedPreferences.getInstance())
          .getString('nutrition_settings_v1')!) as Map;
      expect(raw['goal'], 'leanBulk');
    });

    testWidgets('steppers stay inside 1.2-2.4 and 0.6-1.5', (t) async {
      final c = await pump(t, const TargetsScreen());
      await reveal(t, find.byKey(const ValueKey('protein-plus')));
      for (var i = 0; i < 20; i++) {
        await t.tap(find.byKey(const ValueKey('protein-plus')));
        await t.pump();
        await t.tap(find.byKey(const ValueKey('fat-minus')));
        await t.pump();
      }
      await t.pump();
      await t.tap(find.text('Save targets'));
      await t.pumpAndSettle();
      final s = c.read(nutritionSettingsProvider);
      expect(s.proteinPerKg, closeTo(2.4, 1e-9));
      expect(s.fatPerKg, closeTo(0.6, 1e-9));
    });

    for (final scale in [1.0, 1.3]) {
      testWidgets('SE, text x$scale: no overflow', (t) async {
        await pump(t, const TargetsScreen(), textScale: scale);
        await t.drag(find.byType(Scrollable).first, const Offset(0, -2000));
        await t.pumpAndSettle();
        expectNoOverflow(t);
      });
    }
  });
}
