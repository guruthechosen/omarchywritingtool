# Setup Instructions

Step-by-step guide to get **TranslateOnTheGo** running on your machine.

For an overview of what this tool does, see [README.md](README.md). For reverting/uninstalling, see [UNINSTALL.md](UNINSTALL.md).

---

## Table of Contents

1. [Prerequisites](#1-prerequisites)
2. [Clone the repository](#2-clone-the-repository)
3. [Run the installer](#3-run-the-installer)
4. [Pick a provider and configure it](#4-pick-a-provider-and-configure-it)
   - [Option A — Gemini (cloud)](#option-a--gemini-cloud)
   - [Option B — Ollama (local, on-demand)](#option-b--ollama-local-on-demand)
   - [Option C — LM Studio (local, GUI)](#option-c--lm-studio-local-gui)
5. [Test it](#5-test-it)
6. [Customize](#6-customize)
7. [Upgrading](#7-upgrading)

---

## 1. Prerequisites

You need:

- **Omarchy** or **Arch Linux** with **Hyprland** (Wayland compositor)
- A user account with `sudo` privileges (for installing packages)
- Git
- A terminal

Optional (the installer will install these for you if missing):

- `wl-clipboard` — clipboard access on Wayland
- `walker` — dmenu-style picker
- `curl`, `jq` — API calls and JSON parsing
- `libnotify` — desktop notifications
- `python`, `python-gobject`, `gtk4` — review window

> **Note**: If you're on a distro other than Arch, the installer's `pacman -S` calls will fail. Install the listed dependencies manually with your package manager, then run `bash install.sh` — it will skip package install and continue with symlinks / config.

---

## 2. Clone the repository

Pick a location and clone:

```bash
git clone https://github.com/guruthechosen/translateonthego.git
cd translateonthego
```

Or if you've already downloaded the source, `cd` into the directory.

---

## 3. Run the installer

```bash
bash install.sh
```

This does the following, idempotently:

1. Installs any missing dependencies via `pacman -S --needed` (prompts for sudo).
2. Marks the scripts executable.
3. Creates `~/.config/translateonthego/` and copies `config.example` there as `config` (only if no config exists yet).
4. Symlinks `~/.local/bin/translateonthego` → this repo's `bin/translateonthego`, so you can run the command from anywhere.
5. Symlinks `~/.config/hypr/translateonthego.conf` → this repo's Hyprland config (keybind + window rules).
6. Appends `source = ~/.config/hypr/translateonthego.conf` to `~/.config/hypr/hyprland.conf` (skipped if already present).
7. Runs `hyprctl reload` so Hyprland picks up the new config.

When it finishes, you'll see a summary of next steps printed to the terminal.

---

## 4. Pick a provider and configure it

You have two providers to choose from. Pick the one that fits you. You can switch anytime by editing one line in the config.

### Option A — Gemini (cloud)

Google Gemini is fast, high quality, and has a free tier (~1500 requests/day for `gemini-3.5-flash-lite` at the time of writing). Good default.

#### A.1 Get an API key

Visit <https://aistudio.google.com/apikey>, sign in, and create a key. Copy it.

#### A.2 Make the key available

The tool looks for `GEMINI_API_KEY` in its environment. Two ways to set it:

**Easiest — store in the config file** (survives reboots, doesn't need relogin):

```bash
$EDITOR ~/.config/translateonthego/config
```

Find this block and fill in:

```bash
# GEMINI_API_KEY="your-key-here"
```

→ uncomment and paste your key:

```bash
GEMINI_API_KEY="AIzaSy...your-real-key..."
```

Save. Then restrict file permissions:

```bash
chmod 600 ~/.config/translateonthego/config
```

**Alternative — systemd user environment** (key available to all user services):

```bash
mkdir -p ~/.config/environment.d
echo 'GEMINI_API_KEY=your-key-here' > ~/.config/environment.d/translateonthego.conf
chmod 600 ~/.config/environment.d/translateonthego.conf
```

Then log out of Hyprland completely and log back in (the greeter must restart the session for `environment.d` to take effect — a terminal reload is not enough).

> **Why not `~/.bashrc`?** Hyprland is launched from the login greeter, not an interactive bash shell, so `~/.bashrc` is never read. The export never makes it to the compositor. Use the config file or `environment.d` instead.

#### A.3 Confirm provider

Open `~/.config/translateonthego/config` and confirm:

```bash
PROVIDER="gemini"
MODEL="gemini-3.5-flash-lite"
```

Done. Skip to [Step 5](#5-test-it).

---

### Option B — Ollama (local, on-demand)

Run an open model on your own GPU. Zero API cost, fully offline, private. Costs: disk space for the model (~3–8 GB) and VRAM **only while you have the server running**.

This is set up deliberately as a manual switch. Nothing autostarts at boot, and `tot-llm stop` unloads the model and exits the daemon, so it costs nothing while you're doing other work.

#### B.1 Install Ollama

```bash
sudo pacman -S --needed ollama ollama-cuda
```

Pick the backend that matches your GPU:

| Package | For |
|---------|-----|
| `ollama-cuda` | NVIDIA. ~2.2 GB download (pulls the CUDA toolkit), fastest and most reliable. |
| `ollama-vulkan` | NVIDIA or AMD, ~6 MB. Much lighter, slightly slower. |
| `ollama-rocm` | AMD, ~1 GB. |
| *(none)* | CPU-only fallback, already included in the base `ollama` package. |

Make sure the **system** service stays off — it would autostart at boot and keep models in root-owned `/var/lib/ollama`:

```bash
systemctl is-enabled ollama.service    # want: disabled
sudo systemctl disable --now ollama.service   # only if it says enabled
```

`install.sh` puts a *user* unit at `~/.config/systemd/user/ollama.service` instead. It's installed but never enabled, so it can only start when you ask.

#### B.2 Download a model

```bash
tot-llm pull
```

That fetches whatever `OLLAMA_MODEL` is set to (default `gemma4:e4b-it-qat`) into `~/.local/share/ollama/models`.

The main thing to get right is **fitting your VRAM**. A model that doesn't fit gets partially offloaded to the CPU, which is slow and defeats the purpose. Check your ceiling first:

```bash
nvidia-smi --query-gpu=memory.total --format=csv
```

| Tag | Size | Notes |
|-----|------|-------|
| `gemma4:e4b-it-qat` | 6.1 GB | Gemma 4 E4B, quantization-aware trained — near-full quality at Q4 size. 140+ languages. Good default for an 8 GB card. |
| `qwen3.5:4b` | 3.4 GB | Lighter and faster, strong multilingual. Set `OLLAMA_NO_THINK="true"` for it. |
| `gemma4:12b-it-qat` | 7.2 GB | Better quality; tight in 8 GB alongside the KV cache. |
| `gemma4:e2b-it-qat` | 4.3 GB | Smallest Gemma 4. For 4–6 GB cards. |
| `exaone3.5:7.8b` | 4.8 GB | LG AI Research, purpose-built bilingual Korean/English. Older, weaker outside that pair. |

Avoid the plain `gemma4:e4b` tag — it's 9.6 GB and won't fit in 8 GB.

Browse more at <https://ollama.com/library>.

#### B.3 Switch the provider

```bash
$EDITOR ~/.config/translateonthego/config
```

```bash
PROVIDER="ollama"
OLLAMA_MODEL="gemma4:e4b-it-qat"
```

Save. No relogin needed — the script reads the config on every trigger.

#### B.4 Day-to-day use

```bash
tot-llm start     # bring it up when you want local inference
tot-llm status    # service state, what's in VRAM, disk usage
tot-llm test      # time a real round-trip through the provider
tot-llm stop      # done — VRAM freed, daemon gone
```

If you leave `PROVIDER="ollama"` set but the server is stopped, the tool falls back to Gemini and shows a toast saying so. Set `FALLBACK_ENABLED="false"` if you'd rather it fail loudly.

---

### Option C — LM Studio (local, GUI)

Still supported for existing setups. Install [LM Studio](https://lmstudio.ai/), load a chat model, start its server from the **Developer** tab on the default port `1234`, then set:

```bash
PROVIDER="lmstudio"
LMSTUDIO_URL="http://localhost:1234/v1/chat/completions"
LMSTUDIO_MODEL="local-model"
```

> `"local-model"` is a generic placeholder most LM Studio versions accept. If yours rejects it, use the exact identifier from LM Studio's server UI.

Prefer **Option B** for new setups — it's a fraction of the footprint and doesn't need a GUI running.

---

## 5. Test it

1. Open any app where you can select text — a browser, editor, terminal, chat app.
2. Select a sentence or paragraph.
3. Press **`Super + H`**.
4. A walker popup appears with three options: **Translate** / **Proofread** / **Correct**. Pick one (arrow keys + Enter, or click).
5. Wait 1–3 seconds while the API is called.
6. A review window opens showing:
   - **Original** on top (read-only)
   - **Result** below (editable — tweak if you want)
7. Click **Copy to Clipboard** (or press `Ctrl+Enter`).
8. Return to your app, press `Ctrl+V` (or `Ctrl+Shift+V` in terminals) to paste the result.

If nothing happens at step 3, see [Troubleshooting in README.md](README.md#troubleshooting).

---

## 6. Customize

### Change the translation target language

Edit `~/.config/translateonthego/config`:

```bash
TARGET_LANG="Japanese"   # or "English", "Spanish", "French", "German", etc.
```

If your source text is already in that language, the tool translates to English instead.

### Change the keybind

Edit `~/.config/hypr/translateonthego.conf` (this is a symlink to the repo):

```
bindd = SUPER, H, TranslateOnTheGo, exec, uwsm-app -- translateonthego
```

Replace `SUPER, H` with any combo you like. Examples:

```
bindd = SUPER SHIFT, T, TranslateOnTheGo, exec, uwsm-app -- translateonthego
bindd = SUPER ALT, Space, TranslateOnTheGo, exec, uwsm-app -- translateonthego
```

Then reload Hyprland:

```bash
hyprctl reload
```

### Switch providers on the fly

Just edit the config and save — the change takes effect on the next trigger. No reload, no relogin.

```bash
# When Gemini quota is running low, you're offline, or the text is sensitive:
PROVIDER="ollama"     # then: tot-llm start

# When you want speed / quality back:
PROVIDER="gemini"     # and: tot-llm stop
```

### Change the Gemini model

Edit `MODEL` in config:

```bash
MODEL="gemini-3.5-flash-lite"     # default, fast + cheap
MODEL="gemini-2.5-pro"       # higher quality, slower, uses more quota
```

---

## 7. Upgrading

To pull in new changes from the repo:

```bash
cd /path/to/translateonthego
git pull
bash install.sh     # re-runs, idempotent — re-symlinks, installs any new deps
```

Your `~/.config/translateonthego/config` is never overwritten.

---

## Something broken?

- See **Troubleshooting** in [README.md](README.md#troubleshooting).
- See **Full revert guide** in [UNINSTALL.md](UNINSTALL.md).
- Open an issue on the repo with: what you tried, what you expected, what happened, and the output of `hyprctl version` and `translateonthego --help 2>&1` (if it even runs).
