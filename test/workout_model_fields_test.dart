import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:fitrix/core/sync/sync_merge.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/features/workouts/domain/training_math.dart';

CompletedWorkout _cw({
  String id = 'w1',
  int? sessionRpe,
  List<Exercise>? exercises,
  Duration length = const Duration(minutes: 60),
}) {
  final start = DateTime(2026, 10, 1, 10);
  return CompletedWorkout(
    id: id,
    templateId: 't',
    name: 'Push',
    sport: Sport.gym,
    startedAt: start,
    finishedAt: start.add(length),
    exercises: exercises ??
        const [
          Exercise(name: 'Bench press', sets: [
            WorkoutSet(
                previousKg: 0, previousReps: 0, kg: 60, reps: 5, done: true),
          ]),
        ],
    sessionRpe: sessionRpe,
  );
}

void main() {
  test('new fields round-trip through JSON', () {
    final w = _cw(
      sessionRpe: 8,
      exercises: const [
        Exercise(name: 'Squat', restSeconds: 120, note: 'belt', sets: [
          WorkoutSet(
              previousKg: 0,
              previousReps: 0,
              kg: 40,
              reps: 10,
              done: true,
              warmup: true),
          WorkoutSet(
              previousKg: 0,
              previousReps: 0,
              kg: 100,
              reps: 5,
              done: true,
              rpe: 9),
        ]),
      ],
    );
    final back = CompletedWorkout.fromJson(
        jsonDecode(jsonEncode(w.toJson())) as Map<String, dynamic>);
    expect(back.sessionRpe, 8);
    final ex = back.exercises.single;
    expect(ex.restSeconds, 120);
    expect(ex.note, 'belt');
    expect(ex.sets[0].warmup, isTrue);
    expect(ex.sets[0].rpe, isNull);
    expect(ex.sets[1].warmup, isFalse);
    expect(ex.sets[1].rpe, 9);
  });

  test('old JSON loads with null and false defaults', () {
    final w = CompletedWorkout.fromJson({
      'id': 'old',
      'templateId': 't',
      'name': 'Old',
      'sport': 'gym',
      'startedAt': '2026-10-01T10:00:00.000',
      'finishedAt': '2026-10-01T11:00:00.000',
      'exercises': [
        {
          'name': 'Squat',
          'sets': [
            {
              'previousKg': 0,
              'previousReps': 0,
              'kg': 50,
              'reps': 5,
              'done': true
            }
          ]
        }
      ],
    });
    expect(w.sessionRpe, isNull);
    expect(w.exercises.single.restSeconds, isNull);
    expect(w.exercises.single.note, isNull);
    expect(w.exercises.single.sets.single.rpe, isNull);
    expect(w.exercises.single.sets.single.warmup, isFalse);
    // The stored shape does not grow keys for unset fields.
    expect(w.exercises.single.toJson().containsKey('note'), isFalse);
    expect(w.exercises.single.sets.single.toJson().containsKey('rpe'), isFalse);
    expect(w.toJson().containsKey('sessionRpe'), isFalse);
  });

  test('copyWith carries the new fields', () {
    const s = WorkoutSet(previousKg: 0, previousReps: 0, kg: 1, reps: 1);
    final c = s.copyWith(rpe: 7, warmup: true);
    expect(c.rpe, 7);
    expect(c.warmup, isTrue);
    final e = const Exercise(name: 'a', sets: []).copyWith(
      restSeconds: 90,
      note: 'n',
    );
    expect(e.restSeconds, 90);
    expect(e.note, 'n');
    expect(_cw().copyWith(sessionRpe: 5).sessionRpe, 5);
  });

  test('load uses sessionRpe, or 6 and flags the estimate', () {
    expect(_cw(sessionRpe: 8).load, sessionLoad(8, const Duration(hours: 1)));
    expect(_cw(sessionRpe: 8).loadEstimated, isFalse);
    expect(_cw().load, 360);
    expect(_cw().loadEstimated, isTrue);
  });

  test('CompletedWorkout.from drops warm-ups from setCount', () {
    final active = ActiveWorkout(
      template: const WorkoutTemplate(
        id: 't',
        sport: Sport.gym,
        name: 'Push',
        focus: 'f',
        estimatedDuration: Duration(minutes: 60),
        exercises: [],
      ),
      startedAt: DateTime(2026, 10, 1, 10),
      exercises: const [
        Exercise(name: 'Bench press', sets: [
          WorkoutSet(
              previousKg: 0,
              previousReps: 0,
              kg: 20,
              reps: 10,
              done: true,
              warmup: true),
          WorkoutSet(
              previousKg: 0, previousReps: 0, kg: 60, reps: 5, done: true),
          WorkoutSet(previousKg: 0, previousReps: 0, kg: 60, reps: 5),
        ]),
      ],
    );
    final w = CompletedWorkout.from(active, DateTime(2026, 10, 1, 11),
        sessionRpe: 7);
    expect(w.setCount, 1);
    expect(w.sessionRpe, 7);
  });

  test('server copy of a workout never overrides local-only fields', () {
    final local = _cw(
      sessionRpe: 8,
      exercises: const [
        Exercise(name: 'Bench press', sets: [
          WorkoutSet(
              previousKg: 0,
              previousReps: 0,
              kg: 60,
              reps: 5,
              done: true,
              rpe: 9,
              warmup: false),
        ]),
      ],
    );
    final server = _cw(); // no sessionRpe, no rpe
    final merge = unionById(
      local: [local],
      remote: [server],
      idOf: (w) => w.id,
      compare: newestFirst,
    );
    expect(merge.changed, isFalse);
    expect(merge.items.single.sessionRpe, 8);
    expect(merge.items.single.exercises.single.sets.single.rpe, 9);
  });
}
