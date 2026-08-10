#!/usr/bin/env bash
set -euo pipefail

ACTION="${1:?action required}"
TEXT_FILE="${2:?text file required}"

LIB_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
# shellcheck source=lib/prompts.sh
source "$LIB_DIR/prompts.sh"

: "${GEMINI_API_KEY:?GEMINI_API_KEY not set}"
MODEL="${MODEL:-gemini-3.5-flash-lite}"
TARGET_LANG="${TARGET_LANG:-Korean}"

TEXT="$(cat "$TEXT_FILE")"

if ! SYSTEM="$(tot_system_prompt "$ACTION" "$TARGET_LANG")"; then
  echo "Unknown action: $ACTION" >&2
  exit 2
fi

BODY="$(jq -n \
  --arg sys "$SYSTEM" \
  --arg user "$TEXT" \
  '{
    system_instruction: { parts: [ { text: $sys } ] },
    contents: [ { role: "user", parts: [ { text: $user } ] } ],
    generationConfig: { temperature: 0.2 }
  }')"

URL="https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:generateContent"

RESP="$(curl -sS -X POST "$URL" \
  -H "x-goog-api-key: ${GEMINI_API_KEY}" \
  -H 'Content-Type: application/json' \
  -d "$BODY")" || {
    echo "curl failed" >&2
    exit 1
  }

ERR="$(echo "$RESP" | jq -r '.error.message // empty')"
if [[ -n "$ERR" ]]; then
  echo "$ERR" >&2
  exit 1
fi

echo "$RESP" | jq -r '
  [ .candidates[0].content.parts[]?.text ] | join("")
'
