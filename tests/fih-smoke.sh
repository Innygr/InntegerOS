#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_HOME="$(mktemp -d)"
CUSTOM_HOME="$(mktemp -d)"
trap 'rm -rf "$TMP_HOME" "$CUSTOM_HOME"' EXIT

bash -n "$ROOT_DIR/fih/install.sh"
bash -n "$ROOT_DIR/fih/bin/io"

help_output="$(bash "$ROOT_DIR/fih/bin/io" help)"
version_output="$(bash "$ROOT_DIR/fih/bin/io" version)"
info_output="$(bash "$ROOT_DIR/fih/bin/io" info)"
grep -q 'FIH // Fish Integrated by Blacklight' <<<"$help_output"
grep -q '^FIH 0.1.0$' <<<"$version_output"
grep -q '^Kernel:' <<<"$info_output"

if bash "$ROOT_DIR/fih/bin/io" not-a-command >/dev/null 2>&1; then
  echo "Unknown FIH commands must return a non-zero status." >&2
  exit 1
fi

# The installer requires Fish, but this headless test only needs to exercise
# its file operations. A harmless stub keeps the test independent of APT.
mkdir -p "$TMP_HOME/bin"
printf '#!/usr/bin/env bash\nexit 0\n' > "$TMP_HOME/bin/fish"
chmod +x "$TMP_HOME/bin/fish"
PATH="$TMP_HOME/bin:$PATH" HOME="$TMP_HOME" XDG_CONFIG_HOME="$TMP_HOME/.config" XDG_DATA_HOME="$TMP_HOME/.local/share" \
  bash "$ROOT_DIR/fih/install.sh"

test -x "$TMP_HOME/.local/bin/io"
test -s "$TMP_HOME/.config/fish/conf.d/fih.fish"
test -s "$TMP_HOME/.config/fish/completions/io.fish"
test -s "$TMP_HOME/.config/fish/functions/fih_prompt.fish"
test -s "$TMP_HOME/.config/fish/functions/fish_prompt.fish"
test -s "$TMP_HOME/.local/share/integeros/fih/config"
installed_help="$("$TMP_HOME/.local/bin/io" help)"
grep -q 'No account or network connection required' <<<"$installed_help"

# A pre-existing custom prompt must remain byte-for-byte unchanged.
mkdir -p "$CUSTOM_HOME/bin" "$CUSTOM_HOME/.config/fish/functions"
printf '#!/usr/bin/env bash\nexit 0\n' > "$CUSTOM_HOME/bin/fish"
chmod +x "$CUSTOM_HOME/bin/fish"
printf 'function fish_prompt; echo CUSTOM; end\n' > "$CUSTOM_HOME/.config/fish/functions/fish_prompt.fish"
cp "$CUSTOM_HOME/.config/fish/functions/fish_prompt.fish" "$CUSTOM_HOME/original-prompt"
PATH="$CUSTOM_HOME/bin:$PATH" HOME="$CUSTOM_HOME" XDG_CONFIG_HOME="$CUSTOM_HOME/.config" XDG_DATA_HOME="$CUSTOM_HOME/.local/share" \
  bash "$ROOT_DIR/fih/install.sh"
cmp "$CUSTOM_HOME/original-prompt" "$CUSTOM_HOME/.config/fish/functions/fish_prompt.fish"
test -s "$CUSTOM_HOME/.config/fish/functions/fih_prompt.fish"

echo "FIH smoke tests passed."
