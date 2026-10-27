#!/bin/sh
input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
five_hour_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
seven_day_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')

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

ctx_seg=""
if [ -n "$used_pct" ]; then
  used_int=$(printf "%.0f" "$used_pct")
  ctx_seg="$(usage_color "$used_int")ctx ${used_int}%${reset}"
fi

rate_seg=""
if [ -n "$five_hour_pct" ]; then
  five_int=$(printf "%.0f" "$five_hour_pct")
  if [ "$five_int" -ge 70 ]; then
    rate_seg="$(usage_color "$five_int")5h ${five_int}%${reset}"
  fi
fi
if [ -n "$seven_day_pct" ]; then
  week_int=$(printf "%.0f" "$seven_day_pct")
  if [ "$week_int" -ge 70 ]; then
    rate_seg="${rate_seg:+${rate_seg} }$(usage_color "$week_int")7d ${week_int}%${reset}"
  fi
fi

separator="${dim} · ${reset}"
line="${dir}"
if [ -n "$branch" ]; then
  line="${line}${separator}${branch}"
fi
if [ -n "$ctx_seg" ]; then
  line="${line}${separator}${ctx_seg}"
fi
if [ -n "$rate_seg" ]; then
  line="${line}${separator}${rate_seg}"
fi

printf "%s" "$line"
