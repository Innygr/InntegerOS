#!/usr/bin/env bash
# Build a first-pass InntegerOS live ISO by remastering the selected Kubuntu ISO.
# This embeds the repository payload and release identity in the live filesystem.
# It deliberately does not install unvalidated package-manifest candidates.
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
MANIFEST="${ROOT_DIR}/iso/manifest.json"
BUILD_ROOT="${ROOT_DIR}/iso/build"
SOURCE_DIR="${BUILD_ROOT}/source"
WORK_DIR="${BUILD_ROOT}/work"
OUTPUT_DIR="${BUILD_ROOT}/output"
PYTHON="${PYTHON:-python3}"
KEEP_WORK="${KEEP_WORK:-0}"

usage() {
  cat <<'EOF'
Usage: scripts/build-kubuntu-iso.sh [--help]

Downloads and verifies the Kubuntu source image, embeds the current
InntegerOS repository payload in its live filesystem, and rebuilds the
hybrid ISO while replaying the source image's El Torito boot configuration.

Environment:
  KEEP_WORK=1  Keep extracted work files after a successful build.
  BUILD_ROOT   Override generated build directory (default: iso/build).
EOF
}

case "${1:-}" in
  -h|--help) usage; exit 0 ;;
  "") ;;
  *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
esac

for tool in "${PYTHON}" curl sha256sum xorriso unsquashfs mksquashfs rsync find; do
  command -v "$tool" >/dev/null 2>&1 || {
    echo "Missing build dependency: $tool" >&2
    exit 1
  }
done
[[ -f "$MANIFEST" ]] || { echo "Missing manifest: $MANIFEST" >&2; exit 1; }

mapfile -t source < <("${PYTHON}" - "$MANIFEST" <<'PY'
import json, sys
data = json.load(open(sys.argv[1], encoding="utf-8"))
base = data["base"]
print(base["source_iso"])
print(base["source_sha256"])
print(base["source_url"].rstrip("/") + "/" + base["source_iso"])
print(base["source_url"].rstrip("/") + "/SHA256SUMS")
print(data["product"])
print(data["edition"])
print(data["architecture"])
PY
)
[[ "${#source[@]}" -eq 7 ]] || { echo "Could not read ISO build metadata." >&2; exit 1; }
ISO_NAME="${source[0]}"
EXPECTED_SHA="${source[1]}"
ISO_URL="${source[2]}"
SUMS_URL="${source[3]}"
PRODUCT="${source[4]}"
EDITION="${source[5]}"
ARCH="${source[6]}"

[[ "$PRODUCT" == InntegerOS && "$EDITION" == Plasma && "$ARCH" == amd64 ]] || {
  echo "Refusing unsupported product, edition, or architecture." >&2
  exit 1
}
[[ "$EXPECTED_SHA" =~ ^[0-9a-f]{64}$ ]] || { echo "Invalid source SHA-256 in manifest." >&2; exit 1; }

mkdir -p "$SOURCE_DIR" "$WORK_DIR" "$OUTPUT_DIR"
exec 9>"${BUILD_ROOT}/.build.lock"
if ! flock -n 9; then
  echo "Another InntegerOS ISO build is already running." >&2
  exit 1
fi

SOURCE_ISO="${SOURCE_DIR}/${ISO_NAME}"
if [[ ! -f "$SOURCE_ISO" ]]; then
  echo "Downloading official Kubuntu source image..."
  curl --fail --show-error --location --retry 3 --retry-delay 2 \
    --proto '=https' --tlsv1.2 "$ISO_URL" -o "$SOURCE_ISO"
fi

echo "Verifying source image checksum..."
bash "${ROOT_DIR}/scripts/verify-kubuntu-source.sh" "$SOURCE_ISO"

echo "Inspecting source ISO boot catalog..."
xorriso -indev "$SOURCE_ISO" -report_el_torito plain > "${WORK_DIR}/source-boot-catalog.txt"
grep -q "El Torito" "${WORK_DIR}/source-boot-catalog.txt" || {
  echo "No El Torito boot catalog found; refusing to produce a potentially non-bootable image." >&2
  exit 1
}

echo "Extracting source ISO filesystem..."
rm -rf "${WORK_DIR}/iso-root" "${WORK_DIR}/live-root" "${WORK_DIR}/rebuilt-filesystem.squashfs"
mkdir -p "${WORK_DIR}/iso-root"
xorriso -osirrox on -indev "$SOURCE_ISO" -extract / "${WORK_DIR}/iso-root" >/dev/null

