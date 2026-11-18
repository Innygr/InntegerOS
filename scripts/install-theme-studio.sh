#!/usr/bin/env bash
set -Eeuo pipefail

if [[ "${EUID}" -eq 0 ]]; then
  echo "Run this as your normal user, not with sudo." >&2
  exit 1
fi

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
BIN_DIR="${HOME}/.local/bin"
APP_DIR="${HOME}/.local/share/integeros/theme-studio"
DESKTOP_DIR="${HOME}/.local/share/applications"
SCHEME_DIR="${HOME}/.local/share/color-schemes"

for required in apps/theme-studio/integeros-theme-studio packaging/integeros-theme-studio.desktop config/themes/InntegerOSLight.colors config/themes/InnyGrOS.colors; do
  [[ -f "${ROOT_DIR}/${required}" ]] || { echo "Missing required file: ${required}" >&2; exit 1; }
done

mkdir -p "${BIN_DIR}" "${APP_DIR}" "${DESKTOP_DIR}" "${SCHEME_DIR}"
install -m 0755 "${ROOT_DIR}/apps/theme-studio/integeros-theme-studio" "${APP_DIR}/integeros-theme-studio"
install -m 0755 "${APP_DIR}/integeros-theme-studio" "${BIN_DIR}/integeros-theme-studio"
install -m 0644 "${ROOT_DIR}/packaging/integeros-theme-studio.desktop" "${DESKTOP_DIR}/integeros-theme-studio.desktop"

for scheme in InntegerOSLight InnyGrOS; do
  source_file="${ROOT_DIR}/config/themes/${scheme}.colors"
  target_file="${SCHEME_DIR}/${scheme}.colors"
  if [[ -f "${target_file}" ]] && ! cmp -s "${source_file}" "${target_file}"; then
    cp -p "${target_file}" "${target_file}.backup.$(date +%Y%m%d-%H%M%S)"
  fi
  install -m 0644 "${source_file}" "${target_file}"
done

echo "InntegerOS Theme Studio installed with InntegerOS Light and Dark presets."
