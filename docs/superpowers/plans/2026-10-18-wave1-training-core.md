# FITRIX Wave 1: Training Core Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the new FITRIX screens that run on data the app already has or can keep on the device: morning check-in and recovery, week plan, the redesigned live log and workout summary, exercise library, training programs, nutrition with a food base, progress and load, profile with heart-rate zones. Everything works offline with no Supabase migration.

**Architecture:** New features live under `lib/features/<feature>/{data,domain,presentation}` next to the existing ones. Pure Dart domain code (training math, readiness, plan rules, nutrition targets, HR zones) is unit-tested apart from widgets. New local data is stored in SharedPreferences, one store class per feature, following `NutritionStore` / `WorkoutStorage`. Reference data ships as bundled JSON in `assets/data/`. Screens use the existing token layer (`AppPalette`, `AppSpacing`, `AppRadius`, `AppText`) and the widgets in `lib/core/widgets/`.

**Tech Stack:** Flutter 3, Riverpod 2 (StateNotifier style used in the repo), go_router 14, shared_preferences, intl.

**Spec:** the clickable prototype https://claude.ai/artifact/KT3rbQmjvzqPureqJqRC7c. Its source is `design/clickable/`. Each screen is `design/clickable/<mock_file>.html#s<index>`. All screen copy is in `design/clickable/screens_text.txt`. To see a screen, take a screenshot: `node design/penpot-import/screen_shot.js <mock_file> <index> /tmp/x.png`, then open the PNG. Taps between screens are in `design/penpot-import/build_clickable.py` (`R`).

**Out of scope (wave 2+):**
- Felix hub with 9 topics, per-topic recent chats and share sheet (`mock_felix`).
- Running, cycling, football and winter modules with GPS (`mock_running`, `mock_cycling`, `mock_football`, `mock_winter`).
- Watch integrations (Garmin, Strava, WHOOP, Apple Health).
- Supabase sync of the new local data.

## Global Constraints

- Flutter SDK: `/Users/myxabzbzzzz/РАБОТА/flutter/bin/flutter`, not on PATH. Prefix commands with `export PATH="/Users/myxabzbzzzz/РАБОТА/flutter/bin:$PATH";`.
- Work on branch `redesign`. Workers do not commit; the orchestrator commits after review. No `Co-Authored-By` line (owner rule).
- **No Supabase migrations in this wave.** New fields that the server schema lacks stay local.
  - Example: session RPE on a completed workout lives in local JSON only.
  - Sync must never drop a local-only field when it merges a server copy.
- **Colors** come only from `AppPalette` (light and dark). No `Color(0x…)` or `Colors.*` in screens except `Colors.transparent`.
- **Spacing** comes only from `AppSpacing`, **radii** only from `AppRadius`, **text styles** only from `AppText`.
- **UI copy** is English in `lib/l10n/app_en.arb`. Every new key also gets ru, uz and es values **in the same task**, because `test/l10n_test.dart` requires every key in every language.
  - Uzbek o‘/g‘ use U+2018.
  - Run `flutter gen-l10n` after editing ARB files. Never hand-edit `lib/l10n/generated/`.
  - Exercise and food names from the bundled JSON are data, not ARB keys.
- **Units:** metric only (kg, cm, km, kcal, L).
- **Numbers:** thousands separator from `NumberFormat.decimalPattern(locale)`.
- **Motion:** respect `MediaQuery.disableAnimations`; durations ≤ 400 ms; use the `Motion.curve` easing.
- **Copy rule:** never show invented personal data.
  - The prototype's numbers (Temur, 78.4 kg, 82.5 × 9…) are examples.
  - Screens compute from the user's own history, profile and logs.
  - Empty states say what to do, for example "Log a workout to see your load".
- **Honesty rule:** a control with no working feature behind it is not drawn. A "Connect" button is the only exception: it opens a sheet saying "Coming in a later update".
- **Do not touch:** `lib/l10n/generated/app_localizations_uz.dart` (local modification), `backend/server.log`, `supabase/.env`, `supabase/.temp/`.
- **Every screen task** adds a widget test that pumps the screen at iPhone SE size (375×667) and at textScaler 1.3, then asserts `tester.takeException()` is null.

## Review Focus

1. **Brand-new user** with no history, no check-in, no weight log and no plan. Every new screen renders a useful empty state, never a crash, NaN, "0.0 kg" record or divide-by-zero.
   - Pinned by the "empty" tests in Tasks 1, 4, 5, 6, 8, 9, 10.
2. **Workouts saved by older app versions** have no `rpe`, `warmup` or `sessionRpe`. They load, sync and count with documented defaults: session RPE missing means it is estimated as 6 and marked "estimated".
   - Pinned in Tasks 2 and 9.
3. **A server copy without the local-only fields** replaces a local completed workout during sync. Local `sessionRpe` and per-set `rpe` survive.
   - Pinned in Task 2.
4. **Day boundaries.** The check-in, today's plan and water/food log follow the device's local calendar day. Overnight they roll to a new empty day, and history stays readable.
   - Pinned in Tasks 4, 5, 8.
5. **Profile fields missing** (no age, height or sex). Nutrition targets and HR zones show a "complete your profile" prompt with a link to Edit profile, not wrong numbers.
   - Pinned in Tasks 7 and 8.

---

## File Structure

