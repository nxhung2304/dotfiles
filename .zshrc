export ZSH="$HOME/.oh-my-zsh"
source $ZSH/oh-my-zsh.sh

ZSH_THEME="robbyrussell"

plugins=(
    git
    zsh-autosuggestions
    zsh-syntax-highlighting
    z
)

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

alias n="nvim"

HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory

# Custom PATH additions
export PATH=$HOME/bin:/usr/local/bin:$PATH

# Hook Asdf
. "$HOME/.asdf/asdf.sh"
