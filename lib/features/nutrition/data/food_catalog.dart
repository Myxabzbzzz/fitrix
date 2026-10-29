import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:fitrix/core/text/normalize.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum MealSlot {
  breakfast,
  lunch,
  dinner,
  snack;

  /// The slot called [name]; dinner for anything else.
  static MealSlot fromName(String? name) =>
      values.where((s) => s.name == name).firstOrNull ?? MealSlot.dinner;

  /// The slot that fits the time of day.
  static MealSlot forTime(DateTime t) {
    if (t.hour < 11) return MealSlot.breakfast;
    if (t.hour < 16) return MealSlot.lunch;
    if (t.hour < 21) return MealSlot.dinner;
    return MealSlot.snack;
  }
}

/// The 12 micronutrients tracked per food (amounts per 100 g).
const microKeys = [
  'vitD_mcg',
  'calcium_mg',
  'magnesium_mg',
  'iron_mg',
  'zinc_mg',
  'potassium_mg',
  'sodium_mg',
  'b12_mcg',
  'selenium_mcg',
  'vitE_mg',
  'vitC_mg',
  'vitA_mcg',
];

/// A food from the bundled base (`assets/data/foods.json`). Amounts are per
/// 100 g. Uzbek dishes are recipe estimates ([estimate]).
class Food {
  final String id;
  final String name;

  /// Local names, "uz · ru". Null when the food has none.
  final String? localName;

  /// uzbek, meat_fish, dairy, fruit, veg, grains, bread, drinks or other.
  final String category;
  final bool uzbek;
  final bool estimate;
  final double kcal, protein, carbs, fat, fibre;
  final Map<String, double> micros;
  final List<({String label, int grams})> portions;

  const Food({
    required this.id,
    required this.name,
    this.localName,
    required this.category,
    this.uzbek = false,
    this.estimate = false,
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.fibre = 0,
    this.micros = const {},
    this.portions = const [],
  });

  factory Food.fromJson(Map<String, dynamic> j) {
    double n(String key) => (j[key] as num?)?.toDouble() ?? 0;
    final micros = <String, double>{
      for (final e in ((j['micros'] as Map?) ?? const {}).entries)
        if (e.value is num) e.key as String: (e.value as num).toDouble(),
    };
    return Food(
      id: j['id'] as String,
      name: j['name'] as String,
      localName: j['localName'] as String?,
      category: j['category'] as String,
      uzbek: j['uzbek'] == true,
      estimate: j['estimate'] == true,
      kcal: n('kcal'),
      protein: n('protein'),
      carbs: n('carbs'),
      fat: n('fat'),
      fibre: n('fibre'),
      micros: micros,
      portions: [
        for (final p in (j['portions'] as List? ?? const []))
          (
            label: (p as Map)['label'] as String,
            grams: (p['grams'] as num).round(),
          ),
      ],
    );
  }

  double _k(int grams) => grams / 100;
  int kcalFor(int grams) => (kcal * _k(grams)).round();
  double proteinFor(int grams) => protein * _k(grams);
  double carbsFor(int grams) => carbs * _k(grams);
  double fatFor(int grams) => fat * _k(grams);
  Map<String, double> microsFor(int grams) =>
      {for (final e in micros.entries) e.key: e.value * _k(grams)};
}

class FoodCatalog {
  final List<Food> all;
  final Map<String, Food> _byId;

  FoodCatalog(List<Food> foods)
      : all = List.unmodifiable(foods),
        _byId = {for (final f in foods) f.id: f};

  static const assetPath = 'assets/data/foods.json';

  static Future<FoodCatalog> load(AssetBundle bundle) async {
    final raw = jsonDecode(await bundle.loadString(assetPath)) as List;
    return FoodCatalog([
      for (final f in raw) Food.fromJson(f as Map<String, dynamic>),
    ]);
  }

  Food? byId(String id) => _byId[id];

  /// Foods whose name, local name or name in the app language ([nameOf])
  /// contains [query] (case-insensitive), optionally within [category].
  /// Foods whose name starts with the query come first.
  List<Food> search(String query,
      {String? category, String Function(Food)? nameOf}) {
    final q = searchFold(query);
    String? shown(Food f) {
      final n = nameOf?.call(f);
      return n == null || n == f.name ? null : searchFold(n);
    }

    bool matches(Food f) =>
        q.isEmpty ||
        searchFold(f.name).contains(q) ||
        (f.localName != null && searchFold(f.localName!).contains(q)) ||
        (shown(f)?.contains(q) ?? false);
    final found = [
      for (final f in all)
        if ((category == null || f.category == category) && matches(f)) f,
    ];
    if (q.isNotEmpty) {
      int rank(Food f) => searchFold(f.name).startsWith(q) ||
              (shown(f)?.startsWith(q) ?? false)
          ? 0
          : 1;
      found.sort((a, b) => rank(a).compareTo(rank(b)));
    }
    return found;
  }
}

final foodCatalogProvider = FutureProvider<FoodCatalog>(
  (ref) => FoodCatalog.load(rootBundle),
);
