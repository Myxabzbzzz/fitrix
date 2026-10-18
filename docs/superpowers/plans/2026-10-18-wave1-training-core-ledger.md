# SDD ledger — plan: docs/superpowers/plans/2026-10-18-wave1-training-core.md

Spec: clickable prototype design/clickable/ (+ screens_text.txt). Branch: redesign (in place, main untouched).

## Preflight scan
| Pair / task | Produces → consumes | Finding |
|---|---|---|
| T1→T2 | sessionLoad → CompletedWorkout.load | ok |
| T1→T3 | suggestNextKg, e1rm, volumeKg, recordsIn, catalog → live log | ok |
| T2→T3 | rpe/warmup/restSeconds/note/sessionRpe → notifier, complete screen | ok |
| T3↔T6 | kExerciseLibraryReady flag hides +Exercise/Swap until T6 | ok, T6 removes it |
| T1→T4 | catalog → sparingSwaps needs exercise→BodyArea mapping | GAP: catalog has no BodyArea field → Ruling 2 |
| T4↔T5 | T4 needs today's planned session, T5 comes later | ok: plan gives fallback (first gym template) |
| T1→T5 | catalog → loadsLegs (legs/glutes primary) | ok |
| T7→T8 | Sex, PerformanceProfile → targetsFor | ok (T7 before T8) |
| T8→T9 | Goal enum, targets screen route → kcalAdjustment, "Update my targets" | ok |
| T7↔T9 | both write profile weight via profile repository | ok, same repo |
| T5→T10 | replaceFutureGym → start program | ok |
| T1→T10 | allRecords, e1rm → startKg | ok; 82.5×9 → 80 verified |
| T1 self | e1rm(82.5,9)=107.25→107.3 ✓; 72.5×8=91.83 ✓; 7×86=602 ✓ | ok |
| T4 self | 80+8−12+4+3−5=78 ✓; sleep 7.5h good: 5+round(0.5×6)=8 ✓ | ok; test wording "not loading back or legs" vs sore={legs} → Ruling 3 |
| T7 self | karvonen(56,194) Z1 125–139 ✓; friel Z1 high 146 vs "Z5a 172–176" with "high exclusive" | conflict → Ruling 4 |
| T8 self | bmr 1790, tdee 3088, kcal 3400, P141 F78 C534 ✓ | ok |
| T9 self | (0.3+0.15)×1100=495 → round to 10 = 500 (Dart round half away from zero) ✓ | ok |
| Global vs skill | plan: "workers do not commit"; SDD: implementer commits | → Ruling 1 |

