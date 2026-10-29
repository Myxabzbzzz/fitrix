import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitrix/core/i18n/catalog_overlay.dart';
import 'package:fitrix/core/i18n/catalog_text.dart';
import 'package:fitrix/core/text/normalize.dart';
import 'package:fitrix/features/exercises/data/exercise_catalog.dart';
import 'package:fitrix/features/exercises/domain/exercise_stats.dart';
import 'package:fitrix/features/nutrition/data/food_catalog.dart';

import 'support/catalog_fixtures.dart';

/// The real bundled overlay files for [locale], read from disk.
Future<CatalogOverlay> realOverlay(String locale) {
  final files = <String, Object>{};
  for (final c in [
    'exercises',
    'foods',
    'training_programs',
    'seed_content',
    'workout_catalog'
  ]) {
    final f = File(CatalogOverlay.assetPath(c, locale));
    if (f.existsSync()) files[f.path] = jsonDecode(f.readAsStringSync());
  }
  return CatalogOverlay.load(FixtureBundle(files), locale);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ExerciseCatalog exercises;
  late FoodCatalog foods;
  setUpAll(() async {
    exercises = await ExerciseCatalog.load(rootBundle);
    foods = await FoodCatalog.load(rootBundle);
  });

  test('searchFold folds case, ё and apostrophe variants', () {
    expect(searchFold('  МЁД '), 'мед');
    expect(searchFold("go'sht"), searchFold('go‘sht'));
    expect(searchFold('go`sht'), searchFold('goʻsht'));
    expect(searchFold('goʼsht'), searchFold('go’sht'));
  });

  test('Russian «мед» finds Мёд and «подъем ног» finds the ё name', () async {
    final t = CatalogText(await realOverlay('ru'), exercises: exercises);
    expect(foods.search('мед', nameOf: t.foodName).map((f) => f.name),
        contains('Honey'));
    final hang = exercises.all
        .firstWhere((e) => t.exerciseName(e).contains('Подъём ног в висе'));
    expect(
        filterExercises(exercises.all, query: 'подъем ног', text: t)
            .map((e) => e.id),
        contains(hang.id));
  });

  test('Uzbek «go\'sht» finds a «go‘sht» food and exercise names', () async {
    final t = CatalogText(await realOverlay('uz'), exercises: exercises);
    final found = foods.search("go'sht", nameOf: t.foodName);
    expect(found, isNotEmpty);
    expect(found.map(t.foodName), contains('Mol go‘shti, pishirilgan'));
    expect(foods.search('go`sht', nameOf: t.foodName), isNotEmpty);
    expect(
        filterExercises(exercises.all, query: "o'tirib", text: t), isNotEmpty);
  });
}
