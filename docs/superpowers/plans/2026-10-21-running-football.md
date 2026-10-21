# Wave 2C: Running with GPS and Voice, Football Log — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Record runs with GPS (screen locked) and per-km voice, log football matches/trainings after the game, and feed both into history, load, plan, Progress, cloud sync and Felix.

**Architecture:** Pure run math (`run_track.dart`) under a `RunRecorder` notifier fed by a `LocationSource` (geolocator, fake in tests) and a `RunVoice` speaker (flutter_tts, fake in tests). A finished run or a match is an ordinary `CompletedWorkout` (sport running/football) plus a detail document (`run` / `match`) synced through the existing `user_documents` channel; deletions sync through a new `workout_deleted` tombstone kind. `startWorkout` routes running templates to the recorder and football templates to the log form.

**Tech Stack:** Flutter 3, Riverpod 2, go_router, geolocator ^14, flutter_map ^8, latlong2, new `flutter_tts`; Node backend; Supabase Postgres + pgTAP.

**Spec:** `docs/superpowers/specs/2026-10-21-running-football-design.md` (approved 2026-10-21).

## Global Constraints

- Branch `redesign`; commits without `Co-Authored-By`; Flutter SDK `export PATH="/Users/myxabzbzzzz/РАБОТА/flutter/bin:$PATH"`; `flutter analyze` clean; `flutter test` green (baseline 916 passed, 5 skipped); backend `cd backend && npm test` green (baseline 104).
- Never run anything against the cloud project (`sfajspspziuvsoangivl`): no `supabase db push`, no `--linked`. Local Supabase only (`supabase migration up --local`, `supabase test db`). Never `db reset`. Never stop or restart the live Felix server or any live process.
- Spec values: GPS fix dropped when horizontal accuracy > 25 m or implied speed > 12 m/s from the last kept fix; voice every 1 km plus start/pause/resume/finish; auto-pause off; route simplified to ≤ 2,000 points; duration = moving time (`finishedAt = startedAt + moving time`); load stays `sessionLoad(rpe ?? 6, duration)`; "When in use" location only, recording starts in foreground; `UIBackgroundModes` `location` and `audio`.
- Voice language: app language; if the device has no voice for it, speak the Russian text if a Russian voice exists, else English; never read Uzbek text with a Russian voice.
- Football formats `5x5, 6x6, 7x7, 8x8, 11x11` (shown as 5×5 …); positions `GK, CB, FB, CM, WM, ST`; types `match`, `training`.
- New `user_documents` kinds: `run`, `match`, `workout_deleted` (doc id = completed workout id). Doc `data` must stay < 64 KB.
- Template ids for workouts without a template: `free_run`, `football_log`.
- All new user-visible text in en/ru/uz/es (Uzbek ‘ U+2018), `flutter gen-l10n`, never edit generated files. Honesty: no copy promising heart rate, coaching, or features not built.
- iPhone SE (375×667) at text scale 1.3 without overflow for every new screen.

## Review Focus

- The run keeps recording and the km voice keeps speaking while the app is backgrounded/screen locked; on iOS this is configuration plus geolocator `AppleSettings(allowBackgroundLocationUpdates: true, pauseLocationUpdatesAutomatically: false, activityType: ActivityType.fitness, showBackgroundLocationIndicator: true)`. Pinned by a config test in Task 4 (Info.plist keys and the settings object) — the real proof is the owner's device run.
- GPS noise: a standing start with jittery fixes must not add distance or show an absurd pace; a single 300 m jump must be dropped. Test in Task 3.
- The app is killed mid-run: on next launch the user is offered Resume or Save, and nothing recorded is lost. Test in Task 4 and Task 7.
- A pocket tap cannot finish or discard a run: Finish needs a hold (≥ 1 s) or a confirm sheet, Discard always confirms. Test in Task 6.
- A deleted run/match does not come back after sync from another device or a reinstall. Test in Task 2.

---

### Task 1: Backend context for runs and matches; new document kinds

**Files:**
- Modify: `backend/prompt.js` (`sanitizeContext`, `describeContext`), `backend/prompt.test.js`
- Create: `supabase/migrations/20261021120000_run_match_documents.sql`, `supabase/tests/run_match_documents_test.sql`

