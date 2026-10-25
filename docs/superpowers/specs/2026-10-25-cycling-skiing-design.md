# Wave 2E: Cycling and downhill skiing with GPS — Design

Date: 2026-10-25. Owner: Муха. Status: owner said «начинай»; quoted lines are Муха's, the rest are Claude's calls.

## Intent and why

Running (wave 2C) records GPS with the screen locked and speaks every kilometre. Cycling and winter sports only have generic templates and a manual "done". Муха: cycling «все варианты» (city, road, indoor trainer); skiing «скорее всего с подъёмниками» (downhill with lifts). On the bike: «лучше не использовать голос, но все данные записывать, и в настройках тренировки добавить функцию голоса». Skiing: «итог дня и каждый спуск отдельно».

Success: a ride is recorded like a run (screen locked, phone on the bar or in a pocket) with speed, distance, moving time, climb and route; an indoor session is logged in under a minute; a ski day records the whole day, splits it into descents and lifts automatically, and shows the day summary plus every descent with its own stats and place on the map. All of it feeds history, load, plan, Progress, Health and Felix like runs do.

## Goals

Recorder (shared)
1. One GPS recorder for three activity kinds: run (unchanged behaviour), ride, ski. Only one activity can be in progress at a time; the "in progress" bar, crash recovery (resume / save / discard) and the live screen work for all three.
2. Speed limits per kind (fixes implying faster movement are dropped): run 12 m/s (unchanged), ride 30 m/s (108 km/h), ski 40 m/s (144 km/h, chairlifts and fast descents).
3. Ride and ski use **auto-stop moving time**: time counts only while moving (speed ≥ 1 m/s, a stop shorter than 10 s does not stop the clock). Run keeps manual pause only (unchanged).
4. Voice is a per-kind setting in a small "Workout settings" sheet (gear icon next to Start on the Running, Cycling and Skiing screens): run default **on** (unchanged), ride default **off**, ski default **off**. Ride voice speaks every 5 km (distance, time, last 5 km average speed, average speed) plus start/pause/finish; ski voice speaks after each descent (descent number, its distance, vertical drop, max speed). Voice language rules unchanged.

Cycling
5. Cycling screen (own screen like Running): Start ride, Log indoor ride, week distance and ride count, ride history, workouts grid and coach card below.
6. Live ride screen: large current speed (km/h), distance, moving time, average speed; Pause/Resume, hold to finish, discard.
7. Ride summary: route map, distance, moving time, elapsed time, average and max speed, elevation gain, splits every 5 km, RPE, delete.
8. Indoor ride log (sheet, like the football log): date, minutes, RPE, optional distance km, optional average power W, note. Saved as a cycling workout with no route.
9. Start on a planned cycling session asks Outdoor (GPS) or Indoor (log); both mark the session done.

Skiing (downhill)
10. Skiing screen: Start ski day, history of ski days, workouts grid and coach card. "Winter sports" also gets a tile in My workouts.
11. Ski day recording runs all day with the screen locked. The recorder splits the track into **descents** (sustained altitude loss), **lifts** (sustained altitude gain) and the rest (flat, queues, walking) automatically.
12. Live ski screen: current state (descending / on lift / stopped), descents so far, total vertical down, max speed, time on the slopes.
13. Ski day summary: map with all descents drawn (lifts drawn faint or hidden), day totals — descents count, ski distance (descents only), vertical down, max speed, average descent speed, time on slopes, lift count — and the list of descents. Tapping a descent shows its distance, vertical drop, duration, max and average speed, and highlights it on the map.
14. Load for a ski day = RPE × (day time minus lift time minus manual pauses minus stationary stretches longer than 2 min — queues, huts, lunch); lifts and standing never count. The completed workout's duration and the live "time on slopes" use that same time (Claude's call after review, 2026-10-27).

