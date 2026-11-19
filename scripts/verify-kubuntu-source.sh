#!/usr/bin/env bash
# Verify the selected Kubuntu source ISO against both the repository manifest
# and the checksum published in the official Kubuntu release directory.
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
MANIFEST="${ROOT_DIR}/iso/manifest.json"
MODE="iso"
ISO_PATH=""

usage() {
  cat <<'EOF'
Usage:
  bash scripts/verify-kubuntu-source.sh [--metadata-only]
  bash scripts/verify-kubuntu-source.sh /path/to/kubuntu-26.04.1-desktop-amd64.iso

--metadata-only  Fetch SHA256SUMS and confirm its selected ISO entry matches
                 iso/manifest.json, without requiring the multi-gigabyte ISO.
EOF
}

case "${1:-}" in
  -h|--help) usage; exit 0 ;;
  --metadata-only) MODE="metadata";;
  "") ISO_PATH="${ROOT_DIR}/iso/build/source/kubuntu-26.04.1-desktop-amd64.iso";;
  *) ISO_PATH="$1";;
esac

for command_name in python3 curl sha256sum; do
  command -v "$command_name" >/dev/null 2>&1 || {
    echo "Missing required command: $command_name" >&2
    exit 1
  }
done
[[ -f "$MANIFEST" ]] || { echo "Missing manifest: $MANIFEST" >&2; exit 1; }

mapfile -t source < <(python3 - "$MANIFEST" <<'PY'
import json, sys
data = json.load(open(sys.argv[1], encoding="utf-8"))
base = data["base"]
print(base["source_iso"])
print(base["source_sha256"])
print(base["source_url"].rstrip("/") + "/SHA256SUMS")
print(base["distribution"])
print(base["release"])
PY
)
[[ "${#source[@]}" -eq 5 ]] || { echo "Could not read source-image metadata." >&2; exit 1; }
filename="${source[0]}"
expected="${source[1]}"
sums_url="${source[2]}"
distribution="${source[3]}"
release="${source[4]}"

[[ "$distribution" == "Kubuntu" && "$release" == "26.04.1" ]] || {
  echo "Refusing unexpected source: $distribution $release" >&2
  exit 1
}
[[ "$filename" == "kubuntu-26.04.1-desktop-amd64.iso" ]] || {
  echo "Unexpected source ISO filename: $filename" >&2
  exit 1
}
[[ "$expected" =~ ^[0-9a-f]{64}$ ]] || {
  echo "Manifest source_sha256 is not a valid SHA-256." >&2
  exit 1
}

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
sums_file="$tmpdir/SHA256SUMS"

echo "Fetching official Kubuntu SHA256SUMS..."
curl --fail --silent --show-error --location --proto '=https' --tlsv1.2 "$sums_url" -o "$sums_file"

published="$(awk -v name="$filename" '$2 == name || $2 == "*" name {print $1}' "$sums_file")"
[[ "$published" =~ ^[0-9a-f]{64}$ ]] || {
  echo "Official SHA256SUMS does not contain one unambiguous entry for $filename." >&2
  exit 1
}
[[ "$published" == "$expected" ]] || {
  echo "Manifest checksum does not match the official Kubuntu SHA256SUMS entry." >&2
  echo "Manifest: $expected" >&2
  echo "Official: $published" >&2
  exit 1
}
echo "OK  Manifest checksum matches the official Kubuntu release metadata."

if [[ "$MODE" == "metadata" ]]; then
  echo "Metadata verification passed; the ISO file itself was not downloaded or checked."
  exit 0
fi

[[ -f "$ISO_PATH" ]] || {
  echo "Source ISO not found: $ISO_PATH" >&2
  echo "Place the official ISO there or pass its path as the first argument." >&2
  exit 2
}
actual="$(sha256sum "$ISO_PATH" | awk '{print $1}')"
[[ "$actual" == "$expected" ]] || {
  echo "Source ISO checksum mismatch." >&2
  echo "Expected: $expected" >&2
  echo "Actual:   $actual" >&2
  exit 1
}
echo "OK  Source ISO checksum verified: $filename"
