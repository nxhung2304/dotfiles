# Skip security checks for completions to speed up startup
ZSH_DISABLE_COMPFIX="true"

# Faster compinit caching
autoload -Uz compinit
_comp_path="${ZDOTDIR:-$HOME}/.zcompdump-${HOST%%.*}-${ZSH_VERSION}"
if [[ -f "$_comp_path" && "$_comp_path" -nt "$HOME/.zshrc" ]]; then
  compinit -C -d "$_comp_path"
else
  compinit -d "$_comp_path"
fi

export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="robbyrussell"
plugins=(
    git
    zsh-autosuggestions
    zsh-syntax-highlighting
    z
    zsh-autocomplete
)

source $ZSH/oh-my-zsh.sh

HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory

# Hook direnv: https://direnv.net
eval "$(direnv hook zsh)"


## [Completion]
## Completion scripts setup. Remove the following line to uninstall
[[ -f /Users/rightsvn-hung/.dart-cli-completion/zsh-config.zsh ]] && . /Users/rightsvn-hung/.dart-cli-completion/zsh-config.zsh || true
## [/Completion]
#


# Envs
export PATH=$HOME/bin:/usr/local/bin:$PATH
export PATH="/usr/local/opt/postgresql@17/bin:$PATH"
export PATH="$HOME/fvm/default/bin:$PATH"

# ASDF
export PATH="$HOME/.asdf/shims:$PATH"
ASDF_DIR=""
if [ -f "/opt/homebrew/opt/asdf/libexec/asdf.sh" ]; then
    ASDF_DIR="/opt/homebrew/opt/asdf"
elif [ -f "/usr/local/opt/asdf/libexec/asdf.sh" ]; then
    ASDF_DIR="/usr/local/opt/asdf"
fi

if [ -n "$ASDF_DIR" ]; then
    . "$ASDF_DIR/libexec/asdf.sh"
    # Hook for asdf-java to set JAVA_HOME
    [ -f "$HOME/.asdf/plugins/java/set-java-home.zsh" ] && . "$HOME/.asdf/plugins/java/set-java-home.zsh"
fi

# Android

if [ -d "/usr/local/opt/tcl-tk" ]; then
    export LDFLAGS="-L/usr/local/opt/tcl-tk/lib"
    export CPPFLAGS="-I/usr/local/opt/tcl-tk/include"
    export PKG_CONFIG_PATH="/usr/local/opt/tcl-tk/lib/pkgconfig"
    export PATH="/usr/local/opt/tcl-tk/bin:$PATH"
fi

# opencode
export PATH=/Users/rightsvn-hung/.opencode/bin:$PATH

export TERM=xterm-256color

# export NVM_DIR="$HOME/.nvm"

# AI
# jcom-androidTV_do_local
# export JAVA_HOME=$(/usr/libexec/java_home -v 1.8)
# export JAVA_HOME="/usr/local/opt/openjdk@8"

export ANDROID_SDK_ROOT="${HOME}/Library/Android/sdk"
export ANDROID_HOME="${HOME}/Library/Android/sdk"
PATH=${PATH}:${ANDROID_SDK_ROOT}/platform-tools
PATH=${PATH}:${ANDROID_SDK_ROOT}/tools

cordova_clean() {
  echo "Removing all configs in corodova project"

  rm -rf node_modules/
  echo "Removed node_modules in corodova project"

  rm -rf platforms/
  echo "Removed platforms in corodova project"

  rm -rf plugins/
  echo "Removed plugins in corodova project"
}

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

nv () { NVIM_APPNAME="minimal-nvim" nvim }


export PATH="/Users/rightsvn-hung/.opencode/bin:$PATH"

export DATABASE_PASSWORD="12345678"

# Disable GSS encryption mode
export PGGSSENCMODE=disable
export PATH="$HOME/.local/bin:$PATH"

# ALias
alias n="nvim"
alias v="nvim"
alias c="clear"
t() {
  if [ -z "$TMUX" ]; then
    tmux new-session -As "$(basename "$PWD")"
  else
    tmux
  fi
}
alias ta="tmux attach"
alias da="tmux detach"

alias pe="cd ~/Dev/personal"
alias ri="cd ~/Dev/rights"

# Hook starship
eval "$(starship init zsh)"

# eza (modern ls)
if command -v eza &>/dev/null; then
    export EZA_CONFIG_DIR="$HOME/.config/eza"
    alias ls="eza --icons --group-directories-first"
    alias ll="eza -lbF --git --icons"
    alias la="eza -lbhHigUmuSa --time-style=long-iso --git --icons"
    alias lt="eza --tree --level=2 --icons"
fi

# Utils
alias ip="ipconfig getifaddr en0"

# Dev
alias rnew="ruby ~/Dev/personal/rails-starter/bin/new"
alias cc="claude"

export RIPGREP_CONFIG_PATH="$HOME/.ripgreprc"

alias ffd="fvm flutter devices"
alias ffr="fvm flutter run"
alias ffpg="fvm flutter pub get"
alias ffr_ip16="fvm flutter run -d 00008140-000C6D961447001C"

export JAVA_HOME="/opt/homebrew/opt/openjdk@17"
export PATH="$JAVA_HOME/bin:$PATH"
export PATH="/opt/homebrew/opt/openjdk@17/bin:$PATH"
export ANDROID_HOME="$HOME/Library/Android/sdk"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export PATH="$PATH:$ANDROID_HOME/platform-tools:$ANDROID_HOME/build-tools/34.0.0:$ANDROID_HOME/cmdline-tools/latest/bin"