**Interfaces:**
- Produces: context `lastWorkout` optional fields `distanceKm` (0..500, 2 dp), `paceSecPerKm` (120..1800, int), `match: {type: "match"|"training", format?: "5x5"|"6x6"|"7x7"|"8x8"|"11x11", minutes: 1..200, rpe?: 1..10, goalsFor?: 0..50, goalsAgainst?: 0..50}`; DB kinds `run`, `match`, `workout_deleted` accepted.

- [ ] **Step 1: Failing tests** in `backend/prompt.test.js`: `sanitizeContext({lastWorkout:{date:'2026-10-20',sport:'running',name:'Morning run',distanceKm:6.214,paceSecPerKm:291}})` keeps `distanceKm: 6.21`, `paceSecPerKm: 291`; `distanceKm: 900` dropped; `match:{type:'match',format:'7x7',minutes:50,rpe:8,goalsFor:3,goalsAgainst:4}` kept, `format:'9x9'` dropped from match, `type:'friendly'` drops the whole match object. `describeContext` prints `Last workout: running "Morning run" on 2026-10-20, 30 min, 6.21 km at 4:51/km` and `…football match 7x7, 50 min, RPE 8, result 3-4`.
- [ ] **Step 2: Run** `cd backend && node --test prompt.test.js` — FAIL.
- [ ] **Step 3: Implement** in `sanitizeContext` / `describeContext` (pace printed `m:ss/km`).
- [ ] **Step 4: Migration**: drop and re-add `user_documents_kind_check` with the existing 9 kinds plus `run`, `match`, `workout_deleted`. pgTAP: owner can insert each new kind; `kind='chess'` fails. Run `supabase migration up --local && supabase test db` — pass.
- [ ] **Step 5: Run** `npm test` — pass. **Commit** `Felix context for runs and matches; run, match and workout_deleted document kinds`.

---

### Task 2: Deleting a completed workout syncs everywhere

**Files:**
- Create: `lib/features/workouts/data/deleted_workouts_store.dart`
- Modify: `lib/features/workouts/presentation/providers/workouts_provider.dart` (`WorkoutHistoryNotifier.remove`), `lib/core/sync/collections.dart` (`WorkoutDeletedCollection`, registered in `syncedCollections`), `lib/core/sync/sync_engine.dart` (history pull skips deleted ids), `lib/core/sync/remote_store.dart` + `supabase_remote_store.dart` (`deleteHistory`), `test/support/in_memory_remote_store.dart`
- Test: `test/workout_delete_sync_test.dart` (new)

**Interfaces:**
- Produces:
```dart
class DeletedWorkoutsStore { // prefs key 'deleted_workouts_v1': {id: deletedAtMs}
  Set<String> ids(); void add(String id, DateTime at); void clear();
}
final deletedWorkoutsStoreProvider = Provider<DeletedWorkoutsStore>(...);
// WorkoutHistoryNotifier
void remove(String id); // removes from history, records the id in DeletedWorkoutsStore, pings LocalChanges
// RemoteStore
Future<void> deleteHistory(String userId, String id);
```
`WorkoutDeletedCollection.kind == 'workout_deleted'`; `read()` → `{id: {'deletedAt': iso}}`; `apply()` adds ids and removes them from history (without pinging LocalChanges). The engine calls `deleteHistory` for every locally deleted id once (best effort; failure retried next sync) and never re-adds a pulled history row whose id is deleted. `SyncLocal.clear` clears the store.

- [ ] **Step 1: Failing tests:** device A removes workout X → after sync, remote has no `completed_workouts` row X and has doc `workout_deleted/X`; device B (has X locally) syncs → X gone from its history; device C (fresh) syncs → X never appears even if the remote row delete failed (fake remote keeps the row). Removing an id twice is a no-op.
- [ ] **Step 2: Run** `flutter test test/workout_delete_sync_test.dart` — FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** `flutter analyze && flutter test` — pass. **Commit** `Deleting a workout syncs to the cloud and other devices`.

---

### Task 3: Run math and the run document

**Files:**
- Create: `lib/features/running/data/run_track.dart` (pure), `lib/features/running/data/run_store.dart`
- Modify: `lib/core/sync/collections.dart` (`RunCollection`), `lib/features/workouts/...` (RPE overlay helper, see below)
- Test: `test/run_track_test.dart`, `test/run_store_test.dart`