```
assets/data/exercises.json            exercise library (≥ 60 entries)
assets/data/training_programs.json    5 programs
assets/data/foods.json                food base (≥ 80 foods, ≥ 15 Uzbek dishes)
lib/features/workouts/domain/training_math.dart      e1RM, load, fitness/fatigue/form, records, progression
lib/features/workouts/data/models/workout.dart       + rpe, warmup, restSeconds, note, sessionRpe
lib/features/workouts/presentation/widgets/active_workout_sheet.dart   live log redesign
lib/features/workouts/presentation/widgets/rest_timer.dart            rest timer controller + bar
lib/features/workouts/presentation/widgets/exercise_menu_sheet.dart
lib/features/workouts/presentation/screens/workout_complete_screen.dart
lib/features/exercises/data/exercise_catalog.dart     ExerciseInfo + loader
lib/features/exercises/presentation/{exercise_library_screen,exercise_detail_screen,add_exercise_screen}.dart
lib/features/checkin/{data/checkin_store.dart, domain/readiness.dart, presentation/checkin_sheet.dart, presentation/recovery_screen.dart, presentation/checkin_card.dart}
lib/features/plan/{data/week_plan_store.dart, domain/plan_rules.dart, presentation/week_plan_screen.dart, presentation/add_session_sheet.dart}
lib/features/programs/{data/program_catalog.dart, data/program_store.dart, presentation/programs_screen.dart, presentation/program_detail_screen.dart, presentation/start_program_sheet.dart, presentation/program_progress_screen.dart}
lib/features/nutrition/data/{food_catalog.dart, food_log_store.dart}, domain/{nutrition_targets.dart, micronutrients.dart}, presentation/screens/{nutrition_screen.dart (rewrite), add_food_screen.dart, food_detail_screen.dart, micronutrients_screen.dart, targets_screen.dart}
lib/features/progress/data/body_weight_store.dart, presentation/screens/{progress_screen.dart (rewrite), training_load_screen.dart, records_screen.dart, lift_detail_screen.dart, body_weight_screen.dart}
lib/features/profile/data/performance_store.dart, domain/hr_zones.dart, presentation/screens/{profile_tab_screen.dart (restyle), hr_zones_screen.dart, edit_profile_screen.dart, connected_apps_screen.dart}
lib/core/felix/ask_felix.dart          open Felix with a topic and a prefilled draft
test/<feature>_test.dart               one test file per task
```

Routes (all under the Home branch unless noted; constants in `AppRouter`):
- `/home/plan`
- `/home/checkin/recovery`
- `/home/workouts/exercises`, `/home/workouts/exercises/:id`, `/home/workouts/exercises/add`
- `/home/workouts/complete`
- `/home/programs`, `/home/programs/:id`, `/home/programs/active`
- `/home/nutrition` (existing), `/home/nutrition/add`, `/home/nutrition/food/:id`, `/home/nutrition/micros`, `/home/nutrition/targets`
- `/home/progress` (existing), `/home/progress/load`, `/home/progress/records`, `/home/progress/lift/:name`, `/home/progress/weight`
- Profile branch: `/me/zones`, `/me/edit`, `/me/apps`

---

### Task 1: Training math and exercise catalog (Sonnet)

**Files:**
- Create: `lib/features/workouts/domain/training_math.dart`, `lib/features/exercises/data/exercise_catalog.dart`, `assets/data/exercises.json`
- Test: `test/training_math_test.dart`, `test/exercise_catalog_test.dart`

**Interfaces — Produces:**
```dart
double e1rm(double kg, int reps);                 // Epley kg*(1+reps/30); reps<=1 → kg; reps==0 → 0
int sessionLoad(int rpe, Duration duration);      // rpe × whole minutes (AU)
double volumeKg(Iterable<Exercise> exercises);    // Σ kg×reps of done, non-warmup sets
class DailyLoad { final DateTime day; final int load; }
class LoadSummary { final double fitness; final double fatigue; final double? form; final double? acwr; final AcwrBand? band; }
enum AcwrBand { low, sweetSpot, risky }           // <0.8, 0.8–1.3, >1.3
LoadSummary loadSummary(List<DailyLoad> days, DateTime today);
//   fatigue = mean daily load over the 7 days ending today (missing days = 0)
//   fitness = mean daily load over the 42 days ending today
//   form = (fitness − fatigue) / fitness, null when fitness == 0
//   acwr = fatigue / fitness, null when fitness == 0
class PersonalRecord { final String exercise; final DateTime date; final double value; final double previous; final RecordKind kind; }
enum RecordKind { e1rm, reps }                    // reps = bodyweight exercise (all sets 0 kg)
List<PersonalRecord> recordsIn(CompletedWorkout workout, List<CompletedWorkout> earlier);
List<PersonalRecord> allRecords(List<CompletedWorkout> history);   // chronological, every PR ever set
double? suggestNextKg(List<WorkoutSet> lastSets); // all last working sets hit their reps (done) → best kg + 2.5; else best kg; null if none
double roundToPlate(double kg);                   // nearest 2.5
```
```dart
enum MuscleGroup { chest, back, shoulders, arms, legs, glutes, core }
enum Equipment { barbell, dumbbell, cable, machine, bodyweight, kettlebell }
class ExerciseInfo { id, name, MuscleGroup group, List<String> primary, List<String> secondary, Equipment equipment, String pattern, String level, bool compound, List<String> steps, List<String> mistakes, List<String> similar /*ids*/ }
class ExerciseCatalog { static Future<ExerciseCatalog> load(AssetBundle bundle); List<ExerciseInfo> get all; ExerciseInfo? byName(String name); ExerciseInfo? byId(String id); List<ExerciseInfo> similarTo(ExerciseInfo e); }
final exerciseCatalogProvider = FutureProvider<ExerciseCatalog>(...);
```
`byName` matches case-insensitively and also matches the aliases in the JSON (`"aliases": ["Squat"]` on Back squat).

- [ ] **Step 1: Write failing tests.**
  - `e1rm(82.5, 9)` rounds to 107.3; `e1rm(72.5, 8)` rounds to 91.8; `e1rm(100, 1) == 100`.
  - `sessionLoad(7, Duration(minutes: 86)) == 602`.
  - `loadSummary`:
    - 42 days of load 469 with the last 7 at 390 gives fatigue 390.
    - Form is (fitness − fatigue)/fitness, and the band follows acwr.
    - An empty list gives fitness 0, with form, acwr and band all null.
  - `recordsIn`:
    - The first ever session of an exercise is NOT a record.
    - A higher e1RM is.
    - Bodyweight uses reps.
    - Warm-up sets are ignored.
  - `suggestNextKg`: `[70×8 done ×4]` gives 72.5; one set short gives 70.
  - Catalog test:
    - The JSON loads with ≥ 60 entries and unique ids.
    - Every `similar` id exists.
    - Every exercise name in `WorkoutCatalog.defaults` resolves via `byName`.
