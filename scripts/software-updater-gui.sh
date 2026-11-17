#!/usr/bin/env bash
# InntegerOS 0.7 graphical update assistant.
# Source updates are fast-forward-only and require a clean official checkout.
set -Eeuo pipefail

TITLE="InntegerOS Software Updater"
LOG_DIR="${XDG_CACHE_HOME:-${HOME}/.cache}/integeros"
LOG_FILE="${LOG_DIR}/software-updater.log"
RELEASE_URL="https://raw.githubusercontent.com/Innygr/InntegerOS/main/release/latest.json"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
if ! git -C "${ROOT_DIR}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  if git -C "${HOME}/InntegerOS" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    ROOT_DIR="${HOME}/InntegerOS"
  fi
fi

if ! command -v kdialog >/dev/null 2>&1; then
  printf 'This graphical updater requires kdialog.\n' >&2
  exit 1
fi
if [[ -z "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]]; then
  printf 'Launch this updater from a KDE graphical session.\n' >&2
  exit 1
fi

info() { kdialog --title "${TITLE}" --icon integeros --msgbox "$1" >/dev/null 2>&1 || true; }
error() { kdialog --title "${TITLE}" --icon integeros --error "$1" >/dev/null 2>&1 || true; }
details_error() {
  kdialog --title "${TITLE}" --icon integeros --detailederror "$1" "$2" >/dev/null 2>&1 || true
}
log_output() {
  mkdir -p -- "${LOG_DIR}"
  printf '\n=== %s ===\n%s\n' "$(date '+%F %T')" "$1" >> "${LOG_FILE}"
}

check_source() {
  local output="" origin="" branch="" version="unknown" remote_version="unknown" behind=""
  if ! git -C "${ROOT_DIR}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    info "No Git checkout was found. Open the InntegerOS repository folder and run bash scripts/software-updater-gui.sh there.\n\nExpected repository: ${HOME}/InntegerOS\n\nNo files were changed."
    return
  fi
  version="$(head -n 1 "${ROOT_DIR}/VERSION" 2>/dev/null || echo unknown)"
  origin="$(git -C "${ROOT_DIR}" remote get-url origin 2>/dev/null || true)"
  case "${origin}" in
    https://github.com/Innygr/InntegerOS.git|https://github.com/Innygr/InntegerOS|git@github.com:Innygr/InntegerOS.git|git@github.com:Innygr/InntegerOS) ;;
    *) error "The checkout's origin is not the official InntegerOS repository.\n\nNo changes were made."; return ;;
  esac
  branch="$(git -C "${ROOT_DIR}" branch --show-current)"
  if [[ "${branch}" != main ]]; then
    error "The current branch is '${branch}', not main.\n\nSwitch branches manually after reviewing your work. No changes were made."; return
  fi
  if ! git -C "${ROOT_DIR}" diff --quiet || ! git -C "${ROOT_DIR}" diff --cached --quiet || [[ -n "$(git -C "${ROOT_DIR}" ls-files --others --exclude-standard)" ]]; then
    error "Local edits or untracked files were found. Back them up or commit them before updating.\n\nNo changes were made."; return
  fi
  if ! git -C "${ROOT_DIR}" fetch --quiet origin main; then
    error "Could not fetch GitHub updates. Check your internet connection and try again."; return
  fi
  behind="$(git -C "${ROOT_DIR}" rev-list --count HEAD..origin/main)"
  remote_version="$(git -C "${ROOT_DIR}" show origin/main:VERSION 2>/dev/null | head -n 1 || echo unknown)"
  output="Installed version: ${version}\nLatest version: ${remote_version}\nCommits available: ${behind}\n\nRepository: ${ROOT_DIR}"
  if [[ "${behind}" == 0 ]]; then
    info "${output}\n\nInntegerOS is up to date."
    log_output "Source check: up to date. ${output}"
    return
  fi
  if ! kdialog --title "${TITLE}" --icon integeros --yesno "${output}\n\nApply the source update now? This performs only 'git pull --ff-only origin main'. It does not install packages or apply desktop settings."; then
    info "Update skipped. No source files changed."
    return
  fi
  local pull_output status=0
  pull_output="$(git -C "${ROOT_DIR}" pull --ff-only origin main 2>&1)" || status=$?
  log_output "Source update (exit ${status}):\n${pull_output}"
  if ((status != 0)); then
    details_error "The source update failed (exit ${status}). Review the details before trying again." "${pull_output}"
    return
  fi
  version="$(head -n 1 "${ROOT_DIR}/VERSION" 2>/dev/null || echo unknown)"
  if [[ -f "${ROOT_DIR}/scripts/install-welcome-center.sh" ]] && kdialog --title "${TITLE}" --icon integeros --yesno "InntegerOS source updated successfully to version ${version}.\n\nRefresh the installed Welcome Center and helper scripts now? This updates InntegerOS application files only. It does not apply the desktop profile or install system packages."; then
    local install_output install_status=0
    install_output="$(bash "${ROOT_DIR}/scripts/install-welcome-center.sh" 2>&1)" || install_status=$?
    log_output "Refresh Welcome Center (exit ${install_status}):\n${install_output}"
    if ((install_status != 0)); then
      details_error "The source updated, but refreshing the Welcome Center failed (exit ${install_status})." "${install_output}"
      return
    fi
    info "Source updated to ${version}; the Welcome Center and helper scripts were refreshed. Desktop settings were not reapplied."
  else
    info "Source updated successfully to ${version}. The installed Welcome Center was left unchanged. You can refresh it later by running bash scripts/install-welcome-center.sh from the repository. Desktop settings were not reapplied."
  fi
}


check_release() {
  local local_version remote_data remote_version release_state release_url notes
  local_version="$(head -n 1 "${ROOT_DIR}/VERSION" 2>/dev/null || echo 0)"
  if ! command -v curl >/dev/null 2>&1 || ! command -v python3 >/dev/null 2>&1; then
    info "Release checking needs curl and Python 3. No changes were made."
    return
  fi
  if ! remote_data="$(curl --fail --silent --show-error --location --max-time 15 "${RELEASE_URL}" 2>/dev/null)"; then
    info "Could not reach InntegerOS release information. Check your connection and try again."
    return
  fi
  if ! IEO_RELEASE_DATA="$(printf '%s' "${remote_data}" | python3 -c 'import json,sys; d=json.load(sys.stdin); print("|".join(str(d.get(k,"")).replace("|"," ") for k in ("version","status","url","notes")))')"; then
    error "The InntegerOS release information could not be read. No changes were made."
    return
  fi
  IFS='|' read -r remote_version release_state release_url notes <<< "${IEO_RELEASE_DATA}"
  if [[ -z "${remote_version}" || -z "${release_url}" ]]; then
    error "Release information is incomplete. No changes were made."
    return
  fi
  if dpkg --compare-versions "${remote_version}" gt "${local_version}"; then
    if kdialog --title "${TITLE}" --icon integeros --yesno "A newer InntegerOS release is available.\n\nInstalled: ${local_version}\nAvailable: ${remote_version}\nStatus: ${release_state}\n\n${notes}\n\nOpen the official release page to review the update?"; then
      xdg-open "${release_url}" >/dev/null 2>&1 &
    fi
  else
    info "InntegerOS is up to date.\n\nInstalled version: ${local_version}\nLatest published version: ${remote_version}\n\nSystem package updates are checked separately."
  fi
  log_output "Release metadata check: installed=${local_version}; latest=${remote_version}; status=${release_state}"
}

open_system_updater() {
  if ! command -v konsole >/dev/null 2>&1; then
    error "Konsole is not installed. Open Discover or System Settings to manage system software."; return
  fi
  if ! kdialog --title "${TITLE}" --icon integeros --yesno "Open the terminal updater for Ubuntu/Kubuntu packages?\n\nIt asks before refreshing APT lists and separately before installing upgrades. Review the package list before approving."; then
    return
  fi
  konsole --hold -e bash "${ROOT_DIR}/scripts/software-updater.sh" --system >/dev/null 2>&1 &
}

while true; do
  choice="$(kdialog --title "${TITLE}" --icon integeros --menu \
    "Installed version: $(head -n 1 "${ROOT_DIR}/VERSION" 2>/dev/null || echo unknown)\nChoose an update task. Source and system updates are kept separate." \
    "release" "Check for a newer InntegerOS release" \
    "source" "Update installed InntegerOS source checkout" \
    "system" "Ubuntu / Kubuntu system packages (terminal)" \
    "changelog" "Open InntegerOS changelog" \
    "quit" "Close" 2>/dev/null)" || exit 0
  case "${choice}" in
    release) check_release ;;
    source) check_source ;;
    system) open_system_updater ;;
    changelog)
      if command -v xdg-open >/dev/null 2>&1; then
        xdg-open "${ROOT_DIR}/CHANGELOG.md" >/dev/null 2>&1 &
      else
        info "Changelog: ${ROOT_DIR}/CHANGELOG.md"
      fi
      ;;
    quit|"") exit 0 ;;
  esac
done
