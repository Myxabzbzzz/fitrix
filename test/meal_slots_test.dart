import 'package:flutter_test/flutter_test.dart';
import 'package:fitrix/features/nutrition/data/food_catalog.dart';
import 'package:fitrix/features/nutrition/data/meal_slots.dart';

void main() {
  const b = MealSlot.breakfast,
      l = MealSlot.lunch,
      d = MealSlot.dinner,
      s = MealSlot.snack;

  test('English names', () {
    expect(
        mealSlotsFor(['Breakfast', 'Lunch', 'Dinner', 'Snack']), [b, l, d, s]);
    expect(mealSlotsFor(['Supper']), [d]);
  });

  test('Russian, Uzbek and Spanish names', () {
    expect(mealSlotsFor(['Завтрак', 'Обед', 'Ужин']), [b, l, d]);
    expect(mealSlotsFor(['Перекус', 'Полдник']), [s, s]);
    expect(mealSlotsFor(['Nonushta', 'Tushlik', 'Kechki ovqat', 'Gazak']),
        [b, l, d, s]);
    expect(mealSlotsFor(['Desayuno', 'Almuerzo', 'Cena', 'Merienda']),
        [b, l, d, s]);
    expect(mealSlotsFor(['Desayuno', 'Comida', 'Cena']), [b, l, d]);
  });

  test('unnamed meals map by count and never wrap to breakfast', () {
    expect(mealSlotsFor(['A', 'B', 'C']), [b, l, d]);
    expect(mealSlotsFor(['A', 'B', 'C', 'D']), [b, l, s, d]);
    expect(mealSlotsFor(['A', 'B', 'C', 'D', 'E']), [b, l, s, d, s]);
    expect(mealSlotsFor(['A']), [l]);
  });
}
