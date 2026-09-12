#!/bin/bash

echo "Upgrading Neovim to stable..."

set -e

OS_TYPE=$(uname -s)

if [ "$OS_TYPE" = "Darwin" ]; then
    brew install ninja cmake gettext curl git
elif [ "$OS_TYPE" = "Linux" ]; then
    if [ -f /etc/os-release ] && grep -qi "ubuntu" /etc/os-release; then
        sudo apt update
        sudo apt install -y ninja-build gettext cmake build-essential git
    fi
else
    echo "Access to this link may help you: https://github.com/neovim/neovim/blob/master/BUILD.md#build-prerequisites"
    exit 1
fi

NEOVIM_DIR="$HOME/neovim"
if [ -d "$NEOVIM_DIR" ]; then
    echo "Updating existing Neovim repo..."
    cd "$NEOVIM_DIR" || { echo "Failed to change to $NEOVIM_DIR"; exit 1; }
    git fetch origin stable
else
    echo "Cloning Neovim repo to $NEOVIM_DIR..."
    git clone https://github.com/neovim/neovim "$NEOVIM_DIR"
    cd "$NEOVIM_DIR" || { echo "Failed to change to $NEOVIM_DIR"; exit 1; }
fi


git checkout stable
make CMAKE_BUILD_TYPE=RelWithDebInfo
sudo make install

hash -r

echo "Neovim stable upgrade completed."
nvim --version
