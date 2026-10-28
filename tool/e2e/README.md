# FITRIX on-simulator e2e harness: how to rerun it

Everything runs against the **local** Supabase stack (`supabase start`, API on
127.0.0.1:55321), never the cloud project. The app's defaults already point to
the local stack, so only `API_BASE_URL` is passed. Nothing here touches the
live Felix server on port 3000.

## Files

| Path (repo) | What it is |
|---|---|
| `integration_test/e2e_01_onboarding_test.dart` | First launch → language → email code → profile → onboarding chat (Felix) → transition → Home |
| `integration_test/e2e_02_home_gym_test.dart` | Check-in → Recovery → week plan add → gym live log (sets, RPE, rest, mini sheet drag) → finish → Progress → Nutrition (search, quick add, detail, water) |
| `integration_test/e2e_03_activities_test.dart` | Run with simulated GPS (pause/resume, run bar, 30 s in background, finish, RPE, save, history) → outdoor ride → indoor ride log/edit/delete → ski day (flat) → football match |
| `integration_test/e2e_04_felix_profile_test.dart` | Data restored on a fresh install → Felix hub + chat → Discover / Shop / Map → Profile edit → sign out → sign in → Connected apps → Apple Health sheet |
| `integration_test/e2e_05_felix_deep_test.dart` | Felix full reply, leaving mid-reply, "I ate…" food action → Nutrition, backend-down error path, HR zones |
| `integration_test/support/` | `e2e.dart` (finders, steps, screenshots, error capture), `l10n.dart` (localized finders, `E2E_LANG`), `sign_in.dart` |
| `tool/e2e/host_helper.py` | Host-side HTTP helper on 127.0.0.1:8765: `simctl` screenshots/videos, simulated GPS, backgrounding the app, privacy grants, reading the sign-in code from Mailpit, stopping/starting the **3100** backend |
| `tool/e2e/run.sh` | Runs phases: boots the simulator, starts the helper if needed, reinstalls the last build + grants permissions, `flutter test <phase> -d <udid>` |
| `tool/e2e/sheet.sh`, `tool/e2e/frames.sh` | ffmpeg contact sheets of screenshots / tiled video frames (`frames.sh v.mov --gaps` prints frame cadence) |

`pubspec.yaml` gained `integration_test: sdk: flutter` under dev_dependencies.

## One-time setup

```bash
cd /Users/myxabzbzzzz/РАБОТА/fitrix
export PATH="/Users/myxabzbzzzz/РАБОТА/flutter/bin:$PATH"
open -a Docker                       # wait for `docker info` to succeed
supabase start                       # local stack; applies supabase/migrations
flutter pub get

# Felix backend for the e2e run on 3100 (verifies LOCAL tokens; Ollama qwen3:8b)
OUT=/private/tmp/claude-501/-Users-myxabzbzzzz--------fitrix/3181f353-a107-40c3-9418-ab2c1542d488/scratchpad/e2e
(cd backend && SUPABASE_URL=http://127.0.0.1:55321 PORT=3100 nohup node server.js > $OUT/backend3100.log 2>&1 &)

# A dedicated simulator so the owner's simulators keep their data
UDID=$(xcrun simctl create "FITRIX E2E 17 Pro" com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro com.apple.CoreSimulator.SimRuntime.iOS-26-5)
xcrun simctl boot $UDID && open -a Simulator
# (this session used DC27C1CC-859D-4A2C-A465-F5B665246554 = "FITRIX E2E 17 Pro",
#  and 1CB49320-FE63-4061-9A79-C762E2E274AA = "FITRIX E2E 17e" for the small screen)
```

## Run

```bash
# Phase 1 creates + onboards the account, so use a NEW email for it:
UDID=$UDID E2E_EMAIL=e2e-$(date +%s)@fitrix.test tool/e2e/run.sh integration_test/e2e_01_onboarding_test.dart
# Later phases sign in to that same (onboarded) account on a fresh install:
UDID=$UDID E2E_EMAIL=<same email> tool/e2e/run.sh \
  integration_test/e2e_02_home_gym_test.dart \
  integration_test/e2e_03_activities_test.dart \
  integration_test/e2e_04_felix_profile_test.dart \
  integration_test/e2e_05_felix_deep_test.dart
```

Options (env): `E2E_LANG=ru|en|uz|es` (default `ru`; the language the walk
picks — finders use the app's own ARB strings), `E2E_ONLY=gym,nutrition`
(phase sections: phase 2 `checkin,plan,gym,progress,nutrition`; phase 3
`run,runhist,ride,indoor,ski,football`; phase 5 `reply,food,error,zones`),
`E2E_OUT` (artifacts dir), `API_BASE_URL` (default `http://127.0.0.1:3100`).
The helper must run with the same `--udid`; `run.sh` starts it if port 8765
is free — restart it yourself when switching simulators:

```bash
pkill -f tool/e2e/host_helper.py
nohup python3 tool/e2e/host_helper.py --udid $UDID --out $OUT > $OUT/logs/helper.log 2>&1 &
```

## Artifacts (in `$OUT`)

- `shots/NNN_<step>.png` — simulator screenshot after every step (`FAILED_` prefix when the step failed; the walk continues).
- `videos/<NN_name>.mov` — recordings around transitions; `tool/e2e/frames.sh videos/x.mov out.png <start> <dur> <fps> [cols]` tiles frames.
- `steps.log` — timeline (steps, screenshots, GPS, background, OTP, backend stop/start).
- `report_<phase>.txt` — step failures + Flutter framework errors captured during the phase.
- `logs/<phase>.log` — full `flutter test` output.

## Gotchas learned the hard way

- `flutter test` on a device **uninstalls the app after each run**, so every
  phase starts like a reinstall and signs in again (that doubles as the
  "data survives through cloud sync" check).
- Privacy grants only stick to an installed app, and `simctl privacy grant`
  on the running app **kills it** — `run.sh` therefore reinstalls the last
  build, grants, then lets `flutter test` install over it.
- Stop `simctl io recordVideo` with SIGINT to `simctl` itself (not the `xcrun`
  wrapper), or CoreSimulator keeps recording ("Host recording is already in
  progress") until the simulator is rebooted. The helper does this.
- Integration tests run a **debug** build (the simulator has no profile/release
  mode), so frame pacing in videos is not representative of device performance.
- HealthKit's permission sheet is native; a Flutter test can't tap it.

## Cleanup

```bash
pkill -f tool/e2e/host_helper.py
lsof -ti tcp:3100 -sTCP:LISTEN | xargs kill      # the e2e backend only
supabase stop                                     # optional
xcrun simctl delete DC27C1CC-859D-4A2C-A465-F5B665246554 1CB49320-FE63-4061-9A79-C762E2E274AA  # optional
```
