#!/bin/bash
# Usage: notify.sh <emoji> <message> <sound>
# Sends a clickable notification that jumps to the current tmux session in Ghostty

EMOJI="${1:-✅}"
MESSAGE="${2:-CC - Task done}"
SOUND="${3:-default}"
PROJECT=$(basename "$PWD")
SESSION=$(tmux display-message -p "#S" 2>/dev/null || echo "")

# Build a one-time focus script with the session name baked in
FOCUS_SCRIPT=$(mktemp /tmp/claude-focus-XXXXX.sh)
cat > "$FOCUS_SCRIPT" <<SCRIPT
#!/bin/bash
open -a Ghostty
sleep 0.4
CLIENT=\$(tmux list-clients -F '#{client_name}' 2>/dev/null | head -1)
[ -n "\$CLIENT" ] && [ -n "$SESSION" ] && tmux switch-client -c "\$CLIENT" -t "$SESSION" 2>/dev/null
rm -f "$FOCUS_SCRIPT"
SCRIPT
chmod +x "$FOCUS_SCRIPT"

terminal-notifier \
  -title "$EMOJI $PROJECT" \
  -message "$MESSAGE" \
  -execute "$FOCUS_SCRIPT" \
  -sound "$SOUND"
