#!/usr/bin/env bash
# Setup git filters for generated config

install_git_filters() {
    log_header "GIT FILTERS"

    git -C "$DOTFILES_DIR" config filter.herdr-theme.clean "$DOTFILES_DIR/scripts/herdr/strip-theme-custom"
    git -C "$DOTFILES_DIR" config filter.herdr-theme.smudge cat

    log_success "Git filters configured"
}
