# marchfra's dotfiles

This repository is intended to bootstrap a new machine with one command.

## Quick start

```shell
git clone https://github.com/marchfra/dotfiles.git ~/dotfiles
cd ~/dotfiles
./bootstrap/setup.sh
```

The bootstrap script currently does the following:

1. Detects supported platforms: macOS + Homebrew, Linux + apt, Linux + pacman.
2. Installs packages from the platform manifests in [bootstrap/packages](bootstrap/packages).
3. Collects personalization data (git name/email and dotfiles path) via
   [bootstrap/personalize.sh](bootstrap/personalize.sh), with environment
   variable overrides.
4. Applies git identity globally.
5. Stows all top-level package directories in the repository (excluding
   [bootstrap](bootstrap)) with conflict checks.
6. Runs post-bootstrap hooks, including an idempotent clone of oh-my-tmux into `$XDG_CONFIG_HOME/tmux/oh-my-tmux`.

## Useful options

```shell
./bootstrap/setup.sh --dry-run
./bootstrap/setup.sh --skip-install
./bootstrap/setup.sh --skip-personalize
./bootstrap/setup.sh --skip-stow
```

## Environment overrides

```shell
BOOTSTRAP_NONINTERACTIVE=1
BOOTSTRAP_INSTALL_GUI=0
BOOTSTRAP_PERSONALIZATION_FILE=/absolute/path/to/bootstrap.env
BOOTSTRAP_GIT_NAME="Your Name"
BOOTSTRAP_GIT_EMAIL="you@example.com"
BOOTSTRAP_DOTFILES_DIR="/absolute/path/to/dotfiles"
```

## Notes

1. Stow is configured to fail safely on conflicts. Resolve conflicts and rerun
   the script.
2. `oh-my-tmux` is no longer tracked as repository content; it is cloned by
   bootstrap if missing.
3. Existing manual stow workflow still works if you prefer package-by-package control.
