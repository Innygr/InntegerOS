#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_HOME="$(mktemp -d)"
trap 'rm -rf "$TMP_HOME"' EXIT

bash -n "$ROOT_DIR/fih/install.sh"
bash -n "$ROOT_DIR/fih/bin/io"
"$ROOT_DIR/fih/bin/io" help | grep -q 'FIH // Fish Integrated by Blacklight'
"$ROOT_DIR/fih/bin/io" version | grep -q '^FIH 0.1.0$'
"$ROOT_DIR/fih/bin/io" info | grep -q '^Kernel:'

if "$ROOT_DIR/fih/bin/io" not-a-command >/dev/null 2>&1; then
  echo "Unknown FIH commands must return a non-zero status." >&2
  exit 1
fi

HOME="$TMP_HOME" XDG_CONFIG_HOME="$TMP_HOME/.config" XDG_DATA_HOME="$TMP_HOME/.local/share" \
  bash "$ROOT_DIR/fih/install.sh"

test -x "$TMP_HOME/.local/bin/io"
test -s "$TMP_HOME/.config/fish/conf.d/fih.fish"
test -s "$TMP_HOME/.config/fish/completions/io.fish"
test -s "$TMP_HOME/.config/fish/functions/fih_prompt.fish"
test -s "$TMP_HOME/.config/fish/functions/fish_prompt.fish"
test -s "$TMP_HOME/.local/share/integeros/fih/config"
HOME="$TMP_HOME" XDG_CONFIG_HOME="$TMP_HOME/.config" XDG_DATA_HOME="$TMP_HOME/.local/share" \
  "$TMP_HOME/.local/bin/io" help | grep -q 'No account or network connection required'

echo "FIH smoke tests passed."
