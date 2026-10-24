#!/usr/bin/env bash
# Setup AI CLI Tools: Gemini, Claude, and Codex

# Version Pinnings
# Gemini CLI 0.41.0 - Released: 2026-05-05
# Release: https://github.com/google-gemini/gemini-cli/releases/tag/v0.41.0
GEMINI_VERSION="0.41.0"

# Codex CLI 0.130.0 - Released: 2026-05-08
# Release: https://github.com/openai/codex/releases/tag/v0.130.0
CODEX_VERSION="0.130.0"

install_ai() {
    log_header "AI TOOLS"

    # --- Gemini ---
    echo "🤖 Setting up Gemini CLI..."
    if ! command -v gemini &>/dev/null; then
        if ask "Install Gemini CLI v$GEMINI_VERSION (requires Node.js)?"; then
            npm install -g "@google/gemini-cli@$GEMINI_VERSION"
            log_success "Gemini CLI installed"
        fi
    else
        log_success "Gemini CLI already installed"
    fi

    echo "🔗 Creating symlinks for Gemini config..."
    mkdir -p "$HOME/.gemini"
    ln -sf "$DOTFILES_DIR/.gemini/settings.json" "$HOME/.gemini/settings.json"
    rm -rf "$HOME/.gemini/skills" && ln -sf "$DOTFILES_DIR/.gemini/skills" "$HOME/.gemini/skills"

    # --- Codex ---
    echo "💻 Setting up Codex CLI..."
    if ! command -v codex &>/dev/null; then
        if ask "Install Codex CLI v$CODEX_VERSION (requires Node.js)?"; then
            npm install -g "@openai/codex@$CODEX_VERSION"
            log_success "Codex CLI installed"
        fi
    else
        log_success "Codex CLI already installed"
    fi

    echo "🔗 Creating symlinks for Codex config..."
    mkdir -p "$HOME/.codex"
    ln -sf "$DOTFILES_DIR/.codex/config.toml" "$HOME/.codex/config.toml"
    rm -rf "$HOME/.codex/rules" && ln -sf "$DOTFILES_DIR/.codex/rules" "$HOME/.codex/rules"
    rm -rf "$HOME/.codex/skills" && ln -sf "$DOTFILES_DIR/.codex/skills" "$HOME/.codex/skills"

    # --- Claude ---
    echo "🛡️ Setting up Claude Code config..."
    # (Claude binary is installed via Brewfile)
    mkdir -p "$HOME/.claude"
    for item in settings.json CLAUDE.md commands agents skills code-rules statusline-command.sh; do
        rm -rf "$HOME/.claude/$item"
        ln -sf "$DOTFILES_DIR/.claude/$item" "$HOME/.claude/$item"
    done

    mkdir -p "$HOME/.claude/hooks"
    ln -sf "$DOTFILES_DIR/.claude/hooks/ai_track.py" "$HOME/.claude/hooks/ai_track.py"

    log_success "AI tools setup complete"
}
