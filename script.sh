#!/bin/bash

DOTFILES_DIR="$HOME/dotfiles"

# List of dotfiles to manage
DOTFILES=(
    ".zshrc"
    ".tmux.conf"
    ".gitconfig"
    ".vimrc"
)

# List of config directories to manage
CONFIG_DIRS=(
    "nvim"
    "wezterm"
    "tmux"
    "alacritty"
)

# Create necessary directory structure
setup_directories() {
    mkdir -p "$DOTFILES_DIR/.config"
    for dir in "${CONFIG_DIRS[@]}"; do
        mkdir -p "$DOTFILES_DIR/.config/$dir"
    done
}

# Handle each dotfile
setup_dotfile() {
    local file=$1
    local source="$HOME/$file"
    local target="$DOTFILES_DIR/$file"

    # Check if file exists and is not a symlink
    if [ -f "$source" ] && [ ! -L "$source" ]; then
        echo "📁 Processing $file..."
        cp "$source" "$target"
        rm "$source"
        ln -s "$target" "$source"
        echo "✓ Created symlink for $file"
    elif [ ! -f "$source" ]; then
        echo "⚠️  $file does not exist"
    elif [ -L "$source" ]; then
        echo "ℹ️  $file is already a symlink"
    fi
}

# Handle each config directory
setup_config_dir() {
    local dir=$1
    local source="$HOME/.config/$dir"
    local target="$DOTFILES_DIR/.config/$dir"

    # Check if directory exists and is not a symlink
    if [ -d "$source" ] && [ ! -L "$source" ]; then
        echo "📁 Processing directory $dir..."
        cp -r "$source/." "$target/"
        rm -rf "$source"
        ln -s "$target" "$source"
        echo "✓ Created symlink for $dir"
    elif [ ! -d "$source" ]; then
        echo "⚠️  Directory $dir does not exist"
    elif [ -L "$source" ]; then
        echo "ℹ️  $dir is already a symlink"
    fi
}

main() {
    echo "🚀 Starting dotfiles setup..."
    
    # Create directory structure
    setup_directories
    
    # Process each dotfile
    echo "📄 Processing dotfiles..."
    for file in "${DOTFILES[@]}"; do
        setup_dotfile "$file"
    done
    
    # Process each config directory
    echo "📂 Processing config directories..."
    for dir in "${CONFIG_DIRS[@]}"; do
        setup_config_dir "$dir"
    done
    
    echo "✨ Setup complete!"
    echo "Your dotfiles are now managed in $DOTFILES_DIR"
}

main
