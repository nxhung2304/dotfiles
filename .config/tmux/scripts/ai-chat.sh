#!/bin/bash

WINDOW_NAME="AI-Chat"
SESSION_NAME=$(tmux display-message -p '#S')

create_ai_window() {
    # Tạo window mới
    tmux new-window -n "$WINDOW_NAME" -c "$HOME"
    
    # Panel trái: claude
    tmux send-keys -t "$WINDOW_NAME:0.0" "claude" Enter
    
    # Tạo panel phải: gemini  
    tmux split-window -h -t "$WINDOW_NAME:0" -c "$HOME"
    tmux send-keys -t "$WINDOW_NAME:0.1" "gemini" Enter
    
    # Focus về claude (panel trái)
    tmux select-pane -t "$WINDOW_NAME:0.0"
    
    # Set pane titles
    tmux select-pane -t "$WINDOW_NAME:0.0" -T "Claude"
    tmux select-pane -t "$WINDOW_NAME:0.1" -T "Gemini"
}

# Main logic
if tmux list-windows -F "#{window_name}" | grep -q "^${WINDOW_NAME}$"; then
    # Switch to existing window
    tmux select-window -t "$WINDOW_NAME"
    tmux display-message "Switched to AI-Chat window"
else
    # Create new window
    create_ai_window
    tmux display-message "Created AI-Chat window"
fi
