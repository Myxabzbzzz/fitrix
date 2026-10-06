# FITRIX Quick Start

How to run the app with a real AI coach on your Mac.

## 1. Once: install the model

```bash
# https://ollama.com — install, then:
ollama pull qwen3:8b
```

Any model from `ollama list` works; set `OLLAMA_MODEL` when starting the
backend if you use a different one.

## 2. Start Supabase (local)

Sign-in and the database run on a local Supabase stack (Docker must be
running; install the CLI once with `brew install supabase/tap/supabase`):

```bash
supabase start -x vector,logflare,edge-runtime   # from the project root
```

It uses ports `553xx` (not the default `543xx`) so it can run next to other
local Supabase projects:

- API: http://127.0.0.1:55321
- Studio (tables, users): http://127.0.0.1:55323
- Mailpit (local inbox): http://127.0.0.1:55324 — **sign-in codes show up
  here**; no real email is sent locally

`supabase status` prints URLs and keys again; `supabase stop` stops it
(data is kept).

## 3. Start the backend

```bash
cd backend
npm install            # first time only
cp .env.example .env   # first time only; points at the local Supabase
npm start
```

You should see:

```
🧠 Model: qwen3:8b (thinking off)
🔐 Auth: Supabase access token required (issuer http://127.0.0.1:55321/auth/v1)
🔥 Model qwen3:8b loaded
```

Ollama itself must be running (the menu-bar app, or `ollama serve`).
Chatting requires signing in in the app; to hack on the backend without
sign-in, start it with `AUTH_MODE=off npm start` (never expose that).
All variables: [backend/README.md](backend/README.md#environment-variables).

## 4. Run the app

From the project root:

```bash
flutter run                 # pick the iOS simulator, Android emulator, macOS or Chrome
```

Sign in with any email; the 6-digit code arrives in Mailpit
(http://127.0.0.1:55324). "Continue with Google / Apple" say "coming soon"
until you set them up: see
[README.md → Google and Apple sign-in](README.md#google-and-apple-sign-in)
(Google client ids as `--dart-define`s plus
`ios/Flutter/GoogleSignIn.local.xcconfig` and `supabase/.env`; Apple needs a
paid Apple Developer account).

- **iOS simulator / macOS / web** — works as is (`http://localhost:3000`).
- **Android emulator** — works as is: on Android the app defaults to
  `http://10.0.2.2:3000`, which the emulator routes to your Mac, so keep the
  backend running on the Mac. Android needs Android Studio (SDK + an emulator
  from Device Manager); check with `flutter doctor`. Start an emulator, then:

  ```bash
  flutter emulators --launch <emulator-id>   # or start it from Android Studio
  flutter run -d emulator-5554               # id from `flutter devices`
  ```

- **Physical iPhone** — the phone can't reach your Mac's `localhost`; use the
  Mac's Wi-Fi address (System Settings → Wi-Fi → Details):

  ```bash
  flutter run --dart-define=API_BASE_URL=http://<mac-ip>:3000
  ```

- **Physical Android phone** — same `--dart-define` with the Mac's Wi-Fi
  address, phone on the same network. Android 9+ blocks plain `http://`
  by default; the app's cleartext allow-list lives in
  `android/app/src/main/res/xml/network_security_config.xml` (only
  `10.0.2.2`, `localhost`, `127.0.0.1`), so add
  `<domain includeSubdomains="false"><mac-ip></domain>` there too (the
  file's comment explains). Alternative over USB, no config change:

  ```bash
  adb reverse tcp:3000 tcp:3000
  flutter run --dart-define=API_BASE_URL=http://localhost:3000
  ```

- **Physical phone + local Supabase** — the phone also needs to reach the
  Supabase API on your Mac: add
  `--dart-define=SUPABASE_URL=http://<mac-ip>:55321` (and, on Android, the
  same cleartext allow-list entry as above).

## Check the backend

```bash
curl http://localhost:3000/health        # open, no token needed

# Without a token the chat answers 401
curl -s http://localhost:3000/chat/stream -H 'Content-Type: application/json' \
  -d '{"message":"hi","conversationId":"test"}'
# {"error":"Unauthorized","code":"missing_token","message":"Sign in to chat with Felix."}
```

To call the chat with curl, get a token (see
[backend/README.md → Getting a token for curl](backend/README.md#getting-a-token-for-curl-local-stack)),
then:

```bash
# Streamed reply, as the app receives it
curl -N http://localhost:3000/chat/stream \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"message":"Give me 3 chest exercises","conversationId":"test"}'
```

## Troubleshooting

**Felix says "Please sign in again to chat with Felix."** The backend
rejected the access token (401): not signed in, session expired, or the
app and backend use different Supabase projects. Sign in again; check that
the backend's `SUPABASE_URL` is the project the app uses
(`http://127.0.0.1:55321` locally — `127.0.0.1`, not `localhost`, since the
token's issuer must match). For local hacking, `AUTH_MODE=off npm start`.

**Felix says "You're sending messages too fast."** Per-user rate limit
(429, default 20 chat requests a minute, `RATE_LIMIT_PER_MINUTE`). Wait a
minute.

**No sign-in code arrives.** Locally codes go to Mailpit
(http://127.0.0.1:55324), not your inbox. Is `supabase start` running?

**The chat shows a red bubble with an error.** The backend is reachable but
Ollama failed; the message says why (e.g. model not installed → run the
`ollama pull` it suggests, or set `OLLAMA_MODEL`). Tap the bubble to retry.

**Felix answers with canned onboarding lines.** The app couldn't reach the
backend at all, so it fell back to offline replies. Check that `npm start`
is running and, on a physical phone, that `API_BASE_URL` points at your Mac.
The phone must be on the same Wi-Fi as the Mac, and the macOS firewall must
allow incoming connections to `node`.

**Replies are slow.** The first reply after starting Ollama loads the model
(several seconds); the backend preloads it on startup and keeps it in memory
for 30 minutes. Keep `OLLAMA_THINK` off — thinking mode is ~10× slower.

**Port 3000 is busy.** `lsof -i :3000` to find the process, or run on another
port (`PORT=3001 npm start`) and pass
`--dart-define=API_BASE_URL=http://localhost:3001` to `flutter run`.

## Starting over

Profile → **Sign out** deletes everything stored on the device (profile,
chats, workouts) and returns to onboarding. Restarting the backend clears
the conversation memory Felix keeps on the server. `supabase db reset`
re-creates the local database from `supabase/migrations/` (deletes local
users and their data).

## Tests

```bash
flutter test
cd backend && npm test
```

## Deploying

Cloud setup (Supabase project, `supabase link` / `db push`, email code
templates, SMTP, `--dart-define`s, backend env) is in
[README.md → Deploy to Supabase cloud](README.md#deploy-to-supabase-cloud).

## Quick reference

| Component               | Port  | Command                                          |
|-------------------------|-------|--------------------------------------------------|
| Ollama                  | 11434 | Ollama app or `ollama serve`                     |
| Supabase API            | 55321 | `supabase start -x vector,logflare,edge-runtime` |
| Supabase DB             | 55322 | (same)                                           |
| Supabase Studio         | 55323 | (same)                                           |
| Mailpit (sign-in codes) | 55324 | (same)                                           |
| Backend                 | 3000  | `cd backend && npm start`                        |
| App                     | –     | `flutter run`                                    |