- [ ] **Step 2: Run** `flutter test test/training_math_test.dart test/exercise_catalog_test.dart`. Expected: FAIL.
- [ ] **Step 3: Implement.**
  - `exercises.json` covers every group, with the equipment counts the library pills show.
  - Steps and mistakes are short imperative English. Copy Bench press from `mock_checkin_library` screen 4.
  - Add `assets/data/exercises.json` under the existing `assets/data/` entry (already declared).
- [ ] **Step 4: Run the tests.** Expected: PASS. Then run `flutter analyze`. Expected: no issues.

### Task 2: Workout model fields, sync safety, Ask Felix helper (Sonnet)

**Files:**
- Modify: `lib/features/workouts/data/models/workout.dart`, `lib/core/sync/sync_merge.dart` (or wherever completed workouts are merged), `lib/features/chat/presentation/screens/felix_chat_screen.dart`
- Create: `lib/core/felix/ask_felix.dart`
- Test: `test/workout_model_fields_test.dart`, `test/ask_felix_test.dart`

**Interfaces — Produces:**
- `WorkoutSet`: `+ int? rpe` (1–10), `+ bool warmup` (default false).
- `Exercise`: `+ int? restSeconds`, `+ String? note`.
- `CompletedWorkout`: `+ int? sessionRpe`, `+ int get load` = `sessionLoad(sessionRpe ?? 6, duration)`, `+ bool get loadEstimated` = `sessionRpe == null`.
- All of these go through `copyWith`, `toJson` and `fromJson`. Old JSON without them still loads.
- `CompletedWorkout.from(active, finishedAt, {int? sessionRpe})` drops warm-up sets from `setCount`, and records exclude them.
- `void askFelix(BuildContext context, WidgetRef ref, {required AssistantTopic topic, required String draft})`:
  - selects the topic (`selectedAssistantTopicProvider`);
  - sets `felixDraftProvider` (a new `StateProvider<String?>`);
  - goes to `AppRouter.felix`.
- `FelixChatScreen` puts a non-null draft into its text field once, then clears the provider. It does not auto-send.

- [ ] **Step 1: Write failing tests.**
  - Round-trip JSON with the new fields.
  - Old JSON (copy one from `test/sync_test.dart` fixtures) loads with null and false defaults.
  - Merging a server `CompletedWorkout` (no sessionRpe, no rpe) over a local one with the same id keeps the local `sessionRpe` and the per-set `rpe`.
  - `askFelix` opens the Felix tab with the draft in the field and the topic selected.
- [ ] **Step 2: Run them.** Expected: FAIL.
- [ ] **Step 3: Implement.**
  - The server shape in `supabase_remote_store.dart` stays as it is. Per-set `rpe` and `warmup` ride inside the `exercises` jsonb (already free-form).
  - `sessionRpe` is never sent.
  - The merge keeps local `sessionRpe` when the remote one is null.
- [ ] **Step 4: Run** `flutter test` (whole suite, 437+). Expected: PASS. Then `flutter analyze`.

### Task 3: Live log and workout complete (Sonnet, Opus review)

**Spec screens:**
- `mock_plan_log` 2 (live log), 3 (exercise menu + RPE picker), 4 (workout complete).
- Taps: `R['pl2']`, `R['pl3']`, `R['pl4']`.

**Files:**
- Modify: `lib/features/workouts/presentation/widgets/active_workout_sheet.dart` (expanded state = live log), `lib/features/workouts/presentation/providers/workouts_provider.dart`
- Create: `rest_timer.dart`, `exercise_menu_sheet.dart`, `lib/features/workouts/presentation/screens/workout_complete_screen.dart`
- Test: `test/live_log_test.dart`

**Interfaces:**
- **Consumes:** Task 1 (`suggestNextKg`, `e1rm`, `volumeKg`, `recordsIn`, `ExerciseCatalog`) and Task 2 fields.
- **Produces:**
  - `ActiveWorkoutNotifier`:
    - `setRpe(exerciseIndex, setIndex, int rpe)`, `addWarmupSets(exerciseIndex)`, `removeExercise(i)`, `moveExercise(from, to)`, `replaceExercise(i, String name)`, `addExercises(List<String> names)`, `setNote(i, String)`, `setRest(i, int seconds)`.
    - `finish({int? sessionRpe})` returns the `CompletedWorkout`.
  - `RestTimerController` (ChangeNotifier):
    - `start(Duration)`, `add(Duration)`, `skip()`, `remaining`, `next` label.
    - Default rest is `exercise.restSeconds ?? 120`.
    - It starts when a working set is ticked done.

**Behavior:**
- **Header:** workout name, elapsed time (existing `ElapsedTimeText`), "Set x of y · n t lifted", and a progress bar. Warm-ups are excluded from counts and tonnage.
- **Exercise cards:**
  - Done exercises collapse to one row with "best …" and a PR chip when `recordsIn` finds one.
  - The current exercise is expanded with a table: SET / PREVIOUS / KG / REPS / RPE / ✓.
  - The warm-up row is labelled "W".
  - The Felix line uses `suggestNextKg` from the last completed workout containing that exercise. It is hidden when there is no history.
  - Upcoming exercises collapse.
- **Exercise menu sheet** ("…"):
  - Swap exercise opens the add-exercise screen in replace mode (Task 6). Until Task 6 lands, it shows `similarTo` from the catalog in a list.
  - Add warm-up sets adds 2 sets at about 55% and 75% of the working kg, rounded to plate: 40 × 10 and 55 × 5 for 72.5.
  - Also: Rest timer (stepper of 30 s), Note, Reorder (up/down), Remove.
- **RPE picker:** tap the RPE cell to open a 1–10 sheet with the caption "RPE n · about (10−n) reps left in the tank".
- **Rest bar:** floats above the bottom buttons, with −15s / +15s / Skip.
- **Bottom buttons:** "+ Exercise" (Task 6 route; until then hidden behind a `kExerciseLibraryReady` const) and "Finish workout".
- **Finish workout** opens `WorkoutCompleteScreen`:
  - Date and time; "Workout complete"; "name · n new records".
  - Tiles: Duration, Volume (t), Sets, Records, Load (only after RPE is picked).
  - Overall RPE 1–10 picker.
  - Exercises with best set and e1RM, with PR chips.
  - A "Next time" card from `suggestNextKg` (the first exercise whose suggestion is higher).
  - **Save workout** saves with sessionRpe and goes to `/home/progress`.
  - **Discard** asks for confirmation, then drops the workout and goes home.
  - Drop the "Energy ≈533" tile: there is no calorie model.

