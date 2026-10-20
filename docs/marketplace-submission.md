### Repository URL

https://github.com/guruthechosen/omarchywritingtool

### Category

Productivity

### Tags

ai, bar, launcher

### Suggest a missing tag

_No response_

### Maintainer notes

TranslateOnTheGo adds a Writing Tools launcher to the Omarchy Quattro bar.
Select or copy text, click Writing, choose Translate / Proofread / Correct,
then review and edit the result in a GTK4 window before copying it.

Plugin ID: io.github.guruthechosen.translateonthego. License: MIT.

Manual setup is required: install any missing dependencies and configure a
Gemini API key or a local Ollama / LM Studio endpoint. Dependencies are Bash,
coreutils, curl, jq, wl-clipboard, libnotify, Python, python-gobject, GTK4, and
one supported menu picker (including Omarchy's built-in menu). PLUGIN.md
documents installation, configuration, updates, and removal.

The plugin launches bundled scripts directly. It does not run install.sh,
install packages, overwrite existing config, add keybindings or command
symlinks, install/start services, or download models. The explicit --setup
command creates a private provider config only when none exists. Plugin
removal preserves provider config and local models. The standalone installer
is a separate installation option and is not part of the plugin lifecycle.

Text is sent to the chosen provider only after the user selects an action.
Gemini sends text to Google; local providers default to localhost. Configurable
fallback can send failed local requests to Gemini when a key is configured;
FALLBACK_ENABLED=false disables that behavior. No telemetry or remote build.
No preview assets are included.

Version 1.0.1 addresses the process-argument exposure reported in review. All
three providers load selected text with jq --rawfile and stream request JSON
to curl through stdin. Gemini supplies its API-key header through a Bash pipe
instead of a command argument. Regression tests use real jq/curl against a
loopback fixture, inspect curl's live /proc command line and every jq/curl
invocation, and cover all three actions/providers, large inputs, and errors.
All 17 tests and ShellCheck pass; no real API key or external provider is used
by the tests.

### Submission checklist

- [x] The repository is public and contains installation and removal instructions.
- [x] I have documented the plugin license and any external dependencies.
- [x] I confirm that I own or have permission to submit this plugin and its preview assets.
- [x] The plugin does not overwrite user configuration without explicit consent.
- [x] I understand that approval is for listing and is not a security review.
