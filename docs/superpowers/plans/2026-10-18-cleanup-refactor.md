# Cleanup and Refactor Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove dead code and stale files, and refactor duplicated logic and oversized files, with no change in app behaviour.

**Architecture:** Pure refactor of the Flutter app (`lib/`, `test/`) and the Node backend (`backend/`). Each task removes or moves code and keeps every remaining test green. No new features, no UI changes, no data format changes.

**Tech Stack:** Flutter 3 (Riverpod 2, go_router 14, ARB l10n en/ru/uz/es via `flutter gen-l10n`), Node backend (`node --test`).

**Spec:** Owner request (2026-10-18): «сделать рефакторинг проекта и очистить от мертвого кода и лишние и ненужные файлики убрать». Evidence: the dead-code audit (copied to the plan workspace as `audit.md`). Owner decisions: design/ removed (done in 561cbff); docs: one up-to-date README + QUICKSTART, CODE_DOCUMENTATION.md and finished plans removed, ledgers kept.

## Global Constraints

- No behaviour change visible to the user: same screens, texts, colours, routes, stored data keys (SharedPreferences keys, JSON field names) and backend responses.
- Flutter SDK: `export PATH="/Users/myxabzbzzzz/РАБОТА/flutter/bin:$PATH"`. `flutter analyze` must report "No issues found". `flutter test` all green (baseline 830; only tests of deleted code may disappear — state the new count and which tests went).
- Backend: `cd backend && npm test` all green (baseline 84).
- Generated l10n files (`lib/l10n/app_localizations*.dart`) are never edited by hand: edit the 4 ARB files and run `flutter gen-l10n`. Keep the 4 ARB files with identical key sets.
- Never touch `env/cloud.json`, `supabase/migrations/`, signing files.
- Commits on branch `redesign`, no `Co-Authored-By` line, one or more commits per task, messages in English describing the result.
- Match the surrounding code's style, comment density and naming.

## Review Focus

- A token or helper consolidated into one place must return exactly the same value as each copy it replaces (colours: same ARGB in light and dark; day keys: same string format, local date not UTC).
- Moving widgets between files must keep their keys (`Key('...')`) used by tests and keep `const` constructors.
- Deleting ARB keys: a key only reached through an extension or string interpolation is NOT dead (audit section 4 lists 43 such keys) — only the 29 listed keys go.
- Renamed test files must still run (`flutter test` picks up `*_test.dart` under test/).
- `backend/start.sh` must not print or log secrets from env/cloud.json.

---

### Task 1: Remove dead code

**Files:**
- Delete: `lib/features/progress/presentation/widgets/progress_chart.dart` and its test groups (`test/animations_test.dart` group 'charts' using ProgressChart, `test/progress_nutrition_test.dart` group 'ProgressChart').
- Modify: `progress_widgets.dart` (`thisWeekStart`), `nutrition/data/micronutrients.dart` (`microUnit`), `core/constants/app_constants.dart` (`chatEndpoint`, `appName`, `appSubtitle1`, `appSubtitle2`), `core/sync/sync_engine.dart` (`isDisposed`), `chat/presentation/providers/chat_provider.dart` (`clearMessages`), `map/routing/graph.dart` (`inMain`), `progress/domain/progress_math.dart` (`strengthLevel` if it is a thin wrapper over `strengthInfo` — move its test to `strengthInfo`).
- Modify: the 4 ARB files — delete the 29 keys listed in audit section 4 (and their `@key` blocks); run `flutter gen-l10n`.
- Modify: `pubspec.yaml` — remove `cupertino_icons`; run `flutter pub get`.
- Delete: `backend/test-request.json`.

Keep (ruling): `syncStatusProvider` (wave 2 cloud sync will show status), `LanguageNotifier.isSaved`, `resetChatDocsDir` (mark `@visibleForTesting`).

- [ ] Delete each item; after each group run `flutter analyze`.
- [ ] `flutter test` and `cd backend && npm test` green; report test count delta.
- [ ] Commit.

### Task 2: One colour system

**Files:** `lib/core/theme/app_colors.dart` (delete), `app_palette.dart`, `app_theme.dart`, every file using `AppColors.` (about 50 references in 5–10 files, see `grep -rn "AppColors\." lib test`).

