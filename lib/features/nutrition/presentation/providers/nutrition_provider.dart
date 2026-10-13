import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitrix/core/session/session_providers.dart';
import 'package:fitrix/features/nutrition/data/nutrition_store.dart';

/// The current time; overridden in tests.
final nutritionClockProvider =
    Provider<DateTime Function()>((ref) => DateTime.now);

final nutritionStoreProvider = Provider<NutritionStore>(
  (ref) => NutritionStore(
    ref.watch(sharedPreferencesProvider),
    now: ref.watch(nutritionClockProvider),
  ),
);

/// Meals logged today; empty until something was added.
final todayMealsProvider =
    StateNotifierProvider<TodayMealsNotifier, List<LoggedMeal>>(
  (ref) => TodayMealsNotifier(ref.watch(nutritionStoreProvider)),
);

class TodayMealsNotifier extends StateNotifier<List<LoggedMeal>> {
  final NutritionStore _store;

  TodayMealsNotifier(this._store) : super(_store.loadToday());

  /// Re-reads today from storage: call when the app resumes or the screen
  /// opens, since the date may have changed since this was created.
  void refresh() {
    final fresh = _store.loadToday();
    if (jsonEncode([for (final m in fresh) m.toJson()]) !=
        jsonEncode([for (final m in state) m.toJson()])) {
      state = fresh;
    }
  }

  /// Makes [meals] today's plan, replacing whatever was logged today.
  Future<void> replaceToday(List<LoggedMeal> meals) async {
    state = meals;
    await _store.saveToday(meals);
  }
}
