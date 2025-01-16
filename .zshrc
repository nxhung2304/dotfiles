export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="robbyrussell"

plugins=(
    git
    zsh-autosuggestions
    zsh-syntax-highlighting
    z
)

source $ZSH/oh-my-zsh.sh

export LANG=en_US.UTF-8

export EDITOR='vim'

# Alias
alias zshconfig="vim ~/.zshrc"
alias ohmyzsh="vim ~/.oh-my-zsh"
alias ll="ls -la"
alias la="ls -A"
alias l="ls -CF"

alias rights="cd ~/Dev/rights"
alias personal="cd ~/Dev/personal"

HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory

# Basic auto/tab completion
autoload -U compinit
zstyle ':completion:*' menu select
zmodload zsh/complist
compinit
_comp_options+=(globdots) # Include hidden files

# Use vim keys in tab complete menu
bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'l' vi-forward-char
bindkey -M menuselect 'j' vi-down-line-or-history

# Custom PATH additions
export PATH=$HOME/bin:/usr/local/bin:$PATH

# Hook Asdf
. "$HOME/.asdf/asdf.sh"
