# Wave 2D+: Health Useful Without a Watch — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make Apple Health / Health Connect visibly useful for phone-only users: in-bed sleep fallback, steps-based calorie bonus, steps on Home and Progress, and a 7-day "From Health" summary.

**Architecture:** Extends wave 2D code in `lib/features/health/` (math, plugin source, daily store, providers), nutrition targets, Home, Progress and the Connected apps screen. No backend or migration changes.

**Tech Stack:** Flutter 3, Riverpod 2, `health` 13.3.2, intl.

**Spec:** `docs/superpowers/specs/2026-10-23-health-without-watch-design.md`

## Global Constraints

- Branch `redesign`; commits without `Co-Authored-By`; `export PATH="/Users/myxabzbzzzz/РАБОТА/flutter/bin:$PATH"`; `flutter analyze` clean; `flutter test -j 4` green (baseline 1239 passed, 5 skipped). Format only changed files. Don't stage `docs/fitrix-features.md`.
- Never run anything against the cloud Supabase project; never restart the live Felix server.
- Steps bonus: `stepsKcal = min(800, round(max(0, steps − 5000) × 0.04 × weightKg / 70))`; only when Health connected and today's steps known; added to kcal; carbs absorb it.
- In-bed fallback only when the night window has no asleep segment; awake never counts; label «in bed, from {source}».
- All new text en/ru/uz/es without plural-dependent wording (Uzbek o‘/g‘ U+2018, tutuq per file majority U+2019); `flutter gen-l10n`; generated files committed.
- iPhone SE 375×667 at text scale 1.3 without overflow for changed screens.

## Review Focus

- Not connected or steps unknown → nutrition targets identical to before (no bonus, no line).
- A night with both asleep and in-bed segments uses asleep only.
- Summary counts are labelled as last-7-days counts, never presented as today's values.
- Home steps tile and the removed Today-card steps line: no duplicate, no tile when steps unknown.

---

### Task 1: In-bed sleep fallback

**Files:** `lib/features/health/data/health_source.dart` (`SleepSegment` gains `bool inBed`), `plugin_health_source.dart` (SLEEP_IN_BED → inBed true, asleep false), `lib/features/health/domain/health_math.dart` (`({Duration sleep, bool inBed})? lastNightSleep(segments, today)` — asleep merged; if none, merged in-bed; keep `sleepLastNight` as a thin wrapper or replace its callers), `health_daily_store.dart` (`HealthDay.sleepInBed`, JSON `sleepInBed`), `health_providers.dart` (store it), `checkin_sheet.dart` (label), l10n, `test/support/fake_health_source.dart`, tests in `test/health_math_test.dart`, `test/health_checkin_test.dart`.

- [ ] Failing tests: in-bed 23:00–07:00 only → 8 h, inBed true; in-bed 23:00–07:00 + asleep 23:30–06:30 → 7 h, inBed false; awake segments never counted; check-in label «in bed, from Apple Health» when inBed.
- [ ] Implement; run tests; full suite; commit `Sleep from the iPhone sleep schedule (in bed) fills the check-in when there is no sleep data`.

### Task 2: Steps raise the calorie target

**Files:** `lib/features/nutrition/data/nutrition_targets.dart` (`targetsFor(..., int? stepsToday)`, `Targets.stepsKcal`), the provider that builds today's targets (find where `targetsFor` is called for today), nutrition screen / targets screen line, l10n, tests in the existing nutrition targets test file.

- [ ] Failing tests: 14146 steps at 94 kg → stepsKcal 491 and kcal = previous kcal + 491 (carbs absorb, protein/fat unchanged); 4000 steps → 0; 60000 steps → 800; null steps → identical Targets to today; not connected → no bonus (provider test with FakeHealthSource); nutrition screen shows the «+N kcal» line only with a bonus; SE ×1.3.
- [ ] Implement; run tests; full suite; commit `Steps from Health raise today's calorie target`.

### Task 3: Steps on Home and Progress

**Files:** `lib/features/home/presentation/screens/home_screen.dart` (steps tile outside the Today card; remove the Today-card steps line), Progress screen (find the Progress tab screen) + a small steps bar chart widget (reuse existing chart styling in Progress), `healthDailyStoreProvider` / a `stepsLast7Provider` in `health_providers.dart` (connected-gated, list of 7 `(day, steps?)` oldest→newest + average of known), l10n, tests.

- [ ] Failing tests: Home tile visible when connected + today's steps known, also with no plan/templates; hidden when not connected or unknown; no steps line left in the Today card; Progress chart shows 7 bars with unknown days empty (not zero) and the average; hidden when no day has steps; SE ×1.3 on Home and Progress.
- [ ] Implement; run tests; full suite; commit `Steps on Home and a weekly steps chart in Progress`.

### Task 4: "From Health" 7-day summary on the Connected apps screen

**Files:** `lib/features/profile/presentation/screens/connected_apps_screen.dart`, `health_providers.dart` (`healthSummaryProvider` → counts for the last 7 days: stepsDays, sleepNights, restingHrDays, hrvDays, weighIns, workoutsImported, workoutsWritten), weight importer (remember imported weigh-in day keys, prefs key e.g. `health_weight_imported_v1`, trimmed to 60 days), writer ledger (record write time per id, or keep a separate timestamp list, to count the last 7 days), l10n, tests in `test/connected_apps_test.dart` / `test/health_sync_test.dart`.

- [ ] Failing tests: counts from a seeded cache/imports/ledger; block only when connected; hint shown when all non-step counts are 0 (iOS text mentions Apple Watch, Android text does not); counts labelled "last 7 days"; SE ×1.3.
- [ ] Implement; run tests; full suite; commit `Connected apps shows what came from Health in the last 7 days`.
