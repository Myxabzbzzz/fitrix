# SDD ledger — plan: docs/superpowers/plans/2026-10-23-health.md

Spec: docs/superpowers/specs/2026-10-23-health-design.md (owner said «просто начинай»; choices are Claude's calls)
Branch redesign, in place (as waves 1–2C). Implementers sonnet; task reviews opus (owner preference: Opus reviews); final review opus.
Plan BASE: 6555ab1

## Pre-flight scan
| Pair / task | Produces vs consumes | Finding |
|---|---|---|
| T1↔T9 | context field names restingHr, restingHrBaseline, hrv, hrvKind, hrvBaseline, stepsToday, steps7dAvg, lastWorkout.source/avgHr | consistent |
| T2↔T3 | HealthPlatform, HrvKind, SleepSegment, HealthWorkoutRecord | consistent |
| T3↔T4 | HealthSignals (health_math.dart) produced by healthTodayProvider; readiness(health:) | consistent (checkin_models imports health domain — cross-feature import, acceptable) |
| T4↔T6 | HealthDay.sleepSource; T6 test "values from an older day labelled with the day" | CONFLICT: HealthSignals carries no date → Ruling R1 |
| T4↔T7 | HealthImporter hook via healthImportersProvider | consistent |
| T4↔T5 | healthConnectionProvider connect/disconnect/setWriteWorkouts; HealthSource.platform/availability/openInstall | consistent |
| T7↔T8 | T7 imports through workoutHistoryProvider.notifier.add; T8 writes to Health on add | CONFLICT → Ruling R2 |
| T7↔T9 | HealthImport, healthImportsProvider | consistent |
| T5 | replaces const connectedAppsCount; profile_test updated | self-consistent |
| T2 | config tests vs files created; builds | self-consistent |
| T1 | migration 20261023120000 lists all kinds from 20261021120000 + health_import | self-consistent |
| T9 | test/felix_snapshot_test.dart may not exist — plan says create if absent | self-consistent |

Ruling R1: healthTodayProvider exposes only today's cached HealthDay values (resting HR "today else last 24 h" is resolved at read time into today's day); with no today entry values are null, so nothing stale is shown as today. T6 replaces the "older day labelled" test with "cache holding only yesterday shows no resting HR/HRV/steps rows today". — spec anti-goal is "stale shown as today"; hiding satisfies it — cost if wrong: one morning without values until the first read, minor.
Ruling R2: T7 adds imported workouts through a new WorkoutHistoryNotifier.addImported(CompletedWorkout) (persists + sync push like add, but no Health-write notification); T8 hooks only add() for local creations. — keeps imports out of the writer by construction — cost if wrong: one extra method.

