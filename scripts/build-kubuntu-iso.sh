#!/usr/bin/env bash
# Build a first-pass InntegerOS live ISO by remastering the selected Kubuntu ISO.
# This embeds the repository payload and release identity in the live filesystem.
# It deliberately does not install unvalidated package-manifest candidates.
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
MANIFEST="${ROOT_DIR}/iso/manifest.json"
BUILD_ROOT="${BUILD_ROOT:-${ROOT_DIR}/iso/build}"
SOURCE_DIR="${BUILD_ROOT}/source"
WORK_DIR="${BUILD_ROOT}/work"
OUTPUT_DIR="${ISO_OUTPUT_DIR:-${ROOT_DIR}/dist}"
PYTHON="${PYTHON:-python3}"
KEEP_WORK="${KEEP_WORK:-0}"
LIVE_ROOT="${WORK_DIR}/live-root"
CHROOT_MOUNTS=()

cleanup_chroot() {
  local mountpoint
  for mountpoint in "${CHROOT_MOUNTS[@]:-}"; do
    sudo umount -R "$mountpoint" 2>/dev/null || true
  done
}
trap cleanup_chroot EXIT

usage() {
  cat <<'EOF'
Usage: scripts/build-kubuntu-iso.sh [--help]

Downloads and verifies the Kubuntu source image, embeds the current
InntegerOS repository payload in its live filesystem, and rebuilds the
hybrid ISO while replaying the source image's El Torito boot configuration.

Environment:
  KEEP_WORK=1  Keep extracted work files after a successful build.
  BUILD_ROOT   Override source and temporary work directory (default: iso/build).
  ISO_OUTPUT_DIR  Successful ISO destination (default: dist/).
EOF
}

case "${1:-}" in
  -h|--help) usage; exit 0 ;;
  "") ;;
  *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
esac

for tool in "${PYTHON}" curl sha256sum xorriso unsquashfs mksquashfs rsync find flock sudo; do
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
print(data["product"])
print(data["edition"])
print(data["architecture"])
PY
)
[[ "${#source[@]}" -eq 6 ]] || { echo "Could not read ISO build metadata." >&2; exit 1; }
ISO_NAME="${source[0]}"
EXPECTED_SHA="${source[1]}"
ISO_URL="${source[2]}"
PRODUCT="${source[3]}"
EDITION="${source[4]}"
ARCH="${source[5]}"

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
sudo rm -rf "${WORK_DIR}/iso-root" "${WORK_DIR}/live-root" "${WORK_DIR}/rebuilt-filesystem.squashfs"
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
sudo unsquashfs -no-progress -d "${WORK_DIR}/live-root" "$SQUASHFS_PATH"

echo "Embedding InntegerOS repository payload..."
sudo mkdir -p "${WORK_DIR}/live-root/opt/InntegerOS"
sudo rsync -a --delete \
  --exclude='.git/' \
  --exclude='iso/build/' \
  --exclude='dist/' \
  --exclude='.github/' \
  --exclude='*.iso' \
  --exclude='*.sha256' \
  "${ROOT_DIR}/" "${WORK_DIR}/live-root/opt/InntegerOS/"

VERSION="$(head -n 1 "${ROOT_DIR}/VERSION")"
COMMIT="$(git -C "$ROOT_DIR" rev-parse HEAD 2>/dev/null || printf 'unknown')"
sudo mkdir -p "${WORK_DIR}/live-root/etc"
sudo tee "${WORK_DIR}/live-root/etc/integeros-release" >/dev/null <<EOF
NAME="InntegerOS"
PRETTY_NAME="InntegerOS ${VERSION} Plasma Edition (development image)"
VERSION="${VERSION}"
VERSION_CODENAME="development"
ID=integeros
ID_LIKE="ubuntu"
BUILD_COMMIT="${COMMIT}"
BASE_IMAGE="Kubuntu 26.04.1"
EOF
sudo chmod 0644 "${WORK_DIR}/live-root/etc/integeros-release"

echo "Installing InntegerOS applications and required packages into the live system..."
for mountpoint in dev proc sys run; do sudo mkdir -p "${LIVE_ROOT}/${mountpoint}"; done
sudo mount --rbind /dev "${LIVE_ROOT}/dev"
CHROOT_MOUNTS+=("${LIVE_ROOT}/dev")
sudo mount -t proc proc "${LIVE_ROOT}/proc"
CHROOT_MOUNTS+=("${LIVE_ROOT}/proc")
sudo mount --rbind /sys "${LIVE_ROOT}/sys"
CHROOT_MOUNTS+=("${LIVE_ROOT}/sys")
sudo mount --rbind /run "${LIVE_ROOT}/run"
CHROOT_MOUNTS+=("${LIVE_ROOT}/run")

# Temporarily provide the build runner DNS settings to APT inside the chroot.
RESOLV_LINK="$(sudo readlink "${LIVE_ROOT}/etc/resolv.conf" 2>/dev/null || true)"
RESOLV_BACKUP="${WORK_DIR}/resolv.conf.original"
RESOLV_WAS_LINK=0
if [[ -L "${LIVE_ROOT}/etc/resolv.conf" ]]; then
  RESOLV_WAS_LINK=1
  sudo rm "${LIVE_ROOT}/etc/resolv.conf"
elif [[ -f "${LIVE_ROOT}/etc/resolv.conf" ]]; then
  sudo cp -a "${LIVE_ROOT}/etc/resolv.conf" "${RESOLV_BACKUP}"
fi
sudo install -m 0644 /etc/resolv.conf "${LIVE_ROOT}/etc/resolv.conf"
sudo chroot "${LIVE_ROOT}" /bin/bash /opt/InntegerOS/scripts/provision-live-image.sh
sudo rm -f "${LIVE_ROOT}/etc/resolv.conf"
if ((RESOLV_WAS_LINK)); then
  sudo ln -s "${RESOLV_LINK}" "${LIVE_ROOT}/etc/resolv.conf"
elif [[ -f "${RESOLV_BACKUP}" ]]; then
  sudo cp -a "${RESOLV_BACKUP}" "${LIVE_ROOT}/etc/resolv.conf"
fi
cleanup_chroot
CHROOT_MOUNTS=()

echo "Rebuilding live SquashFS..."
sudo mksquashfs "${WORK_DIR}/live-root" "${WORK_DIR}/rebuilt-filesystem.squashfs" \
  -noappend -comp xz -b 1M -no-progress

OUTPUT_ISO="${OUTPUT_DIR}/InntegerOS-${VERSION}-Plasma-amd64.iso"
rm -f "$OUTPUT_ISO" "${OUTPUT_ISO}.sha256" "${OUTPUT_DIR}/BUILD-METADATA.txt" "${OUTPUT_DIR}/boot-catalog.txt"
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
