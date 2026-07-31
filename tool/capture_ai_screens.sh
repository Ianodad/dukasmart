#!/usr/bin/env bash
# Capture the two AI screenshots that need a VALID Anthropic key:
#   17-ask-answer       — Ask your duka, after an answer has rendered
#   18-daily-report-ai  — the AI insight card on the daily report
#
# The other two AI shots (15-dashboard-ai, 16-ask-suggestions) do not need a
# real key — any non-empty string makes those surfaces render. See
# docs/screenshots/CAPTURE.md for why those two bars differ.
#
# Usage:
#   tool/capture_ai_screens.sh            # prompts for the key (not echoed)
#   ANTHROPIC_API_KEY=sk-ant-... tool/capture_ai_screens.sh
#
# The key is deliberately NOT taken as a command-line argument: argv is visible
# to every process on the box via `ps`, and lands in your shell history.
#
# Use a scoped or expiring key and revoke it afterwards — it is baked into the
# build this script produces. Do not distribute that build.

set -euo pipefail
cd "$(dirname "$0")/.."

PORT="${PORT:-8771}"
OUT="docs/screenshots"
MIRROR="remotion/public/screens"

if [[ -z "${ANTHROPIC_API_KEY:-}" ]]; then
  read -rsp "Anthropic API key (input hidden): " ANTHROPIC_API_KEY
  echo
fi
if [[ -z "${ANTHROPIC_API_KEY}" ]]; then
  echo "error: no key given — the AI surfaces would render but every call would 401." >&2
  exit 1
fi

export PATH="$HOME/flutter/bin:$PATH"

if ! command -v google-chrome >/dev/null; then
  echo "error: google-chrome not on PATH — the capture rig drives it over CDP." >&2
  exit 1
fi

# Preflight the key BEFORE spending a build on it.
#
# Without this the run is a footgun: any non-empty string makes the AI surfaces
# render, so a dead key still produces four plausible-looking PNGs — 17 holding
# an error bubble and 18 silently missing its card — writes them into
# docs/screenshots/, mirrors them into remotion/public/screens/, and exits 0.
# One cheap call turns that into a fast, loud failure.
if command -v curl >/dev/null; then
  echo "==> checking the key against the API"
  code=$(curl -sS -o /dev/null -w '%{http_code}' -m 30 \
    -X POST https://api.anthropic.com/v1/messages \
    -H "x-api-key: ${ANTHROPIC_API_KEY}" \
    -H "anthropic-version: 2023-06-01" \
    -H "content-type: application/json" \
    -d '{"model":"claude-haiku-4-5-20251001","max_tokens":1,"messages":[{"role":"user","content":"hi"}]}' \
    || echo "000")
  case "${code}" in
    200) echo "    key OK" ;;
    401|403)
      echo "error: the API rejected this key (HTTP ${code})." >&2
      echo "       Every AI surface would still RENDER — isConfigured is just" >&2
      echo "       apiKey.isNotEmpty — so the run would produce four" >&2
      echo "       plausible-looking but wrong PNGs. Stopping instead." >&2
      exit 1 ;;
    000) echo "warning: could not reach the API (network?). Continuing — check the output by eye." >&2 ;;
    *)   echo "warning: unexpected preflight status ${code}. Continuing — check the output by eye." >&2 ;;
  esac
else
  echo "warning: curl not found, skipping the key preflight." >&2
fi

echo "==> building web with the key compiled in"
flutter build web --dart-define=ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY}"

if (ss -ltn 2>/dev/null || netstat -ltn 2>/dev/null) | grep -qw ":${PORT}"; then
  echo "error: port ${PORT} is already in use — set PORT=<other> and re-run." >&2
  exit 1
fi

echo "==> serving build/web on :${PORT}"
python3 -m http.server "${PORT}" --directory build/web >/dev/null 2>&1 &
SERVER_PID=$!
trap 'kill "${SERVER_PID}" 2>/dev/null || true' EXIT
sleep 2

echo "==> seeding a realistic trading day (three sales + an expense)"
rm -rf /tmp/dukasmart-drive-profile
node tool/drive_ui.mjs "http://localhost:${PORT}" "${OUT}" tool/seed_demo_day.json

echo "==> asking a question and closing the day"
node tool/drive_ui.mjs "http://localhost:${PORT}" "${OUT}" tool/capture_ai_day.json

for f in 15-dashboard-ai 16-ask-suggestions 17-ask-answer 18-daily-report-ai; do
  if [[ -f "${OUT}/${f}.png" ]]; then
    cp "${OUT}/${f}.png" "${MIRROR}/${f}.png"
    printf '%-22s %s\n' "${f}.png" "$(file -b "${OUT}/${f}.png" | cut -d, -f2 | tr -d ' ')"
  else
    echo "MISSING ${f}.png" >&2
  fi
done

cat <<'EOF'

Done — but the exit code proves nothing about what is IN the images.
The rig taps blind coordinates; a stale tap lands on nothing and still exits 0.

Open all four and check by eye:
  17-ask-answer      must show an ANSWER bubble, not "Something went wrong"
                     and not the empty suggestion-chip state
  18-daily-report-ai must show the AI insight card BELOW the rule-based one

Then ask one question in Swahili to close Open Flag 0, and REVOKE the key.
EOF
