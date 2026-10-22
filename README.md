# TranslateOnTheGo

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Platform: Hyprland / Arch](https://img.shields.io/badge/platform-Hyprland%20%2F%20Arch-1793d1)](https://hyprland.org)
[![Provider: Gemini + Ollama](https://img.shields.io/badge/provider-Gemini%20%7C%20Ollama-4285F4)](#configuration)

Writing tools for your **Omarchy bar**. Translate a message, polish a draft, or fix
typos without moving your text into a separate chat. Select text, click
**Writing**, choose an action, then review and edit the result before copying
it back into your app.

Works with **Gemini**, **Ollama**, or **LM Studio**. Also available as a
standalone Hyprland tool with an optional `Super+H` shortcut.

[Install the plugin](#omarchy-quattro-plugin) · [Provider setup](PLUGIN.md#install-and-configure) · [Marketplace listing](https://plugins.omarchy.org/plugin.html?id=io.github.guruthechosen.translateonthego)

![TranslateOnTheGo: translate, proofread, and correct from the Omarchy bar, with the actual review window](preview.png)

## What can it do?

| Action | Use it for | What it asks the model to do |
| --- | --- | --- |
| **Translate** | Messages, emails, and passages in another language | Translate into your configured target language (Korean by default). Text already in that language is translated into English. |
| **Proofread** | A draft that needs to read more naturally | Improve grammar, clarity, and flow while preserving the original language, meaning, and tone. |
| **Correct** | Typos and grammar fixes with minimal rewriting | Fix spelling, grammar, and punctuation while preserving your wording as much as possible. |

The original stays visible above an **editable result**. Review the output,
make any final changes, and click **Copy to Clipboard** (`Ctrl+Enter`). Paste
with `Ctrl+V`, or `Ctrl+Shift+V` in a terminal. `Esc` cancels.

## Everyday workflow

1. Select the text you want to work on in your browser, editor, or another app.
2. Click **Writing** in the Omarchy bar (**Aa** on a vertical bar).
3. Choose **Translate**, **Proofread**, or **Correct** from your menu picker.
4. Review and optionally edit the result, then copy and paste it back.

If an app does not expose its selection, press `Ctrl+C` first. The tool tries
the PRIMARY selection before the clipboard; the review window warns when it
uses clipboard contents. Always check that the original shown is the text you
intended. The plugin does not replace text in your app automatically.

## Screenshots

### Proofread a draft

Compare the original with the editable result before copying it back.

![Proofread review showing a sample launch update before and after editing](docs/screenshots/proofread.png)

### Translate a message

This example shows English to Korean. Change `TARGET_LANG` in your config to
choose another target language.

![Translate review showing a sample English message and a Korean translation](docs/screenshots/translate.png)

Screenshots show the actual GTK4 review window with prepared, fictional sample
input and output. They illustrate the interface, not a provider benchmark.
The appearance follows your GTK theme; the action picker follows your installed
menu tool.

## Choose your provider

- **Gemini** sends the chosen text to Google's API and requires your own API key.
- **Ollama** uses a running server and a downloaded model. With a localhost
  endpoint, processing runs on your machine.
- **LM Studio** uses its running local server with a model loaded.

For local-only operation, set `FALLBACK_ENABLED="false"`. Otherwise, a failed
local request can fall back to Gemini when a Gemini key is configured. Provider
setup is required after installing the plugin; see [the plugin guide](PLUGIN.md).

---

## Requirements

- **Omarchy / Arch Linux** with **Hyprland** (Wayland compositor)
- `wl-clipboard`, `curl`, `jq`, `libnotify`, `python`, `python-gobject`, `gtk4` — install missing dependencies explicitly for the plugin; the standalone installer can install them via `pacman`.
- **A dmenu-style picker** — any one of `walker`, `omarchy-menu-select` (ships with Omarchy 4+), `fuzzel`, `wofi`, or `rofi`. The tool uses whichever it finds. The standalone installer can install `fuzzel` if you have none.
- **For Gemini**: your own [Google Gemini API key](https://aistudio.google.com/apikey)
- **For Ollama**: `sudo pacman -S --needed ollama ollama-cuda` (or `ollama-vulkan` / `ollama-rocm` / plain `ollama` for CPU), plus enough VRAM for your chosen model
- **For LM Studio**: [LM Studio](https://lmstudio.ai/) with a chat model loaded and its local server running (default port `1234`)

---

## Installation

### Omarchy Quattro plugin

The native plugin adds a **Writing** button to the bar and uses the same
providers and GTK4 review window. See **[PLUGIN.md](PLUGIN.md)** for dependencies,
provider setup, updates, and removal.

```bash
omarchy plugin add https://github.com/guruthechosen/omarchywritingtool.git --enable
PLUGIN_DIR="$HOME/.config/omarchy/plugins/io.github.guruthechosen.translateonthego"
bash "$PLUGIN_DIR/bin/tot-plugin" --check
bash "$PLUGIN_DIR/bin/tot-plugin" --setup
```

Configure your provider in `${XDG_CONFIG_HOME:-$HOME/.config}/translateonthego/config`,
then select text and click **Writing**. Existing config is preserved. Plugin
installation does not run the standalone installer or configure `Super+H`.

Remove with `omarchy plugin remove io.github.guruthechosen.translateonthego`.
Your provider config and local models are retained.

### Standalone Hyprland tool

```bash
git clone https://github.com/guruthechosen/omarchywritingtool.git
cd omarchywritingtool
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
PROVIDER="ollama"     # needs a running Ollama server
PROVIDER="lmstudio"   # local, needs LM Studio running
```

Typical workflow: Gemini as daily driver, switch to a local model when hitting quota, going offline, or handling text you'd rather not send anywhere.

**Auto-fallback:** If a request to a local provider fails, the tool falls back to Gemini automatically (if `GEMINI_API_KEY` is set). A toast tells you it fell back. Disable with `FALLBACK_ENABLED="false"` in config if you want hard failure instead.

### Changing the keybind

Hyprland has two config providers, and `install.sh` picks the right one for you. Check which you're on:

```bash
hyprctl systeminfo | grep configProvider
```

**Lua** (Omarchy 4+) — edit `~/.config/hypr/translateonthego.lua`:

```lua
o.bind("SUPER + H", "TranslateOnTheGo", o.launch("translateonthego"))
```

**Classic `.conf`** — edit `~/.config/hypr/translateonthego.conf`:

```
bindd = SUPER, H, TranslateOnTheGo, exec, uwsm-app -- translateonthego
```

Change the key to taste, then `hyprctl reload`.

---

## Local models (`tot-llm`, standalone installation)

The standalone installer provides the `tot-llm` commands below. Plugin-only users
should manage their Ollama server directly (for example, `ollama serve`).

The standalone local server is **manual-only by design**: nothing is enabled at boot, and stopping it releases both VRAM and RAM. It ships as a *user* systemd unit (`~/.config/systemd/user/ollama.service`) that is installed but never `enable`d.

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

The rule that matters: **the model must fit your VRAM.** Anything that doesn't gets partially offloaded to the CPU, which is slow and loud and defeats the point of running locally. Check your ceiling first:

```bash
nvidia-smi --query-gpu=memory.total --format=csv   # NVIDIA
rocm-smi --showmeminfo vram                        # AMD
# Intel / Apple / integrated: you're sharing system RAM — budget accordingly
```

Then leave ~1–2 GB of headroom on top of the model size for the KV cache.

| Your VRAM | Suggested tag | Size |
|-----------|---------------|------|
| 4–6 GB | `gemma4:e2b-it-qat` or `qwen3.5:2b` | 4.3 / 1.9 GB |
| 8 GB | `gemma4:e4b-it-qat` *(default)* or `qwen3.5:4b` | 6.1 / 3.4 GB |
| 12 GB | `gemma4:12b-it-qat` | 7.2 GB |
| 16 GB+ | `gemma4:26b-a4b-it-qat`, `qwen3.5:9b` | 16 / 6.6 GB |
| CPU only | `qwen3.5:2b` — expect several seconds per request | 1.9 GB |

Notes:

- **Prefer `-it-qat` tags.** Quantization-aware training keeps near-full quality at roughly Q4 size. The plain tags are much larger for little gain — `gemma4:e4b` is 9.6 GB versus 6.1 GB for `gemma4:e4b-it-qat`.
- **Reasoning models** (`qwen3.x`, `exaone-deep`) think before answering, which adds seconds. Set `OLLAMA_NO_THINK="true"` for those. Models without a reasoning mode reject that field, so leave it `"false"` otherwise.
- **Language-specialised options** exist — e.g. `exaone3.5:7.8b` (4.8 GB) is purpose-built bilingual Korean/English, stronger on that pair but weaker elsewhere.

Sizes are quantized download sizes from <https://ollama.com/library> and drift over time. Swap with one line in the config, then `tot-llm pull`.

---

## Usage

1. Select text in any app (terminal, browser, editor). A few apps — LibreOffice notably — don't publish selections; there, press `Ctrl+C` first. See [below](#libreoffice-and-other-apps-that-dont-publish-selections).
2. Click **Writing** in the bar, or press **`Super + H`** with the standalone installation.
3. Your menu picker opens — pick **Translate**, **Proofread**, or **Correct**.
4. Review window appears. Original on top, editable result below. Tweak if desired.
5. **Copy to Clipboard** (or `Ctrl+Enter`).
6. Back in your app, `Ctrl+V` (or `Ctrl+Shift+V` in terminals).

---

## Project layout

```
omarchywritingtool/
├── bin/
│   ├── tot-plugin          # plugin launcher, dependency check, and config setup
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
├── manifest.json           # Omarchy marketplace metadata
├── WritingTools.qml        # native Quattro bar launcher
├── PLUGIN.md               # plugin setup, usage, and removal
├── PUBLISHING.md           # release checks and marketplace submission
├── install.sh              # idempotent installer
├── uninstall.sh            # reverts install.sh
├── INSTRUCTION.md          # step-by-step setup
├── UNINSTALL.md            # full revert guide
├── CONTRIBUTING.md         # style + provider contract
├── SECURITY.md             # data flow, key handling, disclosure
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
| `~/.config/hypr/translateonthego.lua` | Symlink → `hypr/translateonthego.lua` *(lua provider)* |
| `~/.config/hypr/hyprland.lua` | Appended: `require("hypr.translateonthego")` *(lua provider)* |
| `~/.config/hypr/translateonthego.conf` | Symlink → `hypr/translateonthego.conf` *(classic provider)* |
| `~/.config/hypr/hyprland.conf` | Appended: `source = ...` *(classic provider)* |

See [UNINSTALL.md](UNINSTALL.md) for a complete revert guide.

---

## Troubleshooting

- **"GEMINI_API_KEY not set"** — Hyprland didn't inherit the env var (`~/.bashrc` is not sourced by the compositor). Put the key directly in `~/.config/translateonthego/config`, or add it to `~/.config/environment.d/translateonthego.conf` and relogin.
- **"Ollama unreachable at ..."** — the local server is stopped (which is its normal state). Run `tot-llm start`.
- **"model ... not found"** — the server is up but the model was never downloaded. Run `tot-llm pull`.
- **Local answers are slow / CPU fans spin up** — the model didn't fit in VRAM and spilled onto the CPU. Check with `tot-llm status`, then pick a smaller tag or lower `OLLAMA_NUM_CTX`.
- **"does not support thinking"** — `OLLAMA_NO_THINK="true"` was set for a model without a reasoning mode. Set it back to `"false"`.
- **"LM Studio unreachable at ..."** — LM Studio's local server isn't running. Start it from LM Studio → Developer → Start Server. Verify with `curl http://localhost:1234/v1/models`.
- **"Nothing to work on"** — no app owns the PRIMARY selection and the clipboard is empty. Copy with `Ctrl+C` first, then trigger.
- **The review window says "from clipboard" and shows the wrong text** — nothing published a selection, so it fell back to whatever you last copied. See below.

### LibreOffice, and other apps that don't publish selections

**Workaround: press `Ctrl+C` first, then `Super + H`.** The clipboard path works perfectly from LibreOffice.

Selecting text in LibreOffice and hitting the keybind won't pick it up. This is a LibreOffice-side limitation, not something this tool can work around: LibreOffice *does* claim ownership of the Wayland primary selection and advertises 13 formats for it (`text/plain`, `text/plain;charset=utf-8`, `UTF8_STRING`, `text/html`, `text/rtf`, …) — but every one of them serves **zero bytes**.

Verified on LibreOffice 26.2 (`libreoffice-fresh`), gtk3 VCL backend, native Wayland (not XWayland), Hyprland:

```console
$ wl-paste -p --list-types        # 13 types offered, while a sentence is selected
text/plain
text/plain;charset=utf-8
UTF8_STRING
...
$ wl-paste -p -t text/plain | wc -c
0
```

There is no text to retrieve, so no amount of MIME-type negotiation helps. The tool asks for `text/plain` explicitly and falls back through the other offers; they're all empty.

The review window shows a warning banner and labels the source **"Original (from clipboard)"** whenever this happens, so you can tell a wrong *input* from a bad *translation*. Earlier versions silently translated your stale clipboard and looked confident about it.

If you hit this with another app, the same `Ctrl+C` workaround applies.
- **No action menu appears** — you have none of the supported pickers installed. Install any one of `walker`, `fuzzel`, `wofi`, or `rofi` (Omarchy 4+ already provides `omarchy-menu-select`).
- **Nothing happens on `Super + H` after a distro upgrade** — the upgrade probably switched Hyprland's config provider. Check with `hyprctl systeminfo | grep configProvider`, then re-run `bash install.sh`; it detects `lua` vs `conf` and installs the right file.
- **API error toast** — Check your key, quota, and network. The Gemini error message is shown in the notification.

---

## Roadmap

- OpenAI provider (`lib/openai.sh`)
- Provider switcher in the action menu (no config edit)
- Additional actions: Summarize, Make Shorter / Longer, Change Tone
- Optional auto-paste via `ydotool` (uinput-level, more reliable than `wtype`)
- Custom prompts via config
- Screenshots + demo GIF
- AUR package

---

## Contributing

PRs welcome — see **[CONTRIBUTING.md](CONTRIBUTING.md)** for style, the provider contract, and what to test before submitting.

The short version: keep it minimal, never phone home, and never start a local server on the user's behalf.

## Security

Your text goes to whichever provider you configure — Gemini means it leaves your machine; Ollama and LM Studio stay on localhost. Your API key lives in a `600` config file outside the repo. See **[SECURITY.md](SECURITY.md)** for the details and for reporting vulnerabilities.

---

## Inspiration

Apple's macOS Writing Tools — but without the OS lock-in. Built because I wanted the same ubiquity on Hyprland.

---

## License

MIT — see [LICENSE](LICENSE).
