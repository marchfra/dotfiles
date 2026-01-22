# These are needed for the colorls package
export PATH="$(brew --prefix ruby)/bin:$PATH"
export PATH="$(ruby -r rubygems -e 'puts Gem.bindir'):$PATH"
source $(dirname $(gem which colorls))/tab_complete.sh

# plugins=(git zsh-syntax-highlighting zsh-autosuggestions)

source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# User configuration

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='nvim'
# fi

# Set personal aliases, overriding those provided by Oh My Zsh libs,
# plugins, and themes. Aliases can be placed here, though Oh My Zsh
# users are encouraged to define aliases within a top-level file in
# the $ZSH_CUSTOM folder, with .zsh extension. Examples:
# - $ZSH_CUSTOM/aliases.zsh
# - $ZSH_CUSTOM/macos.zsh
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# +------------+
# | NAVIGATION |
# +------------+

setopt AUTO_CD              # Go to folder path without using cd.

setopt AUTO_PUSHD           # Push the old directory onto the stack on cd.
setopt PUSHD_IGNORE_DUPS    # Do not store duplicates in the stack.
setopt PUSHD_SILENT         # Do not print the directory stack after pushd or popd.

# +---------+
# | HISTORY |
# +---------+

setopt SHARE_HISTORY       # Share history between all sessions.
setopt HIST_IGNORE_DUPS    # Do not record an event that was just recorded again.

# +---------+
# | ALIASES |
# +---------+

source $XDG_CONFIG_HOME/aliases/aliases

# +-----------+
# | VI KEYMAP |
# +-----------+

# Vi mode
bindkey -v
export KEYTIMEOUT=1

# Change cursor
source "$ZDOTDIR/plugins/cursor_mode"

# +---------+
# | BINDING |
# +---------+

# edit current command line with vim (vim-mode, then CTRL-v)
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey -M vicmd '^v' edit-command-line

# +-------------+
# | other stuff |
# +-------------+

# brew doctor advice
export PATH="/usr/local/sbin:$PATH"

# iTerm Shell Integration
source ~/.iterm2_shell_integration.zsh

export PATH="$PATH:/Applications/MuseScore 4.app/Contents/MacOS/"  # MuseScore command line
export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/App/bin"

# # pyenv stuff
# eval "$(pyenv virtualenv-init -)"
# PATH=$(pyenv root)/shims:$PATH
# PATH=$(pyenv root)/versions/3.12.0/bin:$PATH
# if command -v pyenv 1>/dev/null 2>&1; then
#   eval "$(pyenv init -)"
# fi

# Point pipx to the pyenv global Python version
PIPX_DEFAULT_PYTHON="$(pyenv root)/versions/3.12.0/bin/python"

# zoxide is a better cd
eval "$(zoxide init --cmd cd zsh)"

# uv set to use managed python by default
export UV_MANAGED_PYTHON=true

# Set up fzf key bindings and fuzzy completion
source <(fzf --zsh)
export FZF_DEFAULT_COMMAND='fd . --hidden --exclude ".git"'
export FZF_DEFAULT_OPTS="--style=full --preview='bat --color=always {}'"

# yazi shell wrapper to change CWD when exiting yazi
# Use y instead of yazi to start, and press q to quit, you'll see the CWD
# changed. Sometimes, you don't want to change, press Q to quit.
function y() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
    yazi "$@" --cwd-file="$tmp"
    IFS= read -r -d '' cwd < "$tmp"
    [ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
    rm -f -- "$tmp"
}

eval "$(starship init zsh)"
