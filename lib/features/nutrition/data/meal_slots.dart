import 'package:fitrix/features/nutrition/data/food_catalog.dart';

const _keywords = <MealSlot, List<String>>{
  MealSlot.dinner: ['dinner', 'supper', 'ужин', 'kechki', 'cena'],
  MealSlot.breakfast: ['breakfast', 'завтрак', 'nonushta', 'desayuno'],
  MealSlot.lunch: ['lunch', 'обед', 'tushlik', 'almuerzo', 'comida'],
  MealSlot.snack: [
    'snack',
    'перекус',
    'полдник',
    'gazak',
    'yengil ovqat',
    'merienda',
    'tentempié',
  ],
};

MealSlot? _byName(String name) {
  final n = name.toLowerCase();
  for (final e in _keywords.entries) {
    if (e.value.any(n.contains)) return e.key;
  }
  return null;
}

/// The slot for each meal name of a Felix plan. Names in any supported
/// language are matched; the others are placed by how many meals there are
/// (3: breakfast, lunch, dinner; 4: breakfast, lunch, snack, dinner) and
/// extra meals become snacks.
List<MealSlot> mealSlotsFor(List<String> names) {
  final order = switch (names.length) {
    1 => const [MealSlot.lunch],
    2 => const [MealSlot.lunch, MealSlot.dinner],
    3 => const [MealSlot.breakfast, MealSlot.lunch, MealSlot.dinner],
    _ => const [
        MealSlot.breakfast,
        MealSlot.lunch,
        MealSlot.snack,
        MealSlot.dinner,
      ],
  };
  return [
    for (final (i, n) in names.indexed)
      _byName(n) ?? (i < order.length ? order[i] : MealSlot.snack),
  ];
}
