# ---------- diagnostics ----------
zrc_warn() {
    print -P "%F{yellow}[zshrc]%f $*" >&2
}

zrc_has() {
    command -v "$1" >/dev/null 2>&1
}

# ---------- base paths ----------
if zrc_has brew; then
    HOMEBREW_PREFIX="$(brew --prefix)"
else
    HOMEBREW_PREFIX=""
    zrc_warn "brew not found"
fi

path=("/usr/local/sbin" $path)

# Ruby path from Homebrew (for colorls) if available
if [[ -n "$HOMEBREW_PREFIX" && -d "$HOMEBREW_PREFIX/opt/ruby/bin" ]]; then
    path=("$HOMEBREW_PREFIX/opt/ruby/bin" $path)
else
    zrc_warn "Homebrew ruby bin path not found"
fi

# ---------- colorls completion ----------
if zrc_has gem && zrc_has ruby && gem which colorls >/dev/null 2>&1; then
    colorls_tab="$(dirname "$(gem which colorls)")/tab_complete.sh"
    gem_bindir="$(ruby -r rubygems -e 'puts Gem.bindir')"
    [[ -d "$gem_bindir" ]] && path=("$gem_bindir" $path)
    if [[ -r "$colorls_tab" ]]; then
        source "$colorls_tab"
    else
        zrc_warn "colorls tab completion script not readable: $colorls_tab"
    fi
else
    zrc_warn "colorls completion disabled (missing gem/ruby or colorls gem)"
fi

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

# +------------+
# | COMPLETION |
# +------------+

source $ZDOTDIR/completion.zsh

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

# MuseScore CLI
if [[ -d "/Applications/MuseScore 4.app/Contents/MacOS" ]]; then
    path+=("/Applications/MuseScore 4.app/Contents/MacOS")
else
    zrc_warn "MuseScore CLI path not found"
fi

# VSCode CLI
if [[ -d "/Applications/Visual Studio Code.app/Contents/Resources/App/bin" ]]; then
path+=("/Applications/Visual Studio Code.app/Contents/Resources/App/bin")
else
zrc_warn "VS Code CLI path not found"
fi

# uv set to use managed python by default
export UV_MANAGED_PYTHON=true

# override default tealdeer (tldr) config directory
export TEALDEER_CONFIG_DIR="/Users/francescomarchisotti/.config/tealdeer/"

# sesh
if zrc_has sesh && zrc_has fzf; then
    function sesh-sessions() {
        {
            exec </dev/tty
            local session
            session=$(sesh list | fzf --height 40% --reverse --border-label ' sesh ' --border --prompt '⚡  ')
            zle reset-prompt > /dev/null 2>&1 || true
            [[ -z "$session" ]] && return
            sesh connect "$session"
        }
    }
    zle     -N             sesh-sessions
    bindkey -M emacs '\es' sesh-sessions
    bindkey -M vicmd '\es' sesh-sessions
    bindkey -M viins '\es' sesh-sessions
else
    zrc_warn "sesh keybinding disabled (missing sesh or fzf)"
fi

# iTerm integration
if [[ -r "$HOME/.iterm2_shell_integration.zsh" ]]; then
    source "$HOME/.iterm2_shell_integration.zsh"
else
    zrc_warn "iTerm integration script not found"
fi

# zoxide
if zrc_has zoxide; then
    eval "$(zoxide init --cmd cd zsh)"
else
    zrc_warn "zoxide not found"
fi

# fzf
if zrc_has fzf; then
    source <(fzf --zsh)
    export FZF_DEFAULT_COMMAND='fd . --hidden --exclude ".git"'
    export FZF_DEFAULT_OPTS="--style=full --preview='bat --color=always {}'"
else
    zrc_warn "fzf not found; key bindings and fuzzy completion disabled"
fi

# yazi shell wrapper to change CWD when exiting yazi
# Use y instead of yazi to start, and press q to quit, you'll see the CWD
# changed. Sometimes, you don't want to change, press Q to quit.
function y() {
    if ! zrc_has yazi; then
        zrc_warn "yazi not found"
        return 127
    fi
    local tmp cwd
    tmp="$(mktemp -t "yazi-cwd.XXXXXX")" || return
    yazi "$@" --cwd-file="$tmp"
    IFS= read -r cwd < "$tmp"
    [[ -n "$cwd" && "$cwd" != "$PWD" ]] && builtin cd -- "$cwd"
    rm -f -- "$tmp"
}

# starship
if zrc_has starship; then
    eval "$(starship init zsh)"
else
    zrc_warn "starship not found"
fi

# zsh-autosuggestions
if [[ -n "$HOMEBREW_PREFIX" && -r "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
    source "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
else
    zrc_warn "zsh-autosuggestions not found"
fi

# zsh-syntax-highlighting (keep as last sourced plugin)
if [[ -n "$HOMEBREW_PREFIX" && -r "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
    source "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
else
    zrc_warn "zsh-syntax-highlighting not found"
fi
