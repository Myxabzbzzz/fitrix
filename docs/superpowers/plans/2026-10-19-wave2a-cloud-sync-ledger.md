# SDD ledger — plan: docs/superpowers/plans/2026-10-19-wave2a-cloud-sync.md

Pre-flight scan:
| pair | shared | finding |
|---|---|---|
| T1/T2 | user_documents columns | T2 Supabase store uses user_id,kind,doc_id,data,deleted,updated_at — matches T1 |
| T2/T3 | SyncedCollection, recordDocDeleted, collections | T3 consumes exactly T2 interface — ok |
| T2/T4 | SyncLocal.clear | T4 extends clear(); T2 must not remove existing clear behaviour — ok |
| T3/T4 | collections clear() | T4 relies on each adapter clear() from T3 — ok |
Each task self-consistent: yes.
Ruling: checkin swaps (checkin_swaps_v1) not synced — today-only, device-local session tweak — cost: swaps not shown on 2nd device same day.
Ruling: week_plan as single doc (LWW) — rarely edited on two devices at once — cost: concurrent edits lose one side.
Ruling: proceed without waiting for plan review — owner said go to wave 2; cloud apply still gated on explicit «да».
Task 1: dispatched (sonnet), BASE e828d74
Task 1: complete — commits 6851865 + e66b01c (controller: trigger before insert or update so clients cannot backdate updated_at); controller-reviewed migration (RLS own rows, no delete policy, cascade); supabase test db PASS
Task 2: dispatched (opus? no: sonnet), BASE e66b01c
Task 2: review r1 (opus) — changes needed: 2 critical (key-order hash churn; delete during push lost), 3 important (delete+recreate, per-kind cursor, first-sync clobber), 1 minor (fake store); file task-2-review-1.md
Ruling: first sync — remote wins for docs without agreed hash on a kind full pull — protects cloud data on new device — cost: an offline edit made before first sign-in on a fresh device for the same id loses
Ruling: parked r1 #6 (rejected doc retried), #8 (revert-after-skip) — low impact
Task 2: fix round 1 → resume implementer
Task 2: re-review r1 (opus) — 1,2,3,5,7 addressed, 4 addressed; NEW A important (quiet kind cursor pins shared fetch → full refetch each sync), B minor (full pull keeps never-agreed local doc over server deletion)
Task 2: fix round 2 → resume implementer (A + B)
Task 2: fix round 2 b32ae0b — controller re-review of diff: A (cursor = newest of whole response for kinds that merged) and B (never-agreed local loses to remote deletion on full pull) correct; tests 854
Task 2: complete — commits c6b3d2c 85dfb5c b32ae0b
Task 3: dispatched (sonnet), BASE b32ae0b
Task 3: review (opus) — spec ✅, changes needed: 1 important (week_plan dismissed non-list throws → cursor pinned), minors 2 (ping before write), 3 (doc content id vs doc id), 4 (singleton LWW felix_plans)
Ruling: fix 1,2,3; park 4 (union merge for felix_plans later) — cost: offline edits on 2 devices lose Felix badges on one side
Task 3: fix round 1 → resume implementer
Task 3: fix round 1 074da6c — controller re-review of diff: 1,2,3 addressed; tests 874
Task 3: complete — commits fd4ba67 074da6c
Task 4: dispatched (sonnet), BASE 074da6c
Task 4: implementer STOPPED by owner before any change (tree clean at 074da6c) — paused, awaiting owner
Task 4: done 5ff22e4 (restarted after accidental stop) — IT test vs local Supabase 2/2 pass; tests 875 (+5 skipped)
Task 4: complete — reviewed in final review
Final review: dispatched (opus), range d4a5... see package
Final review (opus): needs fixes — 1 important (sign-out wipes pending while text promises saved), minors 2 (pre-sign-in tombstones), 3 (deleteAccountBody), 4 (channels block each other), 5 (overlap refetch, rehash), 6 parked
Ruling: fix wave = 1,2,3,4; park 5 (temporary cost only)
Final fix wave: bc12ace (sonnet) — controller re-review: texts ok (ru plurals), tests 880 (+5 skipped), IT 2/2
Cloud: migration 20261019120000 NOT applied (remote empty) — awaiting explicit «да»
