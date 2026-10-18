import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitrix/core/router/app_router.dart';
import 'package:fitrix/core/session/session_providers.dart';
import 'package:fitrix/core/theme/app_theme.dart';
import 'package:fitrix/core/time/today_provider.dart';
import 'package:fitrix/features/progress/data/body_weight_store.dart';
import 'package:fitrix/features/progress/domain/progress_math.dart';
import 'package:fitrix/features/progress/presentation/screens/body_weight_screen.dart';
import 'package:fitrix/features/progress/presentation/screens/lift_detail_screen.dart';
import 'package:fitrix/features/progress/presentation/screens/progress_screen.dart';
import 'package:fitrix/features/progress/presentation/screens/records_screen.dart';
import 'package:fitrix/features/progress/presentation/screens/training_load_screen.dart';
import 'package:fitrix/features/exercises/data/exercise_catalog.dart';
import 'package:fitrix/features/nutrition/data/nutrition_targets.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/features/workouts/domain/training_math.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

final _today = DateTime(2026, 10, 18);

CompletedWorkout _workout(DateTime day, {double kg = 80, int? rpe = 7}) =>
    CompletedWorkout(
      id: 'w${day.toIso8601String()}-$kg',
      templateId: 't',
      name: 'Chest',
      sport: Sport.gym,
      startedAt: DateTime(day.year, day.month, day.day, 18),
      finishedAt: DateTime(day.year, day.month, day.day, 19),
      sessionRpe: rpe,
      exercises: [
        Exercise(name: 'Bench press', sets: [
          WorkoutSet(
              previousKg: 0, previousReps: 8, kg: kg, reps: 8, done: true),
        ]),
      ],
    );

/// A session every second day for six weeks, bench going up.
List<CompletedWorkout> _sixWeeks() => [
      for (var i = 0; i < 21; i++)
        _workout(DateTime(2026, 10, 18 - i * 2), kg: 100 - i.toDouble()),
    ];

Future<Widget> _host(
  Widget child, {
  List<CompletedWorkout> history = const [],
  List<Map<String, Object>> weighIns = const [],
  double textScale = 1,
  Map<String, Object> extra = const {},
}) async {
  SharedPreferences.setMockInitialValues({
    'user_name': 'Alex',
    'user_weight': '78.4',
    'performance_profile_v1': '{"sex":"male"}',
    if (history.isNotEmpty)
      'workout_history': jsonEncode([for (final w in history) w.toJson()]),
    if (weighIns.isNotEmpty) 'body_weight_v1': jsonEncode(weighIns),
    ...extra,
  });
  final prefs = await SharedPreferences.getInstance();
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      clockProvider.overrideWithValue(() => DateTime(2026, 10, 18, 9)),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
        ),
        child: child!,
      ),
      home: child,
    ),
  );
}

