// Phase 3: GPS activities with simulated location.
// Running: start -> route -> close to the run bar -> background (another app
// in front) -> back -> finish (hold) -> summary -> RPE -> save -> history.
// Cycling: outdoor ride on a route -> finish -> summary; indoor ride log ->
// edit -> delete. Skiing: start/finish on a flat route -> empty summary.
// Football: log a match.
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/e2e.dart';
import 'support/l10n.dart';
import 'support/sign_in.dart';

/// A ~1.3 km line north-east through central Tashkent, ~110 m per point.
List<String> route({double lat = 41.3050, double lon = 69.2700, int n = 12}) =>
    [
      for (var i = 0; i < n; i++)
        '${(lat + i * 0.0009).toStringAsFixed(6)},${(lon + (i.isEven ? 0 : 0.0004) + i * 0.0003).toStringAsFixed(6)}'
    ];

Future<void> openSport(WidgetTester t, Sport s) async {
  await goHome(t);
  await scrollTo(t, ftext(L.homeTileWorkouts));
  await tap(t, ftext(L.homeTileWorkouts));
  await idle(t, const Duration(seconds: 2));
  // My workouts has a tile for every sport.
  await scrollTap(t, find.byKey(ValueKey('sport-tile-${s.name}')));
  await idle(t, const Duration(seconds: 2));
}

