export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="robbyrussell"
plugins=(
    git
    zsh-autosuggestions
    zsh-syntax-highlighting
    z
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
export PATH="/Applications/Postgres.app/Contents/Versions/17/bin:$PATH"
export PATH="$HOME/flutter/bin:$PATH"
# export PATH="/usr/local/opt/openjdk@21/bin:$PATH"
export PATH="/usr/local/opt/node@18/bin:$PATH"

# Android
export ANDROID_HOME=~/Library/Android/sdk
# export JAVA_HOME=$(/usr/libexec/java_home)

export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/tools
export PATH=$PATH:$ANDROID_HOME/tools/bin
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin
export PATH=$PATH:$ANDROID_HOME/platform-tools

export PATH="$HOME/.asdf/shims:$PATH"
. $(brew --prefix asdf)/libexec/asdf.sh
export LDFLAGS="-L$(brew --prefix tcl-tk)/lib"
export CPPFLAGS="-I$(brew --prefix tcl-tk)/include"
export PKG_CONFIG_PATH="$(brew --prefix tcl-tk)/lib/pkgconfig"
export PATH="$(brew --prefix tcl-tk)/bin:$PATH"



# opencode
export PATH=/Users/rightsvn-hung/.opencode/bin:$PATH

export TERM=xterm-256color

# export NVM_DIR="$HOME/.nvm"

# AI
# jcom-androidTV_do_local
# export JAVA_HOME=$(/usr/libexec/java_home -v 1.8)
# export JAVA_HOME="/usr/local/opt/openjdk@8"
export GRADLE_HOME="${HOME}/.gradle/wrapper/dists/gradle-3.5-all/xxxxxxxxxxxxx/gradle-3.5/bin"
PATH=${PATH}:${GRADLE_HOME}

export ANDROID_SDK_ROOT="${HOME}/Library/Android/sdk"
export ANDROID_HOME="${HOME}/Library/Android/sdk"
PATH=${PATH}:${ANDROID_SDK_ROOT}/platform-tools
PATH=${PATH}:${ANDROID_SDK_ROOT}/tools
export PATH="/usr/local/opt/openjdk@8/bin:$PATH"

cordova_clean() {
  echo "Removing all configs in corodova project"

  rm -rf node_modules/
  echo "Removed node_modules in corodova project"

  rm -rf platforms/
  echo "Removed platforms in corodova project"

  rm -rf plugins/
  echo "Removed plugins in corodova project"
}

export JAVA_HOME=/usr/local/opt/openjdk@17
export PATH="/usr/local/opt/openjdk@17/bin:$PATH"

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

nv () { NVIM_APPNAME="minimal-nvim" nvim }


