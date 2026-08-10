# TranslateOnTheGo

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Platform: Hyprland / Arch](https://img.shields.io/badge/platform-Hyprland%20%2F%20Arch-1793d1)](https://hyprland.org)
[![Provider: Gemini + Ollama](https://img.shields.io/badge/provider-Gemini%20%7C%20Ollama-4285F4)](#configuration)

Apple-style Writing Tools for Hyprland / Omarchy / Arch. Select text anywhere, hit a keybind, get **Translate / Proofread / Correct** powered by Gemini or a local LLM. Minimal GTK4 review window, result goes to clipboard.

No right-click menus on Wayland — so a Hyprland keybind is the closest idiom. Pick text → `Super + H` → action → review → paste.

---

## Features

- **Global trigger** via Hyprland keybind (`Super + H` by default) over your PRIMARY selection. Falls back to clipboard if nothing is selected.
- **Three actions** via [walker](https://github.com/abenz1267/walker) dmenu:
  - **Translate** — translate to your target language (Korean by default). If already in that language, translates to English.
  - **Proofread** — improve grammar, clarity, flow, naturalness. Keeps original language and tone.
  - **Correct** — fix only grammar / spelling / punctuation. No rephrasing.
- **Providers, swap with one config line:**
  - **Gemini** (`gemini-3.5-flash-lite` by default) — fast, cheap, free tier is plenty for personal use. The daily driver.
  - **Ollama** — a local model on your own GPU. Zero API cost, offline, private. Runs **only when you start it** (`tot-llm start`); it never autostarts at boot and stopping it frees the VRAM completely.
  - **LM Studio** — still supported, but Ollama is the lighter local option.
- **Minimal GTK4 review window** — original (read-only) + result (editable, so you can tweak before applying). `Ctrl+Enter` to copy, `Esc` to cancel.
- **Clipboard-based paste** — result goes to clipboard; you paste with `Ctrl+V` (or `Ctrl+Shift+V` in terminals). Reliable across every app; no flaky auto-paste.

---

## Screenshots

*(Add screenshots to `docs/` and reference them here.)*

---

## Requirements

- **Omarchy / Arch Linux** with **Hyprland** (Wayland compositor)
- `wl-clipboard`, `walker`, `curl`, `jq`, `libnotify`, `python`, `python-gobject`, `gtk4` — the installer will install any that are missing via `pacman`.
- **For Gemini**: a Google Gemini API key — free tier at <https://aistudio.google.com/apikey>
- **For Ollama**: `sudo pacman -S --needed ollama ollama-cuda` (or `ollama-vulkan` / `ollama-rocm` / plain `ollama` for CPU), plus enough VRAM for your chosen model
- **For LM Studio**: [LM Studio](https://lmstudio.ai/) with a chat model loaded and its local server running (default port `1234`)

---

## Installation

```bash
git clone https://github.com/guruthechosen/translateonthego.git
cd translateonthego
bash install.sh
```

Then configure a provider — see **[INSTRUCTION.md](INSTRUCTION.md)** for the step-by-step guide (Gemini key setup, LM Studio setup, customization, upgrading).

---

## Configuration

Config file: **`~/.config/translateonthego/config`** (bash-sourced).

```bash
# Provider: "gemini", "ollama", or "lmstudio"
PROVIDER="gemini"

# Gemini
# GEMINI_API_KEY="your-key-here"
MODEL="gemini-3.5-flash-lite"

# Ollama (used when PROVIDER="ollama")
OLLAMA_HOST="127.0.0.1:11434"
OLLAMA_MODEL="gemma4:e4b-it-qat"
OLLAMA_KEEP_ALIVE="5m"

# Translation target (if source is already this, translates to English)
TARGET_LANG="Korean"
```

Changes take effect on the next trigger — no reload, no relogin.

### Switching providers

Edit one line:

```bash
PROVIDER="gemini"     # cloud, needs API key
PROVIDER="ollama"     # local, needs `tot-llm start`
PROVIDER="lmstudio"   # local, needs LM Studio running
```

Typical workflow: Gemini as daily driver, switch to a local model when hitting quota, going offline, or handling text you'd rather not send anywhere.

**Auto-fallback:** If a local provider is selected but its server isn't running, the tool falls back to Gemini automatically (if `GEMINI_API_KEY` is set). A toast tells you it fell back. Disable with `FALLBACK_ENABLED="false"` in config if you want hard failure instead.

---

## Local models (`tot-llm`)

The local server is **manual-only by design**: nothing is enabled at boot, and stopping it releases both VRAM and RAM. It ships as a *user* systemd unit (`~/.config/systemd/user/ollama.service`) that is installed but never `enable`d.

```bash
tot-llm pull            # download the configured model
tot-llm start           # bring the server up
tot-llm status          # service state, what's in VRAM, disk usage
tot-llm test            # time a real round-trip
tot-llm unload          # free VRAM, leave the server up
tot-llm stop            # full shutdown — nothing resident
```

Models live in **`~/.local/share/ollama/models`** — owned by you, no `sudo` required to add or delete. (The distro's *system* `ollama.service` would instead use root-owned `/var/lib/ollama` and autostart at boot; `tot-llm` warns you if that unit ever gets enabled.)

### Choosing a model

Watch the VRAM ceiling — a model that doesn't fit spills onto the CPU and gets slow, which defeats the point.

| Tag | Size | Notes |
|-----|------|-------|
| `gemma4:e4b-it-qat` | 6.1 GB | Gemma 4 E4B, quantization-aware trained. Default. Fits 8 GB VRAM, 140+ languages. |
| `qwen3.5:4b` | 3.4 GB | Lighter and faster; strong multilingual. Set `OLLAMA_NO_THINK="true"`. |
| `gemma4:12b-it-qat` | 7.2 GB | Better quality, tight fit in 8 GB. |
| `gemma4:e4b` | 9.6 GB | The plain tag — **won't** fit in 8 GB. Prefer the `-it-qat` variant. |

Swap with one line in the config, then `tot-llm pull`.

### Changing the keybind

Edit `~/.config/hypr/translateonthego.conf` (symlinked from the repo):

```
bindd = SUPER, H, TranslateOnTheGo, exec, uwsm-app -- translateonthego
```

Change `SUPER, H` to taste, then `hyprctl reload`.

---

## Usage

1. Select text in any app (terminal, browser, editor — anywhere PRIMARY selection works).
2. Press **`Super + H`**.
3. Walker pops up — pick **Translate**, **Proofread**, or **Correct**.
4. Review window appears. Original on top, editable result below. Tweak if desired.
5. **Copy to Clipboard** (or `Ctrl+Enter`).
6. Back in your app, `Ctrl+V` (or `Ctrl+Shift+V` in terminals).

---

## Project layout

```
translateonthego/
├── bin/
│   ├── translateonthego    # main entry (bash)
│   ├── tot-llm             # start/stop/pull for the local Ollama server
│   └── tot-review.py       # GTK4 review window
├── lib/
│   ├── prompts.sh          # shared system prompts
│   ├── gemini.sh           # Gemini provider
│   ├── ollama.sh           # Ollama provider (native /api/chat)
│   └── lmstudio.sh         # LM Studio provider (OpenAI-compatible)
├── systemd/
│   └── ollama.service      # user unit, installed but never enabled
├── hypr/
│   └── translateonthego.conf   # Hyprland keybind + window rules
├── config.example          # config template
├── install.sh              # idempotent installer
├── uninstall.sh            # reverts install.sh
├── INSTRUCTION.md          # step-by-step setup
├── UNINSTALL.md            # full revert guide
├── LICENSE                 # MIT
└── README.md               # this file
```

### Installed paths

| Path | What |
|------|------|
| `~/.local/bin/translateonthego` | Symlink → `bin/translateonthego` |
| `~/.local/bin/tot-llm` | Symlink → `bin/tot-llm` |
| `~/.config/systemd/user/ollama.service` | Symlink → `systemd/ollama.service` (installed, not enabled) |
| `~/.local/share/ollama/models` | Downloaded local models |
| `~/.config/translateonthego/config` | User config |
| `~/.config/hypr/translateonthego.conf` | Symlink → `hypr/translateonthego.conf` |
| `~/.config/hypr/hyprland.conf` | Appended: `source = ~/.config/hypr/translateonthego.conf` |

See [UNINSTALL.md](UNINSTALL.md) for a complete revert guide.

---

## Troubleshooting

- **"GEMINI_API_KEY not set"** — Hyprland didn't inherit the env var (`~/.bashrc` is not sourced by the compositor). Put the key directly in `~/.config/translateonthego/config`, or add it to `~/.config/environment.d/translateonthego.conf` and relogin.
- **"Ollama unreachable at ..."** — the local server is stopped (which is its normal state). Run `tot-llm start`.
- **"model ... not found"** — the server is up but the model was never downloaded. Run `tot-llm pull`.
- **Local answers are slow / CPU fans spin up** — the model didn't fit in VRAM and spilled onto the CPU. Check with `tot-llm status`, then pick a smaller tag or lower `OLLAMA_NUM_CTX`.
- **"does not support thinking"** — `OLLAMA_NO_THINK="true"` was set for a model without a reasoning mode. Set it back to `"false"`.
- **"LM Studio unreachable at ..."** — LM Studio's local server isn't running. Start it from LM Studio → Developer → Start Server. Verify with `curl http://localhost:1234/v1/models`.
- **"No text selected or on clipboard"** — Some apps don't populate PRIMARY selection. Copy with `Ctrl+C` first, then trigger.
- **Walker doesn't appear** — Confirm `walker` is installed and runnable: `walker -v`.
- **API error toast** — Check your key, quota, and network. The Gemini error message is shown in the notification.

---

## Roadmap

- OpenAI provider (`lib/openai.sh`)
- Provider switcher in the walker menu (no config edit)
- Additional actions: Summarize, Make Shorter / Longer, Change Tone
- Optional auto-paste via `ydotool` (uinput-level, more reliable than `wtype`)
- Custom prompts via config
- Screenshots + demo GIF
- AUR package

---

## Contributing

PRs welcome. Small things:

- Follow existing style: bash with `set -euo pipefail`, Python 3 with stdlib + GTK4.
- Keep the review window minimal — this tool is supposed to stay out of your way.
- Test on a fresh clone before submitting.
- Adding a new provider? Put it in `lib/<provider>.sh` with the same contract: `action text_file` → stdout text, stderr errors.

Bug reports: include `hyprctl version`, the command line that failed, and what you expected.

---

## Inspiration

Apple's macOS Writing Tools — but without the OS lock-in. Built because I wanted the same ubiquity on Hyprland.

---

## License

MIT — see [LICENSE](LICENSE).