## Rulings
- Ruling 1: implementers commit their own task on `redesign` (no Co-Authored-By line, owner rule) — the SDD review package needs per-task commits — cost if wrong: none, commits are local, can be squashed.
- Ruling 2: exercises.json gets `"loads": [BodyArea names]` per exercise (legs/back/chest/arms/shoulders), Task 1 adds `List<String> loads` to ExerciseInfo; Barbell row loads back+legs; Chest-supported row loads back only — sparingSwaps needs it and Task 1 owns the JSON — cost if wrong: a field to rename later.
- Ruling 3: sparingSwaps replacement must load none of the SORE areas; test: sore={legs} → Barbell row → a similar exercise whose loads exclude legs (e.g. Chest-supported row) — the spec screen shows exactly that swap — cost if wrong: small test change.
- Ruling 4: HrZone.high is exclusive and equals the next zone's low for all zones. Friel display: Z1 "< high", middle zones "low–(high−1)", last "≥ low"; tests: friel Z1.high==146, Z5a low 172 displayed "172–176". Karvonen displays "low–high" as in the mock (125–139, 139–153) — matches the mock for both methods — cost if wrong: display tweak.
Task 1: dispatched (base 60117a0, sonnet)
Task 1: implemented c7f837a (DONE_WITH_CONCERNS: pill counts computed from data; warmup test deferred to T2); review dispatched
Task 1: complete (commits 60117a0..c7f837a, review clean)
Task 1: minor (deferred): recordsIn bodyweight branch compares reps against weighted past sets (weighted dips edge)
Task 1: minor (deferred): burpees grouped as core
- Ruling 5: carried into Task 2 — suggestNextKg returns null when best working kg is 0 (bodyweight), skips warm-ups; _isWorking gains !warmup; add names/aliases-unique catalog test — reviewer minors 2–4 touch exactly Task 2's field — cost if wrong: trivial.
Task 2: dispatched (base c7f837a, sonnet)
Task 2: implemented c43ed66 (sync unchanged: unionById keeps local); review dispatched
Task 2: complete (commits c7f837a..c43ed66, review clean)
Task 2: minor (deferred): askFelix draft overwrites typed text; sync test at unionById level not engine level; circular imports workout.dart<->training_math.dart, ask_felix<->felix_chat_screen
- Ruling 6: carried into Task 3 — copyWith cannot clear nullable rpe/restSeconds/note; Task 3 adds a way to clear them if its UI needs it (e.g. clearRpe flag) — Task 3 owns the first caller — cost if wrong: trivial.
Task 3: dispatched (base c43ed66, sonnet)
Task 3: implemented 7bbfa85 (concern: mini bar visible under complete screen); review dispatched (opus)
Task 3: review (opus) → Needs fixes: 2 Important (stale KG/REPS after warm-up/swap/remove; rest timer pauses when bar unmounted). Fix round 1 sent to implementer (FIX_BASE 7bbfa85).
Task 3: minor (deferred): mini bar editable under complete screen; _save saves CompletedWorkout.from(active) not confirmed summary; stale fallback
Task 3: minor (deferred): _save no re-entry guard (duplicate save risk)
Task 3: minor (deferred): system back/swipe on complete screen leaves pending workout set
Task 3: minor (deferred): _selected stores index → stale after reorder/remove
Task 3: minor (deferred): live_log_widgets.dart 1,080 lines — split RPE sheet / set table
Task 3: minor (deferred): warm-up check announced "Set 0 done"
Task 3: minor (deferred): copy "Felix uses it to plan…" claims unbuilt feature (honesty rule) — wire in Task 11 or change copy
Task 3: minor (deferred): rest bar ad-hoc alpha colours; dead addExercises(const []) placeholder
Task 3: fix round 1/5 (2 addressed, 0 open; commits 7bbfa85..80c6e29)
Task 3: complete (commits c43ed66..80c6e29, review clean after 1 fix round)
Task 4: dispatched (base 80c6e29, sonnet)
- Ruling 7: Task 4 swaps are stored with today's check-in (date-scoped) and applied to a copy when starting from Recovery; the user's saved template is never mutated — editing a saved plan from a soreness tweak would be a surprise — cost if wrong: swap not visible in My workouts (acceptable).
Task 4: implemented 54ba382 (concern: todayCheckInProvider no midnight rollover while open); review dispatched
Task 4: review → Needs fixes: 1 Important (no midnight rollover while app open). Fix round 1 sent (FIX_BASE 54ba382).
- Ruling 8: shared `lib/core/time/today_provider.dart` (clockProvider + todayProvider updating on resume and at local midnight) introduced in Task 4 fix; Tasks 5/8 must watch todayProvider for "today" — one day source instead of per-feature rollover code — cost if wrong: small refactor.
- Ruling 9: swaps auto-apply on check-in save (with Undo) accepted — prototype ci2 shows "I swapped … Undo" — cost if wrong: one default flip.
Task 4: minor (deferred): today's readiness drifts after a same-day hard workout (live hardDays) vs frozen past bars
Task 4: minor (deferred): DST-fragile `subtract(Duration(days:n))` in checkin_store/models/recovery_screen
Task 4: minor (deferred): one corrupt check-in entry wipes history on next save
Task 4: minor (deferred): _save uses ref after awaits (sheet may be disposed)
Task 4: minor (deferred): test gaps (retention loose, greetings only morning, 1.3 test without swap card); bare numeric sizes
- Ruling 10: midnight timer lives in DayRollover widget mounted in MaterialApp.router builder (not in the provider) — provider-owned Timer broke widget tests with pending-timer errors — cost if wrong: none functionally.
Task 4: fix round 1/5 (1 addressed, 0 open; commits 54ba382..876c37f)
Task 4: complete (commits 80c6e29..876c37f, review clean after 1 fix round)
Task 4: minor (deferred): fix commit includes unrelated dart-format reflows in ~15 files; SportWorkoutsScreen uses widget.now() not todayProvider
Task 5: dispatched (base 876c37f, sonnet)
Task 5: implemented cf1c6d8; review dispatched (opus)
Task 5: review (opus) → Needs fixes: 2 Important (sessions beyond Sunday invisible; suggestion misses pair with first session yesterday). Fix round 1 sent (FIX_BASE cf1c6d8).
- Ruling 11: week plan shows a "Next week" section up to today+6; "Plan my week" seeds next week's Mon/Wed/Fri when none remain this week, plus an empty-state card with Add session — add sheet offers today+5 and today is Sunday, the strict reading made adds invisible — cost if wrong: one extra section.
Task 5: minor (deferred → carry to Task 10): replaceFutureGym drops today's done gym session
Task 5: minor (deferred): loadsLegs/suggestPlanChange default templates = built-ins (make required); only first suggestion computed; todaysGymTemplateProvider falls back after today's gym done; CoachCard title '' sentinel; Start logic duplicated from sport_workouts_screen; 1px margin; test gaps (lazy list not scrolled in SE test, Home plan card, weekend seed); stale doc comment home_screen.dart:228
Task 5: minor (deferred): Home Today card falls back to first template on rest/done days
Task 5: fix round 1/5 (2 addressed, 0 open; commits cf1c6d8..2c9b590)
Task 5: complete (commits 876c37f..2c9b590, review clean after 1 fix round)
Task 5: minor (deferred): planEmptyBody copy says "rest of this week" when seeding next week / no gym templates
Task 6: dispatched (base 2c9b590, sonnet)
Task 6: implemented 40df61c (no RED evidence — tests written after); review dispatched
Task 6: review → Needs fixes: 2 Important (crash on empty workout in picker; back gesture leaves sheet folded). Fix round 1 sent (FIX_BASE 40df61c), raw index→clamped folded into #1.
Task 6: minor (deferred): quick-workout focus hardcodes English Sport.gym.label; workoutMenuSimilar/NoSimilar keys maybe unused; no real-router ordering test; malformed query no test; change-since compares first vs latest
Task 6: fix round 1/5 (2 addressed, 0 open; commits 40df61c..1e5f001)
Task 6: complete (commits 2c9b590..1e5f001, review clean after 1 fix round)
Task 7: dispatched (base 1e5f001, sonnet)
Task 7: implemented 8e7f8a5 (added LTHR field; Friel Z5b/Z5c per rounding ruling); review dispatched
Task 7: complete (commits 1e5f001..8e7f8a5, review clean — 0 Critical/Important)
Task 7: minor (deferred → Task 11 honesty sweep): connectedAppsWhyBody / connectedAppsFooter claim features that don't exist yet (also Task 3 "Felix uses it to plan…")
Task 7: minor (deferred): edit profile reports success when base save failed; async _load can clobber typed input; thin SE/1.3 tests (Friel tab, lazy rows); hardcoded "20:31" hint
Task 8: dispatched (base 8e7f8a5, sonnet)
Task 8: implemented 1532131 (added warning/success palette tokens; micros from memory); review dispatched (opus)
Task 8: review (opus) → Needs fixes: 1 Important (Felix meal plan slot detection English-only). Fix round 1 sent (FIX_BASE 1532131).
Task 8: minor (deferred): light warning/success contrast ~3.1–3.6:1 on tile; hardcoded "g"/"mg"/"mcg" units vs localized ARB; kcal tolerance loosened max(15%,10kcal) (USDA-genuine); training-hours window 29 days; ring/macro no entrance fill; dinner idea not re-evaluated across 15:00 while open; complete-profile card flashes & duplicated ×3; over-target shows "goal reached"; non copies fortified white-bread calcium; dinner-idea tests thin
Task 8: fix round 1/5 (1 addressed, 0 open; commits 1532131..39b51d4)
Task 8: complete (commits 8e7f8a5..39b51d4, review clean after 1 fix round)
Task 8: minor (deferred): mixed meal plans can duplicate a slot; "comida" broad
Task 9: dispatched (base 39b51d4, sonnet)
Task 9: implemented 124e0e8 (removed strengthFrom/old ProgressScreen tests; new MultiLineChart); review dispatched (opus)
Task 9: review (opus) → Needs fixes: 2 Important (strength level substring matching → wrong standards; off-track card contradicts headline). Fix round 1 sent (FIX_BASE 124e0e8), alias-split lift grouping folded into #1.
Task 9: minor (deferred): recordEntries recomputed every build (memoise); niceRange clamped bottom breaks grid, chart labels not localized; pace line "flat" for declines; _WeightSheet._saving not reset on error; radius literals; dead code (thisWeekStart, ProgressChart only in tests, old ARB keys); untested week/streak/lift helpers; records month headers no year; "+0 kg" records; balance bar 4 zones vs 3 labels; saveProfile flicker vs saveWeight; bodyweight-exercise rep charts no longer shown anywhere; Felix insight by band only
Task 9: fix round 1/5 (2 addressed, 0 open; commits 124e0e8..b0bb27e)
Task 9: complete (commits 39b51d4..b0bb27e, review clean after 1 fix round)
Task 10: dispatched (base b0bb27e, sonnet)
Task 10: implemented 66689ee; review dispatched (opus)
Task 10: review (opus) → Needs fixes: 3 Important (leg day after football + false copy; "At home" program needs barbell; Start vs Now measure mismatch). Fix round 1 sent (FIX_BASE 66689ee).
Task 10: minor (deferred): deadlift progresses at upper rate (group=back); deload/volume copy promises periodization not applied, nextIncrease during deload; "Picked for you" overclaims on fallback, 'pro' keyword matches "improve"; replaceFutureGym from today not from start date (gap before program); templates pile up on restart + id collision; detail week vs actual schedule on off-Monday start; misnamed start test; _start no error handling; "top set" header; pre-start "started" text; no finished state; clash lookahead 14 days; program summaries English-only
Task 10: fix round 1/5 (3 addressed, 0 open; commits 66689ee..7046e92)
Task 10: complete (commits b0bb27e..7046e92, review clean after 1 fix round)
- Ruling 12: Task 11 implementer also does the honesty sweep of copy that promises unbuilt features (ledger minors from Tasks 3, 7, 10) — global honesty rule; cheaper in one pass than in the final fix wave — cost if wrong: a few ARB strings. Phone install (Task 11 step 4) is done by the controller after the final review, not by the worker.
Task 11: dispatched (base 7046e92, opus)
Task 11: implemented b336e6c..6df0df7 (circle_reveal guard fix; sign-out copy warns local data is deleted); review dispatched
- Ruling 13: Gym "Reschedule → plan" tap waived — controller's dispatch said "if such a control exists"; the plan is reachable from the Home Today card and My workouts "This week" — cost if wrong: one small button later.
Task 11: complete (commits 7046e92..6df0df7, review: 0 Critical, 1 Important waived by Ruling 13)
Task 11: minor (deferred): routing test asserts path not rendered widget; "my first Gym workout" capitalization; whole Today card tappable; tune icon for program detail link; Discover bell + Discover Ask Felix without draft (not wave 1)
FINAL REVIEW: dispatched (opus) over 60117a0..6df0df7
FINAL REVIEW: Yes after fixes — 2 Important + 3 triaged items → final-findings.md; one fix dispatch (opus), FIX_BASE 6df0df7
FINAL FIX: done fde3d8d..fdb356f (777 tests, build OK); scoped re-review dispatched
FINAL FIX re-review: all 5 addressed; new Important: replace-running-workout dialog says "Finish current workout?" but discards logged sets (start_workout.dart, gymFinishCurrentTitle/Body).
- Ruling 14: no second fix wave (per process) — the dialog copy fix ("Discard current workout?" / "won't be saved" / "Discard and start", en/ru/uz/es) is carried into Felix-actions-2 Task 2's dispatch so it is reviewed there — real data-loss honesty issue, must ship in the next phone build — cost if wrong: one more build with misleading copy.
Wave 1: COMPLETE (60117a0..fdb356f). Deferred minors remain in this ledger for wave 2.
