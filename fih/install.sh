#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
FIH_DIR="$ROOT_DIR/fih"
DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/integeros/fih"
BIN_DIR="${HOME}/.local/bin"
FISH_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/fish"

if [[ "$EUID" -eq 0 ]]; then
  echo "Run this installer as your normal user, not with sudo." >&2
  exit 1
fi
if ! command -v fish >/dev/null 2>&1; then
  echo "Fish is not installed. Install it through Discover or run: bash scripts/install-apps.sh --group shell" >&2
  exit 1
fi
[[ -s "$FIH_DIR/bin/io" && -s "$FIH_DIR/fish/conf.d/fih.fish" ]] || {
  echo "FIH source files are missing; run this from the InntegerOS repository." >&2
  exit 1
}

mkdir -p "$BIN_DIR" "$DATA_DIR" "$FISH_DIR/conf.d" "$FISH_DIR/completions" "$FISH_DIR/functions"

# Preserve a pre-existing custom fish prompt rather than replacing it.
install -m 0644 "$FIH_DIR/fish/functions/fish_prompt.fish" "$FISH_DIR/functions/fih_prompt.fish"
if [[ ! -e "$FISH_DIR/functions/fish_prompt.fish" ]]; then
  cat > "$FISH_DIR/functions/fish_prompt.fish" <<'PROMPT'
function fish_prompt
    fih_prompt
end
PROMPT
  chmod 0644 "$FISH_DIR/functions/fish_prompt.fish"
else
  echo "Existing fish prompt preserved. To try the FIH prompt, use: functions -c fih_prompt fish_prompt"
fi

install -m 0755 "$FIH_DIR/bin/io" "$BIN_DIR/io"
install -m 0644 "$FIH_DIR/fish/conf.d/fih.fish" "$FISH_DIR/conf.d/fih.fish"
install -m 0644 "$FIH_DIR/fish/completions/io.fish" "$FISH_DIR/completions/io.fish"

# Keep source-linked operation available while also providing an installed payload.
{
  printf 'FIH_VERSION=%q\n' "0.1.0"
  printf 'INNTEGEROS_ROOT=%q\n' "$ROOT_DIR"
} > "$DATA_DIR/config"

echo
echo "FIH installed for this user."
echo "  Command:  io help"
echo "  Shell:    fish (install with: sudo apt install fish)"
echo "  Account:  none required"
echo "  Network:  not used by FIH itself"
echo
echo "FIH does not change your default login shell."
echo "Open a new fish session to load the FIH greeting and completions."
