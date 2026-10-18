import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitrix/core/time/day_key.dart';
import 'package:fitrix/features/nutrition/data/food_catalog.dart';

DateTime? _parseDayKey(String s) {
  final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(s);
  if (m == null) return null;
  return DateTime(
      int.parse(m.group(1)!), int.parse(m.group(2)!), int.parse(m.group(3)!));
}

int _idCounter = 0;

/// A new entry id: unique within this run and across runs.
String newEntryId(DateTime at) =>
    '${at.microsecondsSinceEpoch}-${_idCounter++}';

/// One logged portion of food. Nutrient amounts are for the whole portion.
class FoodEntry {
  final String id;
  final DateTime at;
  final MealSlot slot;
  final String? foodId;
  final String name;
  final int grams;
  final int kcal;
  final double protein, carbs, fat;
  final Map<String, double> micros;

  /// The numbers are Felix's estimate, not from the food base.
  final bool estimate;

  const FoodEntry({
    required this.id,
    required this.at,
    required this.slot,
    this.foodId,
    required this.name,
    required this.grams,
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.micros = const {},
    this.estimate = false,
  });

  factory FoodEntry.fromFood(
    Food food, {
    required int grams,
    required MealSlot slot,
    required DateTime at,
    required String id,
  }) =>
      FoodEntry(
        id: id,
        at: at,
        slot: slot,
        foodId: food.id,
        name: food.name,
        grams: grams,
        kcal: food.kcalFor(grams),
        protein: food.proteinFor(grams),
        carbs: food.carbsFor(grams),
        fat: food.fatFor(grams),
        micros: food.microsFor(grams),
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'at': at.toIso8601String(),
        'slot': slot.name,
        if (foodId != null) 'foodId': foodId,
        'name': name,
        'grams': grams,
        'kcal': kcal,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        if (micros.isNotEmpty) 'micros': micros,
        if (estimate) 'estimate': true,
      };

  /// Throws on a malformed entry; the store skips those.
  factory FoodEntry.fromJson(Map<String, dynamic> j) => FoodEntry(
        id: j['id'] as String,
        at: DateTime.parse(j['at'] as String),
        slot: MealSlot.values.byName(j['slot'] as String),
        foodId: j['foodId'] as String?,
        name: j['name'] as String,
        grams: (j['grams'] as num).round(),
        kcal: (j['kcal'] as num).round(),
        protein: (j['protein'] as num).toDouble(),
        carbs: (j['carbs'] as num).toDouble(),
        fat: (j['fat'] as num).toDouble(),
        micros: {
          for (final e in ((j['micros'] as Map?) ?? const {}).entries)
            if (e.value is num) e.key as String: (e.value as num).toDouble(),
        },
        estimate: j['estimate'] == true,
      );
}

/// The day-by-day food and water log on the device (SharedPreferences,
/// [key]). Keeps [retentionDays] days. Reads are synchronous from memory;
/// every change is written through.
class FoodLogStore {
  static const key = 'food_log_v1';
  static const legacyKey = 'nutrition_today_v1';
  static const migratedKey = 'food_log_migrated_v1';
  static const retentionDays = 30;

  final SharedPreferences _prefs;
  final DateTime Function() _now;
  final List<FoodEntry> _entries = [];
  final Map<String, int> _water = {};

  FoodLogStore(this._prefs, {DateTime Function()? now})
      : _now = now ?? DateTime.now {
    _load();
    _migrate();
  }

  DateTime get _oldest {
    final t = dayOf(_now());
    return DateTime(t.year, t.month, t.day - (retentionDays - 1));
  }

  void _load() {
    final raw = _prefs.getString(key);
    if (raw == null) return;
    try {
      final data = jsonDecode(raw);
      if (data is! Map) return;
      for (final e in (data['entries'] as List? ?? const [])) {
        try {
          _entries.add(FoodEntry.fromJson(e as Map<String, dynamic>));
        } catch (_) {}
      }
      for (final e in ((data['water'] as Map?) ?? const {}).entries) {
        final v = e.value;
        if (e.key is String && v is num && _parseDayKey(e.key) != null) {
          _water[e.key as String] = v.round();
        }
      }
    } catch (_) {}
    _prune();
  }

