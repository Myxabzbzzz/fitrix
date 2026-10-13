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

/// Applies a confirmed [action] to the app's own data.
Future<void> applyChatAction(WidgetRef ref, ChatAction action) async {
  switch (action) {
    case WeightAction():
      final kg = action.resultFrom(
        weightKgOf(await ref.read(profileRepositoryProvider).getProfile()),
      );
      if (kg == null) return;
      await ref
          .read(profileProvider.notifier)
          .saveWeight(formatProfileNumber(kg));
      unawaited(ref.read(accountServiceProvider)?.profileChanged());
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
    case MealPlanAction():
      ref.read(todayMealsProvider.notifier).addAll([
        for (final m in action.meals)
          LoggedMeal(name: m.name, items: m.items, kcal: m.kcal),
      ]);
  }
}
