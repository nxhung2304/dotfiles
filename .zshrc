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
    fzf-tab
)

source $ZSH/oh-my-zsh.sh

HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory

# Hook direnv: https://direnv.net
eval "$(direnv hook zsh)"

eval "$(zoxide init zsh)"


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

if [ -z "$TMUX" ]; then
    export TERM=xterm-256color
fi

ulimit -n 8192

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

alias wtn="wt switch --create"
alias wtd="wt remove"
alias wtl="wt list"

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

export RIPGREP_CONFIG_PATH="$HOME/.ripgreprc"

alias ffd="fvm flutter devices"
alias ffr="fvm flutter run"
alias ffpg="fvm flutter pub get"
alias ffr_ip16="fvm flutter run -d 00008140-000C6D961447001C"

alias andr_ls="emulator -list-avds"
andr_run() {
  emulator -avd "$1" &
}

export JAVA_HOME="/opt/homebrew/opt/openjdk@17"
export PATH="$JAVA_HOME/bin:$PATH"
export PATH="/opt/homebrew/opt/openjdk@17/bin:$PATH"
export ANDROID_HOME="$HOME/Library/Android/sdk"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export PATH="$PATH:$ANDROID_HOME/platform-tools:$ANDROID_HOME/build-tools/34.0.0:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/emulator"

export FZF_DEFAULT_OPTS="--border=rounded --layout=reverse --info=inline-right --pointer='▌' --marker='▏'"
[[ -f "${XDG_STATE_HOME:-$HOME/.local/state}/theme/fzf" ]] && export FZF_DEFAULT_OPTS_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/theme/fzf"

# fzf-tab
zstyle ':fzf-tab:complete:git-(add|diff|restore):*' fzf-preview 'git diff --color=always $word'
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza --color=always -1 -- $realpath'  # nếu bạn dùng eza

# Golang
. ${ASDF_DATA_DIR:-$HOME/.asdf}/plugins/golang/set-env.zsh


export PATH="$PATH":"$HOME/.pub-cache/bin"

upgrade_nvim() {
  cd ~/dotfiles/scripts/nvim/
  chmod +x ./upgrade_stable.sh
  ./upgrade_stable.sh
}

[[ -f ~/.env ]] && source ~/.env

herdr_auto_rename_tab() {
  [[ -n $HERDR_ENV && -n $HERDR_TAB_ID ]] || return
  local command_name=${${(z)3}[1]:t}
  [[ -n $command_name && $command_name != $HERDR_AUTO_TAB_LABEL ]] || return
  local current_label
  current_label=$(herdr tab get "$HERDR_TAB_ID" 2>/dev/null | jq -r '.result.tab.label // empty')
  [[ -n $current_label ]] || return
  [[ $current_label =~ '^[0-9]+$' || $current_label == $HERDR_AUTO_TAB_LABEL ]] || return
  HERDR_AUTO_TAB_LABEL=$command_name
  herdr tab rename "$HERDR_TAB_ID" "$command_name" >/dev/null 2>&1
}
autoload -Uz add-zsh-hook
add-zsh-hook preexec herdr_auto_rename_tab

if command -v wt >/dev/null 2>&1; then eval "$(command wt config shell init zsh)"; fi
export PATH=/opt/homebrew/opt/ffmpeg-full/bin:$PATH

claude() {
  case "$PWD/" in
    "$HOME/Dev/rights/"*)
      env -u CLAUDE_CONFIG_DIR claude "$@" ;;                      # công ty
    *)
      CLAUDE_CONFIG_DIR="$HOME/.claude-personal" command claude "$@" ;;  # cá nhân
  esac
}

alias claude-cty='env -u CLAUDE_CONFIG_DIR claude'

alias claude-personal='CLAUDE_CONFIG_DIR=$HOME/.claude-personal command claude'

alias cc="claude"