**Interfaces:**
- Produces:
```dart
class RunPoint { final double lat, lng; final double? alt; final double accuracy; final DateTime at; }
class RunSplit { final int km; final double meters; final Duration time; } // last partial split has meters < 1000
class RunTrack {                       // immutable
  RunTrack add(RunPoint p);            // applies the 25 m / 12 m/s filter
  RunTrack pause(DateTime at); RunTrack resume(DateTime at);
  double get meters; Duration movingTime(DateTime now); bool get paused;
  List<RunSplit> get splits; double? get elevationGain; // null unless >= 80% of kept points have alt; 3 m hysteresis
  List<RunPoint> get kept;
}
List<RunPoint> simplifyRoute(List<RunPoint> points, {int maxPoints = 2000});
int? paceSecPerKm(double meters, Duration time); // null below 50 m
class RunDetails {                     // the 'run' document, id = workout id
  final DateTime startedAt; final Duration moving, elapsed; final int pauses;
  final double meters; final double? elevationGain; final List<RunSplit> splits;
  final List<List<double>> route;      // [[lat,lng],...] simplified, 5 dp
  final int? rpe; final String? templateId;
  Map<String, Object?> toJson(); factory RunDetails.fromJson(Map<String, Object?> j);
}
class RunStore { Map<String, RunDetails> all(); void put(String id, RunDetails d); void remove(String id); void clear(); } // prefs 'runs_v1'
final runStoreProvider; final runsProvider; // StateNotifier<Map<String, RunDetails>>
void applyDocRpe(Ref ref);             // sets CompletedWorkout.sessionRpe from run/match docs when it differs
```
`RunCollection.kind == 'run'`; `apply` also calls the RPE overlay so a run's RPE reaches history on another device.

- [ ] **Step 1: Failing tests** `run_track_test.dart`:
  - 1 km straight line of fixes every 5 s at 10 km/h → `meters` within 1 % of 1000, one split.
  - Standing start: 30 fixes at the same spot with 5–15 m random jitter and accuracy 10 m → `meters < 15`.
  - One fix 300 m off between two good fixes 5 s apart → dropped; fix with accuracy 40 m → dropped.
  - Pause 2 min then resume → `movingTime` excludes the pause; distance between the pause point and the resume point is not counted.
  - 2.4 km → splits `[1, 2, partial 400 m]` with times summing to moving time.
  - Altitude on 50 % of points → `elevationGain == null`; climbs of +2/−2 m noise → gain 0.
  - `simplifyRoute` of 10,000 points → ≤ 2000 points, first and last kept.
  - `RunDetails` JSON round-trip; `jsonEncode(details.toJson()).length < 64000` for a 2,000-point route.
- [ ] **Step 2: Failing tests** `run_store_test.dart`: put/all/remove persist across a new store instance; `RunCollection.read/apply` round-trip; applying a run doc with `rpe: 8` sets `sessionRpe` 8 on the history workout with that id (and a history pull after the doc also ends with 8).
- [ ] **Step 3: Run** both — FAIL. **Step 4: Implement** (distance via `latlong2` `Distance()`; Douglas–Peucker with increasing tolerance until ≤ maxPoints). **Step 5: Run** `flutter analyze && flutter test` — pass. **Commit** `Run math, run document and RPE overlay`.

---

### Task 4: Run recorder with background location and crash recovery

**Files:**
- Create: `lib/features/running/data/location_source.dart`, `lib/features/running/presentation/run_recorder.dart`
- Modify: `ios/Runner/Info.plist` (`UIBackgroundModes`: `location`, `audio`; `NSLocationWhenInUseUsageDescription` = "FITRIX uses your location to record runs and to show gyms and parks near you."), `android/app/src/main/AndroidManifest.xml` (`FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_LOCATION`, `POST_NOTIFICATIONS`)
- Test: `test/run_recorder_test.dart`, `test/platform_config_test.dart`

