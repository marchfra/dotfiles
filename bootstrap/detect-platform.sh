#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/platform.sh"

os="$(detect_os)"
pkg="$(detect_pkg_manager)"

echo "Detected OS: $os"
echo "Detected package manager: $pkg"

if ! is_supported_platform; then
  cat <<'EOF'
Unsupported platform for this bootstrap phase.
Supported combinations:
- macOS + Homebrew
- Linux + apt
- Linux + pacman
EOF
  exit 1
fi

echo "Platform is supported."
