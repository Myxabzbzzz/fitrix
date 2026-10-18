# Felix Actions 2 + Dark Map Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Felix can log food the user says they ate, keep body weight in sync when the user says they gained or lost weight, and turn a workout plan into templates and planned sessions with one elegant button and a "Felix plan" badge. The map gets a proper dark theme.

**Architecture:** The backend (Node, `backend/`) asks the model for one `<fitrix-action>` JSON block per reply. If the model forgot the block, a JSON-schema fallback call recovers it. The app parses the block into a `ChatAction` (`lib/features/chat/data/models/chat_action.dart`), shows a confirm card (`chat_action_card.dart`), and applies it (`chat_action_apply.dart`) to local stores from wave 1:
- `FoodLogStore` / `foodLogProvider`;
- `BodyWeightStore`;
- `weekPlanProvider`;
- `workoutTemplatesProvider`.

The dark map uses a hue-preserving inverted tile filter chosen on real Tashkent tiles (see `design/map-dark/filter-variants.png`, variant "soft").

**Tech Stack:** Flutter 3 (Riverpod 2, go_router), Node backend with Ollama (qwen3:8b), flutter_map.

**Spec:** the owner's request (2026-10-18), verbatim: «чтобы я феликсу писал типо "я набрал 3кг" и он добавлял мне в профиле 3кг или чтобы я ему говорил "я сьел 200гр курицы и 150гр риса" и он это записывал ко мне в my nutrition или если я говорил феликсу "составь план тренировки на сегодня" или на неделю он составлял его а потом появлялась элегантная кнопочка добавить и оно добавлялось в my workouts с плашкой что это план который составил феликс и еще поработай над картой в темной теме она выглядит не очень».

## Global Constraints

Same as wave 1: `.superpowers/sdd/2026-10-18-wave1-training-core/global.md`. Additions:
- **Backend:** tests run with `cd backend && npm test`. Do not touch `backend/.env` or `backend/server.log`.
- **Every action is confirmed by the user on a card.** Nothing is written without a tap. Every applied action offers Undo on the same card until the chat is left.
- **Food the user names is matched to `assets/data/foods.json`** by name, alias or localName, case-insensitively, also matching ru/uz names. A match uses catalog macros and micros scaled by grams. Without a match, the model's own numbers are used and the entry is marked "≈ Felix estimate".
- **New local data stays local**, as in wave 1. No Supabase migrations.

## Review Focus

1. **Russian, Uzbek and Spanish phrasing.** "я съел 200 г курицы и 150 г риса", "ikki tuxum yedim", "comí 100 g de arroz" must all produce a `food_log` with grams, from the model or the fallback. Grams written as "200гр", "200 g", "0.2 кг" or "2 яйца" (pieces → catalog portion) are parsed.
   - Owned by Tasks 1 and 2.
2. **The model returns nonsense.** Negative grams, 50 000 kcal, an empty list or unknown slot names are rejected by backend validation, so no card is shown and no crash happens.
   - Owned by Task 1, and in the app by Task 2's parser.
3. **"я набрал 3 кг" with no weight in the profile.** The card says to set the weight first and links to Edit profile, instead of failing silently. When the profile has a weight, both the profile and the Body weight log update, and Undo reverts both.
   - Owned by Task 2.
4. **A workout plan "for today" when today already has a planned session.** It is added next to the existing one, not replacing it. A week plan for days already past this week goes to next week.
   - Owned by Task 3.
5. **Dark map legibility.** Street labels stay readable, parks are green, water is blue, and the route line and pins have enough contrast on the dark tiles. The light theme is unchanged.
   - Owned by Task 4.

---

### Task 1: Backend — food_log action, workout plan "when/days", fallbacks (Sonnet)

**Files:**
- Modify: `backend/prompt.js` (Case 4 food_log; Case 2 gains `when` and `days`), the action validator (find where `workout_plan`, `meal_plan` and `weight` are validated, e.g. `backend/actions.js` or `server.js`), `backend/fallback.js` (food-log detection and a schema for food_log)
- Test: `backend/*.test.js` (extend the existing files)

**Produces (the JSON contract the app parses):**
```json
{"type":"food_log","slot":"lunch","items":[{"name":"chicken breast","grams":200,"kcal":330,"protein":62,"carbs":0,"fat":7.2}]}
```
- `slot` is one of `breakfast`, `lunch`, `dinner`, `snack`, or null when the user didn't say.
- 1–15 items.
- `name` is a short generic food name **in English**, for catalog matching.
- `grams` 1–3000; `kcal` 0–3000; `protein`, `carbs` and `fat` 0–500.
- Pieces are converted by the model to grams (an egg is about 50 g).
```json
{"type":"workout_plan","sport":"gym","when":"today","days":["today"],"templates":[…]}
```
- `when` is `"today"`, `"week"` or null (old behaviour).
- `days` is optional, one entry per template, each one of `today`, `mon`…`sun`.
- `when:"today"` requires exactly 1 template.