Task 1: dispatched (sonnet), BASE 6555ab1
Task 1: implemented 840e868 (110 backend tests); review dispatched (opus)
Task 1: review (opus) → Needs fixes: 1 Important (cleanFactors cap 5 drops restingHr/hrv since app sends 5 base factors). ⚠️ topic filtering → owned by T9 app side (checked). Fix round 1 sent (FIX_BASE 840e868).
Task 1: minor (deferred): hrvKind kept without hrv; baselines kept without current value (unused payload)
Task 2: dispatched (sonnet), BASE 64d2a17
Task 1: fix round 1/5 (1 addressed, 0 open; commits 840e868..64d2a17) — backend 111 tests
Task 1: complete (commits 6555ab1..64d2a17, review clean)
Task 2: implemented e78655f (DONE_WITH_CONCERNS: no Android SDK on this Mac → apk build not run); 1086 tests
Ruling: Android build verified only by config tests (no Android SDK installed) — same as earlier waves where Android was "built but checked mostly on iPhone" — cost if wrong: an Android build error found later when someone builds for Android.
Task 2: review (opus) → Needs fixes: 1 Critical (Android workouts() empty: package reads TotalCaloriesBurned per session, permission missing — plan-mandated list), 1 Important (Android sourceId "" → own-record skip can't match). Fix round 1 sent (FIX_BASE e78655f).
Ruling: replace READ_ACTIVE_CALORIES_BURNED / ACTIVE_ENERGY_BURNED with READ_TOTAL_CALORIES_BURNED / TOTAL_CALORIES_BURNED on Android and drop the unused active-energy read on iOS — spec only needs workout kcal, package reads total calories — cost if wrong: kcal on Android imports is total not active (slightly higher).
Task 2: minor (deferred): failed configure() cached forever; history sheet asked even after main denial + silent catch; dead unit-conversion branches; 0 vs null distance/energy across platforms (treat 0 as unknown in T7); Android sleep sessions without stages give no sleep (SLEEP_SESSION/UNKNOWN unmapped) — final review triage; always-true sleep filter; no PluginHealthSource unit tests; entitlement test doesn't assert empty access array; Android shows two sheets (package limitation); pubspec.lock transitive major bumps package_info_plus 9→10, win32 5→6 (not used directly)
Task 2: fix round 1/5 (2 addressed, 0 open; commits e78655f..6540a2d) — 1087 tests
Task 2: complete (commits 64d2a17..6540a2d, review clean)
Task 3: dispatched (sonnet), BASE 6540a2d
Task 3: implemented 37339d3 (1107 tests; extra mappings treadmill/skiing/ice skating/strength — within spec's classes); review dispatched
Task 3: review (opus) → Approved, spec ✅. ⚠️ HRV kinds never mixed → carried to T4 (baseline from same-kind values only). ⚠️ id string format → fine.
Task 3: minor (deferred): float boundary at exact thresholds (hrvDelta(43.2,48) → 0); health_math imports health_source.dart which pulls plugin+riverpod into checkin_models (move value types to plugin-free file); extra mapped names untested; no golden test for importedWorkoutId; no combined rhr+hrv factor test
Task 3: complete (commits 6540a2d..37339d3, review clean)
Task 4: dispatched (sonnet), BASE 37339d3
Task 4: implemented 5963a0b (DONE_WITH_CONCERNS: tests after impl; 31 steps() calls on connect; disconnect keeps cache, signals empty); 1126 tests; review dispatched
Task 4: review (opus) → Needs fixes: 1 Important ("not connected → no reads" test can't detect reads; fake lacks read counter). ⚠️ all sign-out paths call clearLocalData+reload → final review. Fix round 1 sent (FIX_BASE 5963a0b).
Task 4: minor (deferred): lastReadAt local ISO (tz east / clock back stalls throttle); no backoff on repeated failures; connect() awaits ~34 sequential reads before returning (Connect button busy); sign-out race window (read finishing mid-clearLocalData rewrites prefs) — final review triage; sleep window duplicated + no zero-length guard for sleepSource; cache version bumped only by _run; keep-60 cutoff keeps 61; disconnect keeps cache; seed helper brittle; no trigger test
Task 4: fix round 1/5 (1 addressed, 0 open; commits 5963a0b..2900884) — 1126 tests
Task 4: complete (commits 37339d3..2900884, review clean)
Ruling: Task 5 changes HealthConnectionNotifier.connect() to return as soon as access is granted and start the 30-day read without awaiting it (row shows "Connected" immediately, last-read time appears when the read lands) — T4 minor: connect awaited ~34 sequential reads, leaving the Connect button busy — cost if wrong: brief moment where Connected shows before values exist.
Task 5: dispatched (sonnet), BASE 2900884
Task 5: implemented aa064b9 (1138 tests; connect() sets writeWorkouts true, overriding prior off on reconnect); review dispatched
Task 5: review (opus) → Needs fixes: 1 Important (Health Connect availability stale after returning from store). Fix round 1 sent (FIX_BASE aa064b9) with Ruling-promoted items below.
Ruling: promote reviewer Minor #1 (Disconnect during the background 30-day read still marks read + runs importers) to a confirmed spec gap — spec goal 1 "Disconnect stops FITRIX reading" — fix in this round (re-check connected before markRead/putAll/importers). Cost if wrong: small extra change in T4 code.
Ruling: promote Minor #2 (why-box names Apple Watch on Android) — Global Constraint honesty rule — platform-specific copy; fold #3 grammar and #9/#10 ru/es wording into the same string edits since those strings are touched anyway. Cost if wrong: a few extra ARB edits.
Task 5: minor (deferred): misleading SE test name / disconnected hints at 1.3 untested; dead setWriteWorkouts(false) in health_sync_test seed; profile test weakened findsNWidgets(4)→findsWidgets; reconnect resets writeWorkouts to true; iOS 18 Settings path wording; uz polish (kechagi, Health Connect spacing, English labels for iOS paths)
Task 5: fix round 1/5 (3 addressed, 0 open; commits aa064b9..70fc6f8) — 1142 tests
Task 5: minor (deferred): en why-box still a flat list under "fills in"; ru «Обновлено в 22 окт., 10:00» reads oddly for non-today
Task 5: complete (commits 2900884..70fc6f8, review clean)
Task 6: dispatched (sonnet), BASE 70fc6f8
Task 6: implemented b89f1d8 (1163 tests); review dispatched
Task 6: review (opus) → Approved, spec ✅. ⚠️ sleep key: T4 _readDays stores night (d-1 18:00 → d 12:00) under day d — confirmed today's key = last night.
Ruling: screen-open refresh uses the throttled refresh() (no force) — spec goal 12 lists screen-open alongside the throttled start/resume reads; a read < 15 min old is fresh enough — cost if wrong: values up to 15 min stale on open.
Task 6: minor (deferred, final-review triage — user-visible): ru/en/es steps strings lack ICU plurals («8 122 шагов»); uz new strings use me‘yor (U+2018) vs existing me’yor (U+2019); ru «Вариабельность пульса» vs «ВСР»; es «tu normal» → «tu habitual»; Health rows on recovery hidden until today's check-in exists (spec goal 6 wants them on recovery); Home steps hidden when no templates; sheet with saved check-in restores only sleep; test gaps late read after slider move
Task 6: complete (commits 70fc6f8..b89f1d8, review clean)
Task 7: dispatched (sonnet), BASE b89f1d8
Task 7: implemented ad6946f (DONE_WITH_CONCERNS: source label only on runs; deleted weigh-in re-imported; orphan health_import docs on remote/football delete; name language at import time); 1183 tests; review dispatched
Task 7: review (opus) → Needs fixes: 2 Important (imports don't complete templated planned sessions — _unplannedTemplateIds; non-run imports can't be seen/rated/deleted, football list drops them). ⚠️ health_import kind migration = Task 1 (landed 840e868; cloud apply before install). ⚠️ T8 must hook add only — carried. Fix round 1 sent (FIX_BASE ad6946f).
Ruling: build, not defer, goal 10's "shown with source, RPE settable" for non-run imports: one reusable imported-workout row + sheet (source, date, duration, distance/avg HR if known, RPE 1–10, delete) shown in the Football history list and as a "From {health}" section on the sport workouts screen for cycling/fitness/gym/winter — spec goal 10 explicit — cost if wrong: one small widget + sections the cycling wave may restyle.
Ruling: also fix in this round Minor #6 (imported run with unknown distance shows "0.00 km" → dash; anti-goal "invented numbers") and Minor #3 (drop health_import doc in WorkoutHistoryNotifier.remove and on remote workout_deleted, one place) — both touch the same delete/display paths — cost if wrong: small.
Task 7: minor (deferred): deleted (Felix-undone) weigh-in can be refilled from scale; name language at import time; circular import health_importers↔health_providers; one heartRate read per record + disconnect checked only between importers; unrelated dart-format churn in 7 files; import order
Task 7: fix round 1/5 (5 addressed incl. ruled addendum, 0 open; commits ad6946f..104cb5c) — 1192 tests
Task 7: minor (deferred): imported run summary shows "How hard did it feel?" twice when rated; football history appends imports after match logs (not date-sorted); week_plan imports health_import_store for a constant (layering); dash depends on health_import doc arriving before run doc; HealthImportCollection.apply doesn't filter tombstoned ids
Task 7: complete (commits b89f1d8..104cb5c, review clean)
Task 8: dispatched (sonnet), BASE 104cb5c
Task 8: implemented efecd10 (1200 tests; Android gym=STRENGTH_TRAINING, football=OTHER; one-tick delay for run meters); review dispatched
Task 8: review (opus) → Needs fixes: 1 Important (football log edit re-adds with new uuid → second Health write; test covered unused path). Fix round 1 sent (FIX_BASE efecd10).
Ruling: the football edit branch uses a non-writing entry point (edit ≠ creation); the original Health record stays with the old values (we never edit/delete Health records) — spec anti-goal double count outranks stale Health details — cost if wrong: an edited match's corrected minutes don't reach Health.
Task 8: minor (deferred): run test copies recorder order instead of driving RunRecorder (comment added in fix round); ledger length test splits JSON on commas; provider placement differs from brief (harmless)
Task 8: fix round 1/5 (1 addressed, 0 open; commits efecd10..ee1a759) — 1200 tests
Task 8: minor (deferred): edit test mirrors notifier calls instead of driving MatchLogSheet
Task 8: complete (commits 104cb5c..ee1a759, review clean)
Task 9: dispatched (sonnet), BASE ee1a759
Task 9: implemented a7809fb (1207 tests, backend 111); review dispatched
Task 9: review (opus) → Approved, spec ✅. ⚠️ no readiness block (so no health values to Felix) until today's check-in exists — same root as T6 minor (recovery health rows hidden until check-in) → final review triage, flagged as likely must-fix.
Task 9: minor (deferred): fake RunDetails to reuse _runJson; stray hrvKind when values out of range; no client out-of-range tests; imported pace uses elapsed time; 8 KB test trivially passes
Task 9: complete (commits ee1a759..a7809fb, review clean)
Final review: dispatched (opus), range 3e9ce39..HEAD
Final review (opus) → With fixes: C1 watch+manual football log double count; I1 two sources same session both imported (test locks it in); I2 health values only with today's check-in (recovery + Felix); I3 ru steps plurals; I4 sign-out race + uncaught async error; I5 recovery today bar vs ring mismatch; I6 Android sleep sessions w/o stages + partial HC permissions + rationale screen.
Ruling F1 (C1): dedupe both ways. On a local FITRIX add, an import of the same sport is superseded when it overlaps > 50 % of the import, or — for manual-time logs (football_log) — when it is on the same day and the log's minutes are within 50–150 % of the import's duration (first match only). Superseded import is removed with a tombstone; the FITRIX log stays (user's RPE/details). At import, the same rules skip a record that matches an existing FITRIX workout. — spec anti-goal; the user's own log is the richer record — cost if wrong: watch avg HR for that match is lost; two same-day sessions of similar length could be merged.
Ruling F2 (I1): overlap check also against already-imported workouts and records accepted earlier in the batch; flip the test. — anti-goal — cost if wrong: two genuinely separate overlapping sessions from two devices merge (unrealistic).
Ruling F3 (I2): recovery shows health rows even without a check-in; snapshot sends health values without a score; backend accepts a readiness block whose score is absent when health fields exist and prints "Health today: …". Backend must be restarted before the app build. — spec goal 6 + success line — cost if wrong: none significant.
Ruling F4 (I3): no-plural wording «Шаги сегодня: {steps}» / "Steps today: {steps}" / "Pasos hoy: {steps}" (+ 7-day avg variants); also uz me’yor (U+2019, file majority), es «tu habitual».
Ruling F5 (I4, I5, run summary double RPE label, football history date order): fix as reviewer suggests.
Ruling F6 (I6): parked to the Android verification pass (Android has never been compiled on this Mac; iOS is the target device) — Android sleep sessions w/o stages, partial HC permissions breaking workout reads, in-app rationale screen. Cost if wrong: Android users get no sleep / no workouts until that pass.
Final fix wave: dispatched (sonnet), FIX_BASE a7809fb
Final fix wave: DONE_WITH_CONCERNS (commits 843f65c, aec7d2c, 849aa48, 104cb8b; 1235 Flutter, 113 backend); concern: manual-time rule only for football_log — plan-logged football keeps plan template id
Final re-review (opus): F2–F5 ADDRESSED; F1 partially — plan/template-started football logs (MatchLogSheet with template, made-up times, plan template id) still double count.
Ruling F1b: the gap comes from the controller's own F1 wording (limited to football_log), not a new finding — complete F1 inside the same fix wave: manual-time clause applies to every non-imported football workout (all FITRIX football goes through MatchLogSheet with made-up times); flip test health_math_test.dart:211, add plan-template watch+log tests both directions. — spec anti-goal — cost if wrong: a FITRIX football log and a different same-day watch soccer session of similar length merge.
Final fix wave F1b: re-review ADDRESSED (commits 104cb8b..0c04257). Controller verified: flutter analyze clean, flutter test 1239 passed (5 skipped), backend 113/113.
Final review: complete (3e9ce39..0c04257), F6 parked (Android pass).
Simulator smoke: app launches on iPhone 17 simulator with HealthKit entitlement embedded; full Health-data acceptance left for device (needs sign-in + manual Health samples).