**Interfaces:**
- Consumes: Task 3 `RunTrack`, `RunDetails`, `simplifyRoute`, `RunStore`.
- Produces:
```dart
abstract class LocationSource {
  Future<LocationAccess> ensureAccess(); // granted | denied | deniedForever | serviceOff
  Stream<RunPoint> start(); Future<void> stop();
}
class GeolocatorLocationSource implements LocationSource { /* AppleSettings / AndroidSettings per Review Focus line 1 */ }
final locationSourceProvider = Provider<LocationSource>(...);
enum RunPhase { idle, running, paused }
class RunSession { final RunPhase phase; final RunTrack track; final DateTime startedAt; final WorkoutTemplate? template; }
class RunRecorder extends StateNotifier<RunSession?> {
  Future<LocationAccess> start({WorkoutTemplate? template});
  void pause(); void resume();
  Future<CompletedWorkout> finish({int? rpe}); // saves workout (templateId = template?.id ?? 'free_run', sport running, finishedAt = startedAt + moving) + RunDetails; clears recovery
  Future<void> discard();
  Stream<RunEvent> get events;               // RunStarted, RunPaused, RunResumed, KmReached(km, total, lastKm, avgPace), RunFinished — used by voice
}
final runRecorderProvider = StateNotifierProvider<RunRecorder, RunSession?>(...);
final pendingRunProvider = Provider<RunSession?>(...); // a run found in 'run_in_progress_v1' at launch
```
Recovery: the recorder writes `run_in_progress_v1` (startedAt, template id, phase, kept points, pause marks) at most every 10 s and on every pause/resume; `finish`/`discard` remove it.

- [ ] **Step 1: Failing tests** `run_recorder_test.dart` with a fake `LocationSource` (StreamController) and fake clock:
  - start → feed 2.1 km → events include `KmReached(1)`, `KmReached(2)` in order; finish(rpe: 7) → history has a running workout with `templateId 'free_run'`, `duration == moving time`, `sessionRpe 7`; `RunStore` has its details; recovery key gone.
  - start(template: t) → saved under `t.id`.
  - Access denied → `start` returns `denied`, no session, no stream subscription.
  - Kill simulation: after 600 m and a pause, build a new container with the same prefs → `pendingRunProvider` returns the session with ≥ 600 m and phase paused; resume continues the distance.
  - discard → nothing in history or RunStore.
- [ ] **Step 2: Failing test** `platform_config_test.dart`: reads `ios/Runner/Info.plist` and asserts `UIBackgroundModes` contains `location` and `audio` and the usage string mentions runs; `GeolocatorLocationSource.settingsForPlatform(TargetPlatform.iOS)` is `AppleSettings` with `allowBackgroundLocationUpdates == true`, `pauseLocationUpdatesAutomatically == false`, `showBackgroundLocationIndicator == true`.
- [ ] **Step 3: Run** — FAIL. **Step 4: Implement.** **Step 5: Run** `flutter analyze && flutter test` — pass. **Commit** `Run recorder: background GPS, km events, crash recovery`.

---

### Task 5: Voice announcements

**Files:**
- Create: `lib/features/running/presentation/run_voice.dart`
- Modify: `pubspec.yaml` (`flutter_tts`), ARB files
- Test: `test/run_voice_test.dart`

**Interfaces:**
- Consumes: Task 4 `RunRecorder.events`, `selectedLanguageProvider`.
- Produces:
```dart
abstract class Speaker { Future<Set<String>> languages(); Future<void> speak(String text, {required String language}); }
class FlutterTtsSpeaker implements Speaker { /* iOS shared instance, category playback, options duckOthers + mixWithOthers + interruptSpokenAudioAndMixWithOthers */ }
final speakerProvider = Provider<Speaker>(...);
String pickVoiceLanguage(String appLanguage, Set<String> available); // 'uz'→'ru' if available→'en'
class RunVoice { RunVoice(Speaker, Stream<RunEvent>, {required String Function() appLanguage}); void dispose(); }
final runVoiceProvider; // listens while a run session exists
```
Phrases (ARB, en shown): `runVoiceStart` "Run started.", `runVoicePause` "Paused.", `runVoiceResume` "Resumed.", `runVoiceKm` "Kilometre {km}. Time {time}. Last kilometre {lastPace}. Average {avgPace}.", `runVoiceFinish` "Run finished. {distance} kilometres in {time}. Average {avgPace}." Times/paces spoken in words per language ("16 minutes 35 seconds", "4 minutes 52 per kilometre") via helper `spokenDuration(l10n, Duration)`, `spokenPace(l10n, int secPerKm)`.

