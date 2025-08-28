#!/bin/bash

WINDOW_NAME="claude"
SESSION_NAME=$(tmux display-message -p '#S')

if tmux list-windows -t "$SESSION_NAME" -F "#{window_name}" | grep -q "^$WINDOW_NAME$"; then
    tmux select-window -t "$SESSION_NAME:$WINDOW_NAME"
else
    tmux new-window -n "$WINDOW_NAME" -c "$HOME"
    
    tmux send-keys -t "$WINDOW_NAME" "claude" Enter
    
    tmux select-pane -t "$WINDOW_NAME" -T "Claude AI"
fi
