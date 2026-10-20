import 'dart:convert';
import 'dart:io';

import 'package:fitrix/core/constants/app_constants.dart';
import 'package:fitrix/features/chat/data/models/chat_action.dart';
import 'package:fitrix/features/chat/data/models/chat_message.dart';
import 'package:fitrix/features/chat/data/services/chat_api_service.dart';
import 'package:fitrix/features/nutrition/data/food_catalog.dart';
import 'package:shared_preferences/shared_preferences.dart';

const weightDeltaAction = {'type': 'weight', 'mode': 'delta', 'kg': 3};
const workoutPlanAction = {
  'type': 'workout_plan',
  'sport': 'gym',
  'templates': [
    {
      'name': 'Upper body',
      'exercises': [
        {'name': 'Bench press', 'sets': 4, 'reps': 8, 'kg': 60},
        {'name': 'Row', 'sets': 3, 'reps': 10},
      ],
    },
    {
      'name': 'Legs',
      'exercises': [
        {'name': 'Squat', 'sets': 5, 'reps': 5, 'kg': 80},
      ],
    },
  ],
};
const mealPlanAction = {
  'type': 'meal_plan',
  'meals': [
    {'name': 'Breakfast', 'items': 'Oatmeal, banana', 'kcal': 520},
    {'name': 'Lunch', 'items': 'Chicken, rice', 'kcal': 700},
  ],
};

/// Replies with "Sure" and the given action (if any).
class FakeFelixApi extends ChatApiService {
  ChatAction? action;
  final histories = <List<Map<String, String>>?>[];

  @override
  Stream<String> streamMessage(
    String message,
    String conversationId, {
    String? topic,
    Map<String, Object>? profile,
    List<Map<String, String>>? history,
    String? language,
    Map<String, Object>? context,
    List<String>? images,
    void Function(ChatAction action)? onAction,
  }) async* {
    histories.add(history);
    yield 'Sure';
    if (action != null) onAction?.call(action!);
  }
}

ChatMessage felixMessage(Map<String, dynamic> action, {bool applied = false}) =>
    ChatMessage(
      id: 'm1',
      content: 'Here is a plan. Tap the button below.',
      sender: MessageSender.assistant,
      timestamp: DateTime(2026, 10, 13, 9),
      action: ChatAction.tryParse(action),
      actionApplied: applied,
    );
const foodLogAction = {
  'type': 'food_log',
  'slot': 'lunch',
  'items': [
    {
      'name': 'chicken breast',
      'grams': 200,
      'kcal': 330,
      'protein': 62,
      'carbs': 0,
      'fat': 7.2
    },
    {
      'name': 'rice',
      'grams': 150,
      'kcal': 195,
      'protein': 4,
      'carbs': 42,
      'fat': 0.5
    },
    {
      'name': 'dragonfruit smoothie',
      'grams': 300,
      'kcal': 180,
      'protein': 3,
      'carbs': 40,
      'fat': 1
    },
  ],
};

/// The bundled food catalog, read straight from the asset file.
FoodCatalog loadFoodCatalog() {
  final raw =
      jsonDecode(File(FoodCatalog.assetPath).readAsStringSync()) as List;
  return FoodCatalog([
    for (final f in raw) Food.fromJson(f as Map<String, dynamic>),
  ]);
}

/// Mock prefs for a Felix chat: a signed-in user with [weight], plus one
/// assistant message carrying [action] when given.
Future<SharedPreferences> seedFelixPrefs({
  String weight = '75',
  Map<String, dynamic>? action,
  bool applied = false,
}) async {
  SharedPreferences.setMockInitialValues({
    AppConstants.keyUserName: 'Ann',
    AppConstants.keyUserWeight: weight,
    if (action != null)
      AppConstants.keyChatHistory:
          ChatMessage.encodeMessages([felixMessage(action, applied: applied)]),
  });
  return SharedPreferences.getInstance();
}
