#!/bin/sh
input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')
model=$(echo "$input" | jq -r '.model.display_name // empty')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
remaining_pct=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')
five_hour_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_hour_resets_at=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
seven_day_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')

dir=$(basename "$cwd")

# Build context window segment
if [ -n "$used_pct" ]; then
  used_int=$(printf "%.0f" "$used_pct")
  remaining_int=$(printf "%.0f" "$remaining_pct")
  ctx_seg="ctx: ${used_int}% used (${remaining_int}% left)"
else
  ctx_seg="ctx: --"
fi

# Build rate limit segment
rate_seg=""
if [ -n "$five_hour_pct" ]; then
  five_int=$(printf "%.0f" "$five_hour_pct")
  if [ -n "$five_hour_resets_at" ]; then
    now=$(date +%s)
    secs_left=$((five_hour_resets_at - now))
    if [ "$secs_left" -gt 0 ]; then
      hours_left=$(awk "BEGIN { printf \"%.1f\", $secs_left / 3600 }")
      rate_seg="5h: ${five_int}% (${hours_left}h left)"
    else
      rate_seg="5h: ${five_int}% (resetting)"
    fi
  else
    rate_seg="5h: ${five_int}%"
  fi
fi
if [ -n "$seven_day_pct" ]; then
  week_int=$(printf "%.0f" "$seven_day_pct")
  if [ -n "$rate_seg" ]; then
    rate_seg="${rate_seg} | 7d: ${week_int}%"
  else
    rate_seg="7d: ${week_int}%"
  fi
fi

# Assemble output
out="dir: ${dir} | ${ctx_seg}"
if [ -n "$rate_seg" ]; then
  out="${out} | ${rate_seg}"
fi
out="${out} | ${model}"

printf "%s" "$out"
