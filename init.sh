#!/bin/bash

# 1. Script to copy all dotfiles to home directory

# Get the directory where the script is located
DOTFILES_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Print information
echo "Copying dotfiles from $DOTFILES_DIR to $HOME"

# Loop through all files in the dotfiles directory
for file in "$DOTFILES_DIR"/*; do
    # Get just the filename
    filename=$(basename "$file")
    
    # Skip the init.sh script itself and any README files
    if [[ "$filename" != "init.sh" && "$filename" != "README.md" ]]; then
        echo "Copying $filename to $HOME/$filename"
        cp -f "$file" "$HOME/$filename"
    fi
done

curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

echo "Dotfiles installation complete!"

# 2. Setup zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

echo "Install zsh-autosuggestion"
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

echo "Installing zsh-syntax-highlighting"
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

echo "installing direnv"
brew install direnv

## Setup asdf
echo "Installing asdf"
brew install asdf

echo "Installing asdf nodejs"
asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git

echo "Installing asdf ruby"
asdf plugin add ruby https://github.com/asdf-vm/asdf-ruby.git

## Setup tmux
echo "Setup tmux"

mkdir -p ~/.local/bin/scripts
mv scripts/tmux-sessionizer ~/.local/bin/scripts/tmux-sessionizer