- [ ] **Step 1: Write failing tests.**
  - Prompt text contains Case 4 with ru and en examples.
  - The validator accepts the example above.
  - The validator rejects grams 0 or 5000, kcal 9000, 0 items, 16 items, slot "brunch" and a non-string name.
  - The fallback detects food-log intent in "я съел 200 г курицы и 150 г риса", "ikki tuxum yedim", "comí 100 g de arroz" and "I had 2 eggs and toast". It does NOT trigger on "what should I eat?", "сколько белка в курице?" or "составь план питания".
  - `workout_plan` accepts `when`/`days`, rejects `when:"today"` with 2 templates, and rejects a days length that doesn't match the templates.
- [ ] **Step 2: Run** `cd backend && npm test`. Expected: FAIL.
- [ ] **Step 3: Implement.**
  - The fallback for food_log reuses the existing JSON-schema call path used for plans.
  - Keep the visible reply short: confirm what was understood.
- [ ] **Step 4: Run** `npm test`. Expected: all pass, with the existing 68+ tests still green.

### Task 2: App — food_log card and apply; weight also logs a weigh-in (Sonnet)

**Files:**
- Modify: `lib/features/chat/data/models/chat_action.dart` (`FoodLogAction`, `FoodLogItem`; `WorkoutPlanAction` gains `when` and `days` but no UI change in this task), `chat_action_apply.dart`, `chat_action_card.dart`
- Create: `lib/features/nutrition/domain/food_match.dart`
- Test: `test/felix_actions_2_test.dart`

**Interfaces — Produces:**
```dart
class FoodLogItem { String name; int grams; int kcal; double protein, carbs, fat; }
class FoodLogAction extends ChatAction { MealSlot? slot; List<FoodLogItem> items; }
Food? matchFood(String name, FoodCatalog catalog);        // exact/alias/localName, then token containment ("chicken" → "Chicken breast, cooked"); null if ambiguous score
FoodEntry entryFor(FoodLogItem item, Food? food, MealSlot slot, DateTime at);   // catalog values scaled by grams when matched, else item's numbers + estimate flag
MealSlot slotForTime(DateTime t);   // <11 breakfast, <16 lunch, <21 dinner, else snack
```
- `FoodEntry` gains `bool estimate` (default false, JSON-compatible).

