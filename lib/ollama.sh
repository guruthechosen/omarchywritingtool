#!/usr/bin/env bash
set -euo pipefail

ACTION="${1:?action required}"
TEXT_FILE="${2:?text file required}"

LIB_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
# shellcheck source=lib/prompts.sh
source "$LIB_DIR/prompts.sh"

HOST="${OLLAMA_HOST:-127.0.0.1:11434}"
# Accept bare host:port (ollama's own convention) or a full URL.
[[ "$HOST" =~ ^https?:// ]] || HOST="http://$HOST"
URL="${OLLAMA_URL:-${HOST%/}/api/chat}"

MODEL_ID="${OLLAMA_MODEL:-gemma4:e4b-it-qat}"
TARGET_LANG="${TARGET_LANG:-Korean}"
# How long ollama keeps the model resident in VRAM after this request.
KEEP_ALIVE="${OLLAMA_KEEP_ALIVE:-5m}"
NUM_CTX="${OLLAMA_NUM_CTX:-8192}"
# Set to "true" for reasoning models (qwen3.x, exaone-deep) to skip the think
# pass. Left off by default: models without thinking support reject the field.
NO_THINK="${OLLAMA_NO_THINK:-false}"

TEXT="$(cat "$TEXT_FILE")"

if ! SYSTEM="$(tot_system_prompt "$ACTION" "$TARGET_LANG")"; then
  echo "Unknown action: $ACTION" >&2
  exit 2
fi

BODY="$(jq -n \
  --arg model "$MODEL_ID" \
  --arg sys "$SYSTEM" \
  --arg user "$TEXT" \
  --arg keep "$KEEP_ALIVE" \
  --argjson ctx "$NUM_CTX" \
  --argjson nothink "$NO_THINK" \
  '{
    model: $model,
    messages: [
      { role: "system", content: $sys },
      { role: "user",   content: $user }
    ],
    stream: false,
    keep_alive: $keep,
    options: { temperature: 0.2, num_ctx: $ctx }
  }
  | if $nothink then .think = false else . end')"

# curl's own transport error is suppressed — the message below is more useful,
# and anything the server actually returns comes back in $RESP.
RESP="$(curl -sS --connect-timeout 3 --max-time 180 -X POST "$URL" \
  -H 'Content-Type: application/json' \
  -d "$BODY" 2>/dev/null)" || {
    echo "Ollama unreachable at $URL — start it with: tot-llm start" >&2
    exit 1
  }

ERR="$(echo "$RESP" | jq -r '.error.message // .error // empty' 2>/dev/null)"
if [[ -n "$ERR" && "$ERR" != "null" ]]; then
  # The most common failure by far: server is up, model was never pulled.
  if [[ "$ERR" == *"not found"* ]]; then
    echo "$ERR — pull it with: tot-llm pull $MODEL_ID" >&2
  else
    echo "$ERR" >&2
  fi
  exit 1
fi

OUT="$(echo "$RESP" | jq -r '.message.content // empty' 2>/dev/null)"
if [[ -z "$OUT" ]]; then
  echo "Empty or malformed response from Ollama" >&2
  exit 1
fi

# Reasoning models leak a <think>…</think> preamble even when asked not to.
# Strip it so the review window shows the answer, not the monologue.
OUT="$(printf '%s' "$OUT" | perl -0777 -pe 's{\A\s*<think>.*?</think>\s*}{}s')"

printf '%s' "$OUT"
