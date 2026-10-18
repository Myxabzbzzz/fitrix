import 'package:fitrix/features/chat/data/models/chat_action.dart';
import 'package:fitrix/features/nutrition/data/food_catalog.dart';
import 'package:fitrix/features/nutrition/data/food_log_store.dart';

/// The meal slot that fits the time of day.
MealSlot slotForTime(DateTime t) => MealSlot.forTime(t);

final _word = RegExp(r'[\p{L}\p{N}]+', unicode: true);
final _apostrophes = RegExp('[‘’ʻʼ\'`]');

String _norm(String s) => s.toLowerCase().replaceAll(_apostrophes, '').trim();

List<String> _tokens(String s) =>
    [for (final m in _word.allMatches(_norm(s))) m.group(0)!];

/// Every name a food answers to: English name, the same without the
/// ", cooked" part, and each local name (uz, ru).
List<String> _names(Food f) => [
      f.name,
      f.name.split(',').first,
      ...?f.localName?.split('·'),
    ].map(_norm).where((s) => s.isNotEmpty).toList();

/// The food Felix means by [name]: an exact name or local name first, then
/// names that contain every word of [name] (the shortest main name wins,
/// then catalog order). Null when nothing fits.
Food? matchFood(String name, FoodCatalog catalog) {
  final q = _norm(name);
  final qTokens = _tokens(name);
  if (q.isEmpty || qTokens.isEmpty) return null;

  Food? best;
  var bestScore = 1 << 30;
  for (final f in catalog.all) {
    var score = 1 << 30;
    for (final n in _names(f)) {
      if (n == q) {
        score = 0;
        break;
      }
      final t = _tokens(n);
      if (qTokens.every(t.contains) && t.length < score) score = t.length;
    }
    if (score < bestScore) {
      best = f;
      bestScore = score;
    }
  }
  return best;
}

/// The log entry for [item]: the base's values scaled to the grams when
/// [food] is known, otherwise Felix's own numbers marked as an estimate.
FoodEntry entryFor(
  FoodLogItem item,
  Food? food,
  MealSlot slot,
  DateTime at, {
  String? id,
}) {
  final entryId = id ?? newEntryId(at);
  if (food != null) {
    return FoodEntry.fromFood(food,
        grams: item.grams, slot: slot, at: at, id: entryId);
  }
  return FoodEntry(
    id: entryId,
    at: at,
    slot: slot,
    name: item.name,
    grams: item.grams,
    kcal: item.kcal,
    protein: item.protein,
    carbs: item.carbs,
    fat: item.fat,
    estimate: true,
  );
}
