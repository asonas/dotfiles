#!/bin/bash

# Pushover notification script for Claude Code hooks
# Config file: ~/.config/pushover/config
# Reads hook context from stdin (JSON with session_id, cwd, etc.)

CONFIG_FILE="$HOME/.config/pushover/config"

if [ ! -f "$CONFIG_FILE" ]; then
  echo "Pushover config not found: $CONFIG_FILE" >&2
  exit 0
fi

source "$CONFIG_FILE"

if [ -z "$PUSHOVER_USER_KEY" ] || [ -z "$PUSHOVER_API_TOKEN" ]; then
  echo "PUSHOVER_USER_KEY or PUSHOVER_API_TOKEN not set" >&2
  exit 0
fi

# Read hook context from stdin
HOOK_INPUT=$(cat)

PROJECT=$(echo "$HOOK_INPUT" | jq -r '.cwd // empty' 2>/dev/null | xargs basename 2>/dev/null)
NOTIFICATION_MSG=$(echo "$HOOK_INPUT" | jq -r '.message // empty' 2>/dev/null)

TITLE="Claude Code"
if [ -n "$PROJECT" ]; then
  TITLE="Claude Code - $PROJECT"
fi

if [ -n "$NOTIFICATION_MSG" ]; then
  MESSAGE="$NOTIFICATION_MSG"
else
  MESSAGE="入力を待っています"
fi

curl -s \
  --form-string "token=$PUSHOVER_API_TOKEN" \
  --form-string "user=$PUSHOVER_USER_KEY" \
  --form-string "message=$MESSAGE" \
  --form-string "title=$TITLE" \
  --form-string "sound=pushover" \
  https://api.pushover.net/1/messages.json > /dev/null 2>&1

exit 0
