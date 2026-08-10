# Contributing

Thanks for taking an interest. This is a small tool with a deliberately small scope, so the bar for changes is mostly "does it stay out of the user's way".

## Ground rules

- **Keep it minimal.** The whole point is that this tool disappears into a keybind. Features that add a step between selecting text and pasting the result are a hard sell.
- **Never phone home.** The only network calls are to the provider the user explicitly configured. No telemetry, no analytics, no update checks.
- **Never start a local server on the user's behalf.** The Ollama server is manual-only by design (see [Local models](README.md#local-models-tot-llm)). Do not add auto-start-on-demand, even as an opt-in default — the `systemd/ollama.service` unit intentionally has **no `[Install]` section** so that `systemctl enable` fails outright. Don't add one.

## Development setup

```bash
git clone https://github.com/<you>/omarchywritingtool.git
cd omarchywritingtool
bash install.sh
```

`install.sh` is idempotent — re-run it after any change. It symlinks rather than copies, so edits in your clone take effect immediately.

To work without touching your real config, point the tool at a scratch one:

```bash
XDG_CONFIG_HOME=/tmp/tot-dev ./bin/translateonthego
```

## Style

- **Bash**: `#!/usr/bin/env bash` and `set -euo pipefail` at the top of every script. Run `shellcheck` before submitting; the tree is currently clean.
- **Python**: Python 3, standard library plus GTK4 via PyGObject. No third-party dependencies.
- Comments explain *why*, not *what*. If a line needs a comment to say what it does, rewrite the line.

## Testing your changes

There is no automated test suite — it's a UI-driven tool. At minimum, before opening a PR:

```bash
# 1. Everything parses
for f in bin/translateonthego bin/tot-llm lib/*.sh install.sh uninstall.sh; do bash -n "$f"; done

# 2. Each action round-trips through the provider you touched
printf 'The quick brown fox jump over a lazy dogs.' > /tmp/t.txt
./lib/<provider>.sh Correct   /tmp/t.txt
./lib/<provider>.sh Translate /tmp/t.txt
./lib/<provider>.sh Proofread /tmp/t.txt

# 3. The real path works
#    Select text somewhere, press Super+H, run all three actions.

# 4. Install is still reversible
bash uninstall.sh && bash install.sh
```

Test on a **fresh clone** too — it's easy to accidentally depend on state your working copy already has.

## Adding a provider

Drop `lib/<name>.sh` following the existing contract:

- **Input**: `$1` is the action (`Translate` / `Proofread` / `Correct`), `$2` is a path to a file containing the text.
- **Output**: the result text on **stdout**, nothing else — no labels, no quotes, no trailing newline fanfare.
- **Errors**: a human-readable message on **stderr** and a non-zero exit. That message is what the user sees in the failure notification, so make it actionable ("start it with: tot-llm start" beats "connection refused").
- **Prompts**: source `lib/prompts.sh` and call `tot_system_prompt "$ACTION" "$TARGET_LANG"`. Don't copy the prompt strings — they're shared so that behaviour stays identical across providers.

Then register it in `bin/translateonthego`'s `case "$PROVIDER"` block. Set `IS_LOCAL=1` if it talks to a server on the user's machine, which enables the fallback-to-Gemini path. Document the settings in `config.example` and both README and INSTRUCTION.

## Pull requests

- One concern per PR.
- Update the docs in the same PR. `README.md` (overview + reference), `INSTRUCTION.md` (step-by-step), `UNINSTALL.md` (if you added anything that needs removing).
- If you changed what `install.sh` creates, make sure `uninstall.sh` removes it and the verification checklist in `UNINSTALL.md` still covers it.

## Bug reports

Include:

- Output of `hyprctl version` and your distro.
- Which provider and model.
- The command that failed and its full output — run the provider script directly to see stderr, since the keybind path only surfaces a notification.
- What you expected instead.

**Never paste your API key**, including in logs or screenshots. If you think a key leaked, rotate it at <https://aistudio.google.com/apikey>.
