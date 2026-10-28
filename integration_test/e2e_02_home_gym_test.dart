// Phase 2 (signed in, onboarded): Home -> check-in -> Recovery -> week plan
// add -> gym live log (sets, rest, mini sheet) -> finish -> complete ->
// Progress/history -> Nutrition add food + water.
import 'package:fitrix/core/widgets/app_button.dart';
import 'package:fitrix/core/widgets/workout_card.dart';
import 'package:fitrix/features/checkin/data/checkin_models.dart';
import 'package:fitrix/features/checkin/presentation/widgets/checkin_text.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/features/workouts/presentation/sport_l10n.dart';
import 'package:fitrix/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/e2e.dart';
import 'support/l10n.dart';
import 'support/sign_in.dart';

void main() {
  initBinding();

  testWidgets('home, check-in, plan, gym, nutrition', (t) async {
    await Host.log('=== PHASE 2 home/gym');
    app.main();
    captureFlutterErrors();
    await idle(t, const Duration(seconds: 3));
    await signInExisting(t);

    if (want('checkin')) {
      // ---- Check-in
      await Host.videoStart('04_checkin_sheet');
      await step(t, 'checkin_sheet', () async {
        await tapText(t, L.checkinCardAction);
        await waitFor(t, find.text(L.checkinTitle));
        await idle(t, const Duration(seconds: 1));
      });
      await step(t, 'checkin_filled', () async {
        await tap(t, find.byTooltip(L.checkinSleepMore));
        await tap(t, find.byTooltip(L.checkinSleepMore));
        await tapText(t, L.qualityName(SleepQuality.good));
        await tapText(t, L.sorenessName(Soreness.light));
        await tapText(t, L.areaName(BodyArea.legs));
        await tapText(t, L.energyName(Level3.high));
      });
      await step(t, 'checkin_saved_home', () async {
        await scrollTap(t, find.text(L.checkinSave),
            scrollable: find.descendant(
                of: find.byType(BottomSheet),
                matching: find.byType(Scrollable)));
        await idle(t, const Duration(seconds: 2));
      });
      await Host.videoStop();

      await Host.videoStart('05_recovery_reveal');
      await step(t, 'recovery', () async {
        await tap(t, find.text(L.checkinCardSeeMore));
        await idle(t, const Duration(seconds: 2));
      });
      await step(t, 'recovery_scrolled', () async {
        await t.drag(find.byType(Scrollable).first, const Offset(0, -500));
        await idle(t, const Duration(seconds: 1));
      });
      await Host.videoStop();
      await back(t);
    }
    if (want('plan')) {
      // ---- Week plan
      await Host.videoStart('06_week_plan');
      await step(t, 'week_plan', () async {
        await tap(t, find.byKey(const Key('home-today-card')));
        await idle(t, const Duration(seconds: 2));
      });
      await step(t, 'plan_add_sheet', () async {
        await tapKey(t, 'plan-add');
        await idle(t, const Duration(seconds: 1));
      });
      await step(t, 'plan_add_running', () async {
        await tapText(t, Sport.running.localizedLabel(L));
        await idle(t, const Duration(milliseconds: 600));
      });
      await step(t, 'plan_added', () async {
        final btn = find.descendant(
            of: find.byType(BottomSheet), matching: find.byType(AppButton));
        await tap(t, btn.last);
        await idle(t, const Duration(seconds: 2));
      });
      await step(t, 'plan_add_cycling', () async {
        await tapKey(t, 'plan-add');
        await tapText(t, Sport.cycling.localizedLabel(L));
        final btn = find.descendant(
            of: find.byType(BottomSheet), matching: find.byType(AppButton));
        await tap(t, btn.last);
        await idle(t, const Duration(seconds: 2));
      });
      await step(t, 'plan_scrolled', () async {
        await t.drag(find.byType(Scrollable).first, const Offset(0, -600));
        await idle(t, const Duration(seconds: 1));
      });
      await Host.videoStop();
      await back(t);
    }
    if (want('gym')) {
      // ---- Gym live log from My workouts -> Gym
      await Host.videoStart('07_gym_live_log');
      await step(t, 'gym_started', () async {
        await scrollTo(t, ftext(L.homeTileWorkouts));
        await tap(t, ftext(L.homeTileWorkouts));
        await idle(t, const Duration(seconds: 2));
        await scrollTap(t, ftext(Sport.gym.localizedTileLabel(L)));
        await idle(t, const Duration(seconds: 2));
        await Host.shot('gym_sport_screen');
        final start = find.descendant(
            of: find.byType(WorkoutCard).first,
            matching: ftext(Sport.gym.actionLabel(L)));
        await tap(t, start.first);
        await idle(t, const Duration(seconds: 2));
      });
      await step(t, 'gym_set1_entered', () async {
        final row = find.byKey(const ValueKey('set-0-0'));
        if (!await waitFor(t, row)) throw StateError('no set row');
        final fields =
            find.descendant(of: row, matching: find.byType(TextField));
        await enter(t, fields.at(0), '40');
        await enter(t, fields.at(1), '10');
        final done = find.byKey(const ValueKey('keyboardDone'));
        if (done.evaluate().isNotEmpty) await tap(t, done, scroll: false);
      });
      await step(t, 'gym_set1_checked_rest', () async {
        final check = find.descendant(
            of: find.byKey(const ValueKey('set-0-0')),
            matching: byTypeName('_CheckButton'));
        await tap(t, check);
        await idle(t, const Duration(seconds: 2));
      });
      await step(t, 'gym_set2_checked', () async {
        final check = find.descendant(
            of: find.byKey(const ValueKey('set-0-1')),
            matching: byTypeName('_CheckButton'));
        await tap(t, check);
        await idle(t, const Duration(seconds: 1));
      });
      await step(t, 'gym_rpe_picker', () async {
        await tap(t, find.byKey(const ValueKey('rpe-0-0')));
        await idle(t, const Duration(seconds: 1));
      });
      await step(t, 'gym_rpe_picked', () async {
        await tap(t, find.text('8').last);
        final done = find.text(L.workoutKeyboardDone);
        if (done.evaluate().isNotEmpty) await tap(t, done.last, scroll: false);
      });
      await Host.videoStop();

      await Host.videoStart('08_mini_sheet_drag');
      await step(t, 'gym_sheet_collapsed', () async {
        final handle = find.byKey(const ValueKey('activeWorkoutHandle'));
        if (!await waitFor(t, handle)) throw StateError('no sheet handle');
        await t.timedDrag(handle.first, const Offset(0, 600),
            const Duration(milliseconds: 400));
        await idle(t, const Duration(seconds: 2));
      });
      await step(t, 'gym_sheet_reopened', () async {
        final header = find.byKey(const ValueKey('activeWorkoutSheetHeader'));
        await t.timedDrag(header.first, const Offset(0, -500),
            const Duration(milliseconds: 400));
        await idle(t, const Duration(seconds: 2));
      });
      await Host.videoStop();

      await Host.videoStart('09_finish_complete');
      await step(t, 'gym_complete_screen', () async {
        await tapText(t, L.workoutFinishButton);
        await idle(t, const Duration(seconds: 2));
        // "No sets" or confirm dialogs.
        final finish = find.text(L.workoutFinish);
        if (finish.evaluate().isNotEmpty)
          await tap(t, finish.last, scroll: false);
        await idle(t, const Duration(seconds: 2));
      });
      await step(t, 'gym_complete_rated', () async {
        await scrollTap(t, find.byKey(const ValueKey('completeRpe-7')));
      });
      await step(t, 'gym_saved', () async {
        await scrollTap(t, find.text(L.workoutSave));
        await idle(t, const Duration(seconds: 2));
      });
      await Host.videoStop();
    }
    if (want('progress')) {
      // ---- Progress
      await step(t, 'home_after_gym', () async {
        await goHome(t);
      });
      await Host.videoStart('10_progress');
      await step(t, 'progress', () async {
        await scrollTo(t, ftext(L.homeTileProgress));
        await tap(t, ftext(L.homeTileProgress));
        await idle(t, const Duration(seconds: 3));
      });
      await step(t, 'progress_scrolled', () async {
        await t.drag(find.byType(Scrollable).first, const Offset(0, -700));
        await idle(t, const Duration(seconds: 1));
      });
      await step(t, 'progress_scrolled2', () async {
        await t.drag(find.byType(Scrollable).first, const Offset(0, -700));
        await idle(t, const Duration(seconds: 1));
      });
      await Host.videoStop();
      await goHome(t);
    }
    if (want('nutrition')) {
      // ---- Nutrition
      await Host.videoStart('11_nutrition');
      await step(t, 'nutrition', () async {
        await goHome(t);
        await scrollTo(t, ftext(L.homeTileNutrition));
        await tap(t, ftext(L.homeTileNutrition));
        await idle(t, const Duration(seconds: 3));
      });
      await step(t, 'nutrition_add_food', () async {
        await scrollTap(t, find.text(L.nutritionAdd));
        await idle(t, const Duration(seconds: 2));
      });
      await step(t, 'nutrition_search', () async {
        await enter(t, find.byType(TextField).first, 'плов');
        await idle(t, const Duration(seconds: 2));
      });
      await step(t, 'nutrition_food_added', () async {
        final add = keyPrefix('quick-add-');
        await tap(t, add.first);
        await idle(t, const Duration(seconds: 1));
      });
      await step(t, 'nutrition_food_detail', () async {
        await enter(t, find.byType(TextField).first, 'egg');
        await idle(t, const Duration(seconds: 1));
        final rows = keyPrefix('quick-add-');
        if (rows.evaluate().isEmpty) throw StateError('no results for egg');
        // Opening the row (not the + button) shows the detail.
        final row =
            find.ancestor(of: rows.first, matching: find.byType(InkWell)).first;
        await tap(t, row);
        await idle(t, const Duration(seconds: 2));
      });
      await step(t, 'nutrition_detail_added', () async {
        await scrollTap(t, find.byKey(const ValueKey('confirm-add')));
        await idle(t, const Duration(seconds: 2));
      });
      await backUntil(t, find.byKey(const ValueKey('calorie-ring')));
      await step(t, 'nutrition_after_add', () async {
        await idle(t, const Duration(seconds: 2));
      });
      await step(t, 'nutrition_water', () async {
        await scrollTap(t, keyPrefix('water-'));
        await idle(t, const Duration(seconds: 1));
      });
      await Host.videoStop();
      await goHome(t);
    }
    await idle(t, const Duration(seconds: 2));
    await writeReport('02_home_gym');
  }, timeout: const Timeout(Duration(minutes: 20)));
}
