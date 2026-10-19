# Publish TranslateOnTheGo

The marketplace publishes a listing of the public repository after validating
its current commit and receiving maintainer approval. Reference:
[publishing guide](https://plugins.omarchy.org/publish.html),
[development guide](https://plugins.omarchy.org/develop.html), and
[submission format](https://github.com/omacom/omarchy-plugin-marketplace/blob/main/SUBMISSION.md).

## Listing

- Repository: https://github.com/guruthechosen/omarchywritingtool
- Plugin ID: `io.github.guruthechosen.translateonthego`
- Name: TranslateOnTheGo
- Initial plugin version: `1.0.0`
- Author: guruthechosen
- License: MIT
- Category: Productivity
- Tags: `ai`, `bar`, `launcher`
- Issue title: `[Plugin]: TranslateOnTheGo`
- Issue body: [docs/marketplace-submission.md](docs/marketplace-submission.md)

The ID is permanent once listed. Neither this ID nor this repository appeared
in the marketplace registry when checked on 2026-10-19; recheck at submission.
The repository was confirmed public, with `main` as its default branch.
No preview is required for the first listing. Add a genuine `preview.png` of
the widget/review window later if desired, with no private text or keys visible.

## Local validation

On an Omarchy Quattro machine with Qt's `qmllint` available:

```bash
bash scripts/validate-plugin.sh
shellcheck bin/translateonthego bin/tot-llm bin/tot-plugin lib/*.sh install.sh uninstall.sh scripts/*.sh
bash bin/tot-plugin --check
```

`scripts/validate-plugin.sh` runs the installed official manifest validator,
QML lint against installed shell imports with zero warnings allowed, shell
syntax checks, and the regression suite. Set `OMARCHY_PATH` or `QMLLINT` if
your installation uses different paths. Its temporary import alias stays
outside the plugin folder, which must not contain symlinks.

Preparation checks on 2026-10-19 passed on Omarchy `4.0.4-1`, Quickshell `0.3.1`:

- Official `omarchy plugin validate .`.
- QML lint with the actual installed `qs.Ui` types.
- Bash syntax and ShellCheck across the shell scripts.
- All 12 isolated regression tests, including existing-config preservation,
  private config creation, missing dependencies, unusual paths, and launch.
- Real dependency check for GTK4, clipboard tools, and a menu picker.
- A separate offscreen Quickshell smoke test loaded the real widget and
  delivered a left-click signal to a stub backend from a path containing
  spaces, `#`, and `%`.

The offscreen test does not establish live bar placement, selection capture,
or a provider round-trip. No real provider request was made during preparation.

## Release sequence

1. Review the changes, keep the root manifest/README/license, and ensure there
   are no credentials, local config, symlinks, or temporary files in the commit.
2. Complete a live desktop smoke test from a disposable copy under
   `~/.config/omarchy/plugins/io.github.guruthechosen.translateonthego/` (skip
   copying if that ID is already installed). Rescan with
   `omarchy-shell shell rescanPlugins`, then enable with
   `omarchy plugin enable io.github.guruthechosen.translateonthego`.
   Use the setup commands in [PLUGIN.md](PLUGIN.md). Check left-click, menu
   cancellation, all three actions, editable review, Ctrl+Enter, Escape,
   clipboard fallback, disable/re-enable, and a shell restart. Close review
   windows, remove via `omarchy plugin remove`, and confirm config is retained.
   This launcher has no shell summon/hide panel interface.
3. Commit and push the reviewed changes to `main`. A `v1.0.0` tag/release is
   optional; the marketplace validates the repository's current commit.
4. Install from the public URL using [PLUGIN.md](PLUGIN.md) to confirm a fresh
   clone contains the same files. Record the published commit with
   `git rev-parse HEAD`.
5. Review every checkbox in the submission draft, including ownership and the
   listing-only approval statement, then check the five boxes. The saved body
   has been reviewed for the initial submission; recheck it before reuse.
6. Open the [submission form](https://github.com/omacom/omarchy-plugin-marketplace/issues/new?template=submit-plugin.yml),
   or submit the reviewed draft with:

   ```bash
   gh issue create \
     --repo omacom/omarchy-plugin-marketplace \
     --title '[Plugin]: TranslateOnTheGo' \
     --body-file docs/marketplace-submission.md
   ```

7. Read the automated compatibility and security-baseline results. Fix issues
   on the same submission and have maintainers review the exact validated
   commit. Publication requires their `approved-and-verified` approval.

The draft documents manual provider setup and package dependencies so reviewers
can apply the marketplace's manual-setup classification if appropriate.
Preparation does not itself push code, create a release, or submit an issue.