- [ ] **Step 1: Write failing widget tests.**
  - Tick a working set: the rest bar appears at 2:00, and +15s gives 2:15.
  - Set RPE 8: it shows 8 and is saved in state.
  - Add warm-up sets for 72.5 gives 40 × 10 and 55 × 5 rows with W.
  - Finish with RPE 7 after an 86-min workout gives Load 602 on the complete screen.
  - Save puts the workout in history with sessionRpe 7.
  - Discard leaves history unchanged.
  - With no history, no Felix line and no PR chip.
  - SE and 1.3 text: no overflow.
- [ ] **Step 2: Run them.** Expected: FAIL.
- [ ] **Step 3: Implement.** Keep the existing collapsed mini bar and gestures (see `test/gestures_test.dart`, `test/ux_workout_test.dart`, `test/active_workout_style_test.dart`). Update those tests only where the design changed, and say which in the report.
- [ ] **Step 4: Run** `flutter test` and `flutter analyze`. Expected: all pass.

### Task 4: Morning check-in, recovery, Home card (Sonnet)

**Spec screens:**
- `mock_checkin_library` 0 (Home with check-in card), 1 (check-in sheet), 2 (recovery).

**Files:**
- Create: `lib/features/checkin/...` (see File Structure)
- Modify: `home_screen.dart`, `app_router.dart`
- Test: `test/checkin_test.dart`

**Interfaces — Produces:**
```dart
enum SleepQuality { poor, ok, good }   enum Soreness { none, light, medium, strong }
enum Level3 { low, ok, high }          // energy: low/ok/high; stress: low/medium(=ok)/high
enum BodyArea { legs, back, chest, arms, shoulders }
class CheckIn { DateTime at; Duration sleep; SleepQuality quality; Soreness soreness; Set<BodyArea> sore; Level3 energy; Level3 stress; }
class Readiness { int score; List<({String factor, int delta})> factors; ReadinessLabel label; }
enum ReadinessLabel { ready, trainLight, rest }   // ≥70, 50–69, <50
Readiness readiness(CheckIn c, {required int hardDaysLast7});
class CheckInStore { CheckIn? today(); List<CheckIn> lastDays(int n); Future<void> save(CheckIn c); }  // key 'checkins_v1', keeps 60 days
final todayCheckInProvider; final checkInHistoryProvider;
int hardDaysLast7(List<CompletedWorkout> history, DateTime now);  // days with a workout whose sessionRpe ≥ 7
List<({String from, String to})> sparingSwaps(WorkoutTemplate today, Set<BodyArea> sore, ExerciseCatalog catalog);
```

**Readiness formula.** Start from 80, add the deltas below, then clamp to 0–100. With the prototype's inputs this gives 78.
- **Sleep:** quality poor −10, ok 0, good +5. Add `round((hours − 7) × 6)`, clamped to −12…+6.
- **Soreness:** none 0, light −4, medium −12, strong −20.
- **Energy:** low −8, ok 0, high +4.
- **Stress:** low +3, medium 0, high −8.
- **Training load** (hard days in the last 7): 0–2 → 0, 3 → −3, 4 → −5, 5+ → −10.

**Behavior:**
- **Home:** before today's check-in, the card reads "Good morning, {name}" with "Check in". After it, a ring shows the score and opens Recovery.
- **Check-in sheet:**
  - Sleep is a stepper in 15-min steps, default 7 h 30 m.
  - The live score preview updates as inputs change.
  - "Save check-in" opens Recovery.
  - Omit the "Apple Health or Garmin can fill…" line (wave 2).
- **Recovery screen:**
  - Ring and label, "What shaped it" with signed deltas.
  - A "Today's plan, adjusted" card only when `sparingSwaps` is non-empty for today's planned gym session (Task 5) or, before Task 5, the first gym template. Swaps are applied to today's session with Undo.
  - A last-7-days bar chart with the average.
  - "Start workout" starts today's session.

- [ ] **Step 1: Write failing tests.**
  - The prototype inputs (7 h 30 good, medium soreness on legs, energy high, stress low, 4 hard days) give 78 and factors `[+8, −12, +4, +3, −5]`.
  - Clamping at 0 and 100.
  - The store keeps only today as `today()` after midnight: use an injected clock and save at 23:59, then expect `today()` to be null at 00:01.
  - `sparingSwaps` replaces Barbell row with a similar exercise not loading back or legs when sore = {legs}. Catalog: Barbell row lists `legs` in its secondary group.
  - Home shows "Check in" before saving and the score after.
  - Recovery renders with no history.
  - SE and 1.3 text: no overflow.
- [ ] **Step 2: Run them.** Expected: FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** `flutter test` and `flutter analyze`. Expected: all pass.

### Task 5: Week plan and add session (Sonnet, Opus review)

**Spec screens:**
- `mock_plan_log` 0 (this week), 1 (add session sheet).

**Files:**
- Create: `lib/features/plan/...`
- Modify: `home_screen.dart` (Today card reads the plan), `app_router.dart`, `my_workouts_screen.dart` (entry "This week")
- Test: `test/week_plan_test.dart`