- [ ] **Step 1: Failing tests:** fake speaker with languages `{en, ru}` and app language `uz` → every phrase spoken with `language: 'ru'` and Russian text; with `{en}` only → English; app `ru` → Russian `runVoiceKm` for km 3 equals the ARB text with "16 минут 35 секунд"-style words; one `KmReached` → exactly one `speak`; pause/resume/finish each speak once.
- [ ] **Step 2: Run** — FAIL. **Step 3: Implement**; ARB keys in 4 languages; `flutter pub get`, `flutter gen-l10n`. **Step 4: Run** `flutter analyze && flutter test` — pass. **Commit** `Voice announcements for runs`.

---

### Task 6: Live run and run summary screens; Start routing for running

**Files:**
- Create: `lib/features/running/presentation/screens/live_run_screen.dart`, `run_summary_screen.dart`, `lib/features/running/presentation/widgets/run_map.dart`
- Modify: `lib/features/workouts/presentation/start_workout.dart` (running → recorder), `lib/core/router/app_router.dart` (routes), ARB files
- Test: `test/live_run_test.dart`

**Interfaces:**
- Consumes: Tasks 3–5.
- Produces: routes `AppRouter.liveRun` = `/run/live` (full screen, above the shell), `AppRouter.runSummary(String id)` = `/run/:id`; `startWorkout(context, ref, template)` with `template.sport == Sport.running` calls `RunRecorder.start(template: template)` and pushes `/run/live` (denied access → snack with a Settings hint, no navigation).

Live screen: template name (if any) and its exercise lines as a one-line hint; big time, distance (km, 2 dp), current pace (last 200 m), average pace; Pause/Resume; Finish = press-and-hold 1 s with a fill animation (releasing earlier does nothing); lock-screen-safe (no auto-dim changes). Summary: map polyline (`flutter_map`, OSM tiles as the existing map screen, attribution), distance, moving time, avg pace, elevation if not null, elapsed + pauses line, splits table, RPE chips 1–10, Save (calls `finish(rpe)` — or, when opened for a saved run, Delete with confirm via Task 2 `remove`), Discard with confirm.

- [ ] **Step 1: Failing tests:** Start on a running template → `/run/live`, recorder running with that template; a short tap on Finish does not finish; a 1 s hold finishes and opens the summary; Discard asks to confirm and cancelling keeps the run; Save with RPE 7 → history entry with `sessionRpe 7`, plan session of that template marked done; denied access → snack, stays on the screen; SE 375×667 text 1.3 ru: live and summary screens have no overflow.
- [ ] **Step 2: Run** — FAIL. **Step 3: Implement.** **Step 4: Run** `flutter analyze && flutter test` — pass. **Commit** `Live run and run summary screens; Start on running opens the recorder`.

---

### Task 7: Running screen — start, history, resume after a crash

**Files:**
- Create: `lib/features/running/presentation/screens/running_screen.dart`, `lib/features/running/presentation/widgets/run_history_list.dart`
- Modify: `lib/core/router/app_router.dart` (`/workouts/running` shows `RunningScreen`), `lib/features/shell/presentation/main_shell.dart` or app root (resume prompt), ARB files
- Test: `test/running_screen_test.dart`

