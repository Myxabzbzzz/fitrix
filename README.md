# FITRIX - AI-Powered Fitness Application

Flutter app with an AI fitness coach, **Felix**, powered by a local
[Ollama](https://ollama.com) model through a small Node.js backend.

Platforms in this repo: iOS, macOS and web (there is no `android/` folder yet).

## What's in the app

**Onboarding** (shown once; later launches open Home)
- Intro → language → sign-in → profile → chat with Felix → "Felix is ready"
- Sign-in is a local mock: any email works, Google/Apple buttons don't
  call real providers

**Main app** (5-tab bar: Discover · Shop · Home · Felix · Profile)
- **Home** — tiles for My progress, My nutrition, Felix, My workouts, Shop,
  Fitrix map
- **My workouts** — sports → workout plans (today's workout, Start/Edit, add
  your own)
- **Active workout** — sets table (previous / kg / reps / done), live timer,
  collapses to a mini bar above the tab bar and survives an app restart
- **My progress** — strength charts and recent sessions from your saved
  workouts; body weight and calories are sample data for now
- **My nutrition** — calorie ring and macros (sample data)
- **Felix chats** — general assistant plus a trainer chat per sport; replies
  stream in word by word
- **About me** — profile data and Sign out (clears everything on the device)
- Discover, Shop and Fitrix map are "Coming soon" placeholders

Light and dark themes follow the system setting. The language picker saves
your choice, but the UI is English-only for now.

## Running it

See [QUICKSTART.md](QUICKSTART.md). In short:

```bash
ollama pull qwen3:8b                 # once
cd backend && npm install && npm start
flutter run                          # from the project root
```

The app talks to `http://localhost:3000` by default, which works for the iOS
simulator, macOS and web. On a physical phone pass your Mac's LAN address:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.0.103:3000
```

If the backend isn't reachable at all, the onboarding chat falls back to
canned replies so the flow can still be completed. If the backend is up but
the model fails, the chat shows the error with "Tap to retry".

## Backend

`backend/server.js` (Express) proxies chat to Ollama:

- `POST /chat/stream` — streamed reply as NDJSON (`{"delta"}` … `{"done"}`),
  used by the app
- `POST /chat` — same, as a single JSON reply
- `GET /health`, `GET /models`, `POST /chat/reset`

Conversation history is kept in the server's memory per `conversationId`, so
it resets when the server restarts. Configuration (model, thinking mode,
keep-alive) is described in [backend/README.md](backend/README.md).

## Data storage

Everything is stored on the device with `shared_preferences`: language,
email, profile, onboarding status, chat histories, workout plans, the workout
in progress and workout history. Sign out deletes all of it.

## Project structure

```
lib/
├── core/
│   ├── constants/      # API URL, storage keys, copy
│   ├── router/         # go_router routes, onboarding redirect, tab shell
│   ├── session/        # onboarding status / sign-out, preloaded prefs
│   ├── theme/          # Material themes, AppPalette design tokens
│   └── widgets/        # Logo, tiles, pills, page titles
├── features/
│   ├── intro/ language/ auth/ profile/ transition/   # onboarding
│   ├── home/ shell/                                    # Home + tab bar
│   ├── workouts/       # plans, active workout, history, storage
│   ├── progress/       # charts
│   ├── nutrition/
│   └── chat/           # Felix: streaming API client, chats, bubbles
└── main.dart           # loads storage, then starts the app
```

## Tech stack

Flutter · Riverpod · go_router · shared_preferences · dio (streaming HTTP)

## Tests

```bash
flutter test
```

Covers chat streaming and retries (against a local fake backend), workout
persistence and history, progress charts, onboarding redirect and sign-out,
and the main workout flow.
