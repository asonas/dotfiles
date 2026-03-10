#!/bin/bash
# Claude Code status line: Anthropic OAuth usage display
# Shows 5-hour and 7-day utilization with reset times in Asia/Tokyo timezone

CACHE_FILE="/tmp/claude-usage-cache.json"
CACHE_TTL=360
OS_TYPE=$(uname -s)

fetch_usage() {
  local credentials
  if [ "$OS_TYPE" = "Darwin" ]; then
    credentials=$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null)
  else
    credentials=$(cat ~/.claude/.credentials.json 2>/dev/null)
  fi
  if [ -z "$credentials" ]; then
    return 1
  fi

  local access_token
  access_token=$(echo "$credentials" | jq -r '.claudeAiOauth.accessToken // empty' 2>/dev/null)
  if [ -z "$access_token" ]; then
    return 1
  fi

  local response
  response=$(curl -sf --max-time 5 \
    -H "Authorization: Bearer ${access_token}" \
    -H "anthropic-beta: oauth-2025-04-20" \
    "https://api.anthropic.com/api/oauth/usage" 2>/dev/null)

  if [ -z "$response" ]; then
    return 1
  fi

  echo "$response"
  return 0
}

get_cached_or_fetch() {
  if [ -f "$CACHE_FILE" ]; then
    local mtime now age
    if [ "$OS_TYPE" = "Darwin" ]; then
      mtime=$(stat -f %m "$CACHE_FILE" 2>/dev/null)
    else
      mtime=$(stat -c %Y "$CACHE_FILE" 2>/dev/null)
    fi
    now=$(date +%s)
    age=$((now - mtime))
    if [ "$age" -lt "$CACHE_TTL" ]; then
      cat "$CACHE_FILE"
      return 0
    fi
  fi

  local data
  data=$(fetch_usage)
  if [ -n "$data" ]; then
    echo "$data" > "$CACHE_FILE"
    echo "$data"
    return 0
  fi

  return 1
}

color_for_util() {
  local util=${1%.*}  # strip decimal part for integer comparison
  if [ "$util" -ge 80 ]; then
    # red
    printf '\033[31m'
  elif [ "$util" -ge 50 ]; then
    # yellow
    printf '\033[33m'
  else
    # green
    printf '\033[32m'
  fi
}

format_reset_time() {
  local resets_at=$1

  # Convert ISO8601 to epoch
  local epoch
  if [ "$OS_TYPE" = "Darwin" ]; then
    # BSD date: strip fractional seconds and normalize timezone for parsing
    local normalized
    normalized=$(echo "$resets_at" | sed 's/\.[0-9]*//; s/Z$/+0000/; s/+\([0-9][0-9]\):\([0-9][0-9]\)$/+\1\2/; s/T/ /')
    epoch=$(TZ=UTC date -j -f "%Y-%m-%d %H:%M:%S%z" "$normalized" +%s 2>/dev/null)
  else
    # GNU date: parse ISO8601 directly
    epoch=$(date -d "$resets_at" +%s 2>/dev/null)
  fi
  if [ -z "$epoch" ]; then
    echo "$resets_at"
    return
  fi

  local now
  now=$(date +%s)

  # Format in Asia/Tokyo
  local tz_date
  if [ "$OS_TYPE" = "Darwin" ]; then
    tz_date=$(TZ=Asia/Tokyo date -j -f %s "$epoch" "+%m/%d %H:%M" 2>/dev/null)
  else
    tz_date=$(TZ=Asia/Tokyo date -d "@$epoch" "+%m/%d %H:%M" 2>/dev/null)
  fi

  local today_date
  today_date=$(TZ=Asia/Tokyo date "+%m/%d")

  local reset_date
  reset_date=$(echo "$tz_date" | awk '{print $1}')
  local reset_time
  reset_time=$(echo "$tz_date" | awk '{print $2}')

  # Parse hour and minute
  local hour minute ampm display_hour
  hour=$(echo "$reset_time" | cut -d: -f1)
  minute=$(echo "$reset_time" | cut -d: -f2)
  hour=$((10#$hour))

  if [ "$hour" -ge 12 ]; then
    ampm="pm"
    [ "$hour" -gt 12 ] && display_hour=$((hour - 12)) || display_hour=12
  else
    ampm="am"
    [ "$hour" -eq 0 ] && display_hour=12 || display_hour=$hour
  fi

  # Remove leading zero for display
  local time_str
  if [ "$minute" = "00" ]; then
    time_str="${display_hour}${ampm}"
  else
    time_str="${display_hour}:${minute}${ampm}"
  fi

  if [ "$reset_date" = "$today_date" ]; then
    echo "reset ${time_str}"
  else
    # Show month/day without leading zero for month
    local month day
    month=$(echo "$reset_date" | cut -d/ -f1 | sed 's/^0//')
    day=$(echo "$reset_date" | cut -d/ -f2 | sed 's/^0//')
    echo "reset ${month}/${day} ${time_str}"
  fi
}

get_dir_and_branch() {
  local cwd
  cwd=$(pwd)

  # Show path with ~ for home directory
  local dirname
  dirname="${cwd/#$HOME/~}"

  # Get current branch name
  local branch
  branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)

  if [ -n "$branch" ]; then
    printf "%s [%s]" "$dirname" "$branch"
  else
    printf "%s" "$dirname"
  fi
}

main() {
  # Consume stdin (Claude Code passes JSON via stdin)
  cat > /dev/null

  local reset_color='\033[0m'

  # Directory and branch info
  local dir_branch
  dir_branch=$(get_dir_and_branch)

  # Usage info
  local data
  data=$(get_cached_or_fetch)
  if [ -z "$data" ]; then
    printf "%s | usage: unavailable" "$dir_branch"
    return
  fi

  local five_util five_resets seven_util seven_resets
  five_util=$(echo "$data" | jq -r '.five_hour.utilization // empty')
  five_resets=$(echo "$data" | jq -r '.five_hour.resets_at // empty')
  seven_util=$(echo "$data" | jq -r '.seven_day.utilization // empty')
  seven_resets=$(echo "$data" | jq -r '.seven_day.resets_at // empty')

  if [ -z "$five_util" ] || [ -z "$seven_util" ]; then
    printf "%s | usage: unavailable" "$dir_branch"
    return
  fi

  local five_color seven_color
  five_color=$(color_for_util "$five_util")
  seven_color=$(color_for_util "$seven_util")

  local five_reset_str seven_reset_str
  five_reset_str=$(format_reset_time "$five_resets")
  seven_reset_str=$(format_reset_time "$seven_resets")

  printf "%s | ${five_color}5h: ${five_util}%% (${five_reset_str})${reset_color} | ${seven_color}7d: ${seven_util}%% (${seven_reset_str})${reset_color}" "$dir_branch"
}

main "$@"
