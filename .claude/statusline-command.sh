#!/bin/sh
input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')
model=$(echo "$input" | jq -r '.model.display_name // empty')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
remaining_pct=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')

dir=$(basename "$cwd")

# Build context segment
if [ -n "$used_pct" ]; then
  used_int=$(printf "%.0f" "$used_pct")
  remaining_int=$(printf "%.0f" "$remaining_pct")
  printf "dir: %s | ctx: %d%% used (%d%% left) | %s" "$dir" "$used_int" "$remaining_int" "$model"
else
  printf "dir: %s | %s" "$dir" "$model"
fi
