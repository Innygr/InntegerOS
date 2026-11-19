#!/usr/bin/env bash
# Provision the Kubuntu live filesystem with the supported InntegerOS Plasma
# application set. Run only inside the extracted image's chroot.
set -Eeuo pipefail

ROOT=/opt/InntegerOS
[[ -f /etc/os-release ]] || { echo "Missing target os-release." >&2; exit 1; }
. /etc/os-release
[[ "${ID:-}" == ubuntu || " ${ID_LIKE:-} " == *" ubuntu "* ]] || {
  echo "InntegerOS image provisioning requires an Ubuntu/Kubuntu root." >&2
  exit 1
}

read_manifest() {
  local file="$1"
  [[ -f "$file" ]] || { echo "Missing package manifest: $file" >&2; exit 1; }
  awk 'NF && $1 !~ /^#/ { print $1 }' "$file"
}

mapfile -t packages < <(
  {
    read_manifest "$ROOT/iso/manifests/base/common.txt"
    read_manifest "$ROOT/iso/manifests/profiles/plasma/packages.txt"
    printf '%s\n' python3 python3-tk ffmpeg imagemagick
  } | sort -u
)

echo "Refreshing Kubuntu package indexes..."
apt-get update
echo "Installing InntegerOS Plasma and first-party application dependencies..."
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "${packages[@]}"

# Install first-party applications in a system location. Keeping the complete
# source tree in /opt lets the Control Center find its helper scripts reliably.
install -d -m 0755 /usr/share/icons/hicolor/scalable/apps /usr/share/applications /usr/local/bin /usr/local/lib
install -m 0644 "$ROOT/branding/logo/inntegeros-icon.svg" /usr/share/icons/hicolor/scalable/apps/inntegeros.svg
cat > /usr/local/bin/integeros-control-center <<'EOF'
#!/bin/sh
exec /usr/bin/python3 /opt/InntegerOS/apps/control-center/integeros-control-center "$@"
EOF
chmod 0755 /usr/local/bin/integeros-control-center
ln -sfn "$ROOT/apps/blacklight-control/blacklight-control" /usr/local/bin/blacklight-control
install -m 0755 "$ROOT/apps/blacklight-suite/blacklight-desktop-suite" /usr/local/bin/blacklight-desktop-suite
install -m 0644 "$ROOT/apps/integeros-wallpaper-studio.py" /usr/local/lib/integeros-wallpaper-studio.py

cat > /usr/share/applications/integeros-control-center.desktop <<'EOF'
[Desktop Entry]
Type=Application
Name=InntegerOS Control Center
GenericName=System and desktop control center
Comment=Welcome, system maintenance, personalization and Blacklight tools
Exec=/usr/local/bin/integeros-control-center
Icon=inntegeros
Terminal=false
Categories=Settings;System;
StartupNotify=true
EOF

cat > /usr/share/applications/blacklight-desktop-suite.desktop <<'EOF'
[Desktop Entry]
Type=Application
Name=Blacklight Desktop Suite
Comment=Team Blacklight desktop utilities
Exec=/usr/local/bin/blacklight-desktop-suite
Icon=inntegeros
Terminal=false
Categories=Utility;
StartupNotify=true
EOF

cat > /usr/share/applications/integeros-wallpaper-studio.desktop <<'EOF'
[Desktop Entry]
Type=Application
Name=InntegerOS Wallpaper Studio
Comment=Create branded animated desktop wallpapers
Exec=python3 /usr/local/lib/integeros-wallpaper-studio.py
Icon=inntegeros
Terminal=false
Categories=Graphics;
StartupNotify=true
EOF

# Mark the image identity and keep optional bundles opt-in. Do not auto-launch
# configuration tools or mutate a user's home directory during image build.
install -d -m 0755 /etc/integeros
cat > /etc/integeros/image-profile <<'EOF'
EDITION=Plasma
FIRST_PARTY_APPS=control-center,blacklight-desktop-suite,wallpaper-studio
OPTIONAL_BUNDLES=development,creative,gaming
EOF
update-desktop-database /usr/share/applications 2>/dev/null || true
echo "InntegerOS live-image applications and required dependencies installed."
