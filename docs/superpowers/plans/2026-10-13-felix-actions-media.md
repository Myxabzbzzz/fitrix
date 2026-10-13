# Felix actions, voice and photos — plan

Owner decisions (2026-10-13): speech-to-text on the phone; Felix understands photos (Ollama vision model `qwen2.5vl:7b`); anything Felix proposes to change is applied only after the user taps a confirmation button.

## Shared protocol (backend ⇄ app)

### Request (`POST /chat/stream`, existing body plus)
- `images`: optional array with at most 1 base64-encoded JPEG (no data: prefix), ≤ 1.5 MB decoded. When present the backend answers this turn with `OLLAMA_VISION_MODEL` (default `qwen2.5vl:7b`) and passes the image in Ollama's `images` field of the current user message. History turns never carry images.

### Response NDJSON events (existing `{delta}`, `{done:true}`, `{error}` plus)
- `{"action": {...}}` — at most one per reply, sent after the last `delta` and before `done`. Validated by the backend; invalid actions are dropped (logged without content).

Action shapes (exact):
```json
{"type": "weight", "mode": "set" | "delta", "kg": 78.5}
{"type": "workout_plan", "sport": "gym", "templates": [
   {"name": "Upper body", "exercises": [{"name": "Bench press", "sets": 4, "reps": 8, "kg": 60}]}]}
{"type": "meal_plan", "meals": [{"name": "Breakfast", "items": "Oatmeal, banana, 2 eggs", "kcal": 520}]}
```
Limits: `kg` 20–400 for set, −50…+50 for delta (lb converted by the backend: 1 lb = 0.4536 kg, rounded to 0.1); `sport` ∈ gym, fitness, cycling, running, football, winterSports; 1–7 templates, 1–12 exercises each, sets 1–10, reps 1–100, kg 0–500 optional; 1–8 meals, kcal 0–3000, strings ≤ 100 (items ≤ 200).

### How the model emits actions
The system prompt tells Felix to append, after the visible text, one block `<fitrix-action>{JSON}</fitrix-action>` when (a) the user reports a weight change or new weight ("я набрал 3 кг", "I'm 82 kg now", "lost 6 lb") — model emits `{"type":"weight","mode":"delta","amount":3,"unit":"kg"}` or `{"type":"weight","mode":"set","amount":82,"unit":"kg"}`; the backend normalizes to the shape above; (b) it gives a concrete multi-day workout plan → `workout_plan`; (c) it gives a concrete day of meals → `meal_plan`. The text should end with a short invitation like "Tap the button below to add it." in the user's language. The block is never streamed as text: the backend's stream filter holds back anything from `<fitrix-action` until the end, strips it, parses and validates it.

## Tasks (parallel)
- **A. Backend** (`backend/`): prompt rules, stream filter + parser + validation + `{action}` event (also in non-stream `/chat` response as `action` field), lb→kg, images passthrough with model switch and size limits, tests.
- **B. App — actions**: parse `{action}` events into the assistant ChatMessage (`action` field, persisted with the message, not sent in history), render a confirmation card under that bubble (Weight: "Update weight: 75 → 78 kg"; Workout plan: "Add N workouts to Gym" with a preview; Meal plan: "Add to today's nutrition" with kcal total), apply on tap, then show "Added ✓" (card state persisted so it can't be applied twice). Apply: weight → profile (+ account upload); workout_plan → WorkoutTemplates for that sport (existing workouts provider); meal_plan → a new local nutrition store that the Nutrition screen shows instead of sample meals for today. Tests.
- **C. App — voice + photos**: mic button in the Felix composer → on-device dictation (`speech_to_text`) into the input in the app language (ru-RU, uz-UZ if available else ru-RU, es-ES, en-US), Info.plist mic + speech usage texts; "+" button → camera / photo library (`image_picker`), compress to ≤ 1280 px JPEG q80, thumbnail in the user bubble, send as `images` to the backend; keep the photo locally with the message (path in the app's documents dir) — cloud storage of chat photos is a later step. Tests.

## Out of scope now
PDF/other files (vision models can't read them; "+" offers photos only), cloud sync of chat photos, nutrition cloud sync, voice replies (text-to-speech).
