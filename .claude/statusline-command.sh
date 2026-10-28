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

green=$(printf '\033[32m')
yellow=$(printf '\033[33m')
red=$(printf '\033[31m')
dim=$(printf '\033[2m')
reset=$(printf '\033[0m')

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
  printf "%s%s %s%%%s%s" "$(usage_color "$pct_int")" "$label" "$pct_int" "${time_left:+ ($time_left)}" "$reset"
}

ctx_seg=""
if [ -n "$used_pct" ]; then
  used_int=$(printf "%.0f" "$used_pct")
  ctx_seg="$(usage_color "$used_int")ctx ${used_int}%${reset}"
fi

rate_seg=""
if [ -n "$five_hour_pct" ]; then
  five_int=$(printf "%.0f" "$five_hour_pct")
  rate_seg="$(rate_label "5h:" "$five_int" "$five_hour_resets_at")"
fi
if [ -n "$seven_day_pct" ]; then
  week_int=$(printf "%.0f" "$seven_day_pct")
  rate_seg="${rate_seg:+${rate_seg} / }$(rate_label "7 day:" "$week_int" "$seven_day_resets_at")"
fi

separator="${dim} · ${reset}"
line="${dir}"
if [ -n "$branch" ]; then
  line="${line}${separator}${branch}"
fi
if [ -n "$model_name" ]; then
  line="${line}${separator}${model_name}"
fi
usage_line="$ctx_seg"
if [ -n "$rate_seg" ]; then
  usage_line="${usage_line:+${usage_line}, }${rate_seg}"
fi
if [ -n "$usage_line" ]; then
  printf "%s\n%s" "$line" "$usage_line"
else
  printf "%s" "$line"
fi
