#!/usr/bin/env bash
set -Eeuo pipefail

if [[ "${EUID}" -eq 0 ]]; then
  echo "Run this as your normal user, not with sudo." >&2
  exit 1
fi

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
BIN_DIR="${HOME}/.local/bin"
APP_DIR="${HOME}/.local/share/integeros/theme-studio"
RESOURCE_DIR="${APP_DIR}/resources"
DESKTOP_DIR="${HOME}/.local/share/applications"
SCHEME_DIR="${HOME}/.local/share/color-schemes"

for required in apps/theme-studio/integeros-theme-studio packaging/integeros-theme-studio.desktop config/themes/InntegerOSLight.colors config/themes/InnyGrOS.colors scripts/login-theme.sh scripts/boot-animation.sh branding/login/sddm/blacklight branding/boot/plymouth; do
  [[ -e "${ROOT_DIR}/${required}" ]] || { echo "Missing required file or directory: ${ROOT_DIR}/${required}" >&2; exit 1; }
done

mkdir -p "${BIN_DIR}" "${APP_DIR}" "${DESKTOP_DIR}" "${SCHEME_DIR}" \
  "${RESOURCE_DIR}/scripts" "${RESOURCE_DIR}/branding/login" "${RESOURCE_DIR}/branding/boot"
install -m 0755 "${ROOT_DIR}/apps/theme-studio/integeros-theme-studio" "${APP_DIR}/integeros-theme-studio"
install -m 0755 "${APP_DIR}/integeros-theme-studio" "${BIN_DIR}/integeros-theme-studio"
install -m 0644 "${ROOT_DIR}/packaging/integeros-theme-studio.desktop" "${DESKTOP_DIR}/integeros-theme-studio.desktop"

# Keep the existing guarded system-level installers self-contained when launched from Theme Studio.
install -m 0755 "${ROOT_DIR}/scripts/login-theme.sh" "${RESOURCE_DIR}/scripts/login-theme.sh"
install -m 0755 "${ROOT_DIR}/scripts/boot-animation.sh" "${RESOURCE_DIR}/scripts/boot-animation.sh"
rm -rf "${RESOURCE_DIR}/branding/login/sddm/blacklight" "${RESOURCE_DIR}/branding/boot/plymouth"
cp -a "${ROOT_DIR}/branding/login/sddm/blacklight" "${RESOURCE_DIR}/branding/login/sddm/"
cp -a "${ROOT_DIR}/branding/boot/plymouth" "${RESOURCE_DIR}/branding/boot/"

for scheme in InntegerOSLight InnyGrOS; do
  source_file="${ROOT_DIR}/config/themes/${scheme}.colors"
  target_file="${SCHEME_DIR}/${scheme}.colors"
  if [[ -f "${target_file}" ]] && ! cmp -s "${source_file}" "${target_file}"; then
    cp -p "${target_file}" "${target_file}.backup.$(date +%Y%m%d-%H%M%S)"
  fi
  install -m 0644 "${source_file}" "${target_file}"
done

echo "InntegerOS Theme Studio installed with desktop, SDDM and Plymouth controls."
