import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitrix/features/auth/presentation/providers/auth_provider.dart';
import 'package:fitrix/features/chat/data/models/chat_action.dart';
import 'package:fitrix/core/time/today_provider.dart';
import 'package:fitrix/features/nutrition/data/food_catalog.dart';
import 'package:fitrix/features/nutrition/data/food_log_store.dart';
import 'package:fitrix/features/nutrition/domain/food_match.dart';
import 'package:fitrix/features/progress/data/body_weight_store.dart';
import 'package:fitrix/features/progress/presentation/providers/progress_providers.dart';
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
/// changed, or null when nothing was applied. Weight: `{from, to, at}` plus
/// `prevKg`/`prevAt` for a same-day weigh-in it replaced. Food: `{at, count,
/// slot}` (entry ids are derived from `at`). Empty for other actions.
/// [slot] is the slot the user picked on a food card.
Future<Map<String, num>?> applyChatAction(
  WidgetRef ref,
  ChatAction action, {
  MealSlot? slot,
}) async {
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
      final at = ref.read(clockProvider)();
      final replaced = await ref
          .read(bodyWeightProvider.notifier)
          .record(WeighIn(at: at, kg: to));
      return {
        if (from != null) 'from': from,
        'to': to,
        'at': at.millisecondsSinceEpoch,
        if (replaced != null) ...{
          'prevKg': replaced.kg,
          'prevAt': replaced.at.millisecondsSinceEpoch,
        },
      };
    case FoodLogAction():
      final catalog = await ref.read(foodCatalogProvider.future);
      final at = ref.read(clockProvider)();
      final target = slot ?? action.slot ?? slotForTime(at);
      final log = ref.read(foodLogProvider.notifier);
      for (final (i, item) in action.items.indexed) {
        // Distinct times keep the order of the meal.
        await log.add(entryFor(
          item,
          matchFood(item.name, catalog),
          target,
          at.add(Duration(microseconds: i)),
          id: _foodEntryId(at, i),
        ));
      }
      return {
        'at': at.microsecondsSinceEpoch,
        'count': action.items.length,
        'slot': target.index,
      };
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

String _foodEntryId(DateTime at, int i) =>
    'felix-${at.microsecondsSinceEpoch}-$i';

/// Takes back what [applyChatAction] did for [action], using its [result].
/// Only weight and food can be undone.
Future<void> undoChatAction(
    WidgetRef ref, ChatAction action, Map<String, num> result) async {
  switch (action) {
    case WeightAction():
      final from = result['from'];
      final at = result['at'];
      // No `from`: the weight was unset before, so it is emptied again.
      await ref
          .read(profileProvider.notifier)
          .saveWeight(from == null ? '' : formatProfileNumber(from.toDouble()));
      unawaited(ref.read(accountServiceProvider)?.profileChanged());
      if (at != null) {
        final prevKg = result['prevKg'];
        final prevAt = result['prevAt'];
        await ref.read(bodyWeightProvider.notifier).unrecord(
              DateTime.fromMillisecondsSinceEpoch(at.toInt()),
              replaced: prevKg == null || prevAt == null
                  ? null
                  : WeighIn(
                      at: DateTime.fromMillisecondsSinceEpoch(prevAt.toInt()),
                      kg: prevKg.toDouble()),
            );
      }
    case FoodLogAction():
      final at = result['at'];
      final count = result['count'];
      if (at == null || count == null) return;
      final time = DateTime.fromMicrosecondsSinceEpoch(at.toInt());
      for (var i = 0; i < count; i++) {
        await ref.read(foodLogProvider.notifier).remove(_foodEntryId(time, i));
      }
    case WorkoutPlanAction():
    case MealPlanAction():
      break;
  }
}
