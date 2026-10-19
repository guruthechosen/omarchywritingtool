# Uninstall / Full Revert Guide

For a **plugin-only installation**, close any Writing Tools window and run:

```bash
omarchy plugin remove io.github.guruthechosen.translateonthego
```

This preserves provider config and models. See [PLUGIN.md](PLUGIN.md#disable-or-remove)
for details. Do not run the standalone uninstaller for a plugin-only install.

For a **standalone installation**, run the script or follow the manual steps below.

---

## Option 1 — Script (recommended)

```bash
cd /path/to/translateonthego && bash uninstall.sh
```

What it does, in order:

1. **Removes symlink** `~/.local/bin/translateonthego`.
2. **Removes symlink** `~/.config/hypr/translateonthego.conf`.
3. **Strips the source line** `source = ~/.config/hypr/translateonthego.conf` from `~/.config/hypr/hyprland.conf`. A backup is written to `~/.config/hypr/hyprland.conf.bak` before the edit. The preceding `# TranslateOnTheGo` marker comment is also removed.
4. **Prompts** before deleting `~/.config/translateonthego/` (contains your `config` file with any custom settings). Answer `y` to delete, anything else to keep.
5. **Reloads Hyprland** (`hyprctl reload`).

What it does **NOT** do (manual steps — see Option 2 below):

- Does not remove packages installed by `install.sh`.
- Does not remove `GEMINI_API_KEY` from your shell rc or `environment.d`.
- Does not delete the cloned project source.

---

## Option 2 — Manual revert (full, step-by-step)

Use this if the script errored, or if you want to verify every change yourself.

### Step 1: Remove the command symlinks

```bash
rm -f ~/.local/bin/translateonthego ~/.local/bin/tot-llm
```

Confirm: `command -v translateonthego` should print nothing.

### Step 1b: Stop and remove the Ollama user unit

```bash
systemctl --user stop ollama.service
rm -f ~/.config/systemd/user/ollama.service
systemctl --user daemon-reload
```

Downloaded models are separate and survive this. Delete them if you want the disk back:

```bash
du -sh ~/.local/share/ollama/models
rm -rf ~/.local/share/ollama/models
```

### Step 2: Remove the Hyprland config symlink

Only one of these exists, depending on your config provider — removing both is safe:

```bash
rm -f ~/.config/hypr/translateonthego.conf ~/.config/hypr/translateonthego.lua
```

### Step 3a: Remove the `require` line from `hyprland.lua` (Omarchy 4+)

If `hyprctl systeminfo | grep configProvider` says `lua`, `install.sh` appended:

```lua
-- TranslateOnTheGo
require("hypr.translateonthego")
```

```bash
cp ~/.config/hypr/hyprland.lua ~/.config/hypr/hyprland.lua.bak
sed -i '/^-- TranslateOnTheGo$/d; /^require("hypr\.translateonthego")$/d' ~/.config/hypr/hyprland.lua
```

### Step 3b: Remove the `source =` line from `hyprland.conf`

`install.sh` appended two lines at the end of `~/.config/hypr/hyprland.conf`:

```
# TranslateOnTheGo
source = ~/.config/hypr/translateonthego.conf
```

Back up first, then delete those two lines:

```bash
cp ~/.config/hypr/hyprland.conf ~/.config/hypr/hyprland.conf.bak

# Remove both lines
sed -i '/^# TranslateOnTheGo$/d; \|^source = ~/.config/hypr/translateonthego\.conf$|d' \
  ~/.config/hypr/hyprland.conf
```

Verify:

```bash
grep -n 'translateonthego' ~/.config/hypr/hyprland.conf
# should return nothing
```

### Step 4: Remove the runtime config directory

Contains your `config` file (target language, model, etc.).

```bash
rm -rf ~/.config/translateonthego
```

### Step 5: Remove the API key from your shell rc

If you added the export to `~/.bashrc` or `~/.zshrc`:

```bash
# edit manually
$EDITOR ~/.bashrc    # or ~/.zshrc
```

Delete the line:

```bash
export GEMINI_API_KEY="your-key-here"
```

Then reload your shell (or `unset GEMINI_API_KEY` in current session).

### Step 6: Reload Hyprland

```bash
hyprctl reload
```

At this point the `Super + H` binding is gone and the tool no longer runs.

### Step 7 (optional): Remove installed packages

`install.sh` may have installed `wl-clipboard`, `curl`, `jq`, `libnotify`, `python`, `python-gobject`, `gtk4`, and possibly `fuzzel` via `pacman -S --needed`.

These are **likely used by other apps / Omarchy itself** — don't remove unless you're sure they're unused. TranslateOnTheGo doesn't install anything exclusive to itself.

If you installed Ollama for local models and want it gone (this reclaims the CUDA toolkit too, ~5.8 GB):

```bash
sudo pacman -Rns ollama-cuda ollama
```

### Step 8 (optional): Delete the cloned project source

```bash
rm -rf /path/to/translateonthego
```

---

## Verification checklist

After uninstalling, confirm a clean state:

```bash
# 1. Command gone
command -v translateonthego && echo "STILL PRESENT" || echo "gone"

# 2. Symlinks gone
ls -l ~/.local/bin/translateonthego 2>&1 | grep -q "No such" && echo "gone"
ls -l ~/.local/bin/tot-llm 2>&1 | grep -q "No such" && echo "gone"
ls -l ~/.config/hypr/translateonthego.conf 2>&1 | grep -q "No such" && echo "gone"
ls -l ~/.config/systemd/user/ollama.service 2>&1 | grep -q "No such" && echo "gone"

# 3. Hyprland config clean
grep -c 'translateonthego' ~/.config/hypr/hyprland.conf    # should print 0

# 4. Runtime config gone
ls ~/.config/translateonthego 2>&1 | grep -q "No such" && echo "gone"

# 5. Env var gone (in a fresh shell)
bash -lc 'echo "${GEMINI_API_KEY:-unset}"'                 # should print "unset"

# 6. Keybind gone
hyprctl binds | grep -i translateonthego                   # should print nothing
```

All six clean = full revert complete.

---

## Restoring from backup

`uninstall.sh` writes `~/.config/hypr/hyprland.conf.bak` before editing. To restore the pre-uninstall state of that file:

```bash
mv ~/.config/hypr/hyprland.conf.bak ~/.config/hypr/hyprland.conf
hyprctl reload
```

(Only useful if you want to reverse the uninstall edit itself — typically you don't.)
