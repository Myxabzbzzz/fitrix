# SDD ledger — plan: docs/superpowers/plans/2026-10-20-felix-hub.md

Spec: owner request 2026-10-19 «давай felix-хаб» → «начинай» (no questions) + clickable prototype mock_felix.html; plan decisions are Claude's calls.

Pre-flight scan:
| pair / task | shared | finding |
|---|---|---|
| T1/T3 | context JSON schema | T3 toJson must emit T1 schema; readiness.label = ReadinessLabel names (ready/trainLight/rest), factors = ReadinessFactorKey, today.status = TodayKind names, band = AcwrBand names — all match code |
| T2/T3 | AssistantTopic.forSport / ids | match |
| T2/T4 | topic title getters, FelixChatScreen header | CONFLICT: T2 removes title/subtitle/menuLabel getters but header + drawer still need text until T4/T5 |
| T2/T5 | topicTitle | match |
| T3/T5 | FelixSnapshot fields | match |
| T4/T5 | felix_chat_screen.dart | sequential, T5 after T4 — ok |
| T1 self | tests vs impl | consistent |
| T2 self | migration + per-topic push + l10n | consistent |
| T3 self | empty-input test vs today.status | consistent (unplanned only) |
| T4 self | tab re-tap uses goBranch initialLocation | consistent with main_shell |
| T5 self | chips/prompt tests | consistent |
Ruling: T2 adds ARB `felixChatTitle` ("Felix · {topic}") and uses it in the chat header; drawer uses topicTitle; header subtitle shows topicSubtitle until T5 replaces it with felixSees* — T2 must leave the app compiling without the removed getters — cost if wrong: a header string changes twice.
Task 1: dispatched (sonnet), BASE 9508543
Task 1: implemented 5a06da6 (92 backend tests); review dispatched
Task 1: review (opus) — spec ✅, quality approved, 0 Critical/Important
Task 1: minor (deferred): topic paragraph wording odd for nutrition/recovery ("user's nutrition training", "nutrition questions are fine too"); positive change8wKg without + (use signed()); cleanDate accepts 2026-02-31; weekday w/o date lowercase; band kept without acwr but not shown; 8 KB check counts UTF-16 chars; factor-cap test asserts <=5 not exact
Task 1: complete (commits 9508543..5a06da6, review clean)
Task 2: dispatched (sonnet), BASE 5a06da6
Task 2: implemented c270c37 (DONE_WITH_CONCERNS: tests written after impl, no RED run; header title/subtitle ellipsized) — 888 tests; review dispatched
Task 2: review (opus) — spec ✅, quality approved, 0 Critical/Important
Task 2: minor (deferred): app greeting list duplicated (chat_provider.dart unreachable copy vs ChatRepository._appGreeting); ru/es/uz greeting capitalised topic mid-sentence ("Давай поговорим: Питание."); tests written after impl; App assistant last in temp drawer (by design); offline push = one failing request per topic
Task 2: NOTE before cloud push: verify cloud constraint name is chat_messages_topic_check (migration drops it without if exists) — dry-run first
Task 2: complete (commits 5a06da6..c270c37, review clean)
Task 3: dispatched (sonnet), BASE c270c37
Task 3: implemented b80cf4e (DONE_WITH_CONCERNS: load.last7 = sum, acwr 2dp, food sent when entries or water, change8w = latest-earliest in 56d, onboarding sends context too; no RED run) — 895 tests; review dispatched
Task 3: review (opus) — spec ❌ (cross-task), 2 Important: (1) band sent without acwr is dropped by backend describeContext; (2) ACWR range is 0..6 (6·sum7/sum42) but backend accepts 0..5 → recovery loses acwr+band in first week. 5 minors.
Ruling: fix both in backend/prompt.js (Task 1 code) in Task 3's fix round — describeContext prints band alone; acwr range 0..6 + test with 6.0 — the defect is the cross-task contract, cheapest at the receiver — cost if wrong: none (backend-only, tested)
Task 3: minor (deferred): water-only logging sent as "0 kcal eaten"; old weigh-in sent as current weight without date; no test of provider/chat_provider wiring; no RED run; onboarding chat sends context too
Task 3: fix round 1 → resume implementer (FIX_BASE b80cf4e)
Task 3: fix round 1/5 (2 addressed, 0 open; commits b80cf4e..35c228d) — backend 94 tests
Task 3: complete (commits c270c37..35c228d, review clean after 1 fix round)
Task 4: dispatched (sonnet), BASE 35c228d
Task 4: implemented 126b72b (906 tests; added felixDraftTopicProvider, push navigation, greeting helper moved to lib/core/time/greeting.dart); review dispatched
Task 4: review (opus) — spec ❌, 1 Important: Ask Felix draft lost when the same topic's chat was opened from the hub with push (go to same location builds a new page; offstage old screen consumes + clears draft). 6 minors.
Ruling: today line skips today's own non-gym session when picking "next" — keep (avoids showing the same session twice) — cost: none
Ruling: hub intro copy "…in one chat" → "…in one place" (en; ru/uz/es equivalents) — hub now has nine chats, plan copy was taken from the prototype — cost: one string
Task 4: minor (deferred): chatTime DST edge; next-session window includes same weekday next week ("Football on Tuesday" on Tuesday); recent preview blank for streaming/failed/photo-only last message; ask_felix_test.dart:112 vacuous assertion; felix_hub_test.dart:221 fragile .last finder; redundant key app_router.dart:513
Task 4: fix round 1 → resume implementer (FIX_BASE 126b72b)
Task 4: fix round 1/5 (2 addressed, 1 new open — guard strands draft when same-topic chat opened via go sits offstage, repeat Ask: no retry when tab becomes visible; commits 126b72b..8905aba)
Task 4: fix round 2 → resume implementer (FIX_BASE 8905aba)
Task 4: fix round 2/5 (1 addressed, 0 open; commits 8905aba..dc60718) — 908 tests
Task 4: minor (deferred): pending draft replaces text the user already typed (pre-existing behaviour)
Task 4: complete (commits 35c228d..dc60718, review clean after 2 fix rounds)
Task 5: dispatched (sonnet), BASE dc60718
Task 5: implemented 1e718cd (DONE_WITH_CONCERNS: chips/prompts scroll horizontally on SE; adjusted felix_chat_style_test + felix_actions_cards_test invalidations; translations need native check) — 914 tests; review dispatched
Task 5: review (opus) — spec ✅, quality approved, 0 Critical/Important; felix_actions_cards_test change = test artefact (all app writes go through notifiers)
Task 5: minor (deferred): snapshot watched in whole-screen build (rebuilds message list); hint "Ask Felix about app assistant" for app topic + ru "Феликса" vs Latin Felix; inaccurate test comment + redundant targetsProvider invalidation; no test for chips updating after a card is applied; no test that prompt stays out of other topics; third prompt off-screen on SE (scrolls)
Task 5: complete (commits dc60718..1e718cd, review clean)
Final review: dispatched (opus) over 9508543..HEAD
Final review (opus): ready after fixes — 1 Important (hub next-session horizon includes today's weekday next week, felix_hub_screen.dart:32), must-fix minors: app-topic hint "Ask Felix about app assistant"; unsigned positive weight change (prompt.js:506); live-check: action blocks still produced despite "You cannot change the plan or logs yourself" line
Ruling: fix wave = Important + 2 code minors; live-check item done by controller at deploy; other minors wait (listed in final-review.md) — cost if wrong: small cosmetic items ship
Final review: real SupabaseRemoteStore swallows 23514 check violations (skips rows, no throw) — new topics stay pending silently until migration; harmless if migration applied before install
Final fix: dispatched (sonnet), FIX_BASE 1e718cd
Final fix: done 89f52fb (916 Flutter tests, 95 backend); scoped re-review: all 3 addressed, no new breakage; ru naming inconsistency "Феликса" vs "Felix" → native-speaker pass
Controller verify: flutter analyze clean; flutter test 916 passed / 5 skipped; backend 95/95
Wave 2B: COMPLETE (9508543..89f52fb). Pending owner «да»: backend restart via start.sh, cloud migration 20261020120000 (dry-run, check constraint name), iPhone install; live check incl. Nutrition "I had 2 eggs and toast" → food card, Gym "build me a 3-day split" → plan card, existing chats under Recent chats
