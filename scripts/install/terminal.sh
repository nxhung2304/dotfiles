#!/usr/bin/env bash
# Setup Terminal & UI: Tmux

install_terminal() {
    log_header "TERMINAL & UI"

    # 1. Tmux & TPM
    log_info "Setting up Tmux..."
    if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
        if ask "Install Tmux Plugin Manager (TPM)?"; then
            log_info "Installing TPM..."
            git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
            log_success "TPM installed"
        fi
    else
        log_success "TPM already installed"
    fi

    log_info "Linking Tmux config..."
    rm -rf "$HOME/.config/tmux" && ln -sf "$DOTFILES_DIR/.config/tmux" "$HOME/.config/tmux"
    
    mkdir -p "$HOME/.local/bin/scripts"
    ln -sf "$DOTFILES_DIR/scripts/tmux-sessionizer" "$HOME/.local/bin/scripts/tmux-sessionizer"
    chmod +x "$DOTFILES_DIR/scripts/tmux-sessionizer"

    log_success "Terminal and UI setup complete"
}
