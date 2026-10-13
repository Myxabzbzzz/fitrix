import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// A meal the user logged (for now: confirmed from a Felix meal plan).
class LoggedMeal {
  final String name;
  final String items;
  final int kcal;

  const LoggedMeal(
      {required this.name, required this.items, required this.kcal});

  Map<String, dynamic> toJson() => {'name': name, 'items': items, 'kcal': kcal};

  factory LoggedMeal.fromJson(Map<String, dynamic> json) => LoggedMeal(
        name: json['name'] as String,
        items: json['items'] as String? ?? '',
        kcal: (json['kcal'] as num).round(),
      );
}

/// Today's logged meals on the device (SharedPreferences). Only the current
/// day is kept; a new day starts empty.
class NutritionStore {
  static const key = 'nutrition_today_v1';

  final SharedPreferences _prefs;
  final DateTime Function() _now;

  NutritionStore(this._prefs, {DateTime Function()? now})
      : _now = now ?? DateTime.now;

  String get _today {
    final d = _now();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  List<LoggedMeal> loadToday() {
    final raw = _prefs.getString(key);
    if (raw == null) return const [];
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      if (data['date'] != _today) return const [];
      return [
        for (final m in data['meals'] as List)
          LoggedMeal.fromJson(m as Map<String, dynamic>),
      ];
    } catch (_) {
      return const [];
    }
  }

  Future<void> saveToday(List<LoggedMeal> meals) => _prefs.setString(
        key,
        jsonEncode({
          'date': _today,
          'meals': [for (final m in meals) m.toJson()],
        }),
      );
}
