#!/bin/sh
input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')
model_name=$(echo "$input" | jq -r '.model.display_name // empty')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
five_hour_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_hour_resets_at=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
seven_day_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
seven_day_resets_at=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

dir=$(basename "$cwd")
branch=$(git -C "$cwd" branch --show-current 2>/dev/null)

git_paths=$(git -C "$cwd" rev-parse --path-format=absolute --git-common-dir --git-dir --show-toplevel 2>/dev/null)
if [ -n "$git_paths" ]; then
  common_dir=$(echo "$git_paths" | sed -n 1p)
  git_dir=$(echo "$git_paths" | sed -n 2p)
  toplevel=$(echo "$git_paths" | sed -n 3p)
  if [ "$common_dir" != "$git_dir" ]; then
    parent_repo=$(basename "$(dirname "$common_dir")")
    worktree_name=$(basename "$toplevel")
    worktree_name=${worktree_name#"$parent_repo."}
    branch=""
  fi
fi

yellow=$(printf '\033[33m')
red=$(printf '\033[31m')
magenta=$(printf '\033[35m')
bold=$(printf '\033[1m')
dim=$(printf '\033[2m')
green=$(printf '\033[32m')
cyan=$(printf '\033[36m')
reset=$(printf '\033[0m')

if [ -n "$worktree_name" ]; then
  dir="${bold}${parent_repo}${reset} › ${magenta}[WT]${reset} ${bold}${worktree_name}${reset}"
else
  dir="${bold}${dir}${reset}"
fi

usage_color() {
  if [ "$1" -ge 80 ]; then
    printf "%s" "$red"
  elif [ "$1" -ge 50 ]; then
    printf "%s" "$yellow"
  else
    printf "%s" "$green"
  fi
}

format_time_left() {
  seconds_left=$(( $1 - $(date +%s) ))
  if [ "$seconds_left" -le 0 ]; then
    return
  fi
  if [ "$seconds_left" -ge 86400 ]; then
    printf "%d day left" $(( seconds_left / 86400 ))
  elif [ "$seconds_left" -ge 3600 ]; then
    tenths_of_hour=$(( seconds_left * 10 / 3600 ))
    printf "%d,%dh left" $(( tenths_of_hour / 10 )) $(( tenths_of_hour % 10 ))
  else
    printf "%dm left" $(( seconds_left / 60 ))
  fi
}

rate_label() {
  label="$1"
  pct_int="$2"
  resets_at="$3"
  time_left=""
  if [ -n "$resets_at" ]; then
    time_left=$(format_time_left "$resets_at")
  fi
  printf "%s%s%s %s%s%%%s%s%s%s" "$dim" "$label" "$reset" "$(usage_color "$pct_int")" "$pct_int" "$reset" "$dim" "${time_left:+ ($time_left)}" "$reset"
}

ctx_seg=""
if [ -n "$used_pct" ]; then
  used_int=$(printf "%.0f" "$used_pct")
  ctx_seg="${dim}ctx${reset} $(usage_color "$used_int")${used_int}%${reset}"
fi

rate_seg=""
if [ -n "$five_hour_pct" ]; then
  five_int=$(printf "%.0f" "$five_hour_pct")
  rate_seg="$(rate_label "5h:" "$five_int" "$five_hour_resets_at")"
fi
if [ -n "$seven_day_pct" ]; then
  week_int=$(printf "%.0f" "$seven_day_pct")
  rate_seg="${rate_seg:+${rate_seg}${dim} / ${reset}}$(rate_label "7 day:" "$week_int" "$seven_day_resets_at")"
fi

separator="${dim} · ${reset}"
line="${dir}"
if [ -n "$branch" ]; then
  line="${line}${separator}${branch}"
fi
usage_line="$ctx_seg"
if [ -n "$rate_seg" ]; then
  usage_line="${usage_line:+${usage_line}${dim}, ${reset}}${rate_seg}"
fi
if [ -n "$model_name" ]; then
  usage_line="${cyan}${model_name}${reset}${usage_line:+${separator}${usage_line}}"
fi
if [ -n "$usage_line" ]; then
  printf "%s\n%s" "$line" "$usage_line"
else
  printf "%s" "$line"
fi