**Interfaces:**
- Consumes: Tasks 3, 4, 6; existing workouts grid widget from `SportWorkoutsScreen` (extract it into a reusable widget if needed, without changing gym/fitness/cycling/winter screens' behaviour).

Running screen (top to bottom): "Start run" primary button (free run); this week: km and runs count; history list (date, distance, moving time, avg pace; tap → `/run/:id` summary); "Workouts" grid as today (Start → recorder via Task 6). Resume prompt: when `pendingRunProvider` is non-null at app start, a dialog "Unfinished run · {distance} km" with Resume (→ `/run/live`) and Save (→ summary) and Discard (confirm).

- [ ] **Step 1: Failing tests:** history shows saved runs newest first with "6.21 km · 30:12 · 4:51 /km" (en); tapping opens the summary with Delete; Delete (confirm) removes it from the list and from history; pending run at launch → dialog; Resume opens live with the old distance; week stats count only this week's runs; gym/fitness screens unchanged (existing tests pass); SE 1.3 ru no overflow.
- [ ] **Step 2: Run** — FAIL. **Step 3: Implement.** **Step 4: Run** `flutter analyze && flutter test` — pass. **Commit** `Running screen: start, history, resume an unfinished run`.

---

### Task 8: Football log

**Files:**
- Create: `lib/features/football/data/match_log.dart`, `lib/features/football/data/match_store.dart`, `lib/features/football/presentation/match_log_sheet.dart`, `lib/features/football/presentation/football_screen.dart`
- Modify: `lib/core/sync/collections.dart` (`MatchCollection`, uses Task 3 RPE overlay), `start_workout.dart` (football → log sheet), router (`/workouts/football` → `FootballScreen`), ARB files
- Test: `test/football_log_test.dart`

**Interfaces:**
- Produces:
```dart
enum FootballType { match, training }
class MatchLog { // the 'match' document, id = workout id
  final FootballType type; final DateTime date; final String? format; final int minutes;
  final String? position; final int? rpe; final int? goalsFor, goalsAgainst, goals, assists; final String? note; final String? templateId;
  Map<String, Object?> toJson(); factory MatchLog.fromJson(Map<String, Object?> j);
}
class MatchStore { /* prefs 'matches_v1', same shape as RunStore */ }
Future<void> showMatchLogSheet(BuildContext, WidgetRef, {WorkoutTemplate? template, String? editId});
```
Save: workout `sport football`, `name` "Football 7×7" (match) / template name or "Football training", `templateId = template?.id ?? 'football_log'`, `finishedAt` = chosen date at the time of logging (today) or 20:00 for a past date, `startedAt = finishedAt − minutes`, `sessionRpe = rpe`. Edit: change of date or minutes → new workout id + Task 2 `remove(oldId)`; other changes only update the document (and `sessionRpe`). Defaults: type match, format 7x7, minutes 50, position from the last log. Football screen: "Log" primary button; history (date, type, format, minutes, result) → tap opens the sheet in edit mode with Delete; workouts grid below, Start replaced by "Log".

- [ ] **Step 1: Failing tests:** logging a 7×7 match 50 min RPE 8 result 3–4 creates history with duration 50 min, `sessionRpe 8`, load `sessionLoad(8, 50 min)`, today's planned football session done; training type hides result/goals/assists; editing RPE keeps the id; editing minutes creates a new id and the old id is in `DeletedWorkoutsStore`; Delete removes from history; `MatchCollection` round-trip; the sheet fits SE at 1.3 ru.
- [ ] **Step 2: Run** — FAIL. **Step 3: Implement.** **Step 4: Run** `flutter analyze && flutter test` — pass. **Commit** `Football log: matches and trainings after the game`.

---

### Task 9: Felix sees runs and matches

**Files:**
- Modify: `lib/features/chat/data/felix_snapshot.dart`, `lib/features/chat/presentation/providers/felix_snapshot_provider.dart`
- Test: `test/felix_snapshot_test.dart`

**Interfaces:**
- Consumes: Task 1 schema; `runsProvider` (Task 3), match store provider (Task 8).

- [ ] **Step 1: Failing tests:** last workout a run with `RunDetails` (6214 m, moving 30:12) → `lastWorkout.distanceKm == 6.21`, `paceSecPerKm == 292`; last workout a match → `lastWorkout.match == {type:'match', format:'7x7', minutes:50, rpe:8, goalsFor:3, goalsAgainst:4}`; a running workout without details (old history) → no distance keys.
- [ ] **Step 2: Run** — FAIL. **Step 3: Implement.** **Step 4: Run** `flutter analyze && flutter test` — pass. **Commit** `Felix sees distance and pace of runs and match details`.

---

### After the tasks (controller)

- Whole-branch review (Opus), one fix wave.
- Deploy only with Муха's «да», in order: backend restart via `backend/start.sh`; migration `20261021120000` to the cloud (Муха runs `!supabase db push --linked` after a dry-run); build and install over the existing app (`flutter build ios --release --dart-define-from-file=env/cloud.json --dart-define=API_BASE_URL=http://<mac-ip>:3000`, `xcrun devicectl device install app`, phone unlocked).
- Acceptance: Муха's real run with the phone locked in a pocket and music playing (voice every km, route and distance plausible), then one match log.
- Ledger: `docs/superpowers/plans/2026-10-21-running-football-ledger.md`.
