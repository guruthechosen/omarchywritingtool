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
- Current plugin version: `1.0.2`
- Author: guruthechosen
- License: MIT
- Category: Productivity
- Tags: `ai`, `bar`, `launcher`
- Issue title: `[Plugin]: TranslateOnTheGo`
- Issue body: [docs/marketplace-submission.md](docs/marketplace-submission.md)

The ID is permanent. The plugin is listed and verified through
[the original submission](https://github.com/omacom/omarchy-plugin-marketplace/issues/12169).
The repository is public, with `main` as its default branch.

The root `preview.png` is the marketplace image. Additional actual GTK4 captures
live in `docs/screenshots/`; see [the capture notes](docs/screenshots/README.md).
All examples use prepared fictional text. Do not include personal documents,
clipboard contents, API keys, or account settings in future captures.

## Updating the existing listing

Push the reviewed commit, then open a **new**
[verification/update request](https://github.com/omacom/omarchy-plugin-marketplace/issues/new?template=verify-plugin.yml)
with action **Verify and publish a newer upstream commit**, the plugin ID,
repository URL, and full 40-character target commit. Confirm the exact-snapshot
acknowledgment. Do not claim setup-free installation: provider configuration
and dependencies are still required.

The current verified snapshot remains published until maintainers approve the
new snapshot. A push alone does not publish the new description or preview.
The site reads the manifest description (up to 500 characters) and the root
preview image; detailed instructions and extra screenshots belong in the README.

Version `1.0.2` updates only listing metadata, documentation, and screenshots.
It does not change runtime behavior.

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

Version `1.0.1` addresses the marketplace review's process-argument exposure
finding. On 2026-10-20, all 17 tests and ShellCheck passed, including all three
providers/actions against a loopback server using synthetic credentials and
inspection of live curl command lines. No external provider request was made.

## Initial submission reference

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
3. Commit and push the reviewed changes to `main`. A matching version tag/release is
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
