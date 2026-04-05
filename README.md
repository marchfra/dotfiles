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
4. Syncs and initializes git submodules.
5. Applies git identity globally.
6. Stows all top-level package directories in the repository (excluding
   [bootstrap](bootstrap)) with conflict checks.
7. Runs post-bootstrap hooks (currently reserved as extension points).

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
2. `oh-my-tmux` is tracked as a proper git submodule at [tmux/.config/tmux/oh-my-tmux](tmux/.config/tmux/oh-my-tmux).
3. Submodules are pinned to the exact commit recorded in this repository. `bootstrap/setup.sh` checks out those pinned commits.
4. To update a submodule intentionally, move it to the desired revision and commit the gitlink update in this repository.

### Updating pinned submodule commits

For any submodule path:

```shell
cd <submodule-path>
git fetch origin

# Option A: pin to a specific commit/tag
git checkout <target-commit-or-tag>

# Option B: move to the most recent commit on the current branch
git pull --ff-only

cd ~/dotfiles
git add <submodule-path>
```
