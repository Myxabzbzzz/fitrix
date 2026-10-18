import 'package:flutter_test/flutter_test.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/features/workouts/domain/training_math.dart';

WorkoutSet set_(double kg, int reps, {bool done = true}) => WorkoutSet(
    previousKg: kg, previousReps: reps, kg: kg, reps: reps, done: done);

CompletedWorkout workout(DateTime day, List<Exercise> ex) => CompletedWorkout(
      templateId: 't',
      name: 'w',
      sport: Sport.gym,
      startedAt: day,
      finishedAt: day.add(const Duration(hours: 1)),
      exercises: ex,
    );

void main() {
  group('e1rm', () {
    test('Epley', () {
      expect(e1rm(82.5, 9).toStringAsFixed(1), '107.3');
      expect(e1rm(72.5, 8).toStringAsFixed(1), '91.8');
      expect(e1rm(100, 1), 100);
      expect(e1rm(100, 0), 0);
    });
  });

  test('sessionLoad', () {
    expect(sessionLoad(7, const Duration(minutes: 86)), 602);
    expect(sessionLoad(7, const Duration(minutes: 86, seconds: 50)), 602);
  });

  test('volumeKg counts done sets only', () {
    final v = volumeKg([
      Exercise(name: 'a', sets: [set_(100, 5), set_(100, 5, done: false)]),
      Exercise(name: 'b', sets: [set_(20, 10)]),
    ]);
    expect(v, 700);
  });

  group('loadSummary', () {
    final today = DateTime(2026, 10, 18);
    List<DailyLoad> days() => [
          for (var i = 0; i < 42; i++)
            DailyLoad(today.subtract(Duration(days: i)), i < 7 ? 390 : 469),
        ];

    test('fatigue is the 7 day mean', () {
      final s = loadSummary(days(), today);
      expect(s.fatigue, 390);
      const fitness = (7 * 390 + 35 * 469) / 42;
      expect(s.fitness, closeTo(fitness, 1e-9));
      expect(s.form, closeTo((fitness - 390) / fitness, 1e-9));
      expect(s.acwr, closeTo(390 / fitness, 1e-9));
      expect(s.band, AcwrBand.sweetSpot);
    });

    test('bands', () {
      final low = loadSummary([
        for (var i = 7; i < 42; i++)
          DailyLoad(today.subtract(Duration(days: i)), 500),
      ], today);
      expect(low.band, AcwrBand.low);
      final risky = loadSummary([
        for (var i = 0; i < 7; i++)
          DailyLoad(today.subtract(Duration(days: i)), 500),
      ], today);
      expect(risky.band, AcwrBand.risky);
    });

    test('missing days are zero and outside window ignored', () {
      final s = loadSummary([
        DailyLoad(today, 700),
        DailyLoad(today.subtract(const Duration(days: 60)), 9999),
      ], today);
      expect(s.fatigue, 100);
      expect(s.fitness, closeTo(700 / 42, 1e-9));
    });

    test('empty', () {
      final s = loadSummary([], today);
      expect(s.fitness, 0);
      expect(s.fatigue, 0);
      expect(s.form, isNull);
      expect(s.acwr, isNull);
      expect(s.band, isNull);
    });
  });

  group('records', () {
    final d1 = DateTime(2026, 10, 1);
    final d2 = DateTime(2026, 10, 8);

    test('first session is not a record', () {
      final w = workout(d1, [
        Exercise(name: 'Bench press', sets: [set_(80, 8)])
      ]);
      expect(recordsIn(w, []), isEmpty);
    });

    test('higher e1RM is a record', () {
      final a = workout(d1, [
        Exercise(name: 'Bench press', sets: [set_(80, 8)])
      ]);
      final b = workout(d2, [
        Exercise(name: 'Bench press', sets: [set_(82.5, 9)])
      ]);
      final r = recordsIn(b, [a]);
      expect(r, hasLength(1));
      expect(r.single.kind, RecordKind.e1rm);
      expect(r.single.value, closeTo(107.25, 1e-9));
      expect(r.single.previous, closeTo(80 * (1 + 8 / 30), 1e-9));
      expect(r.single.exercise, 'Bench press');
    });

    test('lower or equal is not a record', () {
      final a = workout(d1, [
        Exercise(name: 'Bench press', sets: [set_(80, 8)])
      ]);
      final b = workout(d2, [
        Exercise(name: 'Bench press', sets: [set_(80, 8)])
      ]);
      expect(recordsIn(b, [a]), isEmpty);
    });

    test('bodyweight uses reps', () {
      final a = workout(d1, [
        Exercise(name: 'Push-ups', sets: [set_(0, 20)])
      ]);
      final b = workout(d2, [
        Exercise(name: 'Push-ups', sets: [set_(0, 25), set_(0, 10)])
      ]);
      final r = recordsIn(b, [a]);
      expect(r.single.kind, RecordKind.reps);
      expect(r.single.value, 25);
      expect(r.single.previous, 20);
    });

    // Warm-up sets are ignored once WorkoutSet.warmup exists (Task 2).

    test('allRecords is chronological', () {
      final a = workout(d1, [
        Exercise(name: 'Bench press', sets: [set_(80, 8)])
      ]);
      final b = workout(d2, [
        Exercise(name: 'Bench press', sets: [set_(82.5, 9)])
      ]);
      final c = workout(DateTime(2026, 10, 15), [
        Exercise(name: 'Bench press', sets: [set_(85, 9)])
      ]);
      final r = allRecords([c, a, b]);
      expect(r.map((e) => e.date).toList(), [b.finishedAt, c.finishedAt]);
    });
  });

  group('suggestNextKg', () {
    test('all done adds 2.5', () {
      expect(suggestNextKg([for (var i = 0; i < 4; i++) set_(70, 8)]), 72.5);
    });
    test('one short keeps weight', () {
      expect(
          suggestNextKg([
            set_(70, 8),
            set_(70, 8),
            set_(70, 8),
            set_(70, 8, done: false)
          ]),
          70);
    });
    test('none', () => expect(suggestNextKg([]), isNull));
  });

  test('roundToPlate', () {
    expect(roundToPlate(71), 70);
    expect(roundToPlate(71.3), 72.5);
    expect(roundToPlate(72.5), 72.5);
  });
}
