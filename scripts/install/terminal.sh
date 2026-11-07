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

remove_old_terminal_leftovers() {
    local leftover_link
    for leftover_link in "$HOME/.config/wezterm" "$HOME/.config/alacritty"; do
        if [ -L "$leftover_link" ]; then
            rm "$leftover_link"
            log_info "Removed old terminal link $leftover_link"
        fi
    done

    if ! command -v brew &>/dev/null; then
        return
    fi

    if ! brew list --cask wezterm &>/dev/null; then
        return
    fi

    if ask "Uninstall WezTerm with Homebrew?"; then
        brew uninstall --cask wezterm
    fi
}

install_terminal() {
    log_header "TERMINAL & UI"

    log_info "Setting up Herdr..."
    chmod +x "$DOTFILES_DIR"/scripts/herdr-* "$DOTFILES_DIR"/scripts/herdr/*

    remove_tmux_leftovers
    remove_old_terminal_leftovers

    "$DOTFILES_DIR/scripts/theme-switch" gruvbox

    log_success "Terminal and UI setup complete"
}
