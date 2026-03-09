#!/bin/bash

# Ghostty pane/tab attention script for Claude Code
# - Changes tab title to show waiting indicator
# - Sends BEL to trigger Ghostty's tab attention highlight
# - Reads hook context from stdin (JSON)

HOOK_INPUT=$(cat)

PROJECT=$(echo "$HOOK_INPUT" | jq -r '.cwd // empty' 2>/dev/null | xargs basename 2>/dev/null)
MESSAGE=$(echo "$HOOK_INPUT" | jq -r '.message // empty' 2>/dev/null)

if [ -n "$MESSAGE" ]; then
  TITLE_TEXT="$MESSAGE"
else
  TITLE_TEXT="入力を待っています"
fi

if [ -n "$PROJECT" ]; then
  TITLE="⏳ Claude [$PROJECT]: $TITLE_TEXT"
else
  TITLE="⏳ Claude: $TITLE_TEXT"
fi

# Set tab/window title with waiting indicator
printf '\033]0;%s\007' "$TITLE" > /dev/tty

# Send BEL to trigger Ghostty tab attention (tab text turns highlighted)
printf '\a' > /dev/tty

exit 0
