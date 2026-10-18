import 'package:fitrix/features/nutrition/data/food_catalog.dart';

typedef DinnerIdea = ({Food food, ({String label, int grams}) portion});

/// Dinner ideas for [remainingKcal]: Uzbek dishes and meat or fish whose
/// portion fits the calories, the best portion of each food, most protein
/// first. Dishes with a protein-poor portion (under 15 g) are left out.
List<DinnerIdea> dinnerIdeas(FoodCatalog catalog, int remainingKcal) {
  final ideas = <DinnerIdea>[];
  for (final f in catalog.all) {
    if (!(f.uzbek || f.category == 'meat_fish')) continue;
    DinnerIdea? best;
    for (final p in f.portions) {
      if (f.kcalFor(p.grams) > remainingKcal) continue;
      if (best == null ||
          f.proteinFor(p.grams) > best.food.proteinFor(best.portion.grams)) {
        best = (food: f, portion: p);
      }
    }
    if (best != null && best.food.proteinFor(best.portion.grams) >= 15) {
      ideas.add(best);
    }
  }
  ideas.sort((a, b) => b.food
      .proteinFor(b.portion.grams)
      .compareTo(a.food.proteinFor(a.portion.grams)));
  return ideas;
}
