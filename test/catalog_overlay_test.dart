import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitrix/core/i18n/catalog_overlay.dart';
import 'package:fitrix/core/i18n/catalog_text.dart';
import 'package:fitrix/core/session/session_providers.dart';
import 'package:fitrix/features/content/data/content_repository.dart';
import 'package:fitrix/features/exercises/data/exercise_catalog.dart';
import 'package:fitrix/features/exercises/domain/exercise_stats.dart';
import 'package:fitrix/features/language/presentation/providers/language_provider.dart';
import 'package:fitrix/features/nutrition/data/food_catalog.dart';
import 'package:fitrix/features/nutrition/data/food_log_store.dart';
import 'package:fitrix/features/plan/data/week_plan.dart';
import 'package:fitrix/features/programs/domain/program_catalog.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/features/workouts/data/workout_catalog.dart';

import 'support/catalog_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ExerciseCatalog exercises;
  late FoodCatalog foods;
  late ProgramCatalog programs;
  setUpAll(() async {
    exercises = await ExerciseCatalog.load(rootBundle);
    foods = await FoodCatalog.load(rootBundle);
    programs = await ProgramCatalog.load(rootBundle);
  });

  Future<CatalogOverlay> ru(Map<String, Object> catalogs) =>
      CatalogOverlay.load(FixtureBundle.locale('ru', catalogs), 'ru');

  group('overlay', () {
    test('a translated field reads the overlay, a missing key English',
        () async {
      final o = await ru({'exercises': ruExercises});
      final t = CatalogText(o, exercises: exercises);
      final bench = exercises.byId('bench-press')!;
      final squat = exercises.byId('deadlift')!;
      expect(t.exerciseName(bench), 'Жим штанги лёжа на горизонтальной скамье');
      expect(t.exerciseSteps(bench), hasLength(bench.steps.length));
      expect(t.exerciseSteps(bench).first, startsWith('Глаза под грифом'));
      expect(t.muscle('Chest'), 'Грудные мышцы');
      expect(t.pattern('Horizontal push'), 'Горизонтальный жим');
      // Not in the overlay: English.
      expect(t.exerciseName(squat), squat.name);
      expect(t.exerciseSteps(squat), squat.steps);
      expect(t.muscle('Quads'), 'Quads');
      expect(t.pattern('Hinge'), 'Hinge');
    });

    test('a list of the wrong length keeps the English list', () async {
      final bench = exercises.byId('bench-press')!;
      final o = await ru({
        'exercises': {
          'exercises': {
            'bench-press': {
              'steps': ['Только один шаг'],
              'mistakes': ['', 'b', 'c'],
            },
          },
        },
      });
      final t = CatalogText(o, exercises: exercises);
      expect(t.exerciseSteps(bench), bench.steps);
      expect(t.exerciseMistakes(bench), bench.mistakes);
    });

    test('a missing or malformed file reads English', () async {
      final bundle = FixtureBundle({
        CatalogOverlay.assetPath('foods', 'ru'): ruFoods,
      });
      final o = await CatalogOverlay.load(bundle, 'ru');
      final t = CatalogText(o, exercises: exercises);
      final bench = exercises.byId('bench-press')!;
      expect(t.exerciseName(bench), bench.name);
      expect(t.foodName(foods.byId('chicken_breast')!),
          'Куриная грудка, приготовленная');

      final none = await CatalogOverlay.load(FixtureBundle({}), 'uz');
      expect(none.isEmpty, isTrue);
      expect(CatalogText(none).exerciseName(bench), bench.name);
    });

    test('English never reads an overlay file', () async {
      final bundle = FixtureBundle.locale('en', {'exercises': ruExercises});
      final o = await CatalogOverlay.load(bundle, 'en');
      expect(o.isEmpty, isTrue);
      expect(bundle.reads, isEmpty);
    });
  });

  group('provider', () {
    test('follows the app language, reloads on a switch and caches', () async {
      SharedPreferences.setMockInitialValues({'language': 'en'});
      final prefs = await SharedPreferences.getInstance();
      final bundle = FixtureBundle({
        CatalogOverlay.assetPath('exercises', 'ru'): ruExercises,
        CatalogOverlay.assetPath('exercises', 'es'): {
          'exercises': {
            'bench-press': {'name': 'Press de banca'},
          },
        },
      });
      final c = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        catalogBundleProvider.overrideWithValue(bundle),
      ]);
      addTearDown(c.dispose);
      final bench = exercises.byId('bench-press')!;
      String name() =>
          CatalogText(c.read(catalogOverlayProvider), exercises: exercises)
              .exerciseName(bench);
      c.listen(catalogOverlayProvider, (_, __) {});

      await c.read(catalogOverlayLoaderProvider.future);
      expect(name(), 'Bench press');

      await c.read(selectedLanguageProvider.notifier).setLanguage('ru');
      // Until the Russian overlay is in, English, never a stale language.
      expect(c.read(catalogOverlayProvider).locale, isNot('es'));
      await c.read(catalogOverlayLoaderProvider.future);
      expect(name(), 'Жим штанги лёжа на горизонтальной скамье');

      await c.read(selectedLanguageProvider.notifier).setLanguage('es');
      await c.read(catalogOverlayLoaderProvider.future);
      expect(name(), 'Press de banca');

      final readsBefore = bundle.reads.length;
      await c.read(selectedLanguageProvider.notifier).setLanguage('ru');
      await c.read(catalogOverlayLoaderProvider.future);
      expect(name(), 'Жим штанги лёжа на горизонтальной скамье');
      expect(bundle.reads.length, readsBefore, reason: 'cached per locale');
    });
  });

  group('names stored in English', () {
    test(
        'a workout exercise: catalog name or alias, then the workout '
        'names, then as stored', () async {
      final o = await ru({
        'exercises': ruExercises,
        'workout_catalog': {
          'exerciseNames': {'Plank (sec)': 'Планка (сек)'},
        },
      });
      final t = CatalogText(o, exercises: exercises);
      expect(t.exercise('Bench press'),
          'Жим штанги лёжа на горизонтальной скамье');
      expect(t.exercise('Flat bench press'),
          'Жим штанги лёжа на горизонтальной скамье');
      expect(t.exercise('Plank (sec)'), 'Планка (сек)');
      expect(t.exercise('My own move'), 'My own move');
    });

    test('a starter workout reads translated until the user renames it',
        () async {
      final o = await ru({
        'workout_catalog': {
          'templates': {
            'gym-legs': {'name': 'Ноги', 'focus': 'Низ тела'},
          },
        },
      });
      final t = CatalogText(o);
      final legs =
          WorkoutCatalog.defaults.firstWhere((x) => x.id == 'gym-legs');
      expect(t.templateName(legs), 'Ноги');
      expect(t.templateFocus(legs), 'Низ тела');
      final renamed = legs.copyWith(name: 'Leg day!');
      expect(t.templateName(renamed), 'Leg day!');
      // Stored data is untouched.
      expect(legs.name, 'Legs');
      expect(legs.toJson()['name'], 'Legs');
      expect(legs.exercises.first.name, 'Squat');
      // A finished workout from it reads the same way.
      final done = CompletedWorkout(
        templateId: 'gym-legs',
        name: 'Legs',
        sport: Sport.gym,
        startedAt: DateTime(2026, 10, 1, 18),
        finishedAt: DateTime(2026, 10, 1, 19),
        exercises: const [],
      );
      expect(t.completedTitle(done), 'Ноги');
      expect(done.toJson()['name'], 'Legs');
    });

    test('program sessions in templates and on the plan', () async {
      final o = await ru({
        'training_programs': {
          'ppl-6': {
            'name': 'Тяни / толкай / ноги',
            'sessions': ['Толкай', 'Тяни', 'Ноги'],
          },
        },
      });
      final t = CatalogText(o, programs: programs);
      expect(t.workoutTitle('some-uuid', 'Push / Pull / Legs · Pull'),
          'Тяни / толкай / ноги · Тяни');
      final plan = PlannedSession(
        id: '${programSessionPrefix('ppl-6')}20261012-0',
        day: DateTime(2026, 10, 12),
        sport: Sport.gym,
        title: 'Push',
        minutes: 60,
        intensity: Intensity.normal,
      );
      expect(t.planTitle(plan), 'Толкай');
      expect(plan.toJson()['title'], 'Push');
    });

    test('a logged food reads translated while it keeps the catalog name',
        () async {
      final o = await ru({'foods': ruFoods});
      final t = CatalogText(o);
      final chicken = foods.byId('chicken_breast')!;
      final entry = FoodEntry.fromFood(chicken,
          grams: 120,
          slot: MealSlot.lunch,
          at: DateTime(2026, 10, 1, 13),
          id: 'e1');
      expect(t.foodEntryName(entry, foods), 'Куриная грудка, приготовленная');
      expect(entry.toJson()['name'], 'Chicken breast, cooked');
      expect(t.portion('1 breast'), '1 грудка');
    });
  });

  group('search', () {
    test('the exercise picker finds English and Russian names and aliases',
        () async {
      final o = await ru({'exercises': ruExercises});
      final t = CatalogText(o, exercises: exercises);
      List<String> ids(String q) => [
            for (final e in filterExercises(exercises.all, query: q, text: t))
              e.id
          ];
      expect(ids('скамье'), contains('bench-press'));
      expect(ids('жим штанги'), contains('bench-press'));
      expect(ids('bench press'), contains('bench-press'));
    });

    test('food search finds a food by its Russian name', () async {
      final o = await ru({'foods': ruFoods});
      final t = CatalogText(o);
      expect(foods.search('приготовленная', nameOf: t.foodName).first.id,
          'chicken_breast');
      expect(foods.search('chicken breast', nameOf: t.foodName).first.id,
          'chicken_breast');
      expect(foods.search('приготовленная'), isEmpty);
    });
  });

  group('seed and cloud content', () {
    test('rows read translated by id, whatever their source', () async {
      final o = await ru({
        'seed_content': {
          'products': {
            'p1': {'name': 'Протеин сывороточный'},
          },
          'places': {
            'pl1': {'name': 'Площадь Амира Темура', 'type': 'Парк'},
          },
        },
      });
      final t = CatalogText(o);
      const product = Product(
          id: 'p1', name: 'Whey protein', category: 'food', priceCents: 1);
      expect(t.product(product).name, 'Протеин сывороточный');
      expect(t.product(product).priceCents, 1);
      const place = Place(
          id: 'pl1',
          name: 'Amir Timur Square',
          kind: 'parks',
          type: 'Park',
          lat: 41.3,
          lon: 69.2,
          note: 'Lit at night');
      final shown = t.place(place);
      expect(shown.name, 'Площадь Амира Темура');
      expect(shown.type, 'Парк');
      expect(shown.note, 'Lit at night', reason: 'missing key: English');
      expect(shown.hours, isNull);
      expect(shown.kind, 'parks');
    });
  });

  group('bundled overlay files', () {
    // Checks whichever translations are in assets/data/i18n/: valid JSON,
    // known ids only, numbered lists as long as the source.
    Map<String, dynamic>? read(String catalog, String locale) {
      final f = File(CatalogOverlay.assetPath(catalog, locale));
      return f.existsSync()
          ? jsonDecode(f.readAsStringSync()) as Map<String, dynamic>
          : null;
    }

    for (final locale in ['ru', 'uz', 'es']) {
      test('$locale overlays match the catalogs', () {
        final ex = read('exercises', locale);
        if (ex != null) {
          for (final e in (ex['exercises'] as Map).entries) {
            final info = exercises.byId(e.key as String);
            expect(info, isNotNull, reason: 'exercise ${e.key}');
            final v = e.value as Map;
            if (v['steps'] != null) {
              expect((v['steps'] as List).length, info!.steps.length,
                  reason: '${e.key} steps');
            }
            if (v['mistakes'] != null) {
              expect((v['mistakes'] as List).length, info!.mistakes.length,
                  reason: '${e.key} mistakes');
            }
          }
        }
        final fo = read('foods', locale);
        if (fo != null) {
          for (final id in (fo['foods'] as Map).keys) {
            expect(foods.byId(id as String), isNotNull, reason: 'food $id');
          }
        }
        final tp = read('training_programs', locale);
        if (tp != null) {
          for (final e in tp.entries) {
            final p = programs.byId(e.key);
            expect(p, isNotNull, reason: 'program ${e.key}');
            final v = e.value as Map;
            if (v['sessions'] != null) {
              expect((v['sessions'] as List).length, p!.sessions.length,
                  reason: '${e.key} sessions');
            }
            if (v['progressionRules'] != null) {
              expect((v['progressionRules'] as List).length,
                  p!.progressionRules.length,
                  reason: '${e.key} rules');
            }
          }
        }
        final wc = read('workout_catalog', locale);
        if (wc != null) {
          final ids = {for (final t in WorkoutCatalog.defaults) t.id};
          for (final id in (wc['templates'] as Map? ?? {}).keys) {
            expect(ids, contains(id), reason: 'template $id');
          }
        }
        final seed = read('seed_content', locale);
        if (seed != null) {
          final source = jsonDecode(
                  File('assets/data/seed_content.json').readAsStringSync())
              as Map<String, dynamic>;
          for (final section in seed.keys) {
            final known = {
              for (final r in source[section] as List) (r as Map)['id'],
            };
            for (final id in (seed[section] as Map).keys) {
              expect(known, contains(id), reason: '$section $id');
            }
          }
        }
      });
    }
  });
}
