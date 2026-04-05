#!/usr/bin/env bash

set -euo pipefail

detect_os() {
  local uname_out
  uname_out="$(uname -s)"

  case "$uname_out" in
    Darwin)
      echo "macos"
      ;;
    Linux)
      echo "linux"
      ;;
    *)
      echo "unsupported"
      ;;
  esac
}

detect_linux_pkg_manager() {
  if command -v apt-get >/dev/null 2>&1; then
    echo "apt"
    return
  fi

  if command -v pacman >/dev/null 2>&1; then
    echo "pacman"
    return
  fi

  echo "unsupported"
}

detect_pkg_manager() {
  local os
  os="$(detect_os)"

  case "$os" in
    macos)
      if command -v brew >/dev/null 2>&1; then
        echo "brew"
      else
        echo "unsupported"
      fi
      ;;
    linux)
      detect_linux_pkg_manager
      ;;
    *)
      echo "unsupported"
      ;;
  esac
}

is_supported_platform() {
  local os pkg
  os="$(detect_os)"
  pkg="$(detect_pkg_manager)"

  [[ "$os" != "unsupported" && "$pkg" != "unsupported" ]]
}

xdg_config_home() {
  echo "${XDG_CONFIG_HOME:-$HOME/.config}"
}
