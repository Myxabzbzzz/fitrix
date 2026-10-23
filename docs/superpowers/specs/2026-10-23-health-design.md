# Wave 2D: Apple Health and Health Connect — Design

Date: 2026-10-23. Owner: Муха. Status: owner said «просто начинай» (skip questions); every choice below not quoted from Муха is Claude's call.

## Intent and why

The Connected apps screen lists Apple Health, Garmin, Strava and WHOOP, but nothing connects. Муха: first connect **Apple Health and the Android health app (Health Connect)**, everything else later. Муха does not wear a watch himself but expects users to wear **Apple Watch, WHOOP, Mi Band and Garmin**.

Claude's call: all four of those watches already write to Apple Health (iOS) and Health Connect (Android) through their own apps (Apple Watch natively; Garmin Connect, WHOOP, Mi Fitness / Zepp Life via their "sync to Apple Health / Health Connect" switches). So one integration per platform brings their sleep, heart rate, HRV, steps, weight and workouts into FITRIX. Direct Garmin / WHOOP / Strava APIs stay "coming later".

Success: a user with any of those watches connects Apple Health (or Health Connect) once. The next morning the check-in already has last night's sleep, the recovery screen shows resting HR and HRV against their own normal, workouts recorded on the watch appear in history and training load without double counting, FITRIX workouts appear in Apple Health / Fitness rings, and Felix's recovery advice mentions the real numbers.

## Goals

Connect
1. Connected apps screen: the platform's own row works — "Apple Health" on iOS, "Health Connect" on Android (the other platform's row is not shown). Connect asks the system permission sheet for all read/write types at once. After connecting the row shows "Connected" and the time of the last read; a Disconnect action stops FITRIX reading and writing (on iOS also tell the user that permissions are revoked in Settings › Health › Data Access, because iOS cannot revoke them from the app).
2. Android: if Health Connect is not installed / needs an update, the row says so and opens the store page (`health.installHealthConnect()`). Request history access (`READ_HEALTH_DATA_HISTORY`) so the first import can reach 30 days back.
3. Garmin, WHOOP, Strava rows stay "Coming soon", but their sheet says honestly: «Garmin Connect / WHOOP can already send data to Apple Health (Health Connect) — turn it on in their app and FITRIX will see it». Add a short "Mi Band / Zepp / Mi Fitness" line in the same help text. Fix the "When connecting arrives in a later update…" copy (honesty rule from wave 1 ledger). The profile row count (`connectedAppsCount`) becomes real (0 or 1).
4. Never ask for Health permissions unprompted (not on first launch, not in onboarding). Denied / partial permissions are fine: each feature just shows nothing for the type it can't read.

Read
5. **Sleep last night** (minutes asleep, from the night ending this morning; sum asleep stages, ignore awake/in-bed). The check-in sheet pre-fills the sleep slider with it and shows a small "from Apple Health" (or the source name) label; the user can still change it. If the user already saved today's check-in, it is not overwritten.
6. **Resting HR** (latest value for today, else last 24 h) and **HRV** (night/morning value; iOS gives SDNN, Health Connect gives RMSSD — store which one, never compare across kinds). Shown on the recovery screen with the user's 7-day normal ("52 bpm · your normal 55").
7. **Readiness** gets two new factors when data exists: `restingHr` and `hrv`, each compared to the user's own baseline (mean of the previous up-to-28 days, needs ≥ 5 days of values; no baseline → no factor). Claude's call on deltas: resting HR ≥ +5 bpm above baseline −6, ≥ +8 bpm −10; HRV ≤ −10 % below baseline −6, ≤ −20 % −10; HRV ≥ +10 % above +3. Existing factors unchanged. Factor text on the recovery screen and in Felix context.
8. **Steps today** (and 7-day average): a small line on the recovery screen and Home Today area (builder picks the exact spot within the existing design); sent to Felix.
9. **Weight** from scales (entries whose source is not FITRIX): imported into body weight history (one per day, existing `WeighIn` rules and limits), so smart scales (Mi scale, Withings, Garmin Index) fill the Progress chart. The newest one updates the profile weight like a manual log. A manual entry for the same day wins over an import.
10. **Workouts from other apps** (watch runs, rides, football, strength, skiing…): imported as completed workouts so they count in history, training load, recovery, Progress, the week plan's done status and Felix. Sport mapping by activity type: running→running, cycling/biking→cycling, soccer→football, skiing/snowboarding/cross-country→winterSports, strength/functional→gym, everything else→fitness. Load uses the estimated RPE (as `loadEstimated` today); the user can set RPE on it like on other workouts. Shown with the source name ("Apple Watch", "Garmin Connect") in history. Store distance, average HR (if heart-rate samples exist in the interval) and active calories with the import. Imported runs show in the Running history without a map.
11. **No double counting:** skip Health workouts written by FITRIX itself (source = our bundle / package id) and skip a Health workout that overlaps a FITRIX workout of the same sport by more than half its duration. Imported workout id is a deterministic UUID (v5 of the Health record id), so re-reads and a second device produce the same id; deleting an imported workout leaves the existing `workout_deleted` tombstone, so it is not imported again.
12. **When to read:** on connect (up to 30 days back), then on app start and on return to foreground (throttled, at most once per 15 minutes), and when the check-in sheet or recovery screen opens. No background delivery.

