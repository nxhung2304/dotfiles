#!/usr/bin/env bash
# Setup Mobile Development: Flutter and SDKMAN!

install_mobile() {
    log_header "MOBILE DEVELOPMENT"

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

    # 2. SDKMAN!
    echo "☕ Setting up SDKMAN!..."
    log_info "Checking for SDKMAN!..."
    if [ ! -d "$HOME/.sdkman" ]; then
        if ask "Install SDKMAN! (Software Development Kit Manager)?"; then
            log_info "Installing SDKMAN!..."
            curl -s "https://get.sdkman.io" | bash
            log_success "SDKMAN! installed"
            log_info "Note: You may need to restart your terminal or source ~/.zshrc"
        fi
    else
        log_success "SDKMAN! already installed"
    fi

    # 3. Gradle (via SDKMAN!)
    log_info "Checking for Gradle..."
    if [ -d "$HOME/.sdkman" ]; then
        # shellcheck source=/dev/null
        export SDKMAN_DIR="$HOME/.sdkman"
        [[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"

        if command -v sdk &>/dev/null; then
            if ask "Install latest Gradle via SDKMAN!?"; then
                log_info "Installing Gradle via SDKMAN!..."
                sdk install gradle
                log_success "Gradle installed"
            fi
        fi
    fi

    # 4. CocoaPods
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
