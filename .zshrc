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

alias zshconfig="vim ~/dotfiles/.zshrc"
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

# Envs
export PATH=$HOME/bin:/usr/local/bin:$PATH
export PATH="/Applications/Postgres.app/Contents/Versions/17/bin:$PATH"

# Hook Asdf
. "$HOME/.asdf/asdf.sh"

# Hook direnv: https://direnv.net
eval "$(direnv hook zsh)"
