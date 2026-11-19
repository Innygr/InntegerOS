#!/usr/bin/env bash
# Offline fixture tests for verify-kubuntu-source.sh.
set -Eeuo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
FIXTURE_DIR="$(mktemp -d)"
trap 'rm -rf "$FIXTURE_DIR"' EXIT
mkdir -p "$FIXTURE_DIR/bin"
expected="831e4d4bb85098339ba43d3502cd6619b27e76daf37246a084cd68a6413090b8"
printf '%s  kubuntu-26.04.1-desktop-amd64.iso\n' "$expected" > "$FIXTURE_DIR/SHA256SUMS"
cat > "$FIXTURE_DIR/bin/curl" <<'CURL'
#!/usr/bin/env bash
set -e
while (($#)); do
  if [[ "$1" == "-o" ]]; then
    output="$2"; shift 2
  else
    shift
  fi
done
cp "$FIXTURE_SUMS" "$output"
CURL
chmod +x "$FIXTURE_DIR/bin/curl"
export FIXTURE_SUMS="$FIXTURE_DIR/SHA256SUMS"
PATH="$FIXTURE_DIR/bin:$PATH" bash "$ROOT_DIR/scripts/verify-kubuntu-source.sh" --metadata-only

printf '%064d  kubuntu-26.04.1-desktop-amd64.iso\n' 0 > "$FIXTURE_DIR/SHA256SUMS"
if PATH="$FIXTURE_DIR/bin:$PATH" bash "$ROOT_DIR/scripts/verify-kubuntu-source.sh" --metadata-only >/dev/null 2>&1; then
  echo "Verifier accepted a mismatched published checksum." >&2
  exit 1
fi
echo "Kubuntu source verifier fixtures passed."
