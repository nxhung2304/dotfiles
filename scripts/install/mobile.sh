#!/usr/bin/env bash
# Setup Mobile Development: Flutter and CocoaPods

remove_sdkman_leftovers() {
    [ -d "$HOME/.sdkman" ] || return 0

    if ! mise which gradle &>/dev/null; then
        log_info "Kept ~/.sdkman: install Gradle with mise first (./install.sh mise), then run this step again"

        return
    fi

    if ask "Gradle now comes from mise. Remove SDKMAN (~/.sdkman)?"; then
        rm -rf "$HOME/.sdkman"
        log_success "Removed ~/.sdkman"
    fi
}

install_mobile() {
    log_header "MOBILE DEVELOPMENT"

    remove_sdkman_leftovers

    # 1. Flutter (via FVM)
    echo "🐦 Setting up Flutter (FVM)..."
    log_info "Checking for FVM..."
    if ! command -v fvm &>/dev/null; then
        if ask "Install FVM via Homebrew?"; then
            log_info "Installing FVM..."
            brew tap leoafarias/fvm
            brew install fvm
            log_success "FVM installed"
        fi
    else
        log_success "FVM already installed"
    fi

    if command -v fvm &>/dev/null; then
        if ask "Install Flutter stable version?"; then
            log_info "Installing Flutter stable..."
            fvm install stable
            fvm global stable
            log_success "Flutter stable installed"
        fi
    fi

    # 2. CocoaPods
    log_info "Checking for CocoaPods..."
    if ! command -v pod &>/dev/null; then
        if ask "Install CocoaPods?"; then
            log_info "Installing CocoaPods..."
            if command -v gem &>/dev/null; then
                gem install cocoapods
                log_success "CocoaPods installed via gem"
            elif command -v brew &>/dev/null; then
                brew install cocoapods
                log_success "CocoaPods installed via Homebrew"
            else
                log_error "Neither gem nor brew found. Cannot install CocoaPods."
            fi
        fi
    else
        log_success "CocoaPods already installed"
    fi
}
