#!/usr/bin/env bash
# Setup mise and install runtime versions

# Version Pinnings
# Node.js 22.22.2 (LTS) - Released: 2026-03-24
# Release: https://github.com/nodejs/node/releases/tag/v22.22.2
NODE_VERSION="22.22.2"

# Python 3.13.3 - Released: 2025-04-08
# Release: https://github.com/python/cpython/releases/tag/v3.13.3
PYTHON_VERSION="3.13.3"

# Ruby 3.3.11 - Released: 2026-03-26
# Release: https://github.com/ruby/ruby/releases/tag/v3_3_11
RUBY_VERSION="3.3.11"

# Java (Temurin 17) - Released: 2026-04-22
# Release: https://github.com/adoptium/temurin17-binaries/releases/tag/jdk-17.0.19+10
JAVA_VERSION="openjdk-17"

warn_about_versions_linked_to_asdf() {
    local installs_dir="${MISE_DATA_DIR:-$HOME/.local/share/mise}/installs"
    [ -d "$installs_dir" ] || return 0

    local version_dir linked_versions=()
    for version_dir in "$installs_dir"/*/*; do
        [ -L "$version_dir" ] || continue

        if [[ $(readlink "$version_dir") == */.asdf/* ]]; then
            linked_versions+=("$version_dir")
        fi
    done

    if [ ${#linked_versions[@]} -eq 0 ]; then
        return 0
    fi

    log_info "These mise versions still link into ~/.asdf, so do not delete ~/.asdf yet:"
    printf '  %s\n' "${linked_versions[@]}"
}

install_mise_binary() {
    if command -v mise &>/dev/null; then
        return 0
    fi

    if ! ask "Install mise with the official script (to ~/.local/bin)?"; then
        log_error "mise is required for this step"

        return 1
    fi

    curl -fsSL https://mise.run | sh

    export PATH="$HOME/.local/bin:$PATH"
}

install_mise() {
    log_header "MISE"

    install_mise_binary

    if ask "Install Node.js $NODE_VERSION (LTS)?"; then
        log_info "Installing Node.js $NODE_VERSION..."
        mise use -g "node@$NODE_VERSION"
        # Enable corepack for yarn and pnpm (standard in modern Node.js)
        mise exec "node@$NODE_VERSION" -- corepack enable
        log_success "Node.js $NODE_VERSION installed (Yarn and PNPM enabled via Corepack)"
    fi

    if ask "Install Python $PYTHON_VERSION?"; then
        log_info "Installing Python $PYTHON_VERSION..."
        mise use -g "python@$PYTHON_VERSION"
        log_success "Python $PYTHON_VERSION installed"
    fi

    if ask "Install Ruby $RUBY_VERSION?"; then
        log_info "Installing Ruby $RUBY_VERSION..."
        if command -v brew &>/dev/null; then
            brew list libyaml &>/dev/null || brew install libyaml
            export RUBY_CONFIGURE_OPTS="--with-libyaml-dir=$(brew --prefix libyaml)"
        fi
        mise use -g "ruby@$RUBY_VERSION"
        log_success "Ruby $RUBY_VERSION installed"
    fi

    if ask "Install Java ($JAVA_VERSION)?"; then
        log_info "Installing Java ($JAVA_VERSION)..."
        mise use -g "java@$JAVA_VERSION"
        log_success "Java $JAVA_VERSION installed"
    fi

    warn_about_versions_linked_to_asdf
}
