import 'package:fitrix/features/chat/data/models/chat_action.dart';
import 'package:fitrix/features/nutrition/data/food_catalog.dart';
import 'package:fitrix/features/nutrition/data/food_log_store.dart';

/// The meal slot that fits the time of day.
MealSlot slotForTime(DateTime t) => MealSlot.forTime(t);

final _word = RegExp(r'[\p{L}\p{N}]+', unicode: true);
final _apostrophes = RegExp('[\u2018\u2019\u02bb\u02bc\'`]');

String _norm(String s) => s.toLowerCase().replaceAll(_apostrophes, '').trim();

/// Words split out of [s], plurals cut ("eggs" is "egg").
List<String> _tokens(String s) => [
      for (final m in _word.allMatches(_norm(s))) _singular(m.group(0)!),
    ];

String _singular(String w) =>
    w.length > 3 && w.endsWith('s') && !w.endsWith('ss')
        ? w.substring(0, w.length - 1)
        : w;

/// Every name a food answers to: English name, the same without the
/// ", cooked" part, and each local name (uz, ru).
List<String> _names(Food f) => [
      f.name,
      f.name.split(',').first,
      ...?f.localName?.split('·'),
    ].map(_norm).where((s) => s.isNotEmpty).toList();

/// How a food is cooked says nothing about which food it is.
const _cooking = {
  'boiled',
  'cooked',
  'fried',
  'grilled',
  'baked',
  'roasted',
  'steamed',
  'fresh',
};

const _synonyms = {'pilaf': 'plov', 'pilau': 'plov', 'osh': 'plov'};
const _oatWords = {'oat', 'oatmeal', 'porridge', 'овсянка', 'овсянк'};
const _oatFiller = {..._cooking, 'hot', 'with', 'water', 'milk'};
const _drySigns = {'dry', 'raw', 'flakes'};

/// One word that names several foods: the usual one.
const _usual = {
  'chicken': 'chicken_breast',
  'курица': 'chicken_breast',
  'курицу': 'chicken_breast',
  'tovuq': 'chicken_breast',
  'plov': 'tashkent_plov',
  'плов': 'tashkent_plov',
};

/// The food Felix means by [name]: an exact name or local name first, then
/// names that contain every word of [name] (the shortest main name wins).
/// Null when nothing fits or when several foods fit equally well, so a wrong
/// food is never logged; Felix's own numbers are used then.
Food? matchFood(String name, FoodCatalog catalog) {
  final tokens = [
    for (final t in _tokens(name)) _synonyms[t] ?? t,
  ];
  if (tokens.isEmpty) return null;
  final found = _lookup(tokens, catalog);
  if (found != null) return found;
  final bare = [
    for (final t in tokens)
      if (!_cooking.contains(t)) t,
  ];
  if (bare.isEmpty || bare.length == tokens.length) return null;
  return _lookup(bare, catalog);
}

Food? _lookup(List<String> q, FoodCatalog catalog) {
  if (q.any(_oatWords.contains) || q.contains('oats')) {
    if (q.any(_drySigns.contains)) return catalog.byId('oats_dry');
    if (q.every((t) => _oatWords.contains(t) || _oatFiller.contains(t))) {
      return catalog.byId('oatmeal_cooked');
    }
  }
  if (q.length == 1 && _usual.containsKey(q.single)) {
    return catalog.byId(_usual[q.single]!);
  }

  final phrase = q.join(' ');
  Food? best;
  var bestScore = 1 << 30;
  var tied = false;
  for (final f in catalog.all) {
    var score = 1 << 30;
    for (final n in _names(f)) {
      final t = _tokens(n);
      if (t.join(' ') == phrase) {
        score = 0;
        break;
      }
      if (q.every(t.contains) && t.length < score) score = t.length;
    }
    if (score < bestScore) {
      best = f;
      bestScore = score;
      tied = false;
    } else if (score == bestScore && score < (1 << 30)) {
      tied = true;
    }
  }
  return tied ? null : best;
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
