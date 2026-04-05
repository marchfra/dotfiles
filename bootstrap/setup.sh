#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR_DEFAULT="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$SCRIPT_DIR/platform.sh"

DRY_RUN=0
SKIP_INSTALL=0
SKIP_STOW=0
SKIP_PERSONALIZE=0

print_usage() {
  cat <<'EOF'
Usage: bootstrap/setup.sh [options]

Options:
  --dry-run            Preview actions without installing or stowing.
  --skip-install       Skip package installation.
  --skip-stow          Skip stow symlink step.
  --skip-personalize   Skip personalization prompts and env generation.
  -h, --help           Show this help text.

Environment:
  BOOTSTRAP_NONINTERACTIVE=1             Disable interactive prompts.
  BOOTSTRAP_INSTALL_GUI=0                Skip GUI package manifests.
  BOOTSTRAP_PERSONALIZATION_FILE=<path>  Override personalization env path.
  BOOTSTRAP_DOTFILES_DIR=<absolute-path> Override dotfiles directory.
EOF
}

log() {
  printf '[bootstrap] %s\n' "$*"
}

warn() {
  printf '[bootstrap] WARNING: %s\n' "$*" >&2
}

die() {
  printf '[bootstrap] ERROR: %s\n' "$*" >&2
  exit 1
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --dry-run)
        DRY_RUN=1
        ;;
      --skip-install)
        SKIP_INSTALL=1
        ;;
      --skip-stow)
        SKIP_STOW=1
        ;;
      --skip-personalize)
        SKIP_PERSONALIZE=1
        ;;
      -h|--help)
        print_usage
        exit 0
        ;;
      *)
        die "Unknown option: $1"
        ;;
    esac
    shift
  done
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Missing required command: $1"
}

preflight() {
  local os pkg
  os="$(detect_os)"
  pkg="$(detect_pkg_manager)"

  log "Detected OS: $os"
  log "Detected package manager: $pkg"

  is_supported_platform || die "Unsupported platform. Supported: macOS+brew, Linux+apt, Linux+pacman."
}

load_manifest() {
  local file="$1"
  [[ -f "$file" ]] || return 0
  grep -E -v '^[[:space:]]*($|#)' "$file"
}

manifest_to_words() {
  local file="$1"
  load_manifest "$file" | tr '\n' ' ' | sed 's/[[:space:]]\+$//'
}

run_or_echo() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "[dry-run] $*"
  else
    eval "$*"
  fi
}

install_brew() {
  local formula_file="$SCRIPT_DIR/packages/macos-brew-formulae.txt"
  local cask_file="$SCRIPT_DIR/packages/macos-brew-casks.txt"
  local install_gui="${BOOTSTRAP_INSTALL_GUI:-1}"
  local formula_words=""
  local cask_words=""

  require_cmd brew

  formula_words="$(manifest_to_words "$formula_file")"
  if [[ -n "$formula_words" ]]; then
    run_or_echo "brew install $formula_words"
  fi

  if [[ "$install_gui" == "1" ]]; then
    cask_words="$(manifest_to_words "$cask_file")"
    if [[ -n "$cask_words" ]]; then
      run_or_echo "brew install --cask $cask_words"
    fi
  else
    log "Skipping GUI package install (BOOTSTRAP_INSTALL_GUI=$install_gui)"
  fi
}

install_apt() {
  local cli_file="$SCRIPT_DIR/packages/linux-apt-cli.txt"
  local gui_file="$SCRIPT_DIR/packages/linux-apt-gui.txt"
  local install_gui="${BOOTSTRAP_INSTALL_GUI:-1}"
  local cli_words=""
  local gui_words=""

  require_cmd apt-get

  cli_words="$(manifest_to_words "$cli_file")"
  if [[ -n "$cli_words" ]]; then
    run_or_echo "sudo apt-get update"
    run_or_echo "sudo apt-get install -y $cli_words"
  fi

  if [[ "$install_gui" == "1" ]]; then
    gui_words="$(manifest_to_words "$gui_file")"
    if [[ -n "$gui_words" ]]; then
      run_or_echo "sudo apt-get install -y $gui_words"
    fi
  else
    log "Skipping GUI package install (BOOTSTRAP_INSTALL_GUI=$install_gui)"
  fi
}

install_pacman() {
  local cli_file="$SCRIPT_DIR/packages/linux-pacman-cli.txt"
  local gui_file="$SCRIPT_DIR/packages/linux-pacman-gui.txt"
  local install_gui="${BOOTSTRAP_INSTALL_GUI:-1}"
  local cli_words=""
  local gui_words=""

  require_cmd pacman

  cli_words="$(manifest_to_words "$cli_file")"
  if [[ -n "$cli_words" ]]; then
    run_or_echo "sudo pacman -Sy --needed --noconfirm $cli_words"
  fi

  if [[ "$install_gui" == "1" ]]; then
    gui_words="$(manifest_to_words "$gui_file")"
    if [[ -n "$gui_words" ]]; then
      run_or_echo "sudo pacman -Sy --needed --noconfirm $gui_words"
    fi
  else
    log "Skipping GUI package install (BOOTSTRAP_INSTALL_GUI=$install_gui)"
  fi
}

