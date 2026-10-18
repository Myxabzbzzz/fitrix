import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitrix/features/auth/presentation/providers/auth_provider.dart';
import 'package:fitrix/features/chat/data/models/chat_action.dart';
import 'package:fitrix/core/time/today_provider.dart';
import 'package:fitrix/features/nutrition/data/food_log_store.dart';
import 'package:fitrix/features/nutrition/data/meal_slots.dart';
import 'package:fitrix/features/nutrition/presentation/providers/nutrition_provider.dart';
import 'package:fitrix/features/profile/data/models/profile_row.dart';
import 'package:fitrix/features/profile/data/models/user_profile.dart';
import 'package:fitrix/features/profile/presentation/providers/profile_provider.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/features/workouts/presentation/providers/workouts_provider.dart';

/// The weight in [profile], or null when it isn't a number.
double? weightKgOf(UserProfile? profile) =>
    profile == null ? null : parseProfileNumber(profile.weight);

/// Applies a confirmed [action] to the app's own data. Returns what was
/// changed (weight: `{from, to}`; empty for other actions), or null when
/// nothing was applied.
Future<Map<String, num>?> applyChatAction(
    WidgetRef ref, ChatAction action) async {
  switch (action) {
    case WeightAction():
      final profile = await ref.read(profileRepositoryProvider).getProfile();
      // No saved profile: nothing to update (and none is created here).
      if (profile == null) return null;
      final from = weightKgOf(profile);
      final to = action.resultFrom(from);
      if (to == null) return null;
      final saved = await ref
          .read(profileProvider.notifier)
          .saveWeight(formatProfileNumber(to));
      if (!saved) return null;
      unawaited(ref.read(accountServiceProvider)?.profileChanged());
      return {if (from != null) 'from': from, 'to': to};
    case WorkoutPlanAction():
      ref.read(workoutTemplatesProvider.notifier).addAll(action.sport, [
        for (final t in action.templates)
          (
            name: t.name,
            exercises: [
              for (final e in t.exercises)
                Exercise(name: e.name, sets: [
                  for (var i = 0; i < e.sets; i++)
                    WorkoutSet(
                      previousKg: e.kg,
                      previousReps: e.reps,
                      kg: e.kg,
                      reps: e.reps,
                    ),
                ]),
            ],
          ),
      ]);
      return const {};
    case MealPlanAction():
      // A meal plan is a whole day: it replaces what was logged today.
      final now = ref.read(clockProvider)();
      final today = ref.read(todayProvider);
      final slots = mealSlotsFor([for (final m in action.meals) m.name]);
      await ref.read(foodLogProvider.notifier).replaceDay(today, [
        for (final (i, m) in action.meals.indexed)
          FoodEntry(
            id: newEntryId(now),
            at: DateTime(
                today.year, today.month, today.day, now.hour, now.minute, i),
            slot: slots[i],
            name: m.items.isEmpty ? m.name : m.items,
            grams: 0,
            kcal: m.kcal,
            protein: 0,
            carbs: 0,
            fat: 0,
          ),
      ]);
      return const {};
  }
}