- [ ] Map every used `AppColors.*` value to an existing `AppPalette` token with the same ARGB for that theme; where none exists, add a token to AppPalette (light and dark) with the exact old value.
- [ ] Replace all usages, delete `app_colors.dart`, keep `test/theme_tokens_test.dart` meaningful (update it to AppPalette).
- [ ] Pin with a test: for each replaced pair, the new token's light and dark values equal the old constants (write the old hex values into the test).
- [ ] analyze + test green; commit.

### Task 3: Shared helpers instead of copies

**Files:**
- Create `lib/core/time/day_key.dart`: `DateTime dayOf(DateTime t)` (local midnight) and `String dayKey(DateTime t)` with the exact current format; replace the private `_day`/`_dayKey` copies in `checkin/data/checkin_models.dart`, `checkin/data/checkin_store.dart`, `nutrition/data/food_log_store.dart` (and any other identical copy you find with `grep -rn "_dayKey\|DateTime _day(" lib`).
- One name normaliser `String normalizeName(String)` (= `trim().toLowerCase()`, check each copy is exactly that) in `lib/core/text/normalize.dart`, used by `progress_math.dart liftKey`, `training_math.dart _key`, `live_log_widgets.dart:248`, `checkin_models.dart:161`.
- `_ProgramCard` (discover_screen.dart:313, programs_screen.dart:313): if identical or near-identical, one public `ProgramCard` in `lib/features/programs/presentation/widgets/program_card.dart`; if they differ visibly, keep both and say why.
- `_ExerciseRow` (program_detail_screen.dart:380, workout_complete_screen.dart:410): same rule.
- `_snack` (felix_chat_screen.dart:123, shop_screen.dart:58): one `showAppSnack(BuildContext, String)` in `lib/core/widgets/` if identical.
- Tests: unit tests for `dayOf`/`dayKey` (midnight, 23:59, DST-free local date) and `normalizeName`.

- [ ] Do each consolidation with analyze + targeted tests after it; full `flutter test` at the end; commit.

### Task 4: Split oversized files

**Files:** `lib/features/workouts/presentation/widgets/live_log_widgets.dart` (1084 lines), `lib/features/chat/presentation/screens/felix_chat_screen.dart` (689), `lib/features/plan/.../week_plan_screen.dart` (688), `about_me_screen.dart` (622), `sign_in_screen.dart` (622).

- [ ] Move self-contained widget classes into sibling files under the feature's `presentation/widgets/` so every one of these files ends under 500 lines. Pure moves: no logic change, same class names (private classes that move become public only if they must cross files; prefer keeping a private class with its only user).
- [ ] Update imports; analyze + full test green; commit.

### Task 5: Tidy tests

**Files:** `test/`.
- [ ] Shared overflow helper in `test/support/overflow.dart` (pump at iPhone SE size 375×667 with given text scale and assert no overflow exception) and use it in the 4+ files that repeat that test; keep each test's name.
- [ ] Merge `felix_actions_test.dart` + `felix_actions_2_test.dart` into topic files (e.g. `felix_actions_parsing_test.dart`, `felix_actions_cards_test.dart`) without losing any test.
- [ ] Rename `*_wave1_test.dart` files to feature names (`navigation_test.dart`, etc.; if the name exists, merge or pick a distinct feature name).
- [ ] Test count unchanged (except Task 1 removals); commit.

### Task 6: Backend scripts and docs

**Files:** `backend/start.sh`, `backend/package.json`, `backend/README.md`, `README.md`, `QUICKSTART.md`, `CODE_DOCUMENTATION.md` (delete), `docs/superpowers/plans/2026-10-13-*.md` and `2026-10-18-wave1-training-core.md`, `2026-10-18-felix-actions-2-dark-map.md` (delete; keep the two `*-ledger.md`).

- [ ] Rewrite `backend/start.sh` to the real start: read `SUPABASE_URL` from `../env/cloud.json` (if present, with `node -e` or a JSON parse, never echo secrets), warn if Ollama is not running or `qwen3:8b` not pulled (`OLLAMA_MODEL` override), then `exec node server.js`. Mention it in QUICKSTART.
- [ ] `package.json` description: no stale model names. backend/README: fix stale facts (model, endpoints) against server.js — do not invent.
- [ ] README.md: current state of the app (features list matching lib/features, how to run: QUICKSTART link, tests, phone install in place with `xcrun devicectl device install app` and why not `flutter install`), remove references to CODE_DOCUMENTATION.md. Plain English, concise.
- [ ] Commit.
