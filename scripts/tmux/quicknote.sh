#!/bin/bash

# Folder notes (thay đổi nếu cần)
NOTE_DIR="$HOME/notes"
mkdir -p "$NOTE_DIR"

# Tạo tên file (timestamp + arg nếu có)
DATE=$(date '+%Y-%m-%d')
FILENAME="${1:-${DATE}}.md"
FULL_PATH="${NOTE_DIR}/${FILENAME}"

# Nội dung header note
CONTENT="# Note: ${FILENAME}

"

# Check nếu tmux đang chạy session nào
if tmux ls > /dev/null 2>&1; then
  # Có session – attach vào session đầu tiên, tạo window mới cho Neovim
  SESSION_NAME=$(tmux ls | head -n 1 | cut -d: -f1)
  tmux attach-session -t "$SESSION_NAME" || tmux attach-session  # Attach nếu có thể
  tmux new-window -n "Note" 'nvim '"${FULL_PATH}"' '  # Tạo window mới với Neovim + file
  tmux send-keys -t note 'ggO'  # Mở insert mode đầu file
  tmux send-keys -t note "${CONTENT}"  # Paste header
  tmux send-keys -t note 'Esc gg'  # Thoát insert, đầu file
  tmux select-window -t note  # Switch to note window
else
  # Chưa có session – tạo session mới với Neovim + note
  SESSION_NAME="notes-session"
  tmux new-session -d -s "$SESSION_NAME" 'nvim '"${FULL_PATH}"  # Tạo session detached
  tmux send-keys -t "$SESSION_NAME" 'ggO'  # Mở insert mode
  tmux send-keys -t "$SESSION_NAME" "${CONTENT}"  # Paste header
  tmux send-keys -t "$SESSION_NAME" 'Esc gg'  # Thoát insert
  tmux attach-session -t "$SESSION_NAME"  # Attach vào session
fi
