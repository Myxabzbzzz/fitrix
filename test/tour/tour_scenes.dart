import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitrix/core/router/app_router.dart';
import 'package:fitrix/features/chat/data/models/assistant_topic.dart';
import 'package:fitrix/features/checkin/presentation/widgets/checkin_sheet.dart';
import 'package:fitrix/features/nutrition/data/food_catalog.dart';
import 'package:fitrix/features/plan/presentation/widgets/add_session_sheet.dart';
import 'package:fitrix/features/cycling/presentation/cycling_screen.dart';
import 'package:fitrix/features/running/data/activity_kind.dart';
import 'package:fitrix/features/running/presentation/screens/live_run_screen.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/features/workouts/data/workout_catalog.dart';
import 'package:fitrix/features/workouts/presentation/providers/workouts_provider.dart';
import 'package:fitrix/features/workouts/presentation/start_workout.dart';
import 'package:fitrix/features/workouts/presentation/widgets/exercise_menu_sheet.dart';
import 'package:fitrix/features/workouts/presentation/widgets/live_log_rpe_sheet.dart';

import 'tour_harness.dart';

const tourConfigs = [
  proRuLight,
  proRuDark,
  seRuLight,
  seRuScaled,
  proEnLight,
];

class Scene {
  const Scene(this.id, this.body,
      {this.seed = const Seed(), this.en = false, this.auth = false});
  final String id;
  final Seed seed;

  /// Also shot in English (text-heavy screens).
  final bool en;
  final bool auth;
  final Future<void> Function(TourRig r) body;

  bool runsIn(TourConfig c) => c.lang == 'ru' || en;

  Future<void> run(WidgetTester t, TourConfig cfg) async {
    final r = await pumpTour(t, cfg, seed: seed, auth: auth);
    await body(r);
  }
}

Future<void> _page(TourRig r, String location, String name) async {
  await r.go(location);
  await shotPages(r, name);
}

Scene _simple(String id, String location, {Seed seed = const Seed(), bool en = false}) =>
    Scene(id, (r) => _page(r, location, id), seed: seed, en: en);

/// Starts a live activity and feeds [secs] seconds of fixes.
Future<void> _live(TourRig r, ActivityKind kind) async {
  await r.recorder.start(kind: kind);
  openLiveRun(r.router);
  await r.settle();
  var alt = 2100.0;
  for (var i = 0; i <= 600; i++) {
    switch (kind) {
      case ActivityKind.run:
        r.fix(i, i * 3.1, (i % 120) * 0.4);
      case ActivityKind.ride:
        r.fix(i, i * 7.4, (i % 200) * 0.6);
      case ActivityKind.ski:
        // Descend 0-200 s, lift 200-500 s, descend again.
        final down = i < 200 || i > 500;
        alt += down ? -1.6 : 0.5;
        r.fix(i, down ? i * 6.0 : 1200, down ? 0 : (i - 200) * 2.0, alt);
    }
  }
  await r.t.pump(const Duration(seconds: 1));
  await r.settle(maxFrames: 5);
}

CompletedWorkout _finished() {
  final t = WorkoutCatalog.defaults.first;
  return CompletedWorkout(
    id: 'finished-1',
    templateId: t.id,
    name: t.name,
    sport: t.sport,
    startedAt: tourNow.subtract(const Duration(minutes: 74)),
    finishedAt: tourNow,
    exercises: [
      for (final e in t.exercises.take(5))
        Exercise(name: e.name, sets: [
          for (final s in e.sets)
            s.copyWith(kg: s.kg + 2.5, done: true),
        ]),
    ],
  );
}

