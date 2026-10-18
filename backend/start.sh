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
fi

OLLAMA_URL="${OLLAMA_URL:-http://localhost:11434}"
MODEL="${OLLAMA_MODEL:-qwen3:8b}"
TAGS="$(curl -s --max-time 3 "$OLLAMA_URL/api/tags" || true)"
if [ -z "$TAGS" ]; then
  echo "WARNING: Ollama is not running at $OLLAMA_URL (start the Ollama app or run: ollama serve)"
elif ! printf '%s' "$TAGS" | grep -q "\"name\":\"$MODEL\""; then
  echo "WARNING: model $MODEL is not pulled (run: ollama pull $MODEL)"
fi

[ -d node_modules ] || npm install

exec node server.js
