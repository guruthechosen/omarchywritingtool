# Security

## What this tool does with your text

When you trigger an action, the selected text is sent to whichever provider you configured:

- `PROVIDER="gemini"` — your text goes to **Google's Gemini API** over HTTPS. It leaves your machine. Read Google's terms before using it on anything confidential.
- `PROVIDER="ollama"` / `"lmstudio"` — your text goes to the configured server, which defaults to **localhost**. A remote endpoint sends text to that host.

When `FALLBACK_ENABLED="true"` (the default) and a Gemini key is set, a failed
local request is retried with Gemini. Set `FALLBACK_ENABLED="false"` for local-only
use. A notification announces fallback before the cloud request.

There is no telemetry, no analytics, and no update check. The only outbound network calls are the provider request you asked for.

Text is written to temporary files (`mktemp`) while the review window is open, and deleted when it closes. The result is placed on your clipboard, where it stays until something overwrites it.

Provider scripts read selected text with `jq --rawfile` and pass request JSON
to curl over standard input. Gemini's API-key header is supplied through a
Bash process-substitution pipe. Neither the key nor selected text is placed in
jq/curl command arguments. This protects ordinary process listings, not access
by root or other processes running with your own user privileges.

Versions through `1.0.0` passed the API key and request text in process arguments.
Update to `1.0.1` or later to remove that exposure.

## Your API key

`~/.config/translateonthego/config` is sourced as bash and typically holds `GEMINI_API_KEY`. Consequences worth knowing:

- **`install.sh` and `bin/tot-plugin --setup` create it with mode `600`.** Keep it that way. Check with `stat -c '%a' ~/.config/translateonthego/config`.
- **It is sourced, not parsed.** Anything executable in that file runs with your privileges every time the keybind fires. Don't paste config snippets you don't understand.
- **It is deliberately outside the repo.** `config` is in `.gitignore`; only `config.example` is tracked. Never move your real key into the repo.
- If a key leaks, rotate it immediately at <https://aistudio.google.com/apikey>.

## The local model server

The native plugin does not install or start any model service. The systemd
integration below applies only to the standalone `install.sh` installation.

`systemd/ollama.service` binds to `OLLAMA_HOST=127.0.0.1:11434` — **loopback only**.

Ollama's API has **no authentication**. Anything that can reach the port can use your GPU, read the list of models, and submit arbitrary prompts. If you change `OLLAMA_HOST` to `0.0.0.0` or a LAN address, you are exposing an unauthenticated inference endpoint to your network. Don't, unless you have put your own authentication in front of it.

The unit runs as your user, not root, and stores models under `~/.local/share/ollama/models`. It has **no `[Install]` section**, so it cannot be enabled and never starts at boot or login — only `tot-llm start` (or an explicit `systemctl --user start ollama`) brings it up.

## Reporting a vulnerability

Open an issue for anything low-risk. For something genuinely sensitive — key disclosure, remote code execution — please report it privately via GitHub's **Security → Report a vulnerability** advisory form rather than a public issue.

Please don't include real API keys, tokens, or personal text in reports.
