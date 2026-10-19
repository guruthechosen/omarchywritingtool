#!/usr/bin/env bash
set -euo pipefail

PROJ_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/translateonthego"
BIN_LINK="$HOME/.local/bin/translateonthego"
LLM_LINK="$HOME/.local/bin/tot-llm"
UNIT_SRC="$PROJ_DIR/systemd/ollama.service"
UNIT_DST="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user/ollama.service"
# Hyprland has two config providers. Omarchy 4+ (and any Hyprland reporting
# `configProvider: lua`) uses hyprland.lua and `require`; older setups use
# hyprland.conf and `source =`. Detect rather than assume, or a distro upgrade
# silently orphans the keybind.
if [[ -f "$HOME/.config/hypr/hyprland.lua" ]] \
   || hyprctl systeminfo 2>/dev/null | grep -qi 'configProvider:[[:space:]]*lua'; then
  HYPR_PROVIDER="lua"
  HYPR_SRC="$PROJ_DIR/hypr/translateonthego.lua"
  HYPR_DST="$HOME/.config/hypr/translateonthego.lua"
  HYPR_MAIN="$HOME/.config/hypr/hyprland.lua"
  SOURCE_LINE='require("hypr.translateonthego")'
else
  HYPR_PROVIDER="conf"
  HYPR_SRC="$PROJ_DIR/hypr/translateonthego.conf"
  HYPR_DST="$HOME/.config/hypr/translateonthego.conf"
  HYPR_MAIN="$HOME/.config/hypr/hyprland.conf"
  SOURCE_LINE="source = ~/.config/hypr/translateonthego.conf"
fi

say() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[warn]\033[0m %s\n' "$*" >&2; }
die() { printf '\033[1;31m[err]\033[0m %s\n' "$*" >&2; exit 1; }

# 1. Deps
say "Checking dependencies…"
missing=()
for cmd in curl jq wl-paste wl-copy hyprctl notify-send python3; do
  command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
done

# The action menu works with any dmenu-style picker, so require *one of* them
# rather than a specific launcher. Omarchy 4 dropped walker for its own shell
# menu; pinning walker here would force an unwanted package onto that setup.
PICKER=""
for p in walker omarchy-menu-select fuzzel wofi rofi; do
  if command -v "$p" >/dev/null 2>&1; then PICKER="$p"; break; fi
done
if [[ -z "$PICKER" ]]; then
  say "No menu program found — installing fuzzel (small, Wayland-native)."
  missing+=("fuzzel")
fi

if (( ${#missing[@]} )); then
  say "Installing missing packages via pacman: ${missing[*]}"
  pkg_map=(
    "wl-paste:wl-clipboard"
    "wl-copy:wl-clipboard"
    "notify-send:libnotify"
    "hyprctl:hyprland"
    "fuzzel:fuzzel"
    "curl:curl"
    "jq:jq"
    "python3:python"
  )
  pkgs=()
  for m in "${missing[@]}"; do
    for entry in "${pkg_map[@]}"; do
      k="${entry%%:*}"; v="${entry##*:}"
      if [[ "$m" == "$k" ]]; then pkgs+=("$v"); fi
    done
  done
  if (( ${#pkgs[@]} )); then
    sudo pacman -S --needed "${pkgs[@]}"
  fi
fi

[[ -n "$PICKER" ]] && say "Action menu will use: $PICKER"

python3 -c "import gi; gi.require_version('Gtk','4.0'); from gi.repository import Gtk" \
  2>/dev/null || die "python-gobject + gtk4 missing. Install: sudo pacman -S python-gobject gtk4"

# 2. Perms
say "Marking scripts executable…"
chmod +x "$PROJ_DIR/bin/translateonthego" "$PROJ_DIR/bin/tot-review.py" \
  "$PROJ_DIR/bin/tot-llm" \
  "$PROJ_DIR/lib/gemini.sh" "$PROJ_DIR/lib/lmstudio.sh" "$PROJ_DIR/lib/ollama.sh"

# 3. Config dir
say "Setting up config at $CONFIG_DIR"
mkdir -p "$CONFIG_DIR"
if [[ ! -f "$CONFIG_DIR/config" ]]; then
  cp "$PROJ_DIR/config.example" "$CONFIG_DIR/config"
  chmod 600 "$CONFIG_DIR/config"
  say "Created $CONFIG_DIR/config (edit to customize)"
else
  say "Config exists, leaving untouched"
fi

# 4. Symlink
say "Symlinking $BIN_LINK → $PROJ_DIR/bin/translateonthego"
mkdir -p "$(dirname "$BIN_LINK")"
ln -sfn "$PROJ_DIR/bin/translateonthego" "$BIN_LINK"
ln -sfn "$PROJ_DIR/bin/tot-llm" "$LLM_LINK"

# 4b. Ollama user unit — installed but deliberately never enabled, so it can
#     only ever be started by hand via `tot-llm start`.
say "Installing on-demand Ollama user unit at $UNIT_DST"
mkdir -p "$(dirname "$UNIT_DST")"
ln -sfn "$UNIT_SRC" "$UNIT_DST"
systemctl --user daemon-reload 2>/dev/null || warn "systemctl --user daemon-reload failed"

# The unit has no [Install] section on purpose, so `systemctl enable` cannot
# succeed and no preset sweep can ever turn it on. It starts only via tot-llm.
if systemctl is-enabled ollama.service >/dev/null 2>&1; then
  warn "The SYSTEM ollama.service is enabled and will autostart at boot."
  warn "To keep local models manual-only: sudo systemctl disable --now ollama.service"
fi

if command -v ollama >/dev/null 2>&1; then
  # Only create the model store for people who actually have Ollama.
  mkdir -p "${XDG_DATA_HOME:-$HOME/.local/share}/ollama/models"
else
  say "Ollama not installed. Optional — only needed for local models:"
  say "  sudo pacman -S --needed ollama ollama-cuda   # or ollama-vulkan / ollama-rocm"
fi

# 4c. PATH sanity — the symlinks are useless if this directory isn't on PATH.
case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) warn "$HOME/.local/bin is not on your PATH — 'translateonthego' and 'tot-llm'"
     warn "won't be runnable by name. Add to your shell rc:"
     warn "  export PATH=\"\$HOME/.local/bin:\$PATH\""
     ;;
esac

# 5. Hyprland config symlink + load line
say "Installing Hyprland config ($HYPR_PROVIDER provider)"
ln -sfn "$HYPR_SRC" "$HYPR_DST"

# An upgrade that switches providers leaves the old file loaded by nothing.
# Clear it out so it can't be mistaken for the live config later.
if [[ "$HYPR_PROVIDER" == "lua" && -L "$HOME/.config/hypr/translateonthego.conf" ]]; then
  rm -f "$HOME/.config/hypr/translateonthego.conf"
  say "Removed the orphaned .conf symlink (this setup uses the lua provider)"
fi
if [[ -f "$HOME/.config/hypr/hyprland.conf" ]] && [[ "$HYPR_PROVIDER" == "lua" ]] \
   && grep -qxF "source = ~/.config/hypr/translateonthego.conf" "$HOME/.config/hypr/hyprland.conf" 2>/dev/null; then
  warn "$HOME/.config/hypr/hyprland.conf still has the old 'source =' line, but this"
  warn "setup loads hyprland.lua. The stale line is harmless; remove it if you like."
fi

if [[ -f "$HYPR_MAIN" ]]; then
  if ! grep -qxF "$SOURCE_LINE" "$HYPR_MAIN"; then
    if [[ "$HYPR_PROVIDER" == "lua" ]]; then
      printf '\n-- TranslateOnTheGo\n%s\n' "$SOURCE_LINE" >> "$HYPR_MAIN"
    else
      printf '\n# TranslateOnTheGo\n%s\n' "$SOURCE_LINE" >> "$HYPR_MAIN"
    fi
    say "Added load line to $HYPR_MAIN"
  else
    say "Load line already present in $HYPR_MAIN"
  fi
else
  warn "Hyprland config not found at $HYPR_MAIN — add manually: $SOURCE_LINE"
fi

# 6. Reload Hyprland
if command -v hyprctl >/dev/null 2>&1; then
  if hyprctl reload >/dev/null 2>&1; then
    say "Hyprland reloaded"
  else
    warn "hyprctl reload failed"
  fi
fi

cat <<EOF

\033[1;32mInstalled.\033[0m

Next steps:
  1. Configure a provider — edit $CONFIG_DIR/config and either:

       a) Paste your GEMINI_API_KEY inside the config file (chmod 600'd).
          Get one free at https://aistudio.google.com/apikey

       b) Switch PROVIDER="ollama" for local models. Then:
            sudo pacman -S --needed ollama ollama-cuda
            tot-llm pull        # downloads the configured model
            tot-llm start       # only when you want it; never at boot
            tot-llm stop        # frees VRAM and exits the daemon

  2. Optionally change TARGET_LANG in the same file (default: Korean).

  3. Select text in any app, press \033[1mSuper + H\033[0m, pick an action.

Full guide: INSTRUCTION.md

EOF
