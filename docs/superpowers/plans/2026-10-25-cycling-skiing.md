# Wave 2E: Cycling and Downhill Skiing — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Record outdoor rides and downhill ski days with GPS (ski days split into descents and lifts), log indoor rides, and feed all of them into history, load, plan, Progress, Health and Felix — by generalising the wave 2C running recorder.

**Architecture:** `RunTrack`/`RunRecorder` become activity-aware through an `ActivityKind {run, ride, ski}` and an `ActivityProfile` (speed cap, auto-stop, split distance, sport, default voice). Ski segmentation is pure math over the recorded fixes. Details of every GPS/indoor activity are stored in the existing `run` document (`RunDetails` gains optional fields) — no migration. New Cycling and Skiing screens mirror the Running screen.

**Tech Stack:** Flutter 3, Riverpod 2, geolocator 14, flutter_map 8, flutter_tts; Node backend.

**Spec:** `docs/superpowers/specs/2026-10-25-cycling-skiing-design.md`

## Global Constraints

- Branch `redesign`; commits without `Co-Authored-By`; `export PATH="/Users/myxabzbzzzz/РАБОТА/flutter/bin:$PATH"`; `flutter analyze` clean; `flutter test -j 4` green (baseline 1276 passed, 5 skipped); backend `cd backend && npm test` green (baseline 113). Format only changed files; don't stage `docs/fitrix-features.md`.
- Never run anything against the cloud Supabase project; never restart the live Felix server.
- **Running behaviour must not change**: every existing running test passes unchanged (only mechanical renames allowed when an API is generalised, and then the assertions stay identical).
- Speed caps: run 12 m/s, ride 30 m/s, ski 40 m/s. Auto-stop (ride, ski): moving while speed ≥ 1 m/s; stops < 10 s don't stop the clock. Ride splits and ride voice every 5 km. Voice defaults: run on, ride off, ski off.
- Ski segmentation: altitude median-smoothed over ~30 s; direction split with 15 m hysteresis; descent ≥ 30 m drop; lift ≥ 30 m gain with avg vertical speed ≥ 0.5 m/s and horizontal speed ≤ 8 m/s; else "other". Max speed from fix-to-fix speed smoothed over ≥ 3 s.
- Ski load/duration = day time − lift time − manual pauses. Ride duration = auto-stop moving time.
- Template ids: `free_ride`, `indoor_ride`, `free_ski` (added to the week plan's unplanned ids beside `free_run`).
- Details live in the existing `run` document; `RunDetails` JSON stays backward compatible (old docs parse; new optional fields omitted when null). Whole-day route ≤ 2,000 points; descents reference route index ranges.
- l10n en/ru/uz/es, no plural-dependent wording; Uzbek o‘/g‘ U+2018, tutuq per file majority; `flutter gen-l10n`, generated files committed.
- iPhone SE 375×667 ×1.3 without overflow on every new/changed screen.

## Review Focus

- A chairlift ride (steady climb at 3–5 m/s) is never a descent and never adds load; a lift followed by a descent is split correctly even with ±10 m GPS altitude noise.
- A 60 km/h bike descent and a 90 km/h ski run are kept, not dropped as noise; a 300 m GPS jump is still dropped.
- Ride with traffic-light stops: moving time excludes stops ≥ 10 s; a 5 s stop does not stop the clock.
- Voice stays silent on a ride/ski day unless switched on in settings; running voice still on by default.
- An in-progress run saved by the previous app version (no kind in prefs) restores as a run.

---

### Task 1: Backend context for rides, indoor rides and ski days

**Files:** `backend/prompt.js` (`sanitizeContext`, `describeContext`), `backend/prompt.test.js`.

**Produces:** `lastWorkout` optional fields: `avgSpeedKmh` (1..150, 1 dp), `maxSpeedKmh` (1..200, 1 dp), `elevationGainM` (0..10000 int), `indoor` (bool), `avgPowerW` (20..2000 int), `ski: {descents: 0..300 int, verticalM: 0..30000 int, distanceKm: 0..500 2 dp, maxSpeedKmh: 1..200 1 dp}`.

- [ ] Failing tests: ride `{sport:'cycling', distanceKm: 42.3, avgSpeedKmh: 27.46, maxSpeedKmh: 61.2, elevationGainM: 412}` kept (27.5); `avgSpeedKmh: 400` dropped; indoor `{indoor:true, avgPowerW: 185}` kept; ski block kept, `descents: 1000` drops that field; describe lines: `…cycling "Morning ride" …, 42.3 km at 27.5 km/h avg (max 61.2), +412 m`, `…indoor ride, 185 W avg`, `…ski day: 14 descents, 3120 m down, 18.4 km, max 72.0 km/h`.
- [ ] Implement; `npm test`; commit `Felix context for rides, indoor rides and ski days`.

### Task 2: Activity kinds in the track math and RunDetails

**Files:** `lib/features/running/data/run_track.dart` (+ maybe new `activity_kind.dart` beside it), `test/run_track_test.dart` (new cases only), new `test/activity_track_test.dart`.

**Produces:**
```dart
enum ActivityKind { run, ride, ski }
class ActivityProfile { final ActivityKind kind; final double maxSpeed; final bool autoStop; final int splitMeters; final Sport sport; final bool voiceDefault; final String freeTemplateId; }
ActivityProfile profileFor(ActivityKind k); // run: 12, false, 1000, running, true, 'free_run'; ride: 30, true, 5000, cycling, false, 'free_ride'; ski: 40, true, 1000, winterSports, false, 'free_ski'
RunTrack({ActivityProfile profile = runProfile, ...}) // existing callers unchanged
double? get maxSpeed;        // m/s, smoothed ≥ 3 s
double? get elevationLoss;   // like elevationGain
Duration movingTime(now)     // auto-stop rule when profile.autoStop
RunDetails gains: ActivityKind kind (JSON 'kind', default run when absent), double? maxSpeed, double? elevationLoss, bool indoor, int? avgPowerW, SkiDay? ski (Task 3 type; JSON 'ski')
```
- [ ] Failing tests: 16.7 m/s ride fixes kept with ride profile, dropped with run profile; 25 m/s ski kept; 300 m jump in 2 s dropped for all; auto-stop: 30 s stop excluded, 5 s stop included; splits every 5 km for ride; maxSpeed smoothing ignores a single spike; RunDetails JSON round-trip with new fields; an old JSON (no kind) parses as run; existing run_track tests untouched and green.
- [ ] Implement; full suite; commit `Track math knows rides and ski days: speed caps, auto-stop, max speed`.

### Task 3: Ski segmentation

**Files:** new `lib/features/running/data/ski_math.dart`, `test/ski_math_test.dart`.

**Produces:**
```dart
enum SkiSegmentKind { descent, lift, other }
class SkiSegment { final SkiSegmentKind kind; final int from, to; } // indices into the fixes
class SkiDescent { final DateTime start, end; final double meters, vertical, maxSpeed, avgSpeed; final int routeFrom, routeTo; } // route indices after simplification
class SkiDay { final List<SkiDescent> descents; final int lifts; final Duration liftTime; double get verticalDown; double get skiMeters; double? get maxSpeed; double? get avgDescentSpeed; } // + toJson/fromJson
List<SkiSegment> segmentSki(List<RunPoint> fixes);
SkiDay skiDayFrom(List<RunPoint> fixes, List<int> keptIndexMap); // keptIndexMap: fix index → simplified route index
```
- [ ] Failing tests on synthetic profiles: lift 0→300 m at 4 m/s then descent 300→0 at 12 m/s → 1 lift, 1 descent (300 m vertical); same with ±10 m altitude noise → same result; three laps → 3 descents, 3 lifts; flat traverse/queue → other; a short 20 m dip doesn't count; route index ranges map onto a simplified route (simplifyRoute must expose kept indices — extend it); JSON round-trip.
- [ ] Implement; full suite; commit `Ski days split into descents and lifts`.

### Task 4: Recorder for all kinds

**Files:** `lib/features/running/presentation/run_recorder.dart`, `lib/features/running/data/location_source.dart` (Android notification text per kind; ski battery settings), `lib/features/health/data/health_writer.dart` (meters for ride/ski), `test/run_recorder_test.dart` (new cases), new `test/activity_recorder_test.dart`, l10n for notification texts and default names («Morning ride», «Ski day»).

**Produces:** `start({ActivityKind kind = ActivityKind.run, WorkoutTemplate? template})`; `RunSession.kind`; persisted `kind` (absent → run); events: existing `KmReached` for run, new `DistanceReached(meters, total, lastSplitSpeed, avgSpeed)` every 5 km for ride, `SkiDescentDone(index, meters, vertical, maxSpeed)` for ski (segmentation run incrementally or on a throttle); `finish({int? rpe})` builds `CompletedWorkout(sport: profile.sport, templateId: template ?? profile.freeTemplateId, finishedAt: startedAt + duration)` with the spec's duration rules and `RunDetails(kind, maxSpeed, elevationLoss, ski: skiDayFrom(...))`; `runHistoryProvider` stays running-only.
- [ ] Failing tests: ride session finishes as cycling with free_ride and auto-stop duration; ski session finishes as winterSports with free_ski, duration excludes lift time, RunDetails.ski has descents; restore of a pre-wave prefs payload (no kind) → run; restore of a ski payload → ski; HealthWriter writes meters for a ride; Android notification text per kind (unit-test the settings builder).
- [ ] Implement; full suite; commit `One recorder for runs, rides and ski days`.

### Task 5: Voice per activity with a settings sheet

**Files:** `lib/features/running/presentation/run_voice.dart`, new `lib/features/running/data/activity_settings.dart` (prefs `activity_voice_v1`, per kind), new widget `lib/features/running/presentation/widgets/activity_settings_sheet.dart`, l10n (ride/ski phrases), `test/run_voice_test.dart` (new cases).

**Produces:** `activityVoiceProvider` (Map<ActivityKind,bool>, defaults per profile), `showActivitySettingsSheet(context, kind)`; RunVoice speaks only when the session's kind has voice on; ride phrase every 5 km; ski phrase per descent.
- [ ] Failing tests: ride with default settings → nothing spoken; ride with voice on → 5 km phrase; ski voice on → descent phrase; run default → km phrase as before; settings persist; sheet toggles; SE ×1.3.
- [ ] Implement; full suite; commit `Voice is a setting per activity; quiet by default on rides and ski days`.

### Task 6: Live and summary screens for rides and ski days

**Files:** `live_run_screen.dart`, `run_summary_screen.dart` (kind-aware layouts; or split into small kind widgets under `presentation/widgets/`), `run_map.dart` (draw descents, highlight one), l10n, tests (new `test/ride_ski_screens_test.dart`).

- [ ] Failing tests: live ride shows km/h speed, distance, moving time, avg speed; live ski shows state (descending/on lift/stopped), descents count, vertical down, max speed, time on slopes; ride summary shows avg/max speed, elevation, 5-km splits, map; ski summary shows day totals and the descents list; tapping a descent shows its stats and highlights it; indoor ride summary shows no map; running live/summary tests unchanged; SE ×1.3 for each.
- [ ] Implement; full suite; commit `Live and summary screens for rides and ski days`.

### Task 7: Cycling screen and indoor ride log

**Files:** new `lib/features/cycling/presentation/cycling_screen.dart`, new `lib/features/cycling/presentation/indoor_ride_sheet.dart`, `app_router.dart` (route before `:sport`), `start_workout.dart` (cycling → Outdoor/Indoor choice), `sport_workouts_screen.dart` / `running_screen.dart` / `football_screen.dart` pill routing, `lib/features/plan/data/week_plan.dart` (unplanned ids), l10n, new `test/cycling_screen_test.dart`.

- [ ] Failing tests: Cycling screen Start ride starts a ride and opens the live screen; Log indoor ride saves a cycling workout (template `indoor_ride`, minutes, RPE, optional km and W in RunDetails with `indoor: true`), editable and deletable like the football log; ride history lists rides only; Start on a planned cycling session asks Outdoor/Indoor and both mark it done; free ride fills the day's open cycling session; SE ×1.3.
- [ ] Implement; full suite; commit `Cycling screen: rides with GPS and indoor ride log`.

### Task 8: Skiing screen

**Files:** new `lib/features/skiing/presentation/skiing_screen.dart`, `app_router.dart`, `start_workout.dart` (winterSports → ski recorder), `my_workouts_screen.dart` (Winter sports tile), pill routing, l10n, new `test/skiing_screen_test.dart`.

- [ ] Failing tests: Start ski day starts a ski session and opens live; ski-day history; planned winterSports session Start → ski recorder, marks it done; free ski day fills the open winterSports session; My workouts shows the Winter sports tile; SE ×1.3.
- [ ] Implement; full suite; commit `Skiing screen: record a ski day`.

### Task 9: Felix sees rides and ski days

**Files:** `lib/features/chat/data/felix_snapshot.dart`, `felix_snapshot_provider.dart`, `test/felix_snapshot_test.dart`.

- [ ] Failing tests: last ride → distanceKm, avgSpeedKmh, maxSpeedKmh, elevationGainM, no paceSecPerKm; indoor ride → indoor true, avgPowerW, distanceKm if set; ski day → ski block; values within Task 1 ranges, omitted when null; running JSON unchanged.
- [ ] Implement; full suite + backend tests; commit `Felix sees rides and ski days`.
