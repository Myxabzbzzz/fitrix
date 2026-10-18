import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitrix/features/exercises/data/exercise_catalog.dart';
import 'package:fitrix/features/workouts/data/workout_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ExerciseCatalog catalog;
  setUpAll(() async {
    catalog = await ExerciseCatalog.load(rootBundle);
  });

  test('loads at least 60 unique entries', () {
    expect(catalog.all.length, greaterThanOrEqualTo(60));
    final ids = catalog.all.map((e) => e.id).toSet();
    expect(ids.length, catalog.all.length);
  });

  test('names and aliases are unique across exercises', () {
    final owner = <String, String>{};
    for (final e in catalog.all) {
      for (final n in [e.name, ...e.aliases]) {
        final key = n.trim().toLowerCase();
        final prev = owner[key];
        expect(prev == null || prev == e.id, isTrue,
            reason: '"$n" in ${e.id} also used by $prev');
        owner[key] = e.id;
      }
    }
  });

  test('every group and equipment is covered', () {
    expect(catalog.all.map((e) => e.group).toSet(), MuscleGroup.values.toSet());
    expect(
        catalog.all.map((e) => e.equipment).toSet(), Equipment.values.toSet());
  });

  test('similar ids exist and loads are valid', () {
    const areas = {'legs', 'back', 'chest', 'arms', 'shoulders'};
    for (final e in catalog.all) {
      for (final s in e.similar) {
        expect(catalog.byId(s), isNotNull, reason: '${e.id} -> $s');
      }
      expect(e.loads.toSet().difference(areas), isEmpty, reason: e.id);
      expect(e.steps, isNotEmpty, reason: e.id);
      expect(e.mistakes, isNotEmpty, reason: e.id);
    }
  });

  test('every default workout exercise resolves', () {
    for (final t in WorkoutCatalog.defaults) {
      for (final e in t.exercises) {
        expect(catalog.byName(e.name), isNotNull, reason: e.name);
      }
    }
  });

  test('byName is case-insensitive and uses aliases', () {
    expect(catalog.byName('SQUAT')?.name, 'Back squat');
    expect(catalog.byName('bench press')?.name, 'Bench press');
    expect(catalog.byName('nope'), isNull);
  });

  test('design names and loads', () {
    for (final n in [
      'Lat pulldown',
      'Triceps pushdown',
      'Overhead extension',
      'Face pull',
      'Straight-arm pulldown',
      'Seated cable row',
      'Deadlift',
      'Bulgarian split squat',
      'Close-grip bench press',
      'Curl, EZ bar',
      'Overhead press',
      'Romanian deadlift',
      'Hammer curl',
      'Incline bench',
      'Dumbbell bench press',
      'Machine chest press',
      'Push-ups',
      'Dumbbell row',
      'Chest-supported row',
      'Barbell row',
    ]) {
      expect(catalog.byName(n), isNotNull, reason: n);
    }
    expect(catalog.byName('Barbell row')!.loads, ['back', 'legs']);
    expect(catalog.byName('Chest-supported row')!.loads, ['back']);
    expect(catalog.byName('Back squat')!.loads, containsAll(['legs', 'back']));
  });

  test('bench press and similarTo', () {
    final b = catalog.byName('Bench press')!;
    expect(b.equipment, Equipment.barbell);
    expect(b.pattern, 'Horizontal push');
    expect(b.compound, isTrue);
    expect(b.steps, hasLength(4));
    expect(b.mistakes, hasLength(3));
    expect(
        catalog.similarTo(b).map((e) => e.name),
        containsAll([
          'Dumbbell bench press',
          'Incline bench',
          'Push-ups',
          'Machine chest press'
        ]));
  });
}