void _se(WidgetTester tester) {
  tester.view.physicalSize = const Size(375, 667) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

List<Map<String, Object>> _weighIns() => [
      for (var i = 0; i < 9; i++)
        {
          'at': DateTime(2026, 10, 18 - i * 7).toIso8601String(),
          'kg': 78.4 + i * 0.15,
        },
    ];

ExerciseCatalog _catalog() => ExerciseCatalog([
      for (final e
          in jsonDecode(File('assets/data/exercises.json').readAsStringSync())
              as List)
        ExerciseInfo.fromJson(e as Map<String, dynamic>),
    ]);

CompletedWorkout _lift(DateTime day, String name, double kg, int reps) =>
    CompletedWorkout(
      id: 'l${day.toIso8601String()}-$name',
      templateId: 't',
      name: 'Lift',
      sport: Sport.gym,
      startedAt: DateTime(day.year, day.month, day.day, 18),
      finishedAt: DateTime(day.year, day.month, day.day, 19),
      sessionRpe: 7,
      exercises: [
        Exercise(name: name, sets: [
          WorkoutSet(
              previousKg: 0,
              previousReps: reps,
              kg: kg,
              reps: reps,
              done: true),
        ]),
      ],
    );

/// Nine weigh-ins a week apart whose trend is [perWeek] kg/week.
List<Map<String, Object>> _trend(double perWeek) => [
      for (var i = 0; i < 9; i++)
        {
          'at': DateTime(2026, 10, 18 - i * 7).toIso8601String(),
          'kg': 80 - perWeek * i,
        },
    ];

String _goalPref(Goal g) => jsonEncode({'goal': g.name});

void main() {
  group('lift identity', () {
    final c = _catalog();
    test('only the five barbell lifts get a strength level', () {
      expect(liftKeyFor('Back squat', c), 'squat');
      expect(liftKeyFor('Squat', c), 'squat');
      expect(liftKeyFor('Bench press', c), 'bench');
      expect(liftKeyFor('Barbell row', c), 'row');
      expect(liftKeyFor('Overhead press', c), 'ohp');
      expect(liftKeyFor('Deadlift', c), 'deadlift');
      for (final n in [
        'Hack squat',
        'Front squat',
        'Dumbbell row',
        'One-arm dumbbell row',
        'Chest-supported row',
        'Seated cable row',
        'Machine row',
        'T-bar row',
        'Close-grip bench press',
        'Dumbbell bench press',
        'Romanian deadlift',
        'Something unknown',
      ]) {
        expect(liftKeyFor(n, c), isNull, reason: n);
      }
      expect(liftKeyFor('Back squat', null), isNull);
    });

    test('aliases of one exercise merge into one lift', () {
      final h = [
        _lift(DateTime(2026, 10, 1), 'Squat', 100, 5),
        _lift(DateTime(2026, 10, 8), 'Back squat', 105, 5),
      ];
      final lifts = liftsIn(h, c);
      expect(lifts, hasLength(1));
      expect(lifts.single.name, 'Back squat');
      expect(lifts.single.sessions, 2);
      expect(liftSeries(h, 'Back squat', c), hasLength(2));
      expect(liftSeries(h, 'Squat', c), hasLength(2));
    });
  });

  group('lift screen strength level', () {
    testWidgets('hack squat has none, back squat has one', (t) async {
      _se(t);
      final h = [
        _lift(DateTime(2026, 10, 1), 'Hack squat', 200, 10),
        _lift(DateTime(2026, 10, 8), 'Back squat', 100, 8),
      ];
      await t.pumpWidget(
          await _host(const LiftDetailScreen(name: 'Hack squat'), history: h));
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('strength-level')), findsNothing);
      await t.pumpWidget(
          await _host(const LiftDetailScreen(name: 'Back squat'), history: h));
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('strength-level')), findsOneWidget);
    });
  });

  group('body weight off-track card', () {
    Future<void> pump(WidgetTester t, double perWeek, Goal g) async {
      _se(t);
      await t.pumpWidget(await _host(const BodyWeightScreen(),
          weighIns: _trend(perWeek),
          extra: {'nutrition_settings_v1': _goalPref(g)}));
      await t.pumpAndSettle();
    }

    for (final (trend, goal) in [
      (-0.35, Goal.loseFat),
      (0.15, Goal.maintain),
      (0.2, Goal.leanBulk),
    ]) {
      testWidgets('$goal at $trend/wk is on track: no card', (t) async {
        await pump(t, trend, goal);
        expect(find.text('Update my targets'), findsNothing);
      });
    }

    testWidgets('lean bulk at -0.15/wk shows the card with 500 kcal',
        (t) async {
      await pump(t, -0.15, Goal.leanBulk);
      expect(find.text('Update my targets'), findsOneWidget);
      expect(find.textContaining('500 kcal'), findsOneWidget);
    });
  });

  group('progress math', () {
    test('weeklyTrendKg recovers a -0.15 kg/week series', () {
      final now = DateTime(2026, 10, 18);
      final w = [
        for (var i = 0; i < 8; i++)
          WeighIn(at: DateTime(2026, 10, 18 - (7 - i) * 7), kg: 80 - 0.15 * i),
      ];
      expect(weeklyTrendKg(w, now), closeTo(-0.15, 0.01));
    });

    test('weeklyTrendKg is null with too little data', () {
      final now = DateTime(2026, 10, 18);
      expect(weeklyTrendKg([], now), isNull);
      expect(weeklyTrendKg([WeighIn(at: now, kg: 80)], now), isNull);
      expect(
          weeklyTrendKg([
            WeighIn(at: now, kg: 80),
            WeighIn(at: DateTime(2026, 10, 15), kg: 79),
          ], now),
          isNull);
    });

    test('kcalAdjustment', () {
      expect(kcalAdjustment(-0.15, Goal.leanBulk), 500);
      expect(kcalAdjustment(0.3, Goal.leanBulk), isNull);
      expect(kcalAdjustment(0.0, Goal.maintain), isNull);
      expect(kcalAdjustment(-0.5, Goal.loseFat), isNull);
      expect(kcalAdjustment(0.2, Goal.loseFat), lessThan(0));
    });

    test('strengthInfo bands', () {
      expect(strengthInfo('bench', 107.3, 78.4)?.level, 'intermediate');
      expect(strengthInfo('bench', 40, 80)?.level, 'beginner');
      expect(strengthInfo('squat', 250, 80)?.level, 'elite');
      expect(strengthInfo('bench', 80, 80, female: true)?.level, 'advanced');
    });

    test('dailyLoads sums workouts on one local day', () {
      final a = _workout(DateTime(2026, 10, 18));
      final b = _workout(DateTime(2026, 10, 18), kg: 90);
      final days = dailyLoads([a, b, _workout(DateTime(2026, 10, 17))]);
      expect(days, hasLength(2));
      final today = days.firstWhere((d) => d.day == DateTime(2026, 10, 18));
      expect(today.load, a.load + b.load);
    });
  });

  test('lift route encodes the exercise name', () {
    expect(AppRouter.progressLift('Bench press/Close grip'),
        '/home/progress/lift/Bench%20press%2FClose%20grip');
  });

  group('screens', () {
    testWidgets('empty history says what to do', (t) async {
      _se(t);
      await t.pumpWidget(await _host(const ProgressScreen()));
      await t.pumpAndSettle();
      expect(find.text('Log a workout to see your load'), findsOneWidget);
      expect(t.takeException(), isNull);
    });

    testWidgets('six weeks of history: tiles match loadSummary', (t) async {
      _se(t);
      final history = _sixWeeks();
      await t.pumpWidget(await _host(const ProgressScreen(), history: history));
      await t.pumpAndSettle();
      final s = loadSummary(dailyLoads(history), _today);
      final fmt = NumberFormat.decimalPattern('en');
      String text(String key) =>
          t.widget<Text>(find.byKey(ValueKey(key))).data!;
      expect(text('fitness-value'), fmt.format(s.fitness.round()));
      expect(text('fatigue-value'), fmt.format(s.fatigue.round()));
      final pct = (s.form! * 100).round();
      expect(text('form-value'), '${pct >= 0 ? '+' : '−'}${pct.abs()}%');
      expect(t.takeException(), isNull);
    });

    for (final scale in [1.0, 1.3]) {
      testWidgets('every screen lays out at SE, text x$scale', (t) async {
        _se(t);
        final history = _sixWeeks();
        final screens = <Widget>[
          const ProgressScreen(),
          const TrainingLoadScreen(),
          const RecordsScreen(),
          const LiftDetailScreen(name: 'Bench press'),
          const BodyWeightScreen(),
        ];
        for (final screen in screens) {
          await t.pumpWidget(await _host(screen,
              history: history, weighIns: _weighIns(), textScale: scale));
          await t.pumpAndSettle();
          expect(t.takeException(), isNull, reason: '${screen.runtimeType}');
        }
        // And with nothing at all.
        for (final screen in screens) {
          await t.pumpWidget(await _host(screen, textScale: scale));
          await t.pumpAndSettle();
          expect(t.takeException(), isNull,
              reason: 'empty ${screen.runtimeType}');
        }
      });
    }

    testWidgets('logging weight stores a weigh-in and updates the profile',
        (t) async {
      _se(t);
      await t.pumpWidget(await _host(const BodyWeightScreen()));
      await t.pumpAndSettle();
      await t.tap(find.text("Log today's weight"));
      await t.pumpAndSettle();
      await t.enterText(find.byKey(const ValueKey('weight-field')), '77.5');
      await t.tap(find.byKey(const ValueKey('weight-save')));
      await t.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      final stored = jsonDecode(prefs.getString('body_weight_v1')!) as List;
      expect(stored, hasLength(1));
      expect((stored.single as Map)['kg'], 77.5);
      expect(prefs.getString('user_weight'), '77.5');
      expect(find.text('77.5 kg'), findsWidgets);
    });

    testWidgets('weight outside 20-400 kg is refused', (t) async {
      _se(t);
      await t.pumpWidget(await _host(const BodyWeightScreen()));
      await t.pumpAndSettle();
      await t.tap(find.text("Log today's weight"));
      await t.pumpAndSettle();
      await t.enterText(find.byKey(const ValueKey('weight-field')), '12');
      await t.tap(find.byKey(const ValueKey('weight-save')));
      await t.pumpAndSettle();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('body_weight_v1'), isNull);
      expect(find.byKey(const ValueKey('weight-field')), findsOneWidget);
    });
  });
}
