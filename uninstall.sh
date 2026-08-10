#!/usr/bin/env bash
set -euo pipefail

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/translateonthego"
BIN_LINK="$HOME/.local/bin/translateonthego"
LLM_LINK="$HOME/.local/bin/tot-llm"
UNIT_DST="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user/ollama.service"
MODELS_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/ollama/models"
HYPR_DST="$HOME/.config/hypr/translateonthego.conf"
HYPR_MAIN="$HOME/.config/hypr/hyprland.conf"
SOURCE_LINE="source = ~/.config/hypr/translateonthego.conf"

say() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }

say "Removing $BIN_LINK"
rm -f "$BIN_LINK"

say "Removing $LLM_LINK"
rm -f "$LLM_LINK"

if [[ -L "$UNIT_DST" || -f "$UNIT_DST" ]]; then
  say "Stopping and removing the Ollama user unit"
  systemctl --user stop ollama.service 2>/dev/null || true
  rm -f "$UNIT_DST"
  systemctl --user daemon-reload 2>/dev/null || true
fi

say "Removing $HYPR_DST"
rm -f "$HYPR_DST"

if [[ -f "$HYPR_MAIN" ]] && grep -qxF "$SOURCE_LINE" "$HYPR_MAIN"; then
  say "Stripping source line from $HYPR_MAIN (backup at ${HYPR_MAIN}.bak)"
  cp "$HYPR_MAIN" "${HYPR_MAIN}.bak"
  awk -v line="$SOURCE_LINE" '
    /^# TranslateOnTheGo$/ { next }
    { if ($0 == line) next; print }
  ' "${HYPR_MAIN}.bak" > "$HYPR_MAIN"
fi

if [[ -d "$CONFIG_DIR" ]]; then
  read -r -p "Delete config at $CONFIG_DIR? [y/N] " ans
  if [[ "$ans" =~ ^[Yy]$ ]]; then
    rm -rf "$CONFIG_DIR"
    say "Removed $CONFIG_DIR"
  else
    say "Kept $CONFIG_DIR"
  fi
fi

if [[ -d "$MODELS_DIR" ]] && [[ -n "$(ls -A "$MODELS_DIR" 2>/dev/null)" ]]; then
  say "Downloaded models still occupy $(du -sh "$MODELS_DIR" 2>/dev/null | cut -f1) at $MODELS_DIR"
  read -r -p "Delete them too? [y/N] " ans
  if [[ "$ans" =~ ^[Yy]$ ]]; then
    rm -rf "$MODELS_DIR"
    say "Removed $MODELS_DIR"
  else
    say "Kept $MODELS_DIR"
  fi
fi

if command -v hyprctl >/dev/null 2>&1; then
  hyprctl reload >/dev/null 2>&1 && say "Hyprland reloaded" || true
fi

cat <<EOF

\033[1;32mUninstalled.\033[0m

Notes:
  - Project files at $(cd "$(dirname "$(readlink -f "$0")")" && pwd) untouched. Delete manually if desired.
  - Packages installed by install.sh not removed. Remove manually with pacman -Rns <pkg> if wanted.
  - If GEMINI_API_KEY was exported in ~/.bashrc / ~/.zshrc or ~/.config/environment.d/, remove it manually.

EOF
