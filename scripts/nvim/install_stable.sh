#!/bin/bash

echo "Starting Neovim stable installation..."

set -e

sudo apt update
sudo apt install -y ninja-build gettext cmake build-essential git

NEOVIM_DIR="$HOME/neovim"
if [ ! -d "$NEOVIM_DIR" ]; then
  echo "Cloning Neovim repository..."
  git clone https://github.com/neovim/neovim "$NEOVIM_DIR"
else
  echo "Updating existing Neovim repository..."
  cd "$NEOVIM_DIR" && git pull
fi

cd "$NEOVIM_DIR"
git checkout stable
make CMAKE_BUILD_TYPE=RelWithDebInfo
sudo make install

hash -r

echo "Neovim stable installation completed."
nvim --version
