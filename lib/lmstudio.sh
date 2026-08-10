#!/usr/bin/env bash
set -euo pipefail

ACTION="${1:?action required}"
TEXT_FILE="${2:?text file required}"

LIB_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
# shellcheck source=lib/prompts.sh
source "$LIB_DIR/prompts.sh"

URL="${LMSTUDIO_URL:-http://localhost:1234/v1/chat/completions}"
MODEL_ID="${LMSTUDIO_MODEL:-local-model}"
TARGET_LANG="${TARGET_LANG:-Korean}"

TEXT="$(cat "$TEXT_FILE")"

if ! SYSTEM="$(tot_system_prompt "$ACTION" "$TARGET_LANG")"; then
  echo "Unknown action: $ACTION" >&2
  exit 2
fi

BODY="$(jq -n \
  --arg model "$MODEL_ID" \
  --arg sys "$SYSTEM" \
  --arg user "$TEXT" \
  '{
    model: $model,
    messages: [
      { role: "system", content: $sys },
      { role: "user",   content: $user }
    ],
    temperature: 0.2,
    stream: false
  }')"

RESP="$(curl -sS --connect-timeout 3 --max-time 120 -X POST "$URL" \
  -H 'Content-Type: application/json' \
  -d "$BODY")" || {
    echo "LM Studio unreachable at $URL — is the server running?" >&2
    exit 1
  }

ERR="$(echo "$RESP" | jq -r '.error.message // .error // empty' 2>/dev/null)"
if [[ -n "$ERR" && "$ERR" != "null" ]]; then
  echo "$ERR" >&2
  exit 1
fi

OUT="$(echo "$RESP" | jq -r '.choices[0].message.content // empty' 2>/dev/null)"
if [[ -z "$OUT" ]]; then
  echo "Empty or malformed response from LM Studio" >&2
  exit 1
fi
printf '%s' "$OUT"
