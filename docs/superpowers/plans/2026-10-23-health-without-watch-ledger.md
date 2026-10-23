# SDD ledger — plan: docs/superpowers/plans/2026-10-23-health-without-watch.md
Spec: docs/superpowers/specs/2026-10-23-health-without-watch-design.md (4 items approved by owner in chat; numbers Claude's calls)
Implementers sonnet; reviews opus.
## Pre-flight scan
| Pair / task | Produces vs consumes | Finding |
|---|---|---|
| T1↔T4 | HealthDay.sleepInBed / sleep counted as nights with sleep | consistent (in-bed nights count as sleep nights) |
| T2↔T3 | both read today's steps via health providers | consistent, independent files |
| T3↔T4 | stepsLast7Provider vs healthSummaryProvider both in health_providers.dart | same file, sequential tasks — no conflict |
| each task | tests vs files | self-consistent |
Task 1: dispatched (sonnet), BASE edb4093
Task 1: implemented 2a75ed4 (1246 tests); review dispatched
Task 1: review (opus) → Approved. ⚠️ consumers read HealthDay.sleep (check-in prefill → saved check-in → readiness/Felix) — confirmed no other caller of the math.
Task 1: minor (deferred): sleepLastNight dead in lib; nightSegments computed twice per day; no in-bed+awake overlap test; no HealthDay JSON round-trip test; es «en cama» tighter
Task 1: complete (commits edb4093..2a75ed4, review clean)
Task 2: dispatched (sonnet), BASE 2a75ed4
Task 2: implemented bda0c6d (1253 tests); review dispatched
Task 2: review (opus) → Needs fixes: 1 Important (ru «({steps} шагов)» plural-dependent). ⚠️ targets screen line (brief listed it) — Ruling: add a «+N kcal for steps today» note on the targets screen so its kcal agrees with the ring — brief text — cost: one line. Fix round 1 sent (FIX_BASE bda0c6d).
Task 2: minor (deferred): null-steps test compares only kcal; nutrition_screen watches healthTodayProvider twice; pump helper default connected:true changes old tests' env
Task 2: fix round 1/5 (2 addressed, 0 open; commits bda0c6d..f0ddcd1) — 1254 tests
Task 2: complete (commits 2a75ed4..f0ddcd1, review clean)
Task 3: dispatched (sonnet), BASE f0ddcd1
Task 3: implemented 9309724 (1260 tests; implementer saw progress_screen change on disk — controller checked diff: only steps hunk); review dispatched
Task 3: review (opus) → Needs fixes: 2 Important (Home tile lacks 7-day average — spec goal 2; "no plan" test doesn't clear templates). Fix round 1 sent (FIX_BASE 9309724).
Task 3: minor (deferred): Today-card descendant check could pass vacuously; stale lowercase 'steps' assertions; progress_widgets imports health_providers for StepsWeek; weekday label overflow untested in other locales
Ruling: Home tile uses healthTodayProvider.steps7dAvg (excl. today) — one '7-day avg' number across the app — cost: none
Task 3: fix round 1/5 (2 addressed + avg ruling, 0 open; commits 9309724..558b3db) — 1261 tests
Task 3: complete (commits f0ddcd1..558b3db, review clean)
Task 4: dispatched (sonnet), BASE 558b3db
Task 4: implemented f4aacb2 (1270 tests); review dispatched
Task 4: review (opus) → Needs fixes: 1 Important (weigh-in count remembers sample days even when import skipped). ⚠️ new prefs keys on sign-out — AppSession wipes all prefs (verified in wave 2D). Fix round 1 sent (FIX_BASE f4aacb2) + wording (ru ВСР, uz fixes) since those strings are touched.
Task 4: minor (deferred): ledger-version refresh untested; saved-by-write-time vs imported-by-start-day bases; import cycle health_providers↔health_writer + workouts coupling; SE test English only; disconnect test drags fixed 800px
Task 4: fix round 1/5 (3 addressed incl. {health} placeholder, 0 open; commits f4aacb2..98b8e22) — 1271 tests
Task 4: complete (commits 558b3db..98b8e22, review clean)
Final review: dispatched (opus), range edb4093..98b8e22
Final review (opus) → With fixes: I1 Progress "Daily average" includes today's partial day ≠ Home 7-day avg. Minors: hint vanishes after FITRIX writes/scale weigh-ins; new ledger writes lack mayWrite guard; targets steps row repeats number; Felix lacks stepsKcal; no Home SE test with tile. Deferred list: nothing must-fix.
Ruling FF1: Progress average = completed days only (exclude today), same definition as Home/recovery — one number across the app.
Ruling FF2: "No watch data" hint condition = no sleep, resting HR, HRV or imported workouts in 7 days (watch-type data), ignoring FITRIX-saved workouts and scale weigh-ins — spec wording was too literal; intent is "no watch" — cost: none.
Ruling FF3: add mayWrite guards before the new ledger writes; targets row label "Steps today: S" with "+N" value; Home SE ×1.3 test with the tile. Felix stepsKcal parked (needs backend whitelist + restart; can wait).
Final fix wave: dispatched (sonnet), FIX_BASE 98b8e22
Final fix wave: re-review ADDRESSED (98b8e22..d12ffc5). Final review complete.