final tourScenes = <Scene>[
  // ------------------------------------------------------ onboarding
  Scene('intro', (r) async {
    await r.go(AppRouter.intro);
    await shot(r, 'onb1_intro');
  }, seed: const Seed(onboarded: false, profile: false)),
  Scene('language', (r) async {
    await r.go(AppRouter.language);
    await shot(r, 'onb2_language');
  }, seed: const Seed(onboarded: false, profile: false), en: true),
  Scene('sign-in', (r) async {
    await r.go(AppRouter.signIn);
    await shot(r, 'onb3_sign_in_email');
    await r.t.enterText(find.byKey(const Key('email-input')), 'not-an-email');
    await r.t.testTextInput.receiveAction(TextInputAction.go);
    await r.settle();
    await shot(r, 'onb3_sign_in_email_error');
    await r.t.enterText(find.byKey(const Key('email-input')), 'alex@example.com');
    await r.t.testTextInput.receiveAction(TextInputAction.go);
    await r.settle();
    FocusManager.instance.primaryFocus?.unfocus();
    await r.settle();
    await shot(r, 'onb3_sign_in_code');
  }, seed: const Seed(onboarded: false, profile: false), auth: true, en: true),
  Scene('onboarding-profile', (r) async {
    await r.go(AppRouter.profile);
    await shotPages(r, 'onb4_profile');
  }, seed: const Seed(onboarded: false, profile: false), en: true),
  Scene('onboarding-profile-filled', (r) async {
    await r.go(AppRouter.profile);
    await shotPages(r, 'onb4_profile_filled');
  }, seed: const Seed(onboarded: false)),
  Scene('onboarding-chat', (r) async {
    await r.go(AppRouter.chat);
    await shot(r, 'onb5_chat');
  }, seed: const Seed(onboarded: false, chats: false), en: true),

  // ------------------------------------------------------ home
  Scene('home', (r) async {
    await r.go(AppRouter.home);
    await shotPages(r, 'home_planned');
  }, en: true),
  Scene('home-empty', (r) async {
    await r.go(AppRouter.home);
    await shotPages(r, 'home_empty');
  }, seed: Seed.empty, en: true),
  Scene('home-rest-day', (r) async {
    await r.go(AppRouter.home);
    await shotPages(r, 'home_no_session_today');
  }, seed: const Seed(planToday: false, checkIn: false)),
  Scene('home-drawer', (r) async {
    await r.go(AppRouter.home);
    await r.t.tap(find.byIcon(Icons.menu).first);
    await r.settle();
    await shot(r, 'home_drawer');
  }),
  Scene('checkin-sheet', (r) async {
    await r.go(AppRouter.home);
    showCheckInSheet(r.context);
    await r.settle();
    await shotPages(r, 'checkin_sheet');
  }, seed: const Seed(checkIn: false), en: true),

  // ------------------------------------------------------ workouts
  _simple('my-workouts', AppRouter.workouts, en: true),
  _simple('my-workouts-empty', AppRouter.workouts, seed: Seed.empty),
  _simple('sport-gym', AppRouter.sportWorkouts(Sport.gym)),
  _simple('sport-fitness', AppRouter.sportWorkouts(Sport.fitness)),
  _simple('sport-running', AppRouter.sportWorkouts(Sport.running), en: true),
  _simple('sport-running-empty', AppRouter.sportWorkouts(Sport.running),
      seed: Seed.empty),
  _simple('sport-cycling', AppRouter.sportWorkouts(Sport.cycling)),
  _simple('sport-cycling-empty', AppRouter.sportWorkouts(Sport.cycling),
      seed: Seed.empty),
  _simple('sport-winter', AppRouter.sportWorkouts(Sport.winterSports)),
  _simple('sport-winter-empty', AppRouter.sportWorkouts(Sport.winterSports),
      seed: Seed.empty),
  _simple('sport-football', AppRouter.sportWorkouts(Sport.football), en: true),
  _simple('sport-football-empty', AppRouter.sportWorkouts(Sport.football),
      seed: Seed.empty),
  Scene('football-log-sheet', (r) async {
    await r.go(AppRouter.sportWorkouts(Sport.football));
    await r.tapKey('fb-log');
    await shotPages(r, 'football_log_sheet');
  }, en: true),
  Scene('ride-choice-sheet', (r) async {
    await r.go(AppRouter.sportWorkouts(Sport.cycling));
    final ref = r.t.element(find.byType(CyclingScreen)) as WidgetRef;
    final template = WorkoutTemplate(
      id: 'tour-ride',
      sport: Sport.cycling,
      name: r.ru('Интервалы на велосипеде', 'Bike intervals'),
      focus: '',
      estimatedDuration: const Duration(minutes: 60),
      exercises: const [],
    );
    unawaited(startWorkout(r.context, ref, template));
    await r.settle();
    await shot(r, 'ride_choice_sheet');
    await r.tapKey('ride-choice-indoor');
    await shotPages(r, 'indoor_ride_sheet_from_plan');
  }, en: true),
  Scene('indoor-ride-log', (r) async {
    await r.go(AppRouter.sportWorkouts(Sport.cycling));
    await r.tapKey('cy-log');
    await shotPages(r, 'indoor_ride_log_sheet');
  }),
  Scene('workout-settings-sheet', (r) async {
    await r.go(AppRouter.sportWorkouts(Sport.cycling));
    await r.tapKey('cy-settings');
    await shotPages(r, 'workout_settings_sheet');
  }, en: true),
  Scene('live-gym', (r) async {
    final n = r.container.read(activeWorkoutProvider.notifier);
    n.start(WorkoutCatalog.defaults.first);
    for (final (e, s) in [(0, 0), (0, 1), (0, 2), (1, 0)]) {
      n.toggleSet(e, s);
    }
    n.setRpe(0, 0, 7);
    r.container.read(activeWorkoutExpandedProvider.notifier).state = true;
    await r.go(AppRouter.home);
    await shotPages(r, 'live_gym');
    mainScrollable(r.t)?.position.jumpTo(0);
    await r.settle();
    // A context inside the workout sheet, as the menu button would use.
    BuildContext inSheet() => r.t.element(find.text('Biceps curl').first);
    showExerciseMenuSheet(inSheet(), 0);
    await r.settle();
    await shot(r, 'live_gym_exercise_menu');
    Navigator.of(inSheet()).pop();
    await r.settle();
    showRpePicker(inSheet(), setNumber: 2, initial: null, onPick: (_) {});
    await r.settle();
    await shot(r, 'live_gym_rpe_picker');
  }, en: true),
  Scene('live-gym-collapsed', (r) async {
    r.container
        .read(activeWorkoutProvider.notifier)
        .start(WorkoutCatalog.defaults.first);
    await r.go(AppRouter.home);
    await shot(r, 'live_gym_minibar_home');
  }),
  Scene('workout-complete', (r) async {
    r.container.read(pendingCompletedWorkoutProvider.notifier).state =
        _finished();
    await r.go(AppRouter.workoutComplete);
    await shotPages(r, 'workout_complete');
  }, en: true),

  // ------------------------------------------------------ live activities
  Scene('live-run', (r) async {
    await _live(r, ActivityKind.run);
    await shotPages(r, 'live_run');
    r.recorder.pause();
    await r.t.pump(const Duration(seconds: 1));
    await r.settle(maxFrames: 5);
    await shotPages(r, 'live_run_paused');
  }, en: true),
  Scene('live-run-bar', (r) async {
    await _live(r, ActivityKind.run);
    Navigator.of(r.context).maybePop();
    await r.settle(maxFrames: 5);
    await r.go(AppRouter.home);
    await shot(r, 'live_run_bar_home');
  }),
  Scene('live-ride', (r) async {
    await _live(r, ActivityKind.ride);
    await shotPages(r, 'live_ride');
    await r.tapKey('run-settings');
    await shotPages(r, 'live_ride_settings_sheet');
  }),
  Scene('live-ride-waiting-gps', (r) async {
    await r.go(AppRouter.sportWorkouts(Sport.cycling));
    await r.tapKey('cy-start');
    await shot(r, 'live_ride_waiting_gps');
  }),
  Scene('live-ski', (r) async {
    await _live(r, ActivityKind.ski);
    await shotPages(r, 'live_ski');
  }),

  // ------------------------------------------------------ summaries
  _simple('run-summary', AppRouter.runSummary('run-2'), en: true),
  Scene('run-summary-new', (r) async {
    await r.go(AppRouter.runSummary('run-1', justFinished: true));
    await shotPages(r, 'run_summary_just_finished');
  }),
  _simple('ride-summary', AppRouter.runSummary('ride-1')),
  _simple('indoor-ride-summary', AppRouter.runSummary('ride-2')),
  _simple('ski-summary', AppRouter.runSummary('ski-1'), en: true),
  Scene('ski-summary-selected', (r) async {
    await r.go(AppRouter.runSummary('ski-1'));
    final d = find.text(r.ru('Спуск 2', 'Descent 2'));
    await r.t.ensureVisible(d);
    await r.settle();
    await r.t.tap(d);
    await r.settle();
    await shot(r, 'ski_summary_descent_selected');
    final s = mainScrollable(r.t);
    s?.position.jumpTo(0);
    await r.settle();
    await shot(r, 'ski_summary_descent_selected_top');
  }),

  // ------------------------------------------------------ recovery
  _simple('recovery', AppRouter.recovery, en: true),
  _simple('recovery-no-checkin', AppRouter.recovery,
      seed: const Seed(checkIn: false)),
  _simple('recovery-no-health', AppRouter.recovery,
      seed: const Seed(health: false)),
  _simple('recovery-empty', AppRouter.recovery, seed: Seed.empty),

  // ------------------------------------------------------ nutrition
  _simple('nutrition', AppRouter.nutrition, en: true),
  _simple('nutrition-empty', AppRouter.nutrition, seed: Seed.empty),
  _simple('nutrition-no-profile', AppRouter.nutrition,
      seed: const Seed(profile: false, food: false)),
  _simple('nutrition-targets', AppRouter.nutritionTargets, en: true),
  _simple('nutrition-micros', AppRouter.nutritionMicros),
  _simple('nutrition-add-food', AppRouter.addFood(MealSlot.lunch), en: true),
  _simple('nutrition-food-detail',
      AppRouter.foodDetail('chicken_breast', MealSlot.lunch)),

  // ------------------------------------------------------ progress
  _simple('progress', AppRouter.progress, en: true),
  _simple('progress-empty', AppRouter.progress, seed: Seed.empty),
  _simple('progress-weight', AppRouter.progressWeight),
  Scene('progress-weight-sheet', (r) async {
    await r.go(AppRouter.progressWeight);
    final add = find.byIcon(Icons.add);
    await r.t.ensureVisible(add.last);
    await r.t.tap(add.last);
    await r.settle();
    await shot(r, 'progress_weight_sheet');
  }),
  _simple('progress-weight-empty', AppRouter.progressWeight, seed: Seed.empty),
  _simple('progress-load', AppRouter.progressLoad, en: true),
  _simple('progress-records', AppRouter.progressRecords),
  _simple('progress-lift', AppRouter.progressLift('Bench press')),

  // ------------------------------------------------------ plan, programs
  _simple('week-plan', AppRouter.weekPlan, en: true),
  _simple('week-plan-empty', AppRouter.weekPlan, seed: Seed.empty),
  Scene('week-plan-add-sheet', (r) async {
    await r.go(AppRouter.weekPlan);
    showAddSessionSheet(r.context);
    await r.settle();
    await shotPages(r, 'week_plan_add_sheet');
  }),
  _simple('programs', AppRouter.programs, en: true),
  _simple('program-detail', AppRouter.program('upper-lower-4'), en: true),
  Scene('program-start', (r) async {
    await r.go(AppRouter.program('upper-lower-4'));
    await r.tapKey('program-start');
    await shotPages(r, 'program_start_sheet');
    await r.tapKey('start-confirm');
    await r.go(AppRouter.programsActive);
    await shotPages(r, 'program_active');
    await r.go(AppRouter.programs);
    await shot(r, 'programs_with_active');
  }),

  // ------------------------------------------------------ exercises
  _simple('exercise-library', AppRouter.exerciseLibrary, en: true),
  _simple('exercise-detail', AppRouter.exercise('bench-press'), en: true),
  Scene('exercise-add', (r) async {
    r.container
        .read(activeWorkoutProvider.notifier)
        .start(WorkoutCatalog.defaults.first);
    await r.go(AppRouter.addExerciseTo());
    await shotPages(r, 'exercise-add');
  }),
  _simple('exercise-add-no-workout', AppRouter.addExerciseTo()),

  // ------------------------------------------------------ Felix
  _simple('felix-hub', AppRouter.felix, en: true),
  _simple('felix-hub-empty', AppRouter.felix, seed: Seed.empty),
  _simple('felix-all', AppRouter.felixAll),
  Scene('felix-chat-gym', (r) async {
    await r.go(AppRouter.felixChat(AssistantTopic.gym));
    await shotPages(r, 'felix_chat_gym');
  }, en: true),
  Scene('felix-chat-nutrition', (r) async {
    await r.go(AppRouter.felixChat(AssistantTopic.nutrition));
    await shotPages(r, 'felix_chat_nutrition');
  }, en: true),
  Scene('felix-chat-recovery-new', (r) async {
    await r.go(AppRouter.felixChat(AssistantTopic.recovery));
    await shot(r, 'felix_chat_recovery_new');
  }, en: true),
  Scene('felix-chat-app', (r) async {
    await r.go(AppRouter.felixChat(AssistantTopic.app));
    await shot(r, 'felix_chat_app');
  }),

  // ------------------------------------------------------ profile
  _simple('profile', AppRouter.me, en: true),
  _simple('profile-about-me', AppRouter.aboutMe, en: true),
  _simple('profile-edit', AppRouter.editProfile),
  _simple('profile-hr-zones', AppRouter.hrZones, en: true),
  _simple('connected-apps', AppRouter.connectedApps, en: true),
  _simple('connected-apps-off', AppRouter.connectedApps,
      seed: const Seed(health: false), en: true),

  // ------------------------------------------------------ discover, shop, map
  _simple('discover', AppRouter.discover, en: true),
  _simple('article', AppRouter.article('why-rest-days-make-you-stronger')),
  _simple('shop', AppRouter.shop),
  Scene('shop-cart', (r) async {
    await r.go(AppRouter.shop);
    for (final id in ['whey-protein-2-kg', 'resistance-bands']) {
      final f = find.byKey(Key('add-$id'));
      await r.t.ensureVisible(f);
      await r.settle();
      await r.t.tap(f);
      await r.settle();
    }
    await r.tapKey('cart-button');
    await shot(r, 'shop_cart_sheet');
  }, en: true),
  _simple('map', AppRouter.fitrixMap),
  Scene('map-place', (r) async {
    await r.go(AppRouter.fitrixMap);
    final pin = find.byKey(const ValueKey('pin-proform-gym'));
    if (pin.evaluate().isNotEmpty) {
      await r.t.tap(pin, warnIfMissed: false);
      await r.settle();
    }
    await shot(r, 'map_place_card');
  }),
];
