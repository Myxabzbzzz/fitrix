import 'package:fitrix/features/nutrition/data/food_catalog.dart';
import 'package:fitrix/features/profile/data/models/profile_row.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';

/// Something Felix proposes to change, sent by the backend as an `action`
/// event. It is applied only after the user taps the confirmation button.
sealed class ChatAction {
  const ChatAction();

  Map<String, dynamic> toJson();

  /// Parses an `action` payload; null when it isn't a valid action (the app
  /// then simply shows no card).
  static ChatAction? tryParse(Object? raw) {
    if (raw is! Map) return null;
    try {
      return switch (raw['type']) {
        'weight' => WeightAction.parse(raw),
        'workout_plan' => WorkoutPlanAction.parse(raw),
        'meal_plan' => MealPlanAction.parse(raw),
        'food_log' => FoodLogAction.parse(raw),
        _ => null,
      };
    } catch (_) {
      return null;
    }
  }
}

class WeightAction extends ChatAction {
  /// True: [kg] is the new weight. False: [kg] is a change (may be negative).
  final bool isSet;
  final double kg;

  const WeightAction({required this.isSet, required this.kg});

  static WeightAction? parse(Map raw) {
    final mode = raw['mode'];
    final kg = raw['kg'];
    if (kg is! num || !kg.isFinite) return null;
    if (mode != 'set' && mode != 'delta') return null;
    // Out-of-range values are rejected, not silently clamped.
    if (mode == 'set' &&
        (kg < ProfileLimits.weightMin || kg > ProfileLimits.weightMax)) {
      return null;
    }
    if (mode == 'delta' && (kg < -50 || kg > 50)) return null;
    return WeightAction(isSet: mode == 'set', kg: kg.toDouble());
  }

  /// The weight after applying this to [current] (null when unknown),
  /// rounded to 0.1 and kept in the range the profile accepts. Null for a
  /// change when the current weight is unknown.
  double? resultFrom(double? current) {
    final value = isSet ? kg : (current == null ? null : current + kg);
    if (value == null) return null;
    return (value.clamp(ProfileLimits.weightMin, ProfileLimits.weightMax) * 10)
            .round() /
        10;
  }

  @override
  Map<String, dynamic> toJson() =>
      {'type': 'weight', 'mode': isSet ? 'set' : 'delta', 'kg': kg};
}

class PlannedExercise {
  final String name;
  final int sets;
  final int reps;
  final double kg;

  const PlannedExercise({
    required this.name,
    required this.sets,
    required this.reps,
    this.kg = 0,
  });

  Map<String, dynamic> toJson() =>
      {'name': name, 'sets': sets, 'reps': reps, 'kg': kg};
}

class PlannedWorkout {
  final String name;
  final List<PlannedExercise> exercises;

  const PlannedWorkout({required this.name, required this.exercises});

  Map<String, dynamic> toJson() => {
        'name': name,
        'exercises': [for (final e in exercises) e.toJson()],
      };
}

class WorkoutPlanAction extends ChatAction {
  final Sport sport;
  final List<PlannedWorkout> templates;

  /// `today` or `week` when Felix says when to do the plan; null otherwise
  /// (older plans).
  final String? when;

  /// One entry per template: `today`, `mon`..`sun`, or null. Empty for
  /// older plans.
  final List<String?> days;

  const WorkoutPlanAction({
    required this.sport,
    required this.templates,
    this.when,
    this.days = const [],
  });

  static const _dayNames = {
    'today',
    'mon',
    'tue',
    'wed',
    'thu',
    'fri',
    'sat',
    'sun'
  };

