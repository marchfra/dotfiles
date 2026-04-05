# Completion system + menu UI
zmodload zsh/complist

# Make completion functions discoverable before compinit
if command -v brew >/dev/null 2>&1; then
  fpath=("$(brew --prefix)/share/zsh/site-functions" $fpath)
fi
fpath=("$XDG_CONFIG_HOME/zsh/completions" $fpath)

# Completion behavior
autoload -Uz compinit
compinit -d "$XDG_CACHE_HOME/zsh/.zcompdump"
_comp_options+=(globdots)

# Use hjlk in menu selection (during completion)
# Doesn't work well with interactive mode
bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'j' vi-down-line-or-history
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'l' vi-forward-char

# Optional: nicer matching
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' menu select