  void _prune() {
    final oldest = _oldest;
    _entries.removeWhere((e) => dayOf(e.at).isBefore(oldest));
    _water.removeWhere((k, _) => _parseDayKey(k)!.isBefore(oldest));
  }

  /// Turns the old single-day meal list into entries, once. Only kcal is
  /// known, so the other amounts are zero.
  void _migrate() {
    if (_prefs.getBool(migratedKey) == true) return;
    final raw = _prefs.getString(legacyKey);
    if (raw != null) {
      try {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        final day = _parseDayKey(data['date'] as String);
        final meals = data['meals'] as List;
        const slots = [
          MealSlot.breakfast,
          MealSlot.lunch,
          MealSlot.snack,
          MealSlot.dinner,
        ];
        if (day != null && !day.isBefore(_oldest)) {
          for (var i = 0; i < meals.length; i++) {
            try {
              final m = meals[i] as Map<String, dynamic>;
              final items = (m['items'] as String?) ?? '';
              _entries.add(FoodEntry(
                id: 'legacy-${dayKey(day)}-$i',
                at: DateTime(day.year, day.month, day.day, 12, i),
                slot: slots[i % slots.length],
                name: items.isEmpty ? m['name'] as String : items,
                grams: 0,
                kcal: (m['kcal'] as num).round(),
                protein: 0,
                carbs: 0,
                fat: 0,
              ));
            } catch (_) {}
          }
        }
      } catch (_) {}
    }
    _prefs.setBool(migratedKey, true);
    _save();
  }

  Future<void> _save() {
    _prune();
    return _prefs.setString(
      key,
      jsonEncode({
        'entries': [for (final e in _entries) e.toJson()],
        'water': _water,
      }),
    );
  }

  /// Entries of calendar day [d], oldest first.
  List<FoodEntry> day(DateTime d) {
    final t = dayOf(d);
    return [
      for (final e in _entries)
        if (dayOf(e.at) == t) e,
    ]..sort((a, b) => a.at.compareTo(b.at));
  }

  /// Entries from [from] to [to], both included (dates).
  List<FoodEntry> between(DateTime from, DateTime to) {
    final a = dayOf(from), b = dayOf(to);
    return [
      for (final e in _entries)
        if (!dayOf(e.at).isBefore(a) && !dayOf(e.at).isAfter(b)) e,
    ]..sort((x, y) => x.at.compareTo(y.at));
  }

  /// Ids of foods logged in the last [days] days up to [today], newest
  /// first, without repeats.
  List<String> recentFoodIds(DateTime today, {int days = 7}) {
    final t = dayOf(today);
    final from = DateTime(t.year, t.month, t.day - (days - 1));
    final seen = <String>{};
    return [
      for (final e in between(from, t).reversed)
        if (e.foodId != null && seen.add(e.foodId!)) e.foodId!,
    ];
  }

  Future<void> add(FoodEntry e) {
    _entries.add(e);
    return _save();
  }

  Future<void> remove(String id) {
    _entries.removeWhere((e) => e.id == id);
    return _save();
  }

  /// Makes [entries] the whole food log of day [d]. Water stays.
  Future<void> replaceDay(DateTime d, List<FoodEntry> entries) {
    final t = dayOf(d);
    _entries.removeWhere((e) => dayOf(e.at) == t);
    _entries.addAll(entries);
    return _save();
  }

  int waterMl(DateTime d) => _water[dayKey(d)] ?? 0;

  Future<void> addWater(DateTime d, int ml) {
    final k = dayKey(d);
    _water[k] = (_water[k] ?? 0) + ml;
    return _save();
  }
}
