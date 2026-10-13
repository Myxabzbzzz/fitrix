import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitrix/features/auth/presentation/providers/auth_provider.dart';
import 'package:fitrix/features/chat/data/models/chat_action.dart';
import 'package:fitrix/features/nutrition/data/nutrition_store.dart';
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
      await ref.read(todayMealsProvider.notifier).replaceToday([
        for (final m in action.meals)
          LoggedMeal(name: m.name, items: m.items, kcal: m.kcal),
      ]);
      return const {};
  }
}