**Interfaces — Produces:**
```dart
enum Intensity { easy, normal, hard }
class PlannedSession { String id; DateTime day /*date only*/; Sport sport; String title; String? templateId; int minutes; Intensity intensity; }
enum SessionStatus { planned, done, missed, today }
class WeekPlanStore { List<PlannedSession> all(); Future<void> save(List<PlannedSession>); }   // key 'week_plan_v1'
final weekPlanProvider = StateNotifierProvider<WeekPlanNotifier, List<PlannedSession>>;
//   add(PlannedSession), remove(id), move(id, DateTime day), replaceFutureGym(List<PlannedSession>) — used by Task 7
SessionStatus statusOf(PlannedSession s, List<CompletedWorkout> history, DateTime now);
//   done: a completed workout on that day with the same templateId (or same sport when templateId is null)
//   missed: day < today and not done; today: day == today and not done
Intensity intensityOfTemplate(WorkoutTemplate t);  // legs/full-body gym → hard, other gym → hard if ≥ 60 min; football hard; stretching easy
bool loadsLegs(PlannedSession s, ExerciseCatalog c); // football, running, skiing, or a template with a legs/glutes primary exercise
class PlanSuggestion { String sessionId; DateTime from; DateTime to; String reason; }
PlanSuggestion? suggestPlanChange(List<PlannedSession> week, DateTime today, ExerciseCatalog c);
//   two hard leg-loading sessions on consecutive days → move the later gym one to the first following day
//   with no hard session and ≥ 48 h after the other leg session; null if none
int hardInNext3Days(List<PlannedSession> week, DateTime today);
bool wouldBeThirdHardDayInARow(List<PlannedSession> week, DateTime day, Intensity i);
```

**Behavior:**
- **This week** (Mon–Sun of the current week): title and range; "n sessions · m done"; day strip; Training load bar (Easy / Normal / High):
  - High if `hardInNext3Days` ≥ 3;
  - Normal if 2;
  - Easy otherwise.
  - Caption: "{n} hard sessions in the next 3 days." plus " Recovery today {score}%." when checked in.
- **Felix card:** shown when `suggestPlanChange` is not null. "Optimize plan" moves the session; "Keep" hides the suggestion for that session for the week. The dismissal is stored with the plan.
- **Day sections:** done, missed or planned items. Today's gym item has Start, which starts the template like the Gym screen does. A missed item shows "Missed".
- **Add session sheet:**
  - Sport pills (Gym, Fitness, Running, Cycling, Football, Skiing).
  - The sport's templates. For non-gym sports, one generic entry per sport, for example "Football 7×7 · 90 min · Hard".
  - Day pills: Today and the next 5 days.
  - A warning card from `wouldBeThirdHardDayInARow`, with the suggested day preselected.
  - Button "Add {title} · {day}".
- **Home Today card:** today's first planned non-done session; falls back to the current behavior when the plan is empty.
- **First open with an empty plan:** offer "Plan my week" to seed one session per default gym template on Mon/Wed/Fri of this week (dates ≥ today only). No auto-seeding.

- [ ] **Step 1: Write failing tests.**
  - `statusOf`: done, missed and today with an injected `now`.
  - `suggestPlanChange`: Football Sat + Legs Sun suggests moving Legs to Mon; nothing when they are 2 days apart.
  - `wouldBeThirdHardDayInARow`.
  - Load bar labels for 0, 2 and 4 hard sessions.
  - Optimize moves the session and persists it; Keep hides the card.
  - The add-session flow adds to the store and shows in the list.
  - Empty plan shows "Plan my week".
  - SE and 1.3 text: no overflow.
- [ ] **Step 2: Run them.** Expected: FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** `flutter test` and `flutter analyze`. Expected: all pass.

### Task 6: Exercise library (Sonnet)

**Spec screens:**
- `mock_checkin_library` 3 (library), 4 (exercise detail), 5 (add exercise).

**Files:**
- Create: `lib/features/exercises/presentation/*.dart`
- Modify: `app_router.dart`, `my_workouts_screen.dart` (entry), `active_workout_sheet.dart` (enable "+ Exercise" and Swap: remove `kExerciseLibraryReady`)
- Test: `test/exercise_library_test.dart`

**Behavior:**
- **Library:**
  - Group pills (All + 7 groups) and equipment pills; search field.
  - "Your recent": exercises from history with the best set.
  - "All · A–Z" with letter headers.
- **Detail:**
  - Name; tags (equipment, pattern, compound, level).
  - Primary and secondary muscles as text chips. No body diagram in this wave.
  - "Your numbers" (best set, e1RM, sessions, change since first session, a small e1RM line chart over months) only when history has the exercise; otherwise "Do it once to see your numbers".
  - How to do it (numbered steps), Common mistakes, Similar (tap opens that exercise).
  - "Ask Felix" via `askFelix(topic: gym, draft: 'How do I improve my {name}?')`.
  - "Add to workout": appends to the active workout, or starts a quick workout named "Quick workout" if none is active.
- **Add exercise** (`?mode=add|replace&index=i`):
  - Opened from the live log.
  - Shows the current workout name in the title.
  - The weekly sets hint: "{Group} got {n} sets this week, target is {t}." is shown when below target. t = 14 sets per week per group from history, warm-ups excluded.
  - Suggested exercises (catalog `similar` of exercises in the workout, same group, not already in it), with multi-select.
  - Button "Add {n} exercises", or "Swap" in replace mode.

- [ ] **Step 1: Write failing tests.**
  - Group and equipment filters narrow the list.
  - Search "bench" finds Bench press.
  - Detail with history shows e1RM 107.3 for 82.5 × 9.
  - Detail without history shows the empty text.
  - Add mode with 2 selected adds 2 exercises to the active workout.
  - Replace mode swaps index 1.
  - The weekly sets hint appears for back with 10 sets this week.
  - SE and 1.3 text: no overflow.
- [ ] **Step 2: Run them.** Expected: FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** `flutter test` and `flutter analyze`. Expected: all pass.

### Task 7: Profile, heart-rate zones, edit profile, connected apps (Sonnet)

**Spec screens:**
- `mock_profile` 0–5.

**Files:**
- Create: `performance_store.dart`, `hr_zones.dart`, `hr_zones_screen.dart`, `edit_profile_screen.dart`, `connected_apps_screen.dart`
- Modify: `profile_tab_screen.dart`, `app_router.dart`
- Test: `test/profile_wave1_test.dart`

