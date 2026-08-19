#!/usr/bin/env bash
# Claude Code status line
# Shows: [model] dir-name | ctx: X% | 5h/7d quota (sub) or cost (api key)

input=$(cat)

model=$(echo "$input" | jq -r '.model.display_name' | tr '[:upper:]' '[:lower:]')
dir=$(basename "$(echo "$input" | jq -r '.workspace.current_dir')")

used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
if [ -n "$used_pct" ]; then
  ctx=$(printf "ctx: %.0f%%" "$used_pct")
else
  ctx="ctx: n/a"
fi

# Subscription sessions expose rate_limits (5h/7d quota); API key sessions don't,
# so fall back to showing accrued cost instead.
five_h=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
seven_d=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')

if [ -n "$five_h" ] || [ -n "$seven_d" ]; then
  extra=""
  [ -n "$five_h" ] && extra="5h: $(printf '%.0f' "$five_h")%"
  [ -n "$seven_d" ] && extra="${extra:+$extra }7d: $(printf '%.0f' "$seven_d")%"
else
  cost=$(echo "$input" | jq -r '.cost.total_cost_usd // empty')
  extra=$(printf "\$%.2f" "${cost:-0}")
fi

printf "\033[96m[%s] %s | %s | %s\033[0m\n" "$model" "$dir" "$ctx" "$extra"
