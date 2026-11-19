#!/usr/bin/env bash
# Read-only structural preflight for the InntegerOS ISO project.
set -Eeuo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
MANIFEST="${ROOT_DIR}/iso/manifest.json"
PYTHON="${PYTHON:-python3}"

case "${1:-}" in
  "") ;;
  -h|--help)
    echo "Usage: bash scripts/iso-preflight.sh"
    echo "Validate ISO metadata and package manifests without building or installing anything."
    exit 0
    ;;
  *) echo "Unknown option: $1" >&2; exit 2 ;;
esac

[[ -f "${MANIFEST}" ]] || { echo "Missing ISO manifest: ${MANIFEST}" >&2; exit 1; }
command -v "${PYTHON}" >/dev/null 2>&1 || { echo "Python 3 is required." >&2; exit 1; }

"${PYTHON}" - "${ROOT_DIR}" <<'PY'
import json
import pathlib
import re
import sys

root = pathlib.Path(sys.argv[1])
data = json.loads((root / "iso/manifest.json").read_text(encoding="utf-8"))

assert data.get("product") == "InntegerOS", "Unexpected product identity"
assert data.get("edition") == "Plasma", "First prototype must be Plasma Edition"
assert data.get("architecture") == "amd64", "Initial architecture must be amd64"
assert data.get("image_type") == "live", "Initial image must be a live image"
assert data.get("base", {}).get("distribution") == "Kubuntu", "InntegerOS 1.0 must use the Kubuntu base"
assert data.get("base", {}).get("release") == "26.04.1", "Unexpected Kubuntu base release"
assert data.get("base", {}).get("status") == "selected", "Kubuntu base selection must be explicit"
assert data.get("base", {}).get("source_iso") == "kubuntu-26.04.1-desktop-amd64.iso"
assert re.fullmatch(r"[0-9a-f]{64}", data.get("base", {}).get("source_sha256", "")), "Source ISO SHA-256 is required"
assert data.get("build", {}).get("status") == "not_started", "Build status must be explicit"
assert data.get("installer", {}).get("backend") == "inherit-kubuntu-live-installer", "Installer must inherit the Kubuntu live installer"
assert data.get("installer", {}).get("status") == "pending_validation", "Inherited installer must remain unvalidated until VM tests pass"
assert data.get("installer", {}).get("destructive_actions_require_confirmation") is True

version = (root / "VERSION").read_text(encoding="utf-8").strip()
assert re.fullmatch(r"\d+\.\d+(?:\.\d+)?", version), f"Invalid VERSION value: {version!r}"

all_count = 0
for relative in data.get("package_manifests", []):
    path = root / "iso" / relative
    assert path.is_file(), f"Missing package manifest: {path.relative_to(root)}"
    packages = []
    for number, raw in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        assert re.fullmatch(r"[a-z0-9][a-z0-9+.-]*", line), (
            f"Invalid package token at {path.relative_to(root)}:{number}: {line!r}"
        )
        assert line not in packages, f"Duplicate package {line!r} in {path.relative_to(root)}"
        packages.append(line)
    assert packages, f"Package manifest is empty: {path.relative_to(root)}"
    all_count += len(packages)
    print(f"OK  {path.relative_to(root)} ({len(packages)} candidates)")

base = (root / "iso/manifests/base/common.txt").read_text(encoding="utf-8")
plasma = (root / "iso/manifests/profiles/plasma/packages.txt").read_text(encoding="utf-8")
assert re.search(r"^network-manager$", base, re.M), "Shared base must include NetworkManager"
assert re.search(r"^plasma-desktop$", plasma, re.M), "Plasma profile must include plasma-desktop"
assert data["build"]["tool"] == "kubuntu-iso-remaster", "Build strategy must remain Kubuntu ISO remastering"
assert data["build"]["configuration"] is None, "Do not claim a build configuration exists before it is committed"

print(f"OK  InntegerOS {version} ISO metadata")
print(f"OK  {all_count} package entries across {len(data['package_manifests'])} manifests")
print("INFO Builder and installer remain unselected; no ISO was built.")
PY

echo "ISO preflight passed. This checks repository structure only, not package availability or bootability."