**Interfaces — Produces:**
```dart
enum Sex { male, female }
class PerformanceProfile { Sex? sex; int? restingHr; int? maxHr; int? lthr; int? ftpW; Duration? fiveK; }   // key 'performance_profile_v1'
final performanceProfileProvider = StateNotifierProvider<PerformanceNotifier, PerformanceProfile>;
class HrZone { String name; int low; int high; }   // high exclusive except last
List<HrZone> karvonenZones(int rest, int max);      // 50–60, 60–70, 70–80, 80–90, 90–100 % of reserve, rounded
List<HrZone> frielZones(int lthr);                  // <85, 85–89, 90–94, 95–99, 100–102, 103–106, >106 % of LTHR
int tanakaMaxHr(int age);                           // round(208 − 0.7 × age)
```

**Behavior:**
- **Profile tab** (restyle, keep existing settings behavior and tests):
  - Avatar initial, name, the line "City? · experience · goal" from the profile (skip missing parts).
  - Weight, height and age tiles; "My sports" chips.
  - FITRIX Pro row as today.
  - "Heart-rate zones" row with "Rest {r} · max {m} bpm", or "Set up" when missing.
  - "Connected apps" row with "0 of 4 connected".
  - Settings as today.
- **HR zones:**
  - Karvonen / LTHR (Friel) segmented control; zone tables.
  - When maxHr is missing, show "No test yet? Tanaka estimate: …" using age. Without age, prompt to complete the profile.
- **Edit profile:**
  - Name, weight, height and age are saved through the existing profile repository (same validation as About me).
  - Sex, resting HR, max HR, FTP and 5K PB go to `PerformanceProfile`.
  - Save validates the ranges: HR 30–230, FTP 50–600, 5K 12:00–60:00.
- **Connected apps:** 4 rows (Apple Health, Garmin Connect, Strava, WHOOP), all "Not connected". "Connect" opens the scope sheet (Garmin copy from screen 5) with the button "Coming in a later update" (disabled) and a short line explaining it.

- [ ] **Step 1: Write failing tests.**
  - `karvonenZones(56, 194)` Z1 = 125–139, Z2 = 139–153, Z5 = 180–194.
  - `frielZones(172)` Z1 high = 146, Z5a = 172–176.
  - `tanakaMaxHr(26) == 190`.
  - Edit profile saves performance fields and rejects HR 300.
  - Zones screen without age or max HR shows the profile prompt.
  - Profile shows "0 of 4 connected".
  - SE and 1.3 text: no overflow.
- [ ] **Step 2: Run them.** Expected: FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** `flutter test` and `flutter analyze`. Expected: all pass.

### Task 8: Nutrition with food base, water, micronutrients, targets (Sonnet, Opus review)

**Spec screens:**
- `mock_nutrition` 0–4.

**Files:**
- Create: `foods.json`, `food_catalog.dart`, `food_log_store.dart`, `nutrition_targets.dart`, `micronutrients.dart`, screens
- Modify: `nutrition_screen.dart`, `nutrition_provider.dart`, Felix meal-plan action code that writes `NutritionStore`
- Test: `test/nutrition_wave1_test.dart`

**Interfaces — Produces:**
```dart
enum MealSlot { breakfast, lunch, dinner, snack }
class Food { id; name; String? localName /*uz/ru*/; String category /*uzbek, meat_fish, dairy, fruit, bread, drinks, grains, veg*/; bool uzbek;
  double kcal, protein, carbs, fat, fibre; Map<String,double> micros /*per 100 g, keys below*/; List<({String label, int grams})> portions; }
const microKeys = ['vitD_mcg','calcium_mg','magnesium_mg','iron_mg','zinc_mg','potassium_mg','sodium_mg','b12_mcg','selenium_mcg','vitE_mg','vitC_mg','vitA_mcg'];
class FoodEntry { String id; DateTime at; MealSlot slot; String? foodId; String name; int grams; int kcal; double protein, carbs, fat; Map<String,double> micros; }
class FoodLogStore { List<FoodEntry> day(DateTime d); Future<void> add(FoodEntry e); Future<void> remove(String id); int waterMl(DateTime d); Future<void> addWater(DateTime d, int ml); }
//   key 'food_log_v1', keeps 30 days; migrates 'nutrition_today_v1' meals once into today's entries (slot by order: breakfast, lunch, snack, dinner; kcal only)
enum Goal { loseFat, maintain, leanBulk }   // kcal × 0.85 / 1.0 / 1.10
class Targets { int bmr; double activity; int tdee; int kcal; int protein; int fat; int carbs; int waterMl; }
Targets? targetsFor({Sex? sex, int? age, double? weightKg, double? heightCm, required double trainingHoursPerWeek, required Goal goal,
  double proteinPerKg = 1.8, double fatPerKg = 1.0, bool trainingDay = false});
//   null if sex/age/weight/height missing. BMR Mifflin-St Jeor (male +5, female −161), rounded.
//   activity by weekly training hours: <1 → 1.2, 1–3 → 1.375, 3–6 → 1.55, 6–10 → 1.725, >10 → 1.9
//   kcal rounded to nearest 50; carbs = (kcal − 4p − 9f)/4 rounded; water = 40 ml/kg rounded to 100 ml, +500 on a training day
Map<String,double> microTargets(Sex sex, int age);   // NASEM RDA/AI adults 19–30 and 31–50, men/women; sodium = 2300 limit
enum MicroStatus { low, ok, high }  // low < 60 % of target; high only for sodium > 100 %
```
Goal and the per-kg factors are stored in `'nutrition_settings_v1'`. Training hours per week = the average over the last 4 weeks of completed workout minutes. With none, use 3 h and show "estimated".

**Behavior:**
- **My nutrition:**
  - Date line "· training day" when a workout is done or planned today.
  - kcal ring: eaten of target, left, and "Burned in training" = Σ today's workout load × 0.9 kcal, shown only when > 0, labelled "≈".
  - "How it's set ›" opens Targets.
  - Macro bars.
  - Water row: "+250 ml" / "+500 ml", and the "+0.5 L for today's workout" caption on training days.
  - Meals by slot with "Add" for empty ones.
  - "Low today": the 3 lowest micros with "All {n} ›".
  - Felix dinner idea when protein is ≥ 30 g behind after 15:00:
    - The idea is the uzbek/meat food whose portion fits the remaining kcal and maximises protein.
    - "Add to dinner" logs it.
    - "Other idea" picks the next best.
  - When `targetsFor` is null, show a "Complete your profile" card linking `/me/edit` instead of the ring.