mapfile -t squashfs_images < <(find "${WORK_DIR}/iso-root" -type f -iname '*.squashfs' -print)
if [[ "${#squashfs_images[@]}" -ne 1 ]]; then
  printf 'Expected exactly one live SquashFS image; found %s. Refusing ambiguous remaster.\n' "${#squashfs_images[@]}" >&2
  printf '%s\n' "${squashfs_images[@]}" >&2
  exit 1
fi
SQUASHFS_PATH="${squashfs_images[0]}"
ISO_SQUASHFS_PATH="/${SQUASHFS_PATH#"${WORK_DIR}/iso-root/"}"

echo "Unpacking live filesystem: ${ISO_SQUASHFS_PATH}"
unsquashfs -no-progress -d "${WORK_DIR}/live-root" "$SQUASHFS_PATH"

echo "Embedding InntegerOS repository payload..."
mkdir -p "${WORK_DIR}/live-root/opt/InntegerOS"
rsync -a --delete \
  --exclude='.git/' \
  --exclude='iso/build/' \
  --exclude='.github/' \
  --exclude='*.iso' \
  --exclude='*.sha256' \
  "${ROOT_DIR}/" "${WORK_DIR}/live-root/opt/InntegerOS/"

VERSION="$(head -n 1 "${ROOT_DIR}/VERSION")"
COMMIT="$(git -C "$ROOT_DIR" rev-parse HEAD 2>/dev/null || printf 'unknown')"
mkdir -p "${WORK_DIR}/live-root/etc"
cat > "${WORK_DIR}/live-root/etc/integeros-release" <<EOF
NAME="InntegerOS"
PRETTY_NAME="InntegerOS ${VERSION} Plasma Edition (development image)"
VERSION="${VERSION}"
VERSION_CODENAME="development"
ID=integeros
ID_LIKE="ubuntu"
BUILD_COMMIT="${COMMIT}"
BASE_IMAGE="Kubuntu 26.04.1"
EOF
chmod 0644 "${WORK_DIR}/live-root/etc/integeros-release"

echo "Rebuilding live SquashFS..."
mksquashfs "${WORK_DIR}/live-root" "${WORK_DIR}/rebuilt-filesystem.squashfs" \
  -noappend -comp xz -b 1M -no-progress

OUTPUT_ISO="${OUTPUT_DIR}/InntegerOS-${VERSION}-Plasma-amd64.iso"
rm -f "$OUTPUT_ISO"
echo "Rebuilding ISO and replaying upstream boot configuration..."
xorriso -indev "$SOURCE_ISO" -outdev "$OUTPUT_ISO" \
  -boot_image any replay \
  -map "${WORK_DIR}/rebuilt-filesystem.squashfs" "$ISO_SQUASHFS_PATH" \
  -commit

echo "Checking rebuilt ISO structure..."
xorriso -indev "$OUTPUT_ISO" -report_el_torito plain > "${OUTPUT_DIR}/boot-catalog.txt"
grep -q "El Torito" "${OUTPUT_DIR}/boot-catalog.txt" || {
  echo "Rebuilt ISO has no detectable El Torito boot catalog." >&2
  exit 1
}
sha256sum "$OUTPUT_ISO" > "${OUTPUT_ISO}.sha256"
cat > "${OUTPUT_DIR}/BUILD-METADATA.txt" <<EOF
Product: InntegerOS
Version: ${VERSION}
Edition: Plasma
Architecture: amd64
Base: Kubuntu 26.04.1
Source ISO: ${ISO_NAME}
Source SHA-256: ${EXPECTED_SHA}
Repository commit: ${COMMIT}
Build type: first-pass live filesystem remaster
Installer: inherited from Kubuntu source; not yet VM-validated
VM validation: NOT RUN
Output: $(basename "$OUTPUT_ISO")
Output SHA-256: $(awk '{print $1}' "${OUTPUT_ISO}.sha256")
EOF

echo "ISO build completed: $OUTPUT_ISO"
echo "Checksum: ${OUTPUT_ISO}.sha256"
echo "IMPORTANT: This first-pass image embeds the InntegerOS payload but does not install the proposal-only package manifests. UEFI boot and installer behaviour still require disposable-VM validation."

if [[ "$KEEP_WORK" != 1 ]]; then
  rm -rf "${WORK_DIR}/iso-root" "${WORK_DIR}/live-root" "${WORK_DIR}/rebuilt-filesystem.squashfs"
fi
