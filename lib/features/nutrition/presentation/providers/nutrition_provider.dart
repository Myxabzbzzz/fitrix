import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitrix/core/session/session_providers.dart';
import 'package:fitrix/features/nutrition/data/nutrition_store.dart';

final nutritionStoreProvider = Provider<NutritionStore>(
  (ref) => NutritionStore(ref.watch(sharedPreferencesProvider)),
);

/// Meals logged today; empty until something was added.
final todayMealsProvider =
    StateNotifierProvider<TodayMealsNotifier, List<LoggedMeal>>(
  (ref) => TodayMealsNotifier(ref.watch(nutritionStoreProvider)),
);

class TodayMealsNotifier extends StateNotifier<List<LoggedMeal>> {
  final NutritionStore _store;

  TodayMealsNotifier(this._store) : super(_store.loadToday());

  void addAll(List<LoggedMeal> meals) {
    state = [...state, ...meals];
    _store.saveToday(state);
  }
}