- **Add food:**
  - Slot pills, category pills, search over name and localName.
  - "Recent" = foods logged in the last 7 days.
  - Each result shows its first portion with kcal and protein, and a ⊕ quick-add of that portion.
  - "Can't find it?" opens askFelix(topic: app, draft: 'Estimate the calories in: ').
- **Food detail:**
  - Per 100 g header; portion pills plus a 100 g option.
  - kcal and macro numbers for the chosen portion.
  - "Fits your day?" with a fat-over-target warning when it applies.
  - "Rich in": the top 5 micros by % of the daily target.
  - "Add to {slot} · {kcal} kcal".
- **Micronutrients:**
  - Today / 7 days / 30 days averages.
  - Filter: Athlete essentials (D, calcium, magnesium, iron, zinc, potassium, sodium) / Vitamins / Minerals / All.
  - Status chips.
  - A card when vitamin D is low on every one of the last 7 logged days; links to Shop only if the catalog has a vitamin D product. It doesn't today, so no Shop link.
  - "In season now": a static list by month for Uzbekistan (Oct: pomegranate, quince, persimmon, pumpkin), with local names.
- **Targets:** goal pills, BMR line with formula inputs, activity, goal adjustment, daily target, protein and fat per-kg steppers (protein 1.2–2.4, fat 0.6–1.5), carbs auto, Save.
- **foods.json:** ≥ 80 foods, ≥ 15 Uzbek dishes (all plov variants on screen 1, achichuk, non, lagman, manti, shurpa, somsa, shashlik chicken and beef, chuchvara, dimlama, mastava, norin, qatiq, suzma). Values per 100 g from USDA FoodData Central for basic foods. Uzbek dishes are recipe estimates and are flagged `"estimate": true`; the UI shows a "Recipe estimate" tag.

- [ ] **Step 1: Write failing tests.**
  - `targetsFor(male, 26, 78.4, 181, hours 7.6, leanBulk)` gives bmr 1790, activity 1.725, tdee 3088, kcal 3400, protein 141, fat 78, carbs 534.
  - Missing height gives null.
  - Female BMR uses −161.
  - The migration from `nutrition_today_v1` keeps the kcal and runs once.
  - Day rollover: an entry at 23:59 is not in tomorrow's day.
  - Adding 350 g Tashkent plov adds its kcal to the ring.
  - Water +250 updates the row.
  - The dinner idea appears when protein is behind after 15:00 and not before.
  - The Felix meal-plan action still writes meals: update `test/felix_actions_test.dart` expectations to the new store.
  - The profile-incomplete card.
  - SE and 1.3 text: no overflow.
- [ ] **Step 2: Run them.** Expected: FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** `flutter test` and `flutter analyze`. Expected: all pass.

### Task 9: Progress, load, records, lifts, body weight (Sonnet, Opus review)

**Spec screens:**
- `mock_progress` 0–4.

**Files:**
- Create: `body_weight_store.dart`, screens
- Modify: `progress_screen.dart` (rewrite; remove sample weight and calorie series from `progress_data.dart`), `app_router.dart`
- Test: `test/progress_wave1_test.dart`

**Interfaces — Produces:**
```dart
class WeighIn { DateTime at; double kg; }
class BodyWeightStore { List<WeighIn> all(); Future<void> add(WeighIn w); }  // key 'body_weight_v1'; adding also updates profile weight via the profile repository
double? weeklyTrendKg(List<WeighIn> w, DateTime now, {int weeks = 8});   // least-squares slope × 7, null with < 2 weigh-ins spanning ≥ 7 days
int? kcalAdjustment(double trendKgPerWeek, Goal goal);   // target rate loseFat −0.5, maintain 0, leanBulk +0.3; (target − trend) × 7700 / 7, rounded to 10; null if |diff| < 0.1
String strengthLevel(String lift, double e1rm, double bodyKg);  // ratio bands per lift (bench, squat, deadlift, row, ohp): beginner/novice/intermediate/advanced/elite
List<DailyLoad> dailyLoads(List<CompletedWorkout> history);    // Σ CompletedWorkout.load per local day
```
Strength bands for male × bodyweight (female × 0.65):
| Lift | novice | intermediate | advanced | elite |
|---|---|---|---|---|
| bench | 0.75 | 1.0 | 1.5 | 2.0 |
| squat | 1.0 | 1.5 | 2.0 | 2.5 |
| deadlift | 1.25 | 1.75 | 2.5 | 3.0 |
| row | 0.6 | 0.9 | 1.25 | 1.6 |
| ohp | 0.5 | 0.7 | 1.0 | 1.3 |

**Behavior:**
- **My progress:**
  - Sport pills (Overall + sports present in history).
  - Load this week: Σ load, "% of your usual" against the 4-week average, and a Sat–Fri bar chart coloured by sport.
  - Fitness / Fatigue / Form tiles, plus "estimated" when any load used the default RPE.
  - Records this week count.
  - Load balance bar (acwr and band).
  - Felix insight: a rule-based sentence from band and form. Write the three sentences in ARB: low / sweetSpot / risky.
  - Links: Records (count), Lifts · e1RM (count of lifts), Body weight (latest).
  - Drop "All activities" (no screen this wave).
  - Empty: "Log a workout to see your load".
- **Training load:**
  - 4 / 12 / 16 weeks; fitness and fatigue lines (reuse `progress_chart.dart` painter where possible).
  - Three explanation rows, a "By week" list, and a next-week aim = 4-week average weekly load rounded to 100.
- **Records:** grouped by month, sport pills, "This month" and "Best streak" (consecutive weeks with ≥ 1 record).
- **Lift detail:**
  - Pills of lifts in history.
  - e1RM headline, change since the first session, monthly chart.
  - Strength level with ratio and the next band.
  - Next session table: 85% × 6, 75% × 8–9, 70% × 10, rounded to plate.
  - Felix pace line: weekly e1RM slope.
