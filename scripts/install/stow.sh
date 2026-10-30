#!/usr/bin/env bash
# Setup symlinks with stow

install_stow() {
    log_header "SYMLINK"

    if ask "Create backup of old config before stow?"; then
        BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
        mkdir -p "$BACKUP_DIR"
        echo "📦 Backup location: $BACKUP_DIR"
        for path in ~/.config/nvim ~/.config/karabiner ~/.config/wezterm ~/.zshrc ~/.tmux.conf ~/.gitconfig ~/.vimrc; do
            [ -e "$path" ] && [ ! -L "$path" ] && cp -R "$path" "$BACKUP_DIR/"
        done
    fi

    command -v stow &>/dev/null || brew install stow

    echo "🔗 Creating symlinks with stow..."
    stow --restow --target="$HOME" --verbose .config 2>&1 | tee stow-config.log

    for dir in .claude .codex .gemini scripts; do
        if [ -d "$dir" ]; then
            stow --restow --target="$HOME" --verbose "$dir" 2>&1 | tee "stow-$dir.log" || true
        fi
    done

    log_success "Symlinks created"
}
