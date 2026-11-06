#!/usr/bin/env bash
# Setup Terminal & UI: Herdr

remove_tmux_leftovers() {
    local leftover_link
    for leftover_link in "$HOME/.config/tmux" "$HOME/.local/bin/scripts/tmux-sessionizer"; do
        if [ -L "$leftover_link" ]; then
            rm "$leftover_link"
            log_info "Removed old tmux link $leftover_link"
        fi
    done

    if [ -d "$HOME/.tmux" ] && ask "Remove old tmux plugins folder ~/.tmux?"; then
        rm -rf "$HOME/.tmux"
    fi

    if ! command -v brew &>/dev/null; then
        return
    fi

    if ! brew list tmux &>/dev/null; then
        return
    fi

    if ask "Uninstall tmux with Homebrew?"; then
        brew uninstall tmux
    fi
}

install_terminal() {
    log_header "TERMINAL & UI"

    log_info "Setting up Herdr..."
    chmod +x "$DOTFILES_DIR"/scripts/herdr-* "$DOTFILES_DIR"/scripts/herdr/*

    remove_tmux_leftovers

    "$DOTFILES_DIR/scripts/theme-switch" gruvbox

    log_success "Terminal and UI setup complete"
}
