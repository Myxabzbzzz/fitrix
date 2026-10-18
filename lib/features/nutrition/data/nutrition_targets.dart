import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitrix/features/profile/data/performance_store.dart';

enum Goal {
  loseFat(0.85),
  maintain(1.0),
  leanBulk(1.10);

  /// Calories relative to maintenance.
  final double factor;
  const Goal(this.factor);
}

class Targets {
  final int bmr;
  final double activity;
  final int tdee;
  final int kcal;
  final int protein;
  final int fat;
  final int carbs;
  final int waterMl;

  const Targets({
    required this.bmr,
    required this.activity,
    required this.tdee,
    required this.kcal,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.waterMl,
  });
}

/// Activity multiplier for [hoursPerWeek] of training.
double activityFor(double hoursPerWeek) {
  if (hoursPerWeek < 1) return 1.2;
  if (hoursPerWeek <= 3) return 1.375;
  if (hoursPerWeek <= 6) return 1.55;
  if (hoursPerWeek <= 10) return 1.725;
  return 1.9;
}

/// Daily targets from the body numbers (Mifflin-St Jeor), or null when sex,
/// age, weight or height is missing.
Targets? targetsFor({
  Sex? sex,
  int? age,
  double? weightKg,
  double? heightCm,
  required double trainingHoursPerWeek,
  required Goal goal,
  double proteinPerKg = 1.8,
  double fatPerKg = 1.0,
  bool trainingDay = false,
}) {
  if (sex == null || age == null || weightKg == null || heightCm == null) {
    return null;
  }
  if (age <= 0 || weightKg <= 0 || heightCm <= 0) return null;
  final bmr =
      (10 * weightKg + 6.25 * heightCm - 5 * age + (sex == Sex.male ? 5 : -161))
          .round();
  final activity = activityFor(trainingHoursPerWeek);
  final tdee = (bmr * activity).round();
  final kcal = (tdee * goal.factor / 50).round() * 50;
  final protein = (proteinPerKg * weightKg).round();
  final fat = (fatPerKg * weightKg).round();
  final carbs = ((kcal - 4 * protein - 9 * fat) / 4).round();
  final water = (40 * weightKg / 100).round() * 100 + (trainingDay ? 500 : 0);
  return Targets(
    bmr: bmr,
    activity: activity,
    tdee: tdee,
    kcal: kcal,
    protein: protein,
    fat: fat,
    carbs: carbs < 0 ? 0 : carbs,
    waterMl: water,
  );
}

const proteinPerKgRange = (min: 1.2, max: 2.4);
const fatPerKgRange = (min: 0.6, max: 1.5);

/// Goal and per-kg factors, kept on the device ([key]).
class NutritionSettings {
  static const key = 'nutrition_settings_v1';

  final Goal goal;
  final double proteinPerKg;
  final double fatPerKg;

  const NutritionSettings({
    this.goal = Goal.maintain,
    this.proteinPerKg = 1.8,
    this.fatPerKg = 1.0,
  });

  NutritionSettings copyWith(
          {Goal? goal, double? proteinPerKg, double? fatPerKg}) =>
      NutritionSettings(
        goal: goal ?? this.goal,
        proteinPerKg: proteinPerKg ?? this.proteinPerKg,
        fatPerKg: fatPerKg ?? this.fatPerKg,
      );

  Map<String, Object> toJson() =>
      {'goal': goal.name, 'proteinPerKg': proteinPerKg, 'fatPerKg': fatPerKg};

  /// Tolerant: unknown or missing fields fall back to the defaults.
  factory NutritionSettings.fromJson(Map<String, dynamic> j) {
    double clamp(Object? v, double lo, double hi, double fallback) =>
        v is num ? v.toDouble().clamp(lo, hi) : fallback;
    return NutritionSettings(
      goal: Goal.values.where((g) => g.name == j['goal']).firstOrNull ??
          Goal.maintain,
      proteinPerKg: clamp(
          j['proteinPerKg'], proteinPerKgRange.min, proteinPerKgRange.max, 1.8),
      fatPerKg: clamp(j['fatPerKg'], fatPerKgRange.min, fatPerKgRange.max, 1.0),
    );
  }

  factory NutritionSettings.read(SharedPreferences prefs) {
    final raw = prefs.getString(key);
    if (raw == null) return const NutritionSettings();
    try {
      return NutritionSettings.fromJson(
          jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const NutritionSettings();
    }
  }

  Future<void> write(SharedPreferences prefs) =>
      prefs.setString(key, jsonEncode(toJson()));
}
