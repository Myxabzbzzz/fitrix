# FITRIX Quick Start

How to run the app with a real AI coach on your Mac.

## 1. Once: install the model

```bash
# https://ollama.com — install, then:
ollama pull qwen3:8b
```

Any model from `ollama list` works; set `OLLAMA_MODEL` when starting the
backend if you use a different one.

## 2. Start the backend

```bash
cd backend
npm install        # first time only
npm start
```

You should see:

```
🧠 Model: qwen3:8b (thinking off)
🔥 Model qwen3:8b loaded
```

Ollama itself must be running (the menu-bar app, or `ollama serve`).

## 3. Run the app

From the project root:

```bash
flutter run                 # pick the iOS simulator, macOS or Chrome
```

- **iOS simulator / macOS / web** — works as is (`http://localhost:3000`).
- **Physical iPhone** — the phone can't reach your Mac's `localhost`; use the
  Mac's Wi-Fi address (System Settings → Wi-Fi → Details):

  ```bash
  flutter run --dart-define=API_BASE_URL=http://<mac-ip>:3000
  ```

There is no `android/` folder in this repo yet, so Android isn't buildable.

## Check the backend

```bash
curl http://localhost:3000/health

# Streamed reply, as the app receives it
curl -N http://localhost:3000/chat/stream \
  -H 'Content-Type: application/json' \
  -d '{"message":"Give me 3 chest exercises","conversationId":"test"}'
```

## Troubleshooting

**The chat shows a red bubble with an error.** The backend is reachable but
Ollama failed; the message says why (e.g. model not installed → run the
`ollama pull` it suggests, or set `OLLAMA_MODEL`). Tap the bubble to retry.

**Felix answers with canned onboarding lines.** The app couldn't reach the
backend at all, so it fell back to offline replies. Check that `npm start`
is running and, on a physical phone, that `API_BASE_URL` points at your Mac.

**Replies are slow.** The first reply after starting Ollama loads the model
(several seconds); the backend preloads it on startup and keeps it in memory
for 30 minutes. Keep `OLLAMA_THINK` off — thinking mode is ~10× slower.

**Port 3000 is busy.** `lsof -i :3000` to find the process, or run on another
port (`PORT=3001 npm start`) and pass
`--dart-define=API_BASE_URL=http://localhost:3001` to `flutter run`.

## Starting over

Profile → **Sign out** deletes everything stored on the device (profile,
chats, workouts) and returns to onboarding. Restarting the backend clears
the conversation memory Felix keeps on the server.

## Tests

```bash
flutter test
```

## Quick reference

| Component | Port  | Command                          |
|-----------|-------|----------------------------------|
| Ollama    | 11434 | Ollama app or `ollama serve`     |
| Backend   | 3000  | `cd backend && npm start`        |
| App       | –     | `flutter run`                    |
