#!/usr/bin/env bash
# Setup AI CLI Tools: Claude

remove_codex_gemini_leftovers() {
    local dotfiles_name tool_dir leftover_link
    dotfiles_name=$(basename "$DOTFILES_DIR")
    for tool_dir in .codex .gemini; do
        [ -d "$HOME/$tool_dir" ] || continue
        while IFS= read -r -d '' leftover_link; do
            if [[ $(readlink "$leftover_link") == *"$dotfiles_name/$tool_dir/"* ]]; then
                rm "$leftover_link"
                log_info "Removed old link $leftover_link"
            fi
        done < <(find "$HOME/$tool_dir" -maxdepth 3 -type l -print0)
    done

    if ! command -v npm &>/dev/null; then
        return
    fi

    local package
    for package in @google/gemini-cli @openai/codex; do
        if npm list -g "$package" &>/dev/null && ask "Uninstall $package with npm?"; then
            npm uninstall -g "$package"
        fi
    done
}

install_ai() {
    log_header "AI TOOLS"

    remove_codex_gemini_leftovers

    # --- Claude ---
    echo "🛡️ Setting up Claude Code config..."
    # (Claude binary is installed via Brewfile)
    mkdir -p "$HOME/.claude"

    mkdir -p "$HOME/.claude/hooks"

    echo "⏰ Scheduling weekly AI review (Monday 10:00)..."
    local review_plist="$HOME/Library/LaunchAgents/local.ai-metrics.review.plist"
    mkdir -p "$HOME/Library/LaunchAgents"
    cat > "$review_plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key><string>local.ai-metrics.review</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>$DOTFILES_DIR/scripts/ai-metrics/ai-score-weekly.sh</string>
    </array>
    <key>StartCalendarInterval</key>
    <dict>
        <key>Weekday</key><integer>1</integer>
        <key>Hour</key><integer>10</integer>
        <key>Minute</key><integer>0</integer>
    </dict>
</dict>
</plist>
EOF
    launchctl bootout "gui/$(id -u)" "$review_plist" 2>/dev/null || true
    launchctl bootstrap "gui/$(id -u)" "$review_plist"

    echo "📂 Registering ai-reveal:// links (open in Finder)..."
    bash "$DOTFILES_DIR/scripts/ai-metrics/install-reveal-handler.sh"

    log_success "AI tools setup complete"
}
