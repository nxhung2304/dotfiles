#!/usr/bin/env bash
set -u

export PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"
METRICS_DIR="$HOME/.ai-metrics"
LOG_FILE="$METRICS_DIR/logs/review-$(date +%F).log"
mkdir -p "$METRICS_DIR/logs"
cd "$METRICS_DIR" || exit 1

claude -p "/ai-score" \
    --permission-mode dontAsk \
    --settings '{"disableAllHooks": true}' \
    --no-session-persistence \
    --add-dir "$HOME/.claude/projects" \
    --add-dir "$HOME/dotfiles" \
    --allowedTools "Bash(python3:*)" "Bash(mkdir:*)" "Bash(open:*)" "Read" "Glob" "Grep" \
        "Edit(~/.ai-metrics/**)" "Write(~/.ai-metrics/**)" \
    >> "$LOG_FILE" 2>&1

if [ $? -ne 0 ]; then
    osascript -e "display notification \"Xem $LOG_FILE\" with title \"AI review thất bại\""
fi
