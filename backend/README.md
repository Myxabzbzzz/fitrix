# FITRIX Backend Server

Node.js/Express backend that connects the FITRIX Flutter app to Ollama LLM.

## Features

- ✅ REST API for chat functionality
- ✅ Topic-specific Felix personas (app assistant + a trainer per sport)
- ✅ Conversation history sent by the app, or kept in server memory
- ✅ Ollama integration with context preservation
- ✅ Supabase sign-in required for chat (access token verified locally via
  JWKS), per-user conversation memory and rate limit
- ✅ CORS enabled for Flutter app
- ✅ Error handling and health checks

## Prerequisites

1. **Node.js** (v20.12 or higher; reads `.env` with `process.loadEnvFile`)
   ```bash
   node --version
   ```

2. **Ollama** installed and running
   ```bash
   # Install Ollama: https://ollama.ai
   ollama --version

   # Pull a model (default: qwen3:8b)
   ollama pull qwen3:8b

   # Start Ollama server
   ollama serve
   ```

## Installation

1. Install dependencies:
   ```bash
   cd backend
   npm install
   ```

2. Configure the environment:
   ```bash
   cp .env.example .env       # then edit; .env is git-ignored
   ```
   `npm start` loads `backend/.env`; variables already set in the shell win.

### Environment variables

| Variable | Default | Meaning |
|----------|---------|---------|
| `PORT` | `3000` | HTTP port |
| `OLLAMA_URL` | `http://localhost:11434` | Ollama server |
| `OLLAMA_MODEL` | `qwen3:8b` | any model from `ollama list` |
| `OLLAMA_THINK` | `false` | `true` re-enables reasoning (~10x slower replies) |
| `OLLAMA_KEEP_ALIVE` | `30m` | keep the model loaded between messages |
| `OLLAMA_TIMEOUT_MS` | `120000` | give up (`504`) after this long without a response or new tokens from Ollama |
| `LOG_CHAT_CONTENT` | `false` | `true` writes chat messages and replies to the log (personal data: debugging only); off, the log shows only their length |
| `SUPABASE_URL` | – | Supabase project URL (local: `http://127.0.0.1:55321`, cloud: `https://<ref>.supabase.co`). Turns auth on. |
| `SUPABASE_JWT_SECRET` | – | legacy HS256 JWT secret; only for projects that still sign tokens with it |
| `SUPABASE_JWT_ISSUER` | `<SUPABASE_URL>/auth/v1` | expected `iss` claim, if it differs (custom domain) |
| `AUTH_MODE` | `required` if Supabase is configured, else `off` | `off` disables auth (local hacking only); `required` refuses to start without Supabase config |
| `RATE_LIMIT_PER_MINUTE` | `20` | chat requests per user per minute before `429`; `0` disables |

The startup log says whether auth is on:

```
🔐 Auth: Supabase access token required (issuer http://127.0.0.1:55321/auth/v1)
🚦 Rate limit: 20 chat requests/min per user
```

or warns `⚠️  Auth: OFF — anyone who can reach this server can use the model.`

## Running the Server

### Development Mode (with auto-reload)
```bash
npm run dev
```

### Production Mode
```bash
npm start
```

Server will start on: `http://localhost:3000`

## Authentication

`POST /chat`, `/chat/stream` and `/chat/reset` require the signed-in user's
Supabase access token:

```
Authorization: Bearer <access token>
```

The app sends it automatically (`supabase_flutter` keeps it fresh).
`GET /health` and `GET /models` stay open.

**How tokens are verified.** Supabase Auth signs access tokens with an
asymmetric key — ES256 on the local stack and on new cloud projects (RS256
is supported too). The backend fetches the public keys from
`<SUPABASE_URL>/auth/v1/.well-known/jwks.json`, caches them for 10 minutes
and refetches when a token names an unknown `kid` (key rotation, at most once
per 30 s); no call to Supabase is made per request. Projects still on the
legacy shared secret sign with HS256; for those set `SUPABASE_JWT_SECRET`
(HS256 tokens are rejected otherwise). Every token must also have a valid
signature, an `exp` in the future (30 s clock tolerance), `aud`
`"authenticated"` (so the anon/service-role API keys don't count as users),
`iss` equal to `<SUPABASE_URL>/auth/v1` and a `sub` (the user id). Algorithm
`none` and anything else is rejected. Code: `auth.js`.

**Errors.** Missing, invalid or expired tokens get `401` with a
`WWW-Authenticate: Bearer …` header and:

```json
{"error": "Unauthorized", "code": "missing_token", "message": "Sign in to chat with Felix."}
{"error": "Unauthorized", "code": "invalid_token", "message": "Invalid access token (bad signature). Please sign in again."}
{"error": "Unauthorized", "code": "expired_token", "message": "Your session has expired. Please sign in again."}
```

If the signing keys can't be fetched at all (Supabase down before the first
successful fetch) the answer is `503 Auth unavailable` rather than `401`, so
the app doesn't tell a signed-in user to sign in again.

