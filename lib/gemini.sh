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

if ! SYSTEM="$(tot_system_prompt "$ACTION" "$TARGET_LANG")"; then
  echo "Unknown action: $ACTION" >&2
  exit 2
fi

BODY="$(jq -n \
  --arg sys "$SYSTEM" \
  --rawfile user "$TEXT_FILE" \
  '{
    system_instruction: { parts: [ { text: $sys } ] },
    contents: [ { role: "user", parts: [ { text: $user } ] } ],
    generationConfig: { temperature: 0.2 }
  }')"

URL="https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:generateContent"

# Keep the credential and request body out of process arguments. Bash writes
# the header through a private pipe; curl reads the JSON from standard input.
if [[ "$GEMINI_API_KEY" == *$'\r'* || "$GEMINI_API_KEY" == *$'\n'* ]]; then
  echo "GEMINI_API_KEY must not contain line breaks" >&2
  exit 1
fi
RESP="$(printf '%s' "$BODY" | curl -sS -X POST "$URL" \
  -H @<(printf 'x-goog-api-key: %s\n' "$GEMINI_API_KEY") \
  -H 'Content-Type: application/json' \
  --data-binary @-)" || {
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
