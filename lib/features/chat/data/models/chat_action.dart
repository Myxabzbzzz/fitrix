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

  const WorkoutPlanAction({required this.sport, required this.templates});

  static WorkoutPlanAction? parse(Map raw) {
    final sportName = raw['sport'];
    final sport = Sport.values.where((s) => s.name == sportName).firstOrNull;
    final list = raw['templates'];
    if (sport == null || list is! List || list.isEmpty) return null;
    final templates = <PlannedWorkout>[];
    for (final t in list.take(7)) {
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
        exercises.add(PlannedExercise(
          name: exName,
          sets: sets.round().clamp(1, 10),
          reps: reps.round().clamp(1, 100),
          kg: kg is num ? kg.toDouble().clamp(0, 500) : 0,
        ));
      }
      if (name.isEmpty || exercises.isEmpty) continue;
      templates.add(PlannedWorkout(name: name, exercises: exercises));
    }
    if (templates.isEmpty) return null;
    return WorkoutPlanAction(sport: sport, templates: templates);
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'workout_plan',
        'sport': sport.name,
        'templates': [for (final t in templates) t.toJson()],
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
      if (name.isEmpty || kcal is! num) continue;
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

String _text(Object? value, int max) {
  final text = value is String ? value.trim() : '';
  return text.length > max ? text.substring(0, max) : text;
}
