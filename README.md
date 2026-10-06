# FITRIX - AI-Powered Fitness Application

Flutter app with an AI fitness coach, **Felix**, powered by a local
[Ollama](https://ollama.com) model through a small Node.js backend.

Platforms in this repo: iOS, Android, macOS and web.

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
ollama pull qwen3:8b                              # once
supabase start -x vector,logflare,edge-runtime    # local auth + database
cd backend && npm install && cp .env.example .env && npm start
flutter run                                       # from the project root
```

With no `--dart-define`, the app talks to `http://localhost:3000` on the iOS
simulator, macOS and web, and to `http://10.0.2.2:3000` on Android (the
emulator's alias for the host Mac). On a physical phone pass your Mac's LAN
address:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.0.103:3000
```

On a physical **Android** phone also add that IP to the cleartext allow-list
in
`android/app/src/main/res/xml/network_security_config.xml` (cleartext is
only permitted for `10.0.2.2`, `localhost` and `127.0.0.1` by default).
Over USB you can skip that with `adb reverse tcp:3000 tcp:3000` and
`--dart-define=API_BASE_URL=http://localhost:3000`.

If the backend isn't reachable at all, the onboarding chat falls back to
canned replies so the flow can still be completed. If the backend is up but
the model fails, the chat shows the error with "Tap to retry".

## Backend

`backend/server.js` (Express) proxies chat to Ollama:

- `POST /chat/stream` — streamed reply as NDJSON (`{"delta"}` … `{"done"}`),
  used by the app
- `POST /chat` — same, as a single JSON reply
- `GET /health`, `GET /models`, `POST /chat/reset`

The chat endpoints require a Supabase sign-in: the app sends the user's
access token as `Authorization: Bearer …` and the backend verifies it
against the project's public signing keys (JWKS). Missing/invalid/expired
tokens get `401` (the app shows "Please sign in again"), more than
`RATE_LIMIT_PER_MINUTE` requests per user get `429`. `/health` is open.

When the app doesn't send `history`, the server keeps the conversation in
memory per user and `conversationId`, so it resets when the server restarts.
Configuration (Supabase, model, thinking mode, keep-alive, rate limit) is
described in [backend/README.md](backend/README.md); copy
`backend/.env.example` to `backend/.env` to set it.

## Supabase (local)

Auth (email sign-in codes) and the database run on
[Supabase](https://supabase.com). For development the whole stack runs
locally in Docker via the [Supabase CLI](https://supabase.com/docs/guides/local-development/cli/getting-started):

```bash
brew install supabase/tap/supabase       # once; Docker must be running
supabase start -x vector,logflare,edge-runtime
supabase status                          # URLs and keys
```

`-x` skips services the app doesn't use (log collection, analytics, edge
functions), which makes startup faster and lighter. `supabase start`
applies the migrations in `supabase/migrations/` (tables with row level
security) on first start.

The ports are `553xx` instead of the CLI's default `543xx` (see
`supabase/config.toml`) so this stack can run next to other local Supabase
projects:

| Service | URL |
|---------|-----|
| API (auth, REST) | http://127.0.0.1:55321 |
| Database | `postgresql://postgres:postgres@127.0.0.1:55322/postgres` |
| Studio (tables, users) | http://127.0.0.1:55323 |
| Mailpit (local inbox) | http://127.0.0.1:55324 |

**Sign-in codes locally:** no real email is sent. Every sign-in code lands
in Mailpit — open http://127.0.0.1:55324, pick the newest "Your FITRIX
sign-in code" mail and type the 6 digits into the app. The email body comes
from `supabase/templates/otp_code.html`.

With no `--dart-define`, the app uses the local stack
(`http://127.0.0.1:55321`, `http://10.0.2.2:55321` on the Android emulator)
and the local publishable key. The backend needs
`SUPABASE_URL=http://127.0.0.1:55321` (already in `backend/.env.example`).

`supabase stop` stops the stack and keeps the data; `supabase db reset`
re-creates the local database from the migrations (deletes local users and
data).

## Deploy to Supabase cloud

1. **Create a project** at https://supabase.com/dashboard (pick a region
   close to your users, keep the database password).
2. **Link and push the schema** from the project root:

   ```bash
   supabase login
   supabase link --project-ref <project-ref>   # asks for the DB password
   supabase db push                            # applies supabase/migrations/
   ```

   `<project-ref>` is the `xxxx` in `https://xxxx.supabase.co`.
   `supabase/config.toml` only configures the local stack; cloud auth
   settings are made in the dashboard (next steps).
3. **Email sign-in codes.** The app signs in with a 6-digit email code, not
   a link. In Dashboard → Authentication → Emails → Templates, set **both**
   templates to the content of `supabase/templates/otp_code.html` (it uses
   `{{ .Token }}`, the code), subject "Your FITRIX sign-in code":
   - **Magic Link** — sent to existing users signing in
   - **Confirm signup** — sent to new users on their first sign-in

   Check Authentication → Sign In / Providers → Email: Email provider
   enabled, "Email OTP Length" 6, "Email OTP Expiration" 3600 s (the app
   and template expect 6 digits / 1 hour).
4. **Real SMTP.** Supabase's built-in mailer only delivers to your team's
   addresses and a few emails per hour — fine for a smoke test, not for
   users. In Authentication → Emails → SMTP Settings enable custom SMTP
   (Resend, Postmark, SES, …) with your sender address, then raise the email
   limit in Authentication → Rate Limits.
5. **Run the app against the cloud project** (keys: Project Settings → API
   Keys; the publishable key is safe to ship, row level security protects
   the data):

   ```bash
   flutter run \
     --dart-define=SUPABASE_URL=https://<project-ref>.supabase.co \
     --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_... \
     --dart-define=API_BASE_URL=https://<your-backend-host>
   ```

   Use the same `--dart-define`s for `flutter build`.
6. **Backend for the cloud project** (`backend/.env` or the host's env):

   ```bash
   SUPABASE_URL=https://<project-ref>.supabase.co
   AUTH_MODE=required             # fail at startup if SUPABASE_URL is missing
   RATE_LIMIT_PER_MINUTE=20
   # Only if Project Settings → JWT Keys still shows the legacy secret in use:
   # SUPABASE_JWT_SECRET=<legacy JWT secret>
   ```

   No service-role or secret key is needed: tokens are checked with the
   project's public keys. The backend must also reach an Ollama server
   (`OLLAMA_URL`) and should be served over HTTPS.

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

Covers chat streaming and retries (against a local fake backend, including
the `Authorization` header and the 401/429 messages), workout persistence
and history, progress charts, onboarding redirect and sign-out, and the main
workout flow. Backend tests: `cd backend && npm test`.