- **Body weight:**
  - Latest kg, trend/week, goal band text.
  - Chart with weigh-ins and trend.
  - An off-track card with `kcalAdjustment` and "Update my targets" (opens Task 8 targets).
  - Weigh-ins list with deltas.
  - "Log today's weight" opens a numeric sheet (20–400 kg).

- [ ] **Step 1: Write failing tests.**
  - `weeklyTrendKg` on a synthetic −0.15 kg/wk series gives −0.15 ± 0.01.
  - `kcalAdjustment(−0.15, leanBulk)` gives 500: (0.3 + 0.15) × 1100 = 495, rounded to 10.
  - `strengthLevel('bench', 107.3, 78.4)` is intermediate.
  - `dailyLoads` sums two workouts on one day.
  - Progress with empty history shows the empty text.
  - Progress with 6 weeks of synthetic history shows fitness, fatigue and form numbers matching `loadSummary`.
  - Logging weight adds a weigh-in and updates the profile weight.
  - SE and 1.3 text: no overflow.
- [ ] **Step 2: Run them.** Expected: FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** `flutter test` and `flutter analyze`. Expected: all pass.

### Task 10: Training programs (Sonnet, Opus review)

**Spec screens:**
- `mock_programs` 0–3.

**Files:**
- Create: `training_programs.json`, `program_catalog.dart`, `program_store.dart`, screens
- Modify: `app_router.dart`, `home_screen.dart` drawer or My workouts (entry "Programs")
- Test: `test/programs_test.dart`

**Interfaces:**
- **Consumes:** `weekPlanProvider.replaceFutureGym`, `workoutTemplatesProvider.addAll`, `allRecords`, `e1rm`.
- **Produces:**
```dart
class ProgramExercise { String exercise; int sets; int repsLow; int repsHigh; int rir; }
class ProgramSession { String name; List<ProgramExercise> exercises; int minutes; }
class TrainingProgram { id; name; author; int weeks; int perWeek; String level; List<String> goals; bool atHome; String summary; List<ProgramSession> sessions; int? deloadWeek; List<String> progressionRules; }
class ActiveProgram { String programId; DateTime start; List<int> weekdays /*1=Mon*/; Map<String,String> sessionTemplateIds; }  // key 'active_program_v1'
List<int> defaultWeekdays(TrainingProgram p, List<PlannedSession> nonGymPlan);   // spread across the week, avoid days with a hard non-gym session and the day before it
List<PlannedSession> scheduleProgram(TrainingProgram p, DateTime start, List<int> weekdays, Map<String,String> templateIds);
double? startKg(String exercise, List<CompletedWorkout> history, int reps);  // best recent e1RM → kg for `reps` at RIR 2: e1rm / (1 + (reps+2)/30), rounded to plate
```
- **Programs JSON:** 5 programs, with names and facts as in `mock_programs` 0–1:
  - GZCLP (Cody Lefever);
  - Full body 3× (FITRIX template);
  - StrongLifts 5×5 (Mehdi Hadim);
  - Push/Pull/Legs (FITRIX template);
  - Upper/Lower 4× (FITRIX template, deload week 7).

**Behavior:**
- **Programs list:**
  - Active program card (week x of N, dots, sessions done, Open).
  - "Picked for you": the first program matching the profile goal and experience.
  - Goal and days-a-week filters; cards with Details.
- **Detail:**
  - Facts; "Your week" with clash detection against non-gym planned sessions.
  - The first session's exercises; progression rules; Felix card only when weekdays were adjusted for a clash.
  - Start program.
- **Start sheet:**
  - Date (Today / next Monday / pick); training day pills (exactly `perWeek` required).
  - Start weights from history (`startKg`), with rows hidden when no history.
  - "Replace my weekly plan" toggle (default on): gym days switch, other sports stay.
  - The button creates templates (one per program session, sets prefilled with startKg or 0), schedules the sessions, and saves ActiveProgram.
- **Progress screen:**
  - Week x of N (deload marked).
  - Tiles: sessions done/planned to date, on-time %, records since start.
  - This week's sessions with Start.
  - Main lifts table: start / now (best e1RM-derived working kg) / goal = start + 2.5 kg per 2 weeks (upper) or 5 kg (lower), for the program length.
  - A next-increase card when the last two sessions of a lift hit the top of the rep range.
  - "End program" with confirmation.

- [ ] **Step 1: Write failing tests.**
  - The catalog loads 5 programs, and every exercise resolves in `ExerciseCatalog`.
  - `defaultWeekdays(upperLower4, [football Sat])` avoids Sat and Fri for Lower and gives 4 days.
  - `scheduleProgram` 8 weeks × 4 gives 32 sessions starting at the start date.
  - `startKg('Bench press', 82.5×9 history, 8)` gives 80. That is 107.25 / (1 + 10/30) = 80.4, rounded to plate.
  - Starting with replace on removes future gym sessions and keeps football.
  - The progress screen shows week 1 of 8 right after start.
  - Empty history hides start weights.
  - SE and 1.3 text: no overflow.
- [ ] **Step 2: Run them.** Expected: FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** `flutter test` and `flutter analyze`. Expected: all pass.

### Task 11: Navigation pass, Ask Felix entry points, whole-app check (Opus)

**Files:**
- Modify: `home_screen.dart`, `my_workouts_screen.dart`, `sport_workouts_screen.dart`, screens from Tasks 3–10 as needed
- Test: `test/routing_test.dart` (extend)

**Steps:**
- [ ] **Step 1: Write the failing routing test.** Every route in the File Structure list opens without exception from a signed-out local-only app with empty data, in light and dark themes.
- [ ] **Step 2: Wire the remaining taps from `build_clickable.py` `R`** that point at wave-1 screens: Home tiles, My workouts → This week / Programs / Exercise library, Gym "Reschedule" → plan, and every "Ask Felix" button → `askFelix` with a screen-specific draft.
- [ ] **Step 3: Run** `flutter test`, `flutter analyze` and `flutter build ios --release --no-codesign`. Expected: all green.
- [ ] **Step 4: Phone build.** No migrations are needed this wave; confirm with `git diff main --stat -- supabase/` showing nothing new since 2026-10-13. Then `flutter run --release` on the owner's iPhone.
