# Wave 2A: Cloud Sync of Wave-1 Data — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Check-ins, food log, water, body weight, week plan, active program, performance profile (HR zones), nutrition settings and Felix-plan markers sync to the signed-in account, so they survive sign-out, reinstall and a second device.

**Architecture:** One generic server table `user_documents` (one row per small JSON document, keyed by `kind` + `doc_id`) and one generic sync channel in the existing `SyncEngine` (pull since cursor → merge → push dirty), next to the plans/history/chat channels. Each local store exposes its data as documents through a `SyncedCollection` adapter. A document is dirty when the hash of its local JSON differs from the hash both sides last agreed on; deletions are explicit tombstones recorded by the store, never inferred from absence (stores prune old days locally).

**Tech Stack:** Flutter 3, Riverpod 2, SharedPreferences, supabase_flutter, `crypto` (sha1), Supabase Postgres with RLS, pgTAP tests.

**Spec:** Owner request 2026-10-19 («переходи ко второй волне», cloud first — Claude's recommendation, owner agreed with "да"). Wave 1 rule: new data was local-only; this plan lifts that. The cloud migration is applied to the cloud project only after Муха's explicit «да» for that step; everything in this plan runs against local Supabase.

## Global Constraints

- Branch `redesign`; commits without `Co-Authored-By`; Flutter SDK `export PATH="/Users/myxabzbzzzz/РАБОТА/flutter/bin:$PATH"`; `flutter analyze` clean; `flutter test` green (baseline 832 passed, 4 skipped); backend untouched.
- Never run anything against the cloud project (`sfajspspziuvsoangivl`, env/cloud.json): no `supabase db push`, no `--linked`. Local Supabase only (`supabase migration up --local` from repo root, containers `supabase_*_fitrix` are running). Do not run `supabase db reset` (wipes local data) unless `migration up` cannot work, and say so.
- Local storage keys and formats stay as they are (`checkins_v1`, `food_log_v1`, `body_weight_v1`, `week_plan_v1`, `active_program_v1`, `performance_profile_v1`, `nutrition_settings_v1`, `felix_template_ids_v1`, `felix_plan_batches_v1`): sync reads and writes through the stores, it does not change what they store.
- With nobody signed in the app behaves exactly as now (local only, no network).
- Changes applied by sync never ping `LocalChanges` (sync must not trigger itself).
- All new user-visible text in en/ru/uz/es ARB files (Uzbek uses ‘ U+2018), `flutter gen-l10n`, never edit generated files.

## Review Focus

- A store pruning old days (check-ins 60 days, food log retention) must never delete those days on the server — only user deletions push tombstones. Test in Task 3.
- A document edited while its push is in flight stays dirty and is pushed again on the next run (compare against the hash that was pushed, not the current one). Test in Task 2.
- Another account signing in on the same device: the new collections are cleared with the rest (`SyncLocal.clear`) before the first pull. Test in Task 4.
- A pulled row with an unknown `kind`, `data` that fails the store's `fromJson`, or a newer app's extra fields: skipped or tolerated, never a crash, and it must not stop the rest of the sync. Test in Task 2 (unknown kind) and Task 3 (bad data).
- Felix weight Undo and food-entry delete push a tombstone, and a second device removes the item on its next pull. Test in Task 3.

---

### Task 1: `user_documents` table

**Files:**
- Create: `supabase/migrations/20261019120000_user_documents.sql`
- Create: `supabase/tests/user_documents_test.sql`

**Interfaces:**
- Produces: table `public.user_documents(user_id uuid not null references auth.users(id) on delete cascade, kind text not null, doc_id text not null, data jsonb, deleted boolean not null default false, updated_at timestamptz not null default now(), primary key (user_id, kind, doc_id))`; index on `(user_id, updated_at)`; trigger `user_documents_set_updated_at` using the existing `public.set_updated_at()`; check constraint `kind in ('checkin','food','water','weight','week_plan','program','performance','nutrition_settings','felix_plans')`; `char_length(doc_id) <= 100`; `pg_column_size(data) <= 65536`.
- RLS enabled; policies "Own documents: read/create/update" with `auth.uid() = user_id` (no delete policy: deletions are `deleted = true` rows).

- [ ] **Step 1: pgTAP test** in the style of `supabase/tests/content_shop_places_test.sql`: table and RLS exist; user A can insert/select/update own row; user A cannot select or update user B's row; insert with unknown kind fails; `updated_at` advances on update; deleting the auth user cascades.
- [ ] **Step 2: Migration** as in Interfaces.
- [ ] **Step 3: Apply locally and test:** `supabase migration up --local` then `supabase test db` — all pass.
- [ ] **Step 4: Commit.**

### Task 2: Document sync channel in the engine

**Files:**
- Create: `lib/core/sync/synced_collection.dart`, `lib/core/sync/doc_merge.dart`
- Modify: `lib/core/sync/remote_store.dart`, `supabase_remote_store.dart`, `sync_state.dart`, `sync_local.dart`, `sync_engine.dart`, `test/support/in_memory_remote_store.dart`
- Test: `test/doc_sync_test.dart`

**Interfaces:**
- Produces (`synced_collection.dart`):
  ```dart
  /// One kind of synced document. Docs are small JSON maps keyed by id.
  abstract class SyncedCollection {
    String get kind;                                  // one of the table's kinds
    Map<String, Map<String, Object?>> read();         // live local docs
    /// Applies pulled docs (null value = deleted on the server). Must update
    /// the UI state (notifiers) and must NOT ping LocalChanges. Docs the store
    /// cannot parse are skipped.
    void apply(Map<String, Map<String, Object?>?> docs);
    void clear();                                     // drop all local data of this kind
  }
  String docHash(Map<String, Object?> doc);           // sha1 hex of jsonEncode(doc)
  ```
- Produces (`remote_store.dart`): `class RemoteDoc { final String kind, docId; final Map<String, Object?>? data; final DateTime updatedAt; bool get isDeleted => data == null; }`; `RemoteStore.fetchDocs(String userId, {DateTime? since}) → Future<List<RemoteDoc>>`; `RemoteStore.upsertDocs(String userId, List<RemoteDoc> docs) → Future<Map<String, DateTime>>` keyed `'$kind/$docId'` (deleted docs are sent with `deleted: true, data: null`).
- Produces (`sync_state.dart`): `Map<String, String> docs` ('kind/docId' → agreed hash), `DateTime? docsCursor`, `Map<String, int> docTombstones` ('kind/docId' → ms when deleted), persisted in the same JSON (missing fields in old saved state = empty).
- Produces (`sync_local.dart`): `List<SyncedCollection> get collections` (empty list in this task; Task 3 fills it), and `void recordDocDeleted(String kind, String docId)` that adds a tombstone to SyncState and pings LocalChanges — stores call this on user deletions.
- Produces (`doc_merge.dart`): pure `DocMergeResult mergeDocs({required Map<String, Map<String,Object?>> local, required Map<String,String> agreed, required Set<String> tombstones, required List<RemoteDoc> remote})` for one kind, returning docs to apply and the new agreed hashes. Rules: a doc is dirty if `docHash(local) != agreed[id]` or it has a tombstone; remote changes apply only to non-dirty docs; a dirty doc keeps local (its push will overwrite the server — last writer wins).

- [ ] **Step 1: Failing tests** in `test/doc_sync_test.dart` with `InMemoryRemoteStore` and a fake collection:
  - first sync pushes all local docs, second sync pushes nothing;
  - remote change applied when local is clean, ignored when local is dirty, and the dirty doc wins on the server after the push;
  - tombstone: local delete → server row `deleted`, tombstone cleared; remote delete → `apply({id: null})`;
  - edit during push: doc changed between `upsertDocs` call and its completion stays dirty and is pushed on the next run;
  - remote row with unknown kind is skipped and the rest still applies;
  - `pendingCount()` includes dirty docs and tombstones;
  - agreed-hash entries for docs absent locally and without tombstone are dropped after a sync (map does not grow with pruned days), and that absence does NOT push a delete.
- [ ] **Step 2: Implement** `SyncedCollection`, `docHash`, `mergeDocs`, `RemoteDoc`, store methods (in-memory: keep a server clock that strictly increases; Supabase: `from('user_documents').select().eq('user_id', id).gt('updated_at', since).order('updated_at')`, `upsert(..., onConflict: 'user_id,kind,doc_id').select('kind,doc_id,updated_at')`, in chunks of 200), and engine steps `_pullDocs` / `_pushDocs` after the chat steps, following the existing pattern (one network wait, then `_checkDisposed()`, then synchronous re-read and save).
- [ ] **Step 3:** `flutter test test/doc_sync_test.dart test/sync_test.dart` pass; full `flutter test` and `flutter analyze` clean.
- [ ] **Step 4: Commit.**

### Task 3: Store adapters

**Files:**
- Create: `lib/core/sync/collections.dart` (or one `*_sync.dart` next to each store if it reads better — one adapter per store, each small)
- Modify: the stores/notifiers in `checkin`, `nutrition` (food log, water, nutrition settings), `progress` (body weight), `plan` (week plan), `programs` (active program), `profile` (performance), `workouts` (felix templates store), and `sync_local.dart` (`collections`).
- Test: `test/doc_collections_test.dart`

**Interfaces:**
- Consumes: Task 2 `SyncedCollection`, `SyncLocal.recordDocDeleted`, `localChangesProvider`.
- Documents (kind → doc ids → data):
  - `checkin`: one per day, id `dayKey(day)`, data = `CheckIn.toJson()`.
  - `food`: one per entry, id = `FoodEntry.id`, data = `FoodEntry.toJson()`.
  - `water`: one per day, id `dayKey`, data `{'ml': int}`.
  - `weight`: one per day, id `dayKey(at)`, data = `WeighIn.toJson()`.
  - `week_plan`: single id `current`, data = the store's whole JSON (`sessions` + `dismissed`).
  - `program`: single id `active`, data = `ActiveProgram.toJson()`; clearing the program = tombstone.
  - `performance`: single id `profile`, data = `PerformanceProfile.toJson()`.
  - `nutrition_settings`: single id `settings`, data = `NutritionSettings.toJson()`.
  - `felix_plans`: single id `state`, data `{'ids': [...], 'batches': {...}}` (the two existing keys).
- Rules: every user write pings `LocalChanges`; every user delete (food entry removed, weigh-in removed incl. Felix weight Undo, program cleared, day replaced → removed entries) calls `recordDocDeleted`; local retention pruning calls neither; `apply` writes through the store and refreshes the notifier the UI watches (`ref.exists` pattern from `SyncLocal.applyChat` where the provider may not be built); `clear()` empties the store's keys.

- [ ] **Step 1: Failing tests** per kind (round trip: user change → doc in fake remote; remote doc → visible through the provider the UI reads), plus: pruning an old check-in/food day pushes nothing; removing a food entry and Felix weight Undo push tombstones; a remote doc with malformed data is skipped without throwing and other docs still apply.
- [ ] **Step 2: Implement** adapters and wire them into `SyncLocal.collections`.
- [ ] **Step 3:** full `flutter test`, `flutter analyze` clean. **Step 4: Commit.**

### Task 4: Account switch, sign-out text, end-to-end check

**Files:**
- Modify: `lib/core/sync/sync_local.dart` (`clear()` also clears every collection), the 4 ARB files (`signOutAccountBody`), `test/sync_supabase_it_test.dart`, `README.md` (sync section).

- [ ] **Step 1: Failing test:** data of account A on the device, account B signs in → all new collections empty before B's pull; B's server docs then appear.
- [ ] **Step 2:** `clear()` clears collections. New `signOutAccountBody` (all 4 languages, same meaning): en "Everything you logged is saved to your account and will be removed from this device. Sign in with the same email to get it back." ru «Всё, что вы записали, сохранено в аккаунте и будет удалено с этого устройства. Войдите с той же почтой, чтобы вернуть данные.» uz and es: faithful translations. If the sign-out dialog shows pending unsynced changes elsewhere, keep that behaviour.
- [ ] **Step 3:** Extend `test/sync_supabase_it_test.dart` (gated by its existing env flag) with a two-device doc round trip against local Supabase: device 1 saves a check-in, food entry and weigh-in, device 2 (fresh prefs, same user) gets them; device 2 deletes the food entry, device 1 loses it. Run it locally with the flag and local Supabase; report the result.
- [ ] **Step 4:** README: one paragraph on what syncs now. Full `flutter test`, analyze. **Step 5: Commit.**