void main() {
  initBinding();

  testWidgets('run, ride, ski, football', (t) async {
    await Host.log('=== PHASE 3 activities');
    await Host.setLocation(41.3050, 69.2700);
    app.main();
    captureFlutterErrors();
    await idle(t, const Duration(seconds: 3));
    await signInExisting(t);

    if (want('run')) {
      // ---------------- Running
      await step(t, 'running_screen', () => openSport(t, Sport.running));
      await Host.videoStart('12_run_start');
      await step(t, 'run_live_start', () async {
        await Host.route(route(), speed: 4.5);
        await tapKey(t, 'run-start');
        await idle(t, const Duration(seconds: 3));
      });
      await step(t, 'run_live_20s', () async {
        await idle(t, const Duration(seconds: 20));
      });
      await Host.videoStop();
      await step(t, 'run_paused', () async {
        await tapKey(t, 'run-pause');
        await idle(t, const Duration(seconds: 3));
      });
      await step(t, 'run_resumed', () async {
        await tapKey(t, 'run-pause');
        await idle(t, const Duration(seconds: 2));
      });
      await Host.videoStart('13_run_bar');
      await step(t, 'run_bar_home', () async {
        await tapKey(t, 'run-close');
        await idle(t, const Duration(seconds: 3));
        if (find.byKey(const ValueKey('run-bar')).evaluate().isEmpty) {
          throw StateError('run bar not shown after leaving the live run');
        }
      });
      await step(t, 'run_bar_on_felix_tab', () async {
        await goTab(t, Icons.home_outlined, Icons.home);
        await idle(t, const Duration(seconds: 2));
      });
      await Host.videoStop();
      await step(t, 'run_background_30s', () async {
        await Host.background(30);
        // The app is in the background now; keep the test alive meanwhile.
        await idle(t, const Duration(seconds: 36));
      });
      await step(t, 'run_back_from_background', () async {
        await idle(t, const Duration(seconds: 3));
      });
      await Host.videoStart('14_run_return_finish');
      await step(t, 'run_live_after_bg', () async {
        await tapKey(t, 'run-bar-return');
        await idle(t, const Duration(seconds: 3));
      });
      await step(t, 'run_more_distance', () async {
        await idle(t, const Duration(seconds: 70));
      });
      await step(t, 'run_summary', () async {
        await holdPress(t, find.byKey(const ValueKey('run-finish')),
            const Duration(milliseconds: 1800));
        await idle(t, const Duration(seconds: 4));
      });
      await Host.videoStop();
      await Host.clearLocation();
      await step(t, 'run_summary_scrolled', () async {
        await t.drag(find.byType(Scrollable).first, const Offset(0, -600));
        await idle(t, const Duration(seconds: 1));
      });
      await step(t, 'run_rpe_saved', () async {
        await scrollTap(t, find.byKey(const ValueKey('runRpe-6')));
        await scrollTap(t, find.byKey(const ValueKey('run-save')));
        await idle(t, const Duration(seconds: 3));
      });
    }
    if (want('run') || want('runhist')) {
      await step(t, 'run_history', () async {
        await openSport(t, Sport.running);
        await scrollTo(t, keyPrefix('run-row-'));
      });
      await step(t, 'run_history_open', () async {
        await tap(t, keyPrefix('run-row-'));
        await idle(t, const Duration(seconds: 3));
      });
      await back(t);
    }
    if (want('ride')) {
      // ---------------- Cycling outdoor
      await step(t, 'cycling_screen', () => openSport(t, Sport.cycling));
      await Host.videoStart('15_ride');
      await step(t, 'ride_live', () async {
        await Host.route(route(lat: 41.3200, lon: 69.2400), speed: 9);
        await tapKey(t, 'cy-start');
        await idle(t, const Duration(seconds: 25));
      });
      await step(t, 'ride_live_60s', () async {
        await idle(t, const Duration(seconds: 50));
      });
      await step(t, 'ride_summary', () async {
        await holdPress(t, find.byKey(const ValueKey('run-finish')),
            const Duration(milliseconds: 1800));
        await idle(t, const Duration(seconds: 4));
      });
      await Host.videoStop();
      await Host.clearLocation();
      await step(t, 'ride_summary_scrolled', () async {
        await t.drag(find.byType(Scrollable).first, const Offset(0, -600));
        await idle(t, const Duration(seconds: 1));
      });
      await step(t, 'ride_saved', () async {
        await scrollTap(t, find.byKey(const ValueKey('runRpe-5')));
        await scrollTap(t, find.byKey(const ValueKey('run-save')));
        await idle(t, const Duration(seconds: 3));
      });
    }
    if (want('indoor')) {
      if (!want('ride')) {
        await step(t, 'cycling_screen', () => openSport(t, Sport.cycling));
      }
      // ---------------- Cycling indoor log, edit, delete
      await step(t, 'indoor_sheet', () async {
        await scrollTap(t, find.byKey(const ValueKey('cy-log')));
        await idle(t, const Duration(seconds: 1));
      });
      await step(t, 'indoor_filled', () async {
        await enter(t, find.byKey(const ValueKey('ride-km')), '22.5');
        await enter(t, find.byKey(const ValueKey('ride-power')), '180');
        await enter(t, find.byKey(const ValueKey('ride-note')), 'Zwift e2e');
        FocusManager.instance.primaryFocus?.unfocus();
        await idle(t);
      });
      await step(t, 'indoor_saved', () async {
        await scrollTap(t, find.byKey(const ValueKey('ride-save')));
        await idle(t, const Duration(seconds: 2));
      });
      await step(t, 'indoor_edit_open', () async {
        await scrollTap(
            t,
            fcontains('22,5').evaluate().isNotEmpty
                ? fcontains('22,5')
                : fcontains('22.5'));
        await idle(t, const Duration(seconds: 1));
      });
      await step(t, 'indoor_edited', () async {
        await enter(t, find.byKey(const ValueKey('ride-km')), '30');
        FocusManager.instance.primaryFocus?.unfocus();
        await scrollTap(t, find.byKey(const ValueKey('ride-save')));
        await idle(t, const Duration(seconds: 2));
      });
      await step(t, 'indoor_delete_confirm', () async {
        await scrollTap(t, fcontains('30,00'));
        await scrollTap(t, find.byKey(const ValueKey('ride-delete')));
        await idle(t, const Duration(seconds: 1));
      });
      await step(t, 'indoor_deleted', () async {
        await tapKey(t, 'ride-delete-confirm');
        await idle(t, const Duration(seconds: 2));
      });
    }
    if (want('ski')) {
      // ---------------- Skiing (flat route; altitude can't be simulated)
      await step(t, 'ski_screen', () => openSport(t, Sport.winterSports));
      await step(t, 'ski_live', () async {
        await Host.route(route(lat: 41.3300, lon: 69.3000, n: 4), speed: 5);
        await tapKey(t, 'ski-start');
        await idle(t, const Duration(seconds: 30));
      });
      await step(t, 'ski_summary', () async {
        await holdPress(t, find.byKey(const ValueKey('run-finish')),
            const Duration(milliseconds: 1800));
        await idle(t, const Duration(seconds: 4));
      });
      await Host.clearLocation();
      await step(t, 'ski_saved', () async {
        final save = find.byKey(const ValueKey('run-save'));
        if (save.evaluate().isNotEmpty) await scrollTap(t, save);
        await idle(t, const Duration(seconds: 2));
      });
    }
    if (want('football')) {
      // ---------------- Football
      await step(t, 'football_screen', () => openSport(t, Sport.football));
      await step(t, 'football_sheet', () async {
        await scrollTap(t, find.byKey(const ValueKey('fb-log')));
        await idle(t, const Duration(seconds: 1));
      });
      await step(t, 'football_filled', () async {
        await tapKey(t, 'fb-type-match');
        final fmt = keyPrefix('fb-format-');
        if (fmt.evaluate().isNotEmpty) await tap(t, fmt.at(1));
        final pos = keyPrefix('fb-position-');
        if (pos.evaluate().isNotEmpty) await scrollTap(t, pos.first);
        final plus = keyPrefix('fb-goals-plus');
        if (plus.evaluate().isNotEmpty) await scrollTap(t, plus.first);
      });
      await step(t, 'football_saved', () async {
        await scrollTap(t, find.byKey(const ValueKey('fb-save')));
        await idle(t, const Duration(seconds: 2));
      });
    }
    await goHome(t);
    await step(t, 'home_after_activities', () async {
      await idle(t, const Duration(seconds: 2));
    });
    await writeReport('03_activities');
  }, timeout: const Timeout(Duration(minutes: 25)));
}
