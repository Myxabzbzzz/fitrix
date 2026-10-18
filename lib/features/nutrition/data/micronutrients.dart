import 'package:fitrix/features/nutrition/data/food_catalog.dart';
import 'package:fitrix/features/profile/data/performance_store.dart';

enum MicroStatus { low, ok, high }

/// Daily targets (NASEM RDA / AI) for an adult. Sodium is a limit.
Map<String, double> microTargets(Sex sex, int age) {
  final male = sex == Sex.male;
  final young = age <= 30;
  final over50 = age > 50;
  return {
    'vitD_mcg': age > 70 ? 20 : 15,
    'calcium_mg': (!male && over50) || age > 70 ? 1200 : 1000,
    'magnesium_mg': male ? (young ? 400 : 420) : (young ? 310 : 320),
    'iron_mg': male || over50 ? 8 : 18,
    'zinc_mg': male ? 11 : 8,
    'potassium_mg': male ? 3400 : 2600,
    'sodium_mg': 2300,
    'b12_mcg': 2.4,
    'selenium_mcg': 55,
    'vitE_mg': 15,
    'vitC_mg': male ? 90 : 75,
    'vitA_mcg': male ? 900 : 700,
  };
}

/// Low is under 60 % of the target. High applies to sodium only.
MicroStatus microStatus(String key, double intake, double target) {
  if (key == 'sodium_mg') {
    return intake > target ? MicroStatus.high : MicroStatus.ok;
  }
  return intake < target * 0.6 ? MicroStatus.low : MicroStatus.ok;
}

enum MicroFilter { athlete, vitamins, minerals, all }

const _athlete = [
  'vitD_mcg',
  'calcium_mg',
  'magnesium_mg',
  'iron_mg',
  'zinc_mg',
  'potassium_mg',
  'sodium_mg',
];
const _vitamins = ['vitD_mcg', 'b12_mcg', 'vitE_mg', 'vitC_mg', 'vitA_mcg'];
const _minerals = [
  'calcium_mg',
  'magnesium_mg',
  'iron_mg',
  'zinc_mg',
  'potassium_mg',
  'sodium_mg',
  'selenium_mcg',
];

List<String> microKeysFor(MicroFilter f) => switch (f) {
      MicroFilter.athlete => _athlete,
      MicroFilter.vitamins => _vitamins,
      MicroFilter.minerals => _minerals,
      MicroFilter.all => microKeys,
    };

/// Per-day totals averaged over the days that have entries; the second value
/// is how many such days there were.
({Map<String, double> avg, int days}) averageMicros(
    Map<DateTime, Map<String, double>> perDay) {
  final totals = {for (final k in microKeys) k: 0.0};
  var n = 0;
  for (final day in perDay.values) {
    n++;
    for (final k in microKeys) {
      totals[k] = totals[k]! + (day[k] ?? 0);
    }
  }
  if (n == 0) return (avg: totals, days: 0);
  return (avg: {for (final e in totals.entries) e.key: e.value / n}, days: n);
}

/// Foods in season in Uzbekistan by month (1-12), as food ids of the base.
const seasonalFoodIds = <int, List<String>>{
  1: ['carrot', 'cabbage', 'pomegranate', 'apple'],
  2: ['carrot', 'cabbage', 'apple', 'orange'],
  3: ['spinach', 'carrot', 'apple', 'orange'],
  4: ['spinach', 'onion', 'cucumber', 'apple'],
  5: ['spinach', 'cucumber', 'tomato', 'apricot'],
  6: ['apricot', 'cucumber', 'tomato', 'bell_pepper'],
  7: ['watermelon', 'melon', 'tomato', 'apricot'],
  8: ['watermelon', 'melon', 'grapes', 'tomato'],
  9: ['grapes', 'melon', 'apple', 'bell_pepper'],
  10: ['pomegranate', 'quince', 'persimmon', 'pumpkin'],
  11: ['pomegranate', 'persimmon', 'pumpkin', 'apple'],
  12: ['pomegranate', 'pumpkin', 'carrot', 'cabbage'],
};