Write
13. Every workout saved in FITRIX (gym, run, match, free run, quick workout) is written to Health as a workout with its activity type, start/end, and distance for runs (no route). Toggle "Save my workouts to Health" under the connected row, on by default. Deleting a FITRIX workout does not delete it from Health (Claude's call: deleting someone's Health data is surprising; say so in the help text).

Felix
14. Felix context (`readiness` block) gets `restingHr`, `restingHrBaseline`, `hrv`, `hrvKind`, `hrvBaseline`, `stepsToday`, `steps7dAvg` and the new factors; `lastWorkout` gets `source` and `avgHr` when imported. Backend `sanitizeContext` whitelists and range-checks them; `describeContext` renders them as lines. Recovery topic gets all of it; sport topics get resting HR / HRV only as the readiness label already does.

Sync and account
15. Imported workouts sync like other workouts (the `completed_workouts` table) plus a small per-workout document with the import details (source, Health record id, distance, avg HR, calories). Claude's call: a new `user_documents` kind (e.g. `health_import`) — this needs a migration of the kind check, applied in the cloud **before** the build is installed (lesson `app-build-before-cloud-migration`).
16. Daily health values (sleep, resting HR, HRV, steps) are cached locally per day for baselines and are **not** synced: they are re-read from Health on each device. Sleep still syncs inside the saved check-in as today.
17. Connection state and the write toggle are per device. Sign-out clears the local cache and connection state.

## Non-goals (this wave)

- Direct Garmin, WHOOP, Strava, Polar, Mi Fitness APIs or OAuth.
- Background delivery / reading while the app is closed; Android background read permission.
- Live heart rate during a FITRIX run or gym session; HR zones time-in-zone.
- Writing routes, weight, food, water or sleep to Health. Reading food / water / nutrition from Health.
- Health Records (clinical), menstrual cycle, blood pressure, VO2max, SpO2 — later if asked.
- Football heatmaps, sprints, cadence (still need direct watch data).
- Cycling / skiing GPS recording — that is the next wave.

## Anti-goals (would be a failure even if it works)

- A workout counted twice (FITRIX workout written to Health then imported back, or watch + manual log of the same session not handled).
- Invented or stale numbers shown as today's (e.g. last week's resting HR presented as today's without a date).
- Asking Health permissions before the user taps Connect, or blocking any screen when Health is missing, denied or empty.
- Comparing SDNN to RMSSD, or a baseline from fewer than 5 days.
- The app crashing on Android without Health Connect, or on iOS when the phone is locked ("Protected health data is inaccessible" must be swallowed).

## Constraints

- Package: `health` ^13.3.2 (carp.dk; HealthKit + Health Connect). Wrap it behind an interface + Riverpod provider (`HealthSource`, like `LocationSource` / `Speaker`) so every test uses a fake.
- iOS: deployment target 13.0 → 15.0 (pbxproj and Podfile); `Runner.entitlements` with `com.apple.developer.healthkit` (+ empty `healthkit.access`), `CODE_SIGN_ENTITLEMENTS` in the Runner target; `NSHealthShareUsageDescription` / `NSHealthUpdateUsageDescription` in Info.plist (English, like the location string — translating permission strings is already a pre-release item). Verified 2026-10-23: Муха's free Apple team (8J66M56MGN) signs a build with the HealthKit entitlement (automatic provisioning added it).
- Android: `minSdk` 26; `MainActivity` → `FlutterFragmentActivity`; manifest: Health Connect `<queries>`, permissions-rationale intent filter + `activity-alias` (`VIEW_PERMISSION_USAGE` / `HEALTH_PERMISSIONS`) pointing to an in-app privacy explanation, READ permissions for steps, heart rate, resting HR, HRV, sleep, weight, exercise, distance, active calories, READ history; WRITE exercise and distance. Android is built but checked mostly on iPhone (as before).
- Extend `test/platform_config_test.dart` for the new plist / entitlement / manifest keys.
- l10n: en/ru/uz/es for every new string (Uzbek o‘/g‘ with U+2018, existing l10n test); generated files are committed.
- Brand names (Apple Health, Health Connect, Garmin…) are not translated.
- Existing tests stay green; new logic (baselines, factors, sport mapping, dedupe, sleep night window, UUID v5) is unit-tested; widget tests at iPhone SE size and 1.3 text scale as before.
- Backend: Node `backend/prompt.js` + `prompt.test.js`; server restart via `backend/start.sh` after merge.

## Left to the builder

- Exact screen placement of resting HR / HRV / steps within the existing recovery and Home designs (follow the clickable prototype's recovery screen where it has these).
- Exact sleep night window (suggested: 18:00 yesterday → 12:00 today, by the session end time).
- Store names, keys, file layout, provider structure.
- Which Health types are requested at once vs. lazily, as long as goal 1's single Connect tap covers what this wave reads/writes.

## Acceptance

- Unit and widget tests green (Flutter and backend).
- iOS Simulator: add sample sleep, resting HR, HRV, steps, weight and a workout in the Health app → connect in FITRIX → values appear in check-in, recovery, Progress, history; a FITRIX workout appears in Health; reconnect/re-read does not duplicate.
- Муха's iPhone (no watch): connect works, empty data shows nothing broken, a FITRIX workout appears in Apple Health.
