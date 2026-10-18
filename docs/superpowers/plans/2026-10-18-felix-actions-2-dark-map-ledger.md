# SDD ledger — plan: docs/superpowers/plans/2026-10-18-felix-actions-2-dark-map.md

Preflight: T2 and T3 both edit chat_action.dart/apply/card → sequential (fine). T2 adds WorkoutPlanAction.when/days parsing that T3 consumes. T3 reuses plan rules from lib/features/plan. T4 independent. T5 controller.
- Ruling 1: start after wave-1 final fix lands (same branch, avoid concurrent commits).
Task 1: dispatched (base 2c621a2, sonnet) — backend only, runs alongside wave-1 final re-review (read-only)
- Ruling 2: Task 2 also fixes the wave-1 residual: replace-running-workout dialog copy (Discard, not Finish) — see wave-1 ledger Ruling 14.
Task 1: implemented ab9a907 (74 backend tests); review dispatched
Task 2: dispatched (base ab9a907, sonnet) while Task 1 review runs (reviewer read-only; Task 2 touches lib/ only)
Task 1: complete (commits 2c621a2..ab9a907, review clean)
Task 1: minor (deferred → check in Task 5 live test): fallback recall — QUESTION veto on что/как/what anywhere; verbless phrasing ("на обед был плов 300г", "на завтрак два яйца") and "ел" not detected; plan wins over food when both; stale \b comment
Task 2: implemented f51ebb2 (795 tests); review dispatched. Pre-existing: FelixChatScreen header overflows at 1.3 text (ledger for wave 2)
Task 2: review → Needs fixes: 2 Important (set-weight blocked without base; matchFood ties/oats dry). Fix round 1 sent (FIX_BASE f51ebb2).
Task 2: minor (deferred): partial apply on mid-loop exception; stale appliedResult after Undo; app_en.arb whitespace churn
Task 2: fix round 1/5 (2 addressed, 0 open; commits f51ebb2..1c1b515)
Task 2: complete (commits ab9a907..1c1b515, review clean after 1 fix round)
Task 2: minor (deferred): cooking-word strip maps fried potatoes/rice to boiled/plain (under-estimates); "oat milk" → cooked porridge (wrong food); dead q.contains('oats')
Task 3: dispatched (base 1c1b515, sonnet)
Task 3: implemented 50603df (811 tests; flaky profile_wave1_test once); review dispatched (opus)
Task 4: dispatched (base 50603df, sonnet) in parallel with Task 3 review (map files only)
Task 4: implemented e4a321e (816 tests); review dispatched
Task 3: review (opus) → Needs fixes: 2 Important (no My workouts badge/entry + Open to hub; spread uses all-time sessions). Fix round 1 sent (FIX_BASE e4a321e — note Task 4 commit sits between; fix diff will be e4a321e..HEAD).
- Ruling 3: Task 3 minors #3 (edit_workout_sheet delete keeps Felix id) and #4 (undo without batch duplicates templates on re-tap) ruled into fix round 1 — data integrity, one-liners — cost if wrong: none.
Task 3: minor (deferred): partial apply leaves templates if weekPlan.addAll throws; double check mark; day chips shown when when==null / missing Today chip; magic numbers (cell height, radius 12, icon sizes); spread fallback order differs from programs' defaultWeekdays
Task 4: complete (commits 50603df..e4a321e, review clean)
Task 4: minor (deferred): no dedicated metro-casing test; preview.png not re-rendered (matrix identical)
Task 5 (controller) live test on qwen3:8b: ru weight → no action (+ dishonest "я обновил" + English leak); plans lack when/days and use Russian/made-up exercise names; "ikki tuxum" → 1 egg; food_log ru/uz OK; question → no action OK.
Task 1: reopened — live-test fix round sent to original implementer (weight fallback, honesty copy, server-side when/days inference, catalog exercise names in prompt, count→grams examples). FIX_BASE = HEAD at dispatch; runs concurrently with Task 3 fix round (backend vs lib — disjoint files).
Task 3: fix round 1/5 (4 addressed, 0 open; commits e4a321e..d0bb36b)
Task 3: complete (commits 1c1b515..d0bb36b excl. e4a321e map commit, review clean after 1 fix round)
Task 3: minor (deferred): flaky animations_test / profile_wave1_test in full runs
Task 1: live fix round (5 addressed; commits d0bb36b..d98bff5) — complete; model-dependent parts PARTIAL by nature
Task 1: minor (deferred): weight fallback false positives ("I'm lifting 80 kg", "вес штанги 80 кг") — user must tap; exercise-names.json manual copy, no sync test; looksLikePlan widened (tested); "2 яйца и 3 яйца" first count
FINAL REVIEW: dispatched (opus) over 2c621a2..d98bff5
FINAL REVIEW: Yes after fixes — 3 Important + rulings (sign fix, today>week, undo msg, old-card undo, oat milk, double check, uz Felix) → final-findings.md; one fix dispatch (opus), FIX_BASE d98bff5
- Ruling 4: weight-sign correction, today-over-week, dedicated undo error, hiding undo on legacy cards and uz name fix ruled into the final fix wave — user-visible correctness on the exact phrases the owner will try — cost if wrong: a few lines.
FINAL FIX: a7d54c0 (backend), 697d784 (app) — 84 backend / 830 flutter, build OK; scoped re-review dispatched
FINAL FIX re-review: all 10 addressed. Plan COMPLETE (2c621a2..697d784). Installed on iPhone in place (devicectl) 2026-10-18 21:40; backend restarted (401 without token).
