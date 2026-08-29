#!/usr/bin/env bash
# Claude Code status line
# Shows: dir-name [model]  ctx bar  5h/7d quota bars (sub) or cost (api key)

input=$(cat)

CYAN=$'\033[96m'
YELLOW=$'\033[93m'
RESET=$'\033[0m'
SEP='│'

# Filled segments are a colored background with dark text on top; the rest of
# the bar is a neutral track with light text. Each meter's fill matches its
# own label color.
TRACK=$'\033[97;100m'

LABEL_CTX=$'\033[94m'
FILL_CTX=$'\033[30;104m'
LABEL_QUOTA=$'\033[95m'
FILL_QUOTA=$'\033[30;105m'

BAR_WIDTH=8

# Renders "label [  42%  ]" as a bar whose fill tracks the percentage, with the
# number printed inside it. An empty pct renders an empty bar with no number.
meter() {
  local label=$1 pct=$2 label_color=$3 fill=$4 text pad content filled
  if [ -n "$pct" ]; then
    pct=$(printf '%.0f' "$pct")
    [ "$pct" -gt 100 ] && pct=100
    [ "$pct" -lt 0 ] && pct=0
    text="${pct}%"
  else
    pct=0
    text=""
  fi

  # Center the number in the track, then color the leading cells as filled.
  pad=$(( (BAR_WIDTH - ${#text}) / 2 ))
  printf -v content '%*s%s%*s' "$pad" "" "$text" "$(( BAR_WIDTH - pad - ${#text} ))" ""

  filled=$(( (pct * BAR_WIDTH + 50) / 100 ))
  # Any usage at all should show as at least one cell, so 0% stays distinct.
  [ "$filled" -eq 0 ] && [ "$pct" -gt 0 ] && filled=1

  printf '%s%s%s %s%s%s%s%s' "$label_color" "$label" "$RESET" \
    "$fill" "${content:0:filled}" \
    "$TRACK" "${content:filled}" "$RESET"
}

# Keep just the family: "Opus 5 (1M context)" -> "opus", "Haiku 4.5" -> "haiku".
model=$(echo "$input" | jq -r '.model.display_name' |
  sed -e 's/ *([^)]*)//g' -e 's/ *[0-9][0-9.]*$//' | tr '[:upper:]' '[:lower:]')
dir=$(basename "$(echo "$input" | jq -r '.workspace.current_dir')")

used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
ctx=$(meter "ctx" "$used_pct" "$LABEL_CTX" "$FILL_CTX")

# Subscription sessions expose rate_limits (5h/7d quota); API key sessions don't,
# so fall back to showing accrued cost instead.
five_h=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
seven_d=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')

if [ -n "$five_h" ] || [ -n "$seven_d" ]; then
  extra=""
  [ -n "$five_h" ] && extra=$(meter "5h" "$five_h" "$LABEL_QUOTA" "$FILL_QUOTA")
  [ -n "$seven_d" ] && extra="${extra:+$extra  }$(meter "7d" "$seven_d" "$LABEL_QUOTA" "$FILL_QUOTA")"
else
  cost=$(echo "$input" | jq -r '.cost.total_cost_usd // empty')
  extra=$(printf '$%.2f' "${cost:-0}")
fi

printf '%s%s%s %s %s%s%s %s %s %s %s\n' \
  "$YELLOW" "$dir" "$RESET" "$SEP" "$CYAN" "$model" "$RESET" \
  "$SEP" "$ctx" "$SEP" "$extra"
