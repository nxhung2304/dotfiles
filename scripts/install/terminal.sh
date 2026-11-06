#!/usr/bin/env bash
# Setup Terminal & UI: Tmux, Herdr

install_terminal() {
    log_header "TERMINAL & UI"

    log_info "Setting up Herdr..."
    mkdir -p "$HOME/.config/herdr"
    ln -sf "$DOTFILES_DIR/.config/herdr/config.toml" "$HOME/.config/herdr/config.toml"
    chmod +x "$DOTFILES_DIR"/scripts/herdr-* "$DOTFILES_DIR"/scripts/herdr/*

    "$DOTFILES_DIR/scripts/theme-switch" gruvbox

    log_success "Terminal and UI setup complete"
}