Everywhere
15. Rides, indoor rides and ski days are ordinary completed workouts (sport cycling / winterSports): history, load, recovery, plan done status (free rides / ski days fill the day's open session of that sport like free runs), Progress, cloud sync (details as `run` documents — see Constraints), Health (written with distance), Felix context.
16. Felix: `lastWorkout` for rides gets distance, average speed (km/h), max speed, elevation gain; indoor rides get minutes, optional distance and power; ski days get descents, vertical down, ski distance and max speed. Backend whitelist + description lines.

## Non-goals (this wave)

- Cross-country (classic/skate) skiing specifics; snowboard is recorded as a ski day.
- Cadence, power from sensors, heart rate during the activity, Bluetooth sensors.
- Route planning, segments/leaderboards, piste names, resort maps.
- Interval/target workouts with real-time coaching.
- Barometer altitude (GPS altitude only this wave).

## Anti-goals

- A chairlift counted as a descent or as training load.
- A fast bike descent or ski run dropped as "GPS noise" (the 12 m/s running cap must not apply).
- Voice speaking on a ride when the user did not turn it on.
- A ski day lost when the phone is cold/locked/killed (crash recovery must cover a 6–8 h day).
- Running behaviour changing in any way.
- Draining the battery so fast that a normal 5-hour ski day cannot be recorded on a charged iPhone (builder: reduce GPS work for ski, e.g. distance filter, while keeping descents accurate).

## Constraints

- Branch `redesign`; Flutter + Riverpod as in wave 2C; reuse the running recorder, track math, map, voice and dialogs — generalise, don't fork.
- **Cloud: no new `user_documents` kind.** Ride, indoor-ride and ski-day details are stored as `run` documents (the existing kind is a generic "activity details" document keyed by workout id); new optional fields are added to `RunDetails` (e.g. `kind`, `maxSpeed`, `elevationLoss`, `indoor`, `avgPowerW`, `ski` block with descents). Older app versions must still parse these documents (unknown fields ignored). Document size < 64 KB: route ≤ 2,000 points for the whole ski day; per-descent geometry is stored as index ranges into that route, not duplicated.
- Backend: `backend/prompt.js` whitelist and description; restart via `backend/start.sh` after merge (owner's «да»).
- iOS background location and audio already configured; Android foreground notification text must name the activity kind.
- l10n en/ru/uz/es without plural-dependent wording; Uzbek o‘/g‘ U+2018; tutuq per file majority.
- iPhone SE 375×667 ×1.3 without overflow for every new screen.
- Tests: pure math (speed caps, auto-stop, ski segmentation on synthetic altitude profiles incl. noisy GPS altitude and a lift followed by a descent), recorder per kind with the fake location source, voice settings, widget tests; running tests stay green unchanged.

## Claude's calls (owner can override)

- Ski segmentation: smooth altitude (median over ~30 s), split by direction with 15 m hysteresis; legs trimmed by the last/first crossing of the band; stationary stretches (ground speed < 0.5 m/s for > 2 min — queues, huts, lunch) are "other" and split legs. A descent needs ≥ 30 m drop and ≥ 100 m ground distance at moving ground speed ≥ 1.5 m/s; a lift ≥ 30 m gain with average climb ≥ 0.3 m/s and ground speed ≤ 12 m/s; everything else is "other". Max speed from fix-to-fix speed, robust over ≥ 3 s; descent average speed over moving time. Known limitation: riding a gondola down, or a lift with a ≥ 35 m mid-station dip, can still be read as a descent (revisit with real ski-day data).
- Ride splits every 5 km; ride voice every 5 km.
- Indoor ride template id `indoor_ride`; free ride `free_ride`; free ski day `free_ski`; all three added to the plan's "unplanned" ids.
- Ride/ski duration = auto-stop moving time (ride) / day minus lifts minus pauses (ski).
- Elevation gain for rides shown only when the device reports altitude for most points (as runs).

## Left to the builder

- Exact layouts following the app's tokens and the running screens; map colours for descents/lifts.
- How the recorder is parameterised (activity profile object, etc.).
- Battery strategy for ski days within the anti-goal.
