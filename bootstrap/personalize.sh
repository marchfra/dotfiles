#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/platform.sh"

CONFIG_HOME="$(xdg_config_home)"
DEFAULT_OUTFILE="$CONFIG_HOME/dotfiles/bootstrap.env"
OUTFILE="${BOOTSTRAP_PERSONALIZATION_FILE:-$DEFAULT_OUTFILE}"
NON_INTERACTIVE="${BOOTSTRAP_NONINTERACTIVE:-0}"

# Optional overrides for automation/CI:
# - BOOTSTRAP_GIT_NAME
# - BOOTSTRAP_GIT_EMAIL
# - BOOTSTRAP_DOTFILES_DIR

is_tty() {
  [[ -t 0 && -t 1 ]]
}

can_prompt() {
  [[ "$NON_INTERACTIVE" != "1" ]] && is_tty
}

prompt_with_default() {
  local prompt_text="$1"
  local default_value="$2"
  local reply

  if [[ -n "$default_value" ]]; then
    read -r "reply?$prompt_text [$default_value]: "
    echo "${reply:-$default_value}"
  else
    read -r "reply?$prompt_text: "
    echo "$reply"
  fi
}

require_value() {
  local key="$1"
  local value="$2"
  local message="$3"

  if [[ -n "$value" ]]; then
    echo "$value"
    return
  fi

  if can_prompt; then
    local prompted
    prompted="$(prompt_with_default "$message" "")"
    if [[ -n "$prompted" ]]; then
      echo "$prompted"
      return
    fi
  fi

  echo "Missing required value for $key." >&2
  echo "Set $key or run in interactive mode to provide it." >&2
  exit 1
}

validate_email() {
  local email="$1"
  [[ "$email" == *"@"* ]]
}

load_existing_defaults() {
  if [[ -f "$OUTFILE" ]]; then
    # shellcheck disable=SC1090
    source "$OUTFILE"
  fi
}

write_env_file() {
  local out_dir
  out_dir="$(dirname "$OUTFILE")"
  mkdir -p "$out_dir"

  umask 077
  {
    printf 'export BOOTSTRAP_GIT_NAME=%q\n' "$BOOTSTRAP_GIT_NAME"
    printf 'export BOOTSTRAP_GIT_EMAIL=%q\n' "$BOOTSTRAP_GIT_EMAIL"
    printf 'export BOOTSTRAP_DOTFILES_DIR=%q\n' "$BOOTSTRAP_DOTFILES_DIR"
  } > "$OUTFILE"
}

main() {
  load_existing_defaults

  local default_name="${BOOTSTRAP_GIT_NAME:-}"
  local default_email="${BOOTSTRAP_GIT_EMAIL:-}"
  local default_dir="${BOOTSTRAP_DOTFILES_DIR:-$HOME/dotfiles}"

  if can_prompt; then
    BOOTSTRAP_GIT_NAME="$(prompt_with_default "Git user.name" "$default_name")"
    BOOTSTRAP_GIT_EMAIL="$(prompt_with_default "Git user.email" "$default_email")"
    BOOTSTRAP_DOTFILES_DIR="$(prompt_with_default "Dotfiles directory" "$default_dir")"
  else
    BOOTSTRAP_GIT_NAME="${BOOTSTRAP_GIT_NAME:-}"
    BOOTSTRAP_GIT_EMAIL="${BOOTSTRAP_GIT_EMAIL:-}"
    BOOTSTRAP_DOTFILES_DIR="${BOOTSTRAP_DOTFILES_DIR:-$default_dir}"
  fi

  BOOTSTRAP_GIT_NAME="$(require_value "BOOTSTRAP_GIT_NAME" "$BOOTSTRAP_GIT_NAME" "Git user.name")"
  BOOTSTRAP_GIT_EMAIL="$(require_value "BOOTSTRAP_GIT_EMAIL" "$BOOTSTRAP_GIT_EMAIL" "Git user.email")"

  if ! validate_email "$BOOTSTRAP_GIT_EMAIL"; then
    echo "Invalid email: $BOOTSTRAP_GIT_EMAIL" >&2
    exit 1
  fi

  if [[ "$BOOTSTRAP_DOTFILES_DIR" != /* ]]; then
    echo "Dotfiles directory must be an absolute path: $BOOTSTRAP_DOTFILES_DIR" >&2
    exit 1
  fi

  write_env_file

  cat <<EOF
Personalization values saved to:
$OUTFILE

Loaded values:
- BOOTSTRAP_GIT_NAME=$BOOTSTRAP_GIT_NAME
- BOOTSTRAP_GIT_EMAIL=$BOOTSTRAP_GIT_EMAIL
- BOOTSTRAP_DOTFILES_DIR=$BOOTSTRAP_DOTFILES_DIR
EOF
}

main "$@"