**Behavior:**
- **Food card:**
  - Header "Log to {Slot}" with a slot dropdown (default `action.slot ?? slotForTime(now)`).
  - One row per item: name (catalog name when matched, else Felix's name with "≈"), grams, kcal.
  - Total kcal and protein.
  - Primary button "Add to My nutrition · {kcal} kcal".
  - After adding: "Added to {Slot}" with Undo (removes exactly those entries) and "Open" (goes to `/home/nutrition`).
- **Weight:**
  - Apply also adds a `WeighIn(now, newKg)` to `BodyWeightStore` (wave 1, Task 9).
  - Undo restores the previous profile weight and removes that weigh-in.
  - With no profile weight, the card shows "Set your weight first" with a button to `AppRouter.editProfile` (`/me/edit`) instead of the confirm button.
- **Meal plan:** unchanged behaviour (it replaces the day).

- [ ] **Step 1: Write failing tests.**
  - Parse the food_log JSON; reject an invalid one, so no card is shown.
  - `matchFood("chicken breast")` returns the catalog chicken; `matchFood("плов")` returns a plov dish; `matchFood("dragonfruit smoothie")` returns null.
  - Applying 200 g chicken + 150 g rice adds 2 entries whose kcal equals catalog kcal per 100 g × grams / 100, rounded. An unmatched item uses Felix kcal with `estimate` true.
  - Undo removes them.
  - `slotForTime` boundaries at 10:59, 11:00, 15:59, 16:00, 20:59 and 21:00.
  - "I gained 3 kg" at 78.4 sets the profile to 81.4 and adds a weigh-in of 81.4. Undo gives 78.4 with no weigh-in.
  - With no profile weight, the card shows the set-weight prompt.
  - SE size at 1.3 text: no overflow on the cards.
- [ ] **Step 2: Run them.** Expected: FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** `flutter test` and `flutter analyze`. Expected: all pass.

### Task 3: App — workout plan card, Felix plan badge, scheduling (Sonnet, Opus review)

**Files:**
- Modify: `chat_action_card.dart` (the workout plan card), `chat_action_apply.dart`, the workout template cards in `lib/core/widgets/workout_card.dart` and/or `sport_workouts_screen.dart`, `my_workouts_screen.dart`
- Create: `lib/features/workouts/data/felix_templates_store.dart`
- Test: `test/felix_plan_card_test.dart`

**Interfaces — Produces:**
```dart
final felixTemplateIdsProvider;   // Set<String>, key 'felix_template_ids_v1'; add(ids), remove(ids)
List<PlannedSession> scheduleFelixPlan({required List<WorkoutTemplate> created, required String? when, required List<String>? days,
  required DateTime today, required List<PlannedSession> existing});
//   when=today → one session today (kept next to existing ones)
//   when=week, days given → each template on that weekday this week if ≥ today, else the same weekday next week
//   when=week, no days → spread over the next 7 days starting today, skipping days that already have a hard session and the day before/after a hard non-gym session (reuse plan rules from lib/features/plan)
//   when=null → no planned sessions (templates only, old behaviour)
```

**Behavior:**
- **Card:**
  - Felix avatar plus the eyebrow "FELIX PLAN".
  - Title: the plan name, or "{n} workouts".
  - A compact list of sessions (name · n exercises · first 3 exercise names), with day chips when scheduled (Today / Mon…).
  - One primary full-width accent button, 48 pt high, `AppRadius` card radius: "Add to My workouts", or "Add to today's plan" when `when=today`.
  - Pressed state with a short scale animation (≤ 200 ms, respects reduced motion).
  - After adding, the button becomes a quiet "Added ✓" row with "Open" (opens My workouts, or the week plan when sessions were scheduled) and "Undo". Undo removes the templates, their planned sessions and their Felix ids.
- **Badge:** every template whose id is in `felixTemplateIdsProvider` shows a small "Felix plan" chip (Felix avatar 16 px plus text) on its card everywhere templates are listed (Gym/sport screen, My workouts, the add-session sheet in the week plan).

- [ ] **Step 1: Write failing tests.**
  - `scheduleFelixPlan`: today puts 1 session on today; week with days [mon, wed, fri] on a Wednesday gives Wed and Fri this week and Mon next week; week without days on a week with football on Saturday puts no session on Fri, Sat or Sun when other days are free; null gives an empty list.
  - Applying adds the templates and the Felix ids, and the badge is shown on the Gym screen card.
  - Undo removes the templates, sessions and ids.
  - The card shows "Add to today's plan" for `when=today`.
  - SE size at 1.3 text: no overflow.
- [ ] **Step 2: Run them.** Expected: FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** `flutter test` and `flutter analyze`. Expected: all pass.

### Task 4: Dark map (Sonnet)

**Files:**
- Modify: `lib/features/map/presentation/map_screen.dart` (`_darkTiles` and overlays), `place_card.dart` as needed
- Test: `test/map_screen_test.dart` (extend)

**Values:**
- Dark tile filter = variant "soft" from `design/map-dark/` (Flutter `ColorFilter.matrix`, offsets in 0–255):
```
0.1713, -0.8644, -0.087, 0, 210.9,
-0.2577, -0.4354, -0.087, 0, 210.9,
-0.2577, -0.8644, 0.342, 0, 210.9,
0, 0, 0, 1, 0
```

**Behavior in dark mode:**
- The route polyline uses `palette.accent`, with a casing in `palette.background` at 60 % so it separates from the dark roads. Walk, bike, car and metro dashes keep their pattern.
- Metro line colours stay as is, with a dark casing.
- Pins use the palette tile/accent pair with a 1 px `palette.border` ring.
- The "© OpenStreetMap contributors" chip uses `palette.tile` at 85 % with `textSecondary`.
- The place card and the travel-mode pills use palette tokens; no light-only colours.
- Light mode is unchanged.

- [ ] **Step 1: Write failing tests.**
  - In dark theme the tile layer's `ColorFiltered` uses exactly the matrix above; in light it uses the identity.
  - The attribution text is present in both themes.
  - No `Colors.white`/`Color(0xFF…)` literal is used by the map overlays: grep-based test over `lib/features/map/presentation/`.
- [ ] **Step 2: Run them.** Expected: FAIL.
- [ ] **Step 3: Implement.** To check the look, re-render `design/map-dark/preview.html` with the final matrix (`node design/map-dark/shot.js`) and view `preview.png`.
- [ ] **Step 4: Run** `flutter test` and `flutter analyze`. Expected: all pass.

### Task 5: Integration — backend restart, phone build (Controller)

- [ ] Run `npm test`, `flutter test`, `flutter analyze` and `flutter build ios --release --no-codesign`. Expected: all green.
- [ ] Restart the backend with its env (see `lessons/fitrix-backend-restart-needs-env`). Then check with the real model:
  - "я съел 200 г курицы и 150 г риса" gives a food card;
  - "я набрал 3 кг" gives a weight card;
  - "составь план тренировки на сегодня" gives a plan card with "Add to today's plan".
- [ ] Install on the owner's iPhone (`flutter build ios --release --dart-define-from-file=env/cloud.json --dart-define=API_BASE_URL=http://<mac-ip>:3000`, then `flutter install --release -d <device>`).
