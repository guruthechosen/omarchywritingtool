#!/usr/bin/env bash
set -euo pipefail

PROJ_DIR="$(dirname "$(dirname "$(readlink -f "$0")")")"
SHELL_DIR="${OMARCHY_PATH:-/usr/share/omarchy}/shell"
QMLLINT="${QMLLINT:-/usr/lib/qt6/bin/qmllint}"

cd "$PROJ_DIR"
omarchy plugin validate "$PROJ_DIR"

# Quickshell supplies the qs.* alias at runtime. qmllint needs an ordinary
# import directory containing that alias; keep it outside the plugin checkout.
imports="$(mktemp -d -t tot-qml-imports.XXXXXX)"
trap 'rm -rf "$imports"' EXIT
ln -s "$SHELL_DIR" "$imports/qs"
"$QMLLINT" --ignore-settings -W 0 -I "$imports" "$PROJ_DIR/WritingTools.qml"

for script in bin/translateonthego bin/tot-llm bin/tot-plugin lib/*.sh install.sh uninstall.sh scripts/*.sh; do
  bash -n "$script"
done
python3 -m unittest discover -s tests -v
printf 'Plugin manifest, QML, shell syntax, and regression tests passed.\n'
