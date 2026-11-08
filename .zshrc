typeset -U path PATH

if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi

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
HISTSIZE=100000
SAVEHIST=100000
setopt appendhistory
setopt share_history
setopt hist_ignore_all_dups
setopt hist_ignore_space
setopt hist_reduce_blanks

# Hook direnv: https://direnv.net
eval "$(direnv hook zsh)"

eval "$(zoxide init zsh)"


## [Completion]
## Completion scripts setup. Remove the following line to uninstall
[[ -f "$HOME/.dart-cli-completion/zsh-config.zsh" ]] && . "$HOME/.dart-cli-completion/zsh-config.zsh" || true
## [/Completion]
#


# Envs
export EDITOR="nvim"
export VISUAL="nvim"
export PATH=$HOME/bin:/usr/local/bin:$PATH
export PATH="$HOMEBREW_PREFIX/opt/postgresql@17/bin:$PATH"
export PATH="$HOME/fvm/default/bin:$PATH"

# ASDF
# export PATH="$HOME/.asdf/shims:$PATH"
# ASDF_DIR=""
# if [ -f "/opt/homebrew/opt/asdf/libexec/asdf.sh" ]; then
#     ASDF_DIR="/opt/homebrew/opt/asdf"
# elif [ -f "/usr/local/opt/asdf/libexec/asdf.sh" ]; then
#     ASDF_DIR="/usr/local/opt/asdf"
# fi
#
# if [ -n "$ASDF_DIR" ]; then
#     . "$ASDF_DIR/libexec/asdf.sh"
#     # Hook for asdf-java to set JAVA_HOME
#     [ -f "$HOME/.asdf/plugins/java/set-java-home.zsh" ] && . "$HOME/.asdf/plugins/java/set-java-home.zsh"
# fi

# mise
export PATH="$HOME/.local/bin:$PATH"
eval "$(mise activate zsh)"

# Android

# opencode
export PATH="$HOME/.opencode/bin:$PATH"

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

nv () { NVIM_APPNAME="minimal-nvim" nvim }

nd_click_action() {
  local focus_ghostty="open -b com.mitchellh.ghostty"
  if [[ -z $HERDR_PANE_ID ]]; then
    print -r -- "$focus_ghostty"
    return
  fi

  local pane_json workspace_id tab_id herdr_command
  pane_json=$(herdr pane get "$HERDR_PANE_ID" 2>/dev/null)
  workspace_id=$(jq -r '.result.pane.workspace_id // empty' <<<"$pane_json")
  tab_id=$(jq -r '.result.pane.tab_id // empty' <<<"$pane_json")
  if [[ -z $workspace_id || -z $tab_id ]]; then
    print -r -- "$focus_ghostty"
    return
  fi

  herdr_command="${HERDR_SOCKET_PATH:+HERDR_SOCKET_PATH=${(q)HERDR_SOCKET_PATH} }${(q)commands[herdr]}"
  print -r -- "$herdr_command workspace focus ${(q)workspace_id} >/dev/null; $herdr_command tab focus ${(q)tab_id} >/dev/null; $focus_ghostty"
}

nd() {
  local exit_code=$?
  local finished_command
  finished_command=$(print -r -- "${history[$HISTCMD]}" | sed -E 's/[[:space:]]*(\||;|&&)[[:space:]]*nd[[:space:]]*$//')

  local result
  if [[ ! -t 0 ]]; then
    cat
    result="đã chạy xong"
  elif (( exit_code == 0 )); then
    result="đã thành công"
  else
    result="lỗi (exit $exit_code)"
  fi

  terminal-notifier \
    -title "Ghostty" \
    -message "$finished_command $result" \
    -sound default \
    -execute "$(nd_click_action)" \
    >/dev/null
  return "$exit_code"
}


# Disable GSS encryption mode
export PGGSSENCMODE=disable

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

export RIPGREP_CONFIG_PATH="$HOME/.config/ripgrep/config"

alias ffd="fvm flutter devices"
alias ffr="fvm flutter run"
alias ffpg="fvm flutter pub get"
alias ffr_ip16='fvm flutter run -d "$IPHONE_16_UDID"'

alias andr_ls="emulator -list-avds"
andr_run() {
  emulator -avd "$1" &
}

export ANDROID_HOME="$HOME/Library/Android/sdk"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export PATH="$PATH:$ANDROID_HOME/platform-tools:$ANDROID_HOME/build-tools/34.0.0:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/emulator"

export FZF_DEFAULT_OPTS="--border=rounded --layout=reverse --info=inline-right --pointer='▌' --marker='▏'"
[[ -f "${XDG_STATE_HOME:-$HOME/.local/state}/theme/fzf" ]] && export FZF_DEFAULT_OPTS_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/theme/fzf"

# fzf-tab
zstyle ':fzf-tab:complete:git-(add|diff|restore):*' fzf-preview 'git diff --color=always $word'
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza --color=always -1 -- $realpath'  # nếu bạn dùng eza

# Golang
# . ${ASDF_DATA_DIR:-$HOME/.asdf}/plugins/golang/set-env.zsh


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
export PATH="$HOMEBREW_PREFIX/opt/ffmpeg-full/bin:$PATH"

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
