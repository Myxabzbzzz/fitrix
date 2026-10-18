#!/bin/bash
# Starts the FITRIX backend against the cloud Supabase project.
# Usage: backend/start.sh   (any directory)
#
# SUPABASE_URL is taken from ../env/cloud.json when it exists and the
# variable is not already set. Only the host is printed, never any key.

set -e
cd "$(dirname "$0")"

CLOUD_JSON="../env/cloud.json"
if [ -z "$SUPABASE_URL" ] && [ -f "$CLOUD_JSON" ]; then
  SUPABASE_URL="$(node -e '
    const c = JSON.parse(require("fs").readFileSync(process.argv[1], "utf8"));
    process.stdout.write(typeof c.SUPABASE_URL === "string" ? c.SUPABASE_URL : "");
  ' "$CLOUD_JSON")"
  if [ -n "$SUPABASE_URL" ]; then
    export SUPABASE_URL
    echo "Using cloud Supabase ($(node -e 'console.log(new URL(process.argv[1]).host)' "$SUPABASE_URL"))"
  fi
  if [ -z "$SUPABASE_URL" ]; then
    echo "WARNING: $CLOUD_JSON has no SUPABASE_URL; the server will use SUPABASE_URL from backend/.env (local Supabase), or run with auth OFF if none"
  fi
elif [ -z "$SUPABASE_URL" ]; then
  echo "WARNING: $CLOUD_JSON not found; the server will use SUPABASE_URL from backend/.env (local Supabase), or run with auth OFF if none"
fi

# Pick OLLAMA_URL / OLLAMA_MODEL from backend/.env when not set in the environment
# (only these two keys are read; nothing else is parsed or printed).
env_value() {
  [ -f .env ] || return 0
  sed -n "s/^[[:space:]]*$1[[:space:]]*=[[:space:]]*//p" .env | tail -n 1 | sed -e 's/[[:space:]]*$//' -e 's/^"\(.*\)"$/\1/' -e "s/^'\(.*\)'\$/\1/"
}
[ -n "$OLLAMA_URL" ] || OLLAMA_URL="$(env_value OLLAMA_URL)"
[ -n "$OLLAMA_MODEL" ] || OLLAMA_MODEL="$(env_value OLLAMA_MODEL)"
OLLAMA_URL="${OLLAMA_URL:-http://localhost:11434}"
MODEL="${OLLAMA_MODEL:-qwen3:8b}"
TAGS="$(curl -s --max-time 3 "$OLLAMA_URL/api/tags" || true)"
if [ -z "$TAGS" ]; then
  echo "WARNING: Ollama is not running at $OLLAMA_URL (start the Ollama app or run: ollama serve)"
elif ! printf '%s' "$TAGS" | grep -qF -e "\"name\":\"$MODEL\"" -e "\"name\":\"${MODEL}:latest\""; then
  echo "WARNING: model $MODEL is not pulled (run: ollama pull $MODEL)"
fi

[ -d node_modules ] || npm install

exec node server.js