install_packages() {
  local pkg
  pkg="$(detect_pkg_manager)"

  if [[ "$SKIP_INSTALL" -eq 1 ]]; then
    log "Skipping package installation (--skip-install)"
    return
  fi

  case "$pkg" in
    brew)
      install_brew
      ;;
    apt)
      install_apt
      ;;
    pacman)
      install_pacman
      ;;
    *)
      die "Unsupported package manager: $pkg"
      ;;
  esac
}

personalization_env_file() {
  local config_home
  config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
  echo "${BOOTSTRAP_PERSONALIZATION_FILE:-$config_home/dotfiles/bootstrap.env}"
}

run_personalization() {
  if [[ "$SKIP_PERSONALIZE" -eq 1 ]]; then
    log "Skipping personalization (--skip-personalize)"
    return
  fi

  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "[dry-run] $SCRIPT_DIR/personalize.sh"
    return
  fi

  "$SCRIPT_DIR/personalize.sh"
}

load_personalization() {
  local env_file
  local have_env_overrides=0
  env_file="$(personalization_env_file)"

  if [[ -n "${BOOTSTRAP_GIT_NAME:-}" && -n "${BOOTSTRAP_GIT_EMAIL:-}" ]]; then
    have_env_overrides=1
  fi

  if [[ "$have_env_overrides" -eq 0 ]]; then
    [[ -f "$env_file" ]] || die "Missing personalization env file: $env_file"

    # shellcheck disable=SC1090
    source "$env_file"
  fi

  [[ -n "${BOOTSTRAP_GIT_NAME:-}" ]] || die "BOOTSTRAP_GIT_NAME missing in personalization env"
  [[ -n "${BOOTSTRAP_GIT_EMAIL:-}" ]] || die "BOOTSTRAP_GIT_EMAIL missing in personalization env"

  BOOTSTRAP_DOTFILES_DIR="${BOOTSTRAP_DOTFILES_DIR:-$DOTFILES_DIR_DEFAULT}"
  [[ "$BOOTSTRAP_DOTFILES_DIR" = /* ]] || die "BOOTSTRAP_DOTFILES_DIR must be absolute"
}

apply_git_identity() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "[dry-run] git config --global user.name '$BOOTSTRAP_GIT_NAME'"
    log "[dry-run] git config --global user.email '$BOOTSTRAP_GIT_EMAIL'"
    return
  fi

  git config --global user.name "$BOOTSTRAP_GIT_NAME"
  git config --global user.email "$BOOTSTRAP_GIT_EMAIL"
}

discover_stow_packages() {
  local repo_dir="$1"
  local dir
  local package

  for dir in "$repo_dir"/*; do
    [[ -d "$dir" ]] || continue
    package="$(basename "$dir")"

    case "$package" in
      bootstrap)
        continue
        ;;
    esac

    printf '%s\n' "$package"
  done | sort
}

stow_packages() {
  local target_dir="$HOME"
  local repo_dir="$BOOTSTRAP_DOTFILES_DIR"
  local package
  local package_count=0

  if [[ "$SKIP_STOW" -eq 1 ]]; then
    log "Skipping stow step (--skip-stow)"
    return
  fi

  require_cmd stow
  mkdir -p "$HOME/.config"

  while IFS= read -r package; do
    [[ -n "$package" ]] || continue
    package_count=$((package_count + 1))

    log "Checking stow conflicts for package: $package"
    if ! stow --dir="$repo_dir" --target="$target_dir" -n "$package" >/tmp/stow-check.log 2>&1; then
      cat /tmp/stow-check.log >&2
      die "Stow conflict detected for '$package'. Resolve conflicts and rerun. Suggested check: stow --dir='$repo_dir' --target='$target_dir' -n '$package'"
    fi

    if [[ "$DRY_RUN" -eq 1 ]]; then
      log "[dry-run] stow --dir='$repo_dir' --target='$target_dir' '$package'"
    else
      stow --dir="$repo_dir" --target="$target_dir" "$package"
    fi
  done < <(discover_stow_packages "$repo_dir")

  if [[ "$package_count" -eq 0 ]]; then
    die "No stow packages found in $repo_dir"
  fi
}

main() {
  parse_args "$@"
  preflight
  install_packages
  run_personalization
  load_personalization
  apply_git_identity
  stow_packages
  log "Bootstrap checkpoint complete."
}

main "$@"
