#!/bin/bash
# Runs one or more e2e phases on the iOS Simulator against the LOCAL stack.
# Usage: tool/e2e/run.sh <phase-file> [<phase-file> ...]
#   e.g. tool/e2e/run.sh integration_test/e2e_01_onboarding_test.dart
# Env: UDID (default iPhone 17 Pro), E2E_OUT (artifacts dir), E2E_EMAIL,
#      API_BASE_URL (default http://127.0.0.1:3100).
# Prereqs (see README.md): `supabase start`, backend on :3100, helper running
# (this script starts the helper if it isn't up).
set -euo pipefail
cd "$(dirname "$0")/../.."
export PATH="${FLUTTER_BIN:-/Users/myxabzbzzzz/РАБОТА/flutter/bin}:$PATH"
UDID="${UDID:-060E5201-1362-4413-84B6-0EBEF6C6BBA7}"
OUT="${E2E_OUT:-/private/tmp/claude-501/-Users-myxabzbzzzz--------fitrix/3181f353-a107-40c3-9418-ab2c1542d488/scratchpad/e2e}"
API="${API_BASE_URL:-http://127.0.0.1:3100}"
EMAIL="${E2E_EMAIL:-e2e@fitrix.test}"
mkdir -p "$OUT/logs"

xcrun simctl boot "$UDID" 2>/dev/null || true

# Privacy grants only stick to an installed app, and `flutter test` uninstalls
# the app after every run (and granting to a running app kills it). So put
# the last build back first, grant, and let `flutter test` install over it
# (an in-place install keeps the grants).
grant() {
  if [ -d build/ios/iphonesimulator/Runner.app ]; then
    xcrun simctl install "$UDID" build/ios/iphonesimulator/Runner.app || true
  fi
  for svc in location location-always photos microphone camera; do
    xcrun simctl privacy "$UDID" grant "$svc" com.elibayev.fitrix 2>/dev/null || true
  done
}

if ! curl -s --max-time 2 http://127.0.0.1:8765/ping >/dev/null; then
  python3 tool/e2e/host_helper.py --udid "$UDID" --out "$OUT" >"$OUT/logs/helper.log" 2>&1 &
  echo $! >"$OUT/helper.pid"
  sleep 1
fi
curl -s --max-time 2 http://127.0.0.1:8765/ping >/dev/null || { echo "helper not up"; exit 1; }

for target in "$@"; do
  name="$(basename "$target" .dart)"
  echo "=== $name"
  grant
  flutter test "$target" -d "$UDID" \
    --dart-define=API_BASE_URL="$API" \
    --dart-define=E2E_EMAIL="$EMAIL" \
    --dart-define=E2E_ONLY="${E2E_ONLY:-}" \
    --dart-define=E2E_LANG="${E2E_LANG:-ru}" \
    2>&1 | tee "$OUT/logs/$name.log" || true
done