**Per user.** The verified user id (`sub`) scopes the server-side
conversation memory: the same `conversationId` from two users is two separate
conversations, so nobody can read or continue someone else's chat, and
`/chat/reset` only resets the caller's own. Each user may send
`RATE_LIMIT_PER_MINUTE` chat requests per minute (sliding window, in memory);
beyond that:

```
HTTP/1.1 429 Too Many Requests
Retry-After: 58
{"error": "Too many requests", "message": "You're sending messages too fast. Please wait 58s and try again.", "retryAfter": 58}
```

Memory and rate-limit counters live in the process: they reset on restart
and aren't shared between several backend instances.

**Local hacking without sign-in:** `AUTH_MODE=off npm start` (or leave
`SUPABASE_URL` unset). Never expose such a server.

### Getting a token for curl (local stack)

```bash
API=http://127.0.0.1:55321
KEY=sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH   # local publishable key
EMAIL=me@fitrix.test

curl -s $API/auth/v1/otp -H "apikey: $KEY" -H 'Content-Type: application/json' \
  -d "{\"email\":\"$EMAIL\",\"create_user\":true}"
# Read the 6-digit code in Mailpit (http://127.0.0.1:55324) and use it below
TOKEN=$(curl -s $API/auth/v1/verify -H "apikey: $KEY" -H 'Content-Type: application/json' \
  -d "{\"type\":\"email\",\"email\":\"$EMAIL\",\"token\":\"123456\"}" \
  | python3 -c 'import json,sys; print(json.load(sys.stdin)["access_token"])')
```

Tokens are valid for an hour (`jwt_expiry` in `supabase/config.toml`).

## API Endpoints

### 1. Health Check
```bash
GET /health

Response:
{
  "status": "ok",
  "message": "FITRIX Backend is running"
}
```

### 2. Send Chat Message
```bash
POST /chat

Request:
{
  "message": "What should my protein intake be?",   // required, 1-4000 chars
  "conversationId": "uuid-here",                   // required, <= 200 chars
  "topic": "gym",                                  // optional, see below
  "profile": {                                     // optional
    "name": "Misha",
    "age": 27,
    "weightKg": 82,
    "heightCm": 181
  },
  "history": [                                     // optional, oldest first
    { "role": "assistant", "content": "Hey! I'm Felix, your gym trainer." },
    { "role": "user", "content": "I want to bulk" },
    { "role": "assistant", "content": "Eat in a small surplus..." }
  ]
}

Response:
{
  "reply": "Based on your weight of 82 kg, aim for 131-180 g of protein a day..."
}
```

Fields:

