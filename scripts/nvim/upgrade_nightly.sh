#!/bin/bash

echo "Upgrading Neovim to nightly..."

set -e

sudo apt update
sudo apt install -y ninja-build gettext cmake build-essential git

NEOVIM_DIR="$HOME/neovim"
if [ -d "$NEOVIM_DIR" ]; then
    echo "Updating existing Neovim repo..."
    cd "$NEOVIM_DIR" || { echo "Failed to change to $NEOVIM_DIR"; exit 1; }
    git fetch origin
    git reset --hard origin/master
else
    echo "Cloning Neovim repo..."
    git clone https://github.com/neovim/neovim "$NEOVIM_DIR"
    cd "$NEOVIM_DIR" || { echo "Failed to change to $NEOVIM_DIR"; exit 1; }
fi


git checkout master
make CMAKE_BUILD_TYPE=RelWithDebInfo
sudo make install

hash -r

echo "Neovim nightly upgrade completed."
nvim --version
