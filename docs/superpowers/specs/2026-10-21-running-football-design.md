# Wave 2C: Running with GPS and voice, football match log — Design

Date: 2026-10-21. Owner: Муха. Status: approved by owner 2026-10-21.

## Intent and why

FITRIX already plans running and football sessions in the week plan and counts training load, but a run or a match is only a generic "done" session with an estimated load. Муха runs with the phone on him and plays football with the phone in the bag by the pitch. So the two sports need different things:

- **Running:** a real run recorder. GPS while the phone is in a pocket with the screen off, and **voice** announcements (Муха: «голосом лучше, на экран почти не смотрю»). After the run, a summary that feeds load, recovery, progress, the week plan and Felix.
- **Football:** no live recording (a phone in a bag measures nothing). A quick **match log after the game** that feeds the same places, so Felix and the plan know a match happened and how hard it was.

Success: Муха goes for a run, starts it, puts the phone away, hears each kilometre, finishes, and the run appears everywhere it should (plan marked done, load, Progress, Felix can review it). After a match he logs it in under a minute, and the next day Felix and the recovery card take it into account.

## Goals

Running
1. Start a run from the Running screen (and from a planned running session in the week plan / Home Today card).
2. Record GPS with the screen locked: distance, moving time, pace, route.
3. Voice every kilometre: distance, time, last-km pace, average pace — in the app language (en/ru/uz/es). Voice on start, pause, resume, finish. Audio ducks other audio (music keeps playing quieter), works with the screen locked.
4. Screen during the run (for the rare glance): time, distance, current pace, average pace, Pause / Resume, Finish (long-press or confirm, so a pocket tap can't end the run).
5. Summary after Finish: map of the route, distance, moving time, average pace, per-km splits, elevation gain if the GPS gives altitude, RPE 1–10 (optional), Save / Discard.
6. A saved run is a completed workout of sport `running`: it counts in training load (RPE × minutes as today), recovery, Progress, the week plan's done status, and Felix's context (distance and average pace in `lastWorkout`).
7. Run history: list of past runs on the Running screen; tap opens the summary.
8. A run in progress survives the app being killed or the phone restarting the app: points are saved as they come, and on the next launch the user can resume or save what was recorded.

Football
9. "Log a match" on the Football screen (and from a planned football session): date, format (5×5, 6×6, 7×7, 8×8, 11×11), minutes played, position (GK, CB, FB, CM, WM, ST), RPE 1–10, optional result (our score – their score), goals, assists, note. Under a minute to fill.
10. A logged match is a completed workout of sport `football`: load (RPE × minutes), recovery, Progress, plan done status, Felix's context (format, minutes, RPE, result).
11. Match history on the Football screen; tap opens the match to view, edit or delete it.

Both
12. Data syncs to the cloud like other workouts (survives reinstall and a second device).
13. Felix: running and football topic chats see the latest run / match through the existing `context` (Task 3 of wave 2B); the topic prompts stay.

## Non-goals (this wave)

- Heart rate, cadence, sprints, high-speed running, heatmaps, top speed for football — need a watch; they come with the watch integration wave.
- Live football recording on the phone.
- Pace calculator from a race result (VDOT), ready-made 5K/10K/marathon plans, shoe mileage, curated Tashkent routes, track stopwatch, football tests (Yo-Yo, sprint) and drill library — all from the prototype, deferred.
- Target-pace or interval workouts with guidance ("speed up"); this wave announces, it does not coach in real time.
- Cycling and winter sports recording (next waves; the recorder should not make them hard to add).
- Strava/Garmin import or export.

## Anti-goals (would be a failure even if it technically works)

- The run stops recording when the screen locks or the user switches to music — the core promise.
- Distance or pace that jumps wildly from GPS noise (a standing start showing 3:00/km, a tunnel adding 500 m).
- Voice that is silent with the screen locked, or that stops the user's music instead of ducking it.
- Losing a run because the app was killed, the battery saver kicked in, or Finish was pressed by accident in a pocket.
- Asking for "Always" location access when "While using" with background updates is enough; any copy that hides why location is needed.
- Draining the battery noticeably faster than other run apps (Strava/Nike) for the same run.

## Constraints

- Flutter app on branch `redesign`; iOS is what Муха uses (iPhone 14 Pro); Android must not break (build and run, background recording may be best-effort there).
- Existing packages: `geolocator` ^14, `flutter_map` ^8, `latlong2`. A text-to-speech package is needed (new dependency — builder picks, e.g. `flutter_tts`; must speak in ru/uz/es/en or fall back gracefully if a voice is missing on the device).
- iOS: `UIBackgroundModes` gets `location` and `audio`; `NSLocationWhenInUseUsageDescription` is updated to mention runs (all four languages via InfoPlist strings if the project has them; otherwise English as now). "When in use" permission only; recording starts in the foreground.
- Map tiles: the app already uses OSM tiles for the map screen; production tile policy is a known pre-release item (not solved here).
- Cloud: `completed_workouts` keeps one row per run/match as today (sport, start, finish, name). Run and match details (route, splits, distance, match fields) go to the cloud as `user_documents` rows with new kinds (`run`, `match`), doc id = the completed workout id. This needs a migration that widens the kind check — applied to the cloud only after Муха's explicit «да», **before** installing the build.
- Route size: store a simplified route (for example every 5–10 m or Douglas–Peucker to ≤ 2,000 points) so a document stays under the 64 KB limit of `user_documents.data`.
- Load stays RPE × minutes (existing `sessionLoad`), so Progress numbers stay comparable; no distance-based load this wave.
- All user-visible text in en/ru/uz/es (Uzbek uses ‘ U+2018). Honesty rule: no copy promising heart rate, coaching or features not built.
- iPhone SE at text scale 1.3 without overflow.
- Never apply migrations to the cloud or restart the live Felix server without Муха's explicit «да».

## Decided with Муха (2026-10-20/21)

- Football: phone stays in the bag → log after the match, no live GPS. (Муха: «скорее всего он в сумке у поля».)
- Running: phone is with him → live GPS recording. (Муха: «беру с собой телефон на пробежку».)
- Voice over screen during runs. (Муха: «голосом лучше, на экран почти не смотрю».)
- Scope of the playbacks above was accepted without changes («продолжи»).
- Existing workouts and Start buttons (Муха: «да в целом все хорошо»):
  - Running: Start on any running session or workout (sport screen, plan row, Home Today card, Felix plans) opens the GPS recorder; the workout's name and notes (its exercises/sets, if any) show at the top as a hint and the run is saved under that template id so the plan marks it done. The workouts grid stays on the Running screen below Start run and history.
  - Football: every football Start becomes "Log", which opens the post-game form with a Match / Training toggle. Match has result, goals, assists; Training has only minutes, position (optional) and RPE. The set logger is no longer used for football. The workouts grid stays below Log and history.

## Claude's calls (owner can override)

- Voice every 1 km (not configurable this wave); also on start/pause/resume/finish. Content per km: "Kilometre 3. Time 16 minutes 35. Last kilometre 4:52. Average 4:51." in the app language.
- Auto-pause: off this wave (manual Pause only) — auto-pause in cities with traffic lights is error-prone; revisit with watch data.
- GPS filtering: ignore fixes with horizontal accuracy worse than 25 m and implausible jumps (> 12 m/s between fixes); distance from filtered points.
- Finish needs a hold or a confirm sheet; Discard needs a confirm.
- Run name default: "Run" localized + time of day ("Morning run"); match name: "Football 7×7".
- Elevation gain shown only when the device reports altitude for most points.
- Felix context gets `lastWorkout.distanceKm` and `lastWorkout.paceSecPerKm` for runs, and `lastWorkout.match: {format, minutes, rpe, goalsFor, goalsAgainst}` for football — backend `sanitizeContext` and `describeContext` extended with ranges.
- A run started from a planned session marks that session done; a run started free matches the day's open running session if there is one (same rule as other sports today).

- **Edit and delete reach every device.** History today is insert-only (no update policy, union merge), so a local delete would come back after a reinstall. This wave adds deletion sync for completed workouts: deleting a run or match deletes the cloud `completed_workouts` row (the delete policy exists) and writes a tombstone document (`user_documents` kind `workout_deleted`, doc id = workout id) that other devices apply on pull. Editing a match's date or minutes saves it as a new workout and deletes the old one this way. Other edits (RPE, result, goals, assists, position, note) only change the `match` document. Gym workouts get the same delete for free, but no new UI this wave.
- **RPE syncs for runs and matches.** Session RPE stays local for gym workouts (unchanged), but for runs and matches it is stored in the `run` / `match` document and applied on pull. Otherwise a match logged on one device would not count as a hard day on another.
- **Duration is moving time.** A run's `finishedAt` = `startedAt` + moving time (pauses excluded), so load, Progress, the plan's done row and Felix's `minutes` use moving time. Elapsed time and pause count are kept in the `run` document and shown on the summary. A match's duration is the minutes played.
- **Voice language.** Speak in the app language. When the device has no voice for it (Uzbek usually has none on iOS), speak the Russian text if a Russian voice exists, otherwise English. Never read Uzbek text with a Russian voice.

## Left to the builder

- Package choice for TTS and any foreground/background helper; how to keep the iOS location session alive (geolocator `AppleSettings` with `allowBackgroundLocationUpdates`, `pauseLocationUpdatesAutomatically: false`, activity type fitness, `showBackgroundLocationIndicator`).
- Exact screen layouts, following the clickable prototype (`~/РАБОТА/fitrix-design/design/clickable/mock_running.html`, `mock_football.html`) and the app's tokens, without the deferred parts.
- How the recorder is structured so cycling can reuse it later.
- Test approach for GPS (fake location stream) and TTS (fake speaker); a manual device test on a real run is the acceptance step.