  static WorkoutPlanAction? parse(Map raw) {
    final sportName = raw['sport'];
    final sport = Sport.values.where((s) => s.name == sportName).firstOrNull;
    final list = raw['templates'];
    if (sport == null || list is! List || list.isEmpty) return null;
    final templates = <PlannedWorkout>[];
    final rawDays = raw['days'] is List ? raw['days'] as List : const [];
    final days = <String?>[];
    for (final (i, t) in list.take(7).indexed) {
      if (t is! Map) continue;
      final name = _text(t['name'], 100);
      final exercises = <PlannedExercise>[];
      for (final e
          in (t['exercises'] is List ? t['exercises'] as List : []).take(12)) {
        if (e is! Map) continue;
        final exName = _text(e['name'], 100);
        final sets = e['sets'];
        final reps = e['reps'];
        if (exName.isEmpty || sets is! num || reps is! num) continue;
        final kg = e['kg'];
        if (!sets.isFinite || !reps.isFinite) continue;
        if (sets < 1 || sets > 10 || reps < 1 || reps > 100) continue;
        if (kg != null && (kg is! num || !(kg >= 0 && kg <= 500))) continue;
        exercises.add(PlannedExercise(
          name: exName,
          sets: sets.round().clamp(1, 10),
          reps: reps.round().clamp(1, 100),
          kg: kg is num ? kg.toDouble().clamp(0, 500) : 0,
        ));
      }
      if (name.isEmpty || exercises.isEmpty) continue;
      templates.add(PlannedWorkout(name: name, exercises: exercises));
      final day = i < rawDays.length ? rawDays[i] : null;
      days.add(day is String && _dayNames.contains(day) ? day : null);
    }
    if (templates.isEmpty) return null;
    final when = raw['when'];
    return WorkoutPlanAction(
      sport: sport,
      templates: templates,
      when: when == 'today' || when == 'week' ? when as String : null,
      days: rawDays.isEmpty ? const [] : days,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'workout_plan',
        'sport': sport.name,
        'templates': [for (final t in templates) t.toJson()],
        if (when != null) 'when': when,
        if (days.isNotEmpty) 'days': days,
      };
}

class PlannedMeal {
  final String name;
  final String items;
  final int kcal;

  const PlannedMeal(
      {required this.name, required this.items, required this.kcal});

  Map<String, dynamic> toJson() => {'name': name, 'items': items, 'kcal': kcal};
}

class MealPlanAction extends ChatAction {
  final List<PlannedMeal> meals;

  const MealPlanAction({required this.meals});

  int get totalKcal => meals.fold(0, (sum, m) => sum + m.kcal);

  static MealPlanAction? parse(Map raw) {
    final list = raw['meals'];
    if (list is! List) return null;
    final meals = <PlannedMeal>[];
    for (final m in list.take(8)) {
      if (m is! Map) continue;
      final name = _text(m['name'], 100);
      final kcal = m['kcal'];
      if (name.isEmpty || kcal is! num || !kcal.isFinite) continue;
      if (kcal < 0 || kcal > 3000) continue;
      meals.add(PlannedMeal(
        name: name,
        items: _text(m['items'], 200),
        kcal: kcal.round().clamp(0, 3000),
      ));
    }
    if (meals.isEmpty) return null;
    return MealPlanAction(meals: meals);
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'meal_plan',
        'meals': [for (final m in meals) m.toJson()],
      };
}

class FoodLogItem {
  final String name;
  final int grams;
  final int kcal;
  final double protein, carbs, fat;

  const FoodLogItem({
    required this.name,
    required this.grams,
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  static FoodLogItem? parse(Object? raw) {
    if (raw is! Map) return null;
    final name = _text(raw['name'], 100);
    if (name.isEmpty) return null;
    double? num_(String key, double max) {
      final v = raw[key];
      if (v is! num || !v.isFinite || v < 0 || v > max) return null;
      return v.toDouble();
    }

    final grams = raw['grams'];
    if (grams is! num || !grams.isFinite || grams < 1 || grams > 3000) {
      return null;
    }
    final kcal = num_('kcal', 3000);
    final protein = num_('protein', 500);
    final carbs = num_('carbs', 500);
    final fat = num_('fat', 500);
    if (kcal == null || protein == null || carbs == null || fat == null) {
      return null;
    }
    return FoodLogItem(
      name: name,
      grams: grams.round(),
      kcal: kcal.round(),
      protein: protein,
      carbs: carbs,
      fat: fat,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'grams': grams,
        'kcal': kcal,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
      };
}

/// Felix logs what the user ate. Rejected as a whole when any item is
/// invalid, so a meal is never logged half-way.
class FoodLogAction extends ChatAction {
  final MealSlot? slot;
  final List<FoodLogItem> items;

  const FoodLogAction({this.slot, required this.items});

  static FoodLogAction? parse(Map raw) {
    final list = raw['items'];
    if (list is! List || list.isEmpty || list.length > 15) return null;
    final items = <FoodLogItem>[];
    for (final e in list) {
      final item = FoodLogItem.parse(e);
      if (item == null) return null;
      items.add(item);
    }
    final slotName = raw['slot'];
    final slot = MealSlot.values.where((s) => s.name == slotName).firstOrNull;
    return FoodLogAction(slot: slot, items: items);
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'food_log',
        'slot': slot?.name,
        'items': [for (final i in items) i.toJson()],
      };
}

String _text(Object? value, int max) {
  final text = value is String ? value.trim() : '';
  // By characters (runes), so emoji and surrogate pairs are never cut.
  final runes = text.runes;
  return runes.length > max ? String.fromCharCodes(runes.take(max)) : text;
}