- `topic`: which Felix answers. `"app"` (default) is the general app
  assistant; `"gym"`, `"fitness"`, `"cycling"`, `"running"`, `"football"`
  and `"winterSports"` (the app's `Sport.name` values) are trainers focused
  on that sport. Unknown values fall back to `"app"`.
- `profile`: what Felix knows about the user, added to the system prompt.
  Known fields: `name`, `age` (years), `weightKg`, `heightCm`, plus optional
  `sex`, `goal`, `experience`. Numbers may be numbers or numeric strings;
  implausible values (e.g. `heightCm: 9999`) and unknown fields are dropped.
- `history`: the recent conversation as the app shows it, **not** including
  `message`. Entries need `role` `"user"` or `"assistant"` and a non-empty
  string `content` (cut to 4000 chars); anything else is skipped and only
  the last 20 entries are used. When `history` is present (even `[]`) it is
  the whole context and the server's memory for `conversationId` is neither
  read nor written, so a backend restart doesn't make Felix forget the chat.
  Without `history` the server keeps the last 20 turns per `conversationId`
  in memory, as before. A conversation idle for an hour is forgotten, and at
  most 1000 are kept (the least recently used goes first).

The system prompt is built per request from `topic` and `profile`: Felix
replies in the user's language, in plain text, and politely declines
anything unrelated to fitness, health, nutrition or the app in one short
sentence. Markdown the model emits anyway (`**bold**`, `#` headings, `* `
bullets) is stripped from the reply.

Invalid requests (malformed JSON, missing or oversized `message` or
`conversationId`) get `400 {"error": "...", "message": "..."}`. If Ollama
stays silent for `OLLAMA_TIMEOUT_MS` the answer is `504`; other model
failures are `500` with a generic message (the details go to the server
log only).

All `/chat` endpoints need `Authorization: Bearer <token>` (see
[Authentication](#authentication)); without it they answer `401`.

### 3. Reset Conversation
```bash
POST /chat/reset   (resets only the caller's own conversation)

Request:
{
  "conversationId": "uuid-here"
}

Response:
{
  "message": "Conversation reset successfully"
}
```

### 4. List Available Models
```bash
GET /models

Response:
{
  "models": [...]
}
```

## Testing

### Test with curl:
```bash
# Health check
curl http://localhost:3000/health

# Send message ($TOKEN: see "Getting a token for curl")
curl -X POST http://localhost:3000/chat \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "message": "Hello Felix!",
    "conversationId": "test-123"
  }'
```

### Test with Postman:
1. Import the endpoints above
2. Set method to POST
3. Add JSON body and an `Authorization: Bearer <token>` header
4. Send request

### Unit tests

```bash
npm test
```

Covers the prompt, markdown stripping, token verification (locally signed
ES256/RS256/HS256 tokens, a stub JWKS: expiry, audience, issuer, tampering,
key rotation) and the HTTP layer against a stub Ollama (401s, per-user
memory, 429).

## Configuration

### Change Ollama Model

```bash
OLLAMA_MODEL=llama3.2 npm start
```

The model is preloaded at startup so the first reply isn't delayed.

### Streaming

`POST /chat/stream` takes the same body as `/chat` and answers with
newline-delimited JSON as tokens are generated:

```
{"delta":"Bench"}
{"delta":" press"}
{"done":true}
```

If the model fails mid-reply the last line is `{"error":"..."}`. The Flutter
app uses this endpoint so replies appear word by word.

### Change Port

Start with custom port:
```bash
PORT=8080 npm start
```

Or edit the PORT constant in `server.js`.

### Customize Felix's Personality

Edit `prompt.js`: `TOPICS` holds the persona for each chat topic and
`BASE_RULES` the style, language and scope rules shared by all of them.
Run `npm test` after changing it.

## Connecting to Flutter App

1. Start this backend server (with `SUPABASE_URL` pointing at the same
   Supabase project the app signs in to)
2. Run the Flutter app; it uses `http://localhost:3000` by default
   (`10.0.2.2:3000` on the Android emulator), or pass another address:
   ```bash
   flutter run -d macos --dart-define=API_BASE_URL=http://localhost:3000
   ```
3. Sign in in the app; chat requests then carry the access token. A `401`
   shows "Please sign in again to chat with Felix.", a `429` asks the user
   to slow down.

## Troubleshooting

### 401 "Invalid access token (wrong issuer)"
The token's `iss` must equal `<SUPABASE_URL>/auth/v1`. Locally use
`SUPABASE_URL=http://127.0.0.1:55321` (not `localhost`), or set
`SUPABASE_JWT_ISSUER`. Also check the app and backend use the same project.

### 401 "HS256 tokens are not accepted"
The project signs with the legacy JWT secret: set `SUPABASE_JWT_SECRET`.

### 401 "Sign in to chat with Felix" from the app
The app isn't signed in to Supabase (or runs without it). Sign in, or run
the backend with `AUTH_MODE=off` while hacking locally.

### Error: "Ollama is not running"
```bash
# Start Ollama in a separate terminal
ollama serve
```

### Error: "ECONNREFUSED"
- Make sure Ollama is running on port 11434
- Check `OLLAMA_URL` configuration

### Error: "Model not found"
```bash
# Pull the configured model first (or set OLLAMA_MODEL to one you have)
ollama pull qwen3:8b
```

### Port already in use
```bash
# Change port
PORT=3001 npm start
```

## Development

### File Structure
```
backend/
├── server.js          # Express app and Ollama calls
├── auth.js            # Supabase token verification (JWKS/HS256), rate limit
├── prompt.js          # System prompt per topic/profile, input validation
├── plainText.js       # Strips markdown from (streamed) replies
├── *.test.js          # Unit tests: npm test (testTokens.js: test helpers)
├── .env.example       # Configuration template (copy to .env)
├── package.json       # Dependencies
└── README.md         # This file
```

### Adding Features

To add new endpoints, edit `server.js`:
```javascript
app.post('/your-endpoint', async (req, res) => {
  // Your logic here
});
```

## Production Deployment

For production:
- Set `SUPABASE_URL=https://<project-ref>.supabase.co` (and
  `SUPABASE_JWT_SECRET` only if the project still uses the legacy secret);
  consider `AUTH_MODE=required` so a missing variable fails at startup
  instead of silently running without auth
- Tune `RATE_LIMIT_PER_MINUTE`; for several instances behind a load balancer
  move rate limits and conversation memory to a shared store
- Serve over HTTPS (reverse proxy), add request logging
- Use PM2 or similar for process management

See "Deploy to Supabase cloud" in the main [README](../README.md).

```bash
# Install PM2
npm install -g pm2

# Start with PM2
pm2 start server.js --name fitrix-backend

# Monitor
pm2 logs fitrix-backend
```

## License

Part of the FITRIX fitness application.
