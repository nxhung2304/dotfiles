export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="robbyrussell"
plugins=(
    git
    zsh-autosuggestions
    zsh-syntax-highlighting
    z
)

source $ZSH/oh-my-zsh.sh
source ~/.env

export LANG=en_US.UTF-8
export EDITOR='vim'

HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory

# Envs
export PATH=$HOME/bin:/usr/local/bin:$PATH
export PATH="/Applications/Postgres.app/Contents/Versions/17/bin:$PATH"
export PATH="$HOME/flutter/bin:$PATH"

# Hook Asdf
. "$HOME/.asdf/asdf.sh"

# Hook direnv: https://direnv.net
eval "$(direnv hook zsh)"

# Alias
alias zshconfig="vim ~/dotfiles/.zshrc"
alias ohmyzsh="vim ~/.oh-my-zsh"
alias ll="ls -la"
alias la="ls -A"
alias l="ls -CF"
alias rights="cd ~/Dev/rights"
alias personal="cd ~/Dev/personal"
alias n="nvim"

## docker 
alias dcb="docker-compose build"
alias dcd="docker-compose down"
alias dcu="docker-compose up -d"

alias dclw="docker-compose logs -f web"
alias dcew="docker-compose exec web"
alias dcrw="docker-compose run web"

ipad="00008112-000C283836F9401E" # iPad Pro 11 inch
hiporn="00008120-000915DA2EE9A01E" # Huy's iPhone 15
ipse="62FC2A6B-A549-47B9-9E2C-6437FAD39F64" # iPhone SE Simulator

alias ffr_ipad="fvm flutter run -d $ipad"
alias ffr_ipse="fvm flutter run -d $ipse"
alias ffr_hiporn="fvm flutter run -d $hiporn"

alias noti='send_slack_notification'
send_slack_notification ()
{
  local api_key="${SLACK_NAMI_API_KEY}"
  local user_id="${SLACK_NAMI_USER_ID}"
  local message=''
  if [ -z "$1" ]; then
    message='Command success' 
  else
    message="$1"
  fi

  response=$(curl -s -X POST -H "Authorization: Bearer $api_key" -H 'Content-type: application/json' \
    --data "{\"channel\":\"$user_id\",\"text\":\"$message\"}" \
    https://slack.com/api/chat.postMessage)

  if echo "$response" | grep -q '"ok":true'; then
    echo $message
  else
    echo "failure: $(echo "$response" | jq -r '.error')"
  fi
}

export ANDROID_HOME=~/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/tools
export PATH=$PATH:$ANDROID_HOME/tools/bin
export PATH=$PATH:$ANDROID_HOME/platform-tools

export PATH="$HOME/.asdf/shims:$PATH"

## [Completion]
## Completion scripts setup. Remove the following line to uninstall
[[ -f /Users/rightsvn-hung/.dart-cli-completion/zsh-config.zsh ]] && . /Users/rightsvn-hung/.dart-cli-completion/zsh-config.zsh || true
## [/Completion]

