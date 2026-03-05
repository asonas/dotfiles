#!/bin/bash
# Add a task to Things3 via URL scheme
# Usage: things-add.sh "タスク名" ["メモ/URL"] ["タグ名"]
# Task is always added to "今日"
# Skips if a task with the same name already exists in "今日"

NAME="$1"
NOTES="${2:-}"
TAG="${3:-}"

if [ -z "$NAME" ]; then
  echo "Usage: things-add.sh 'task name' ['notes'] ['tag']" >&2
  exit 1
fi

# Check for duplicate in Things3 "今日" list
EXISTING=$(osascript -e '
tell application "Things3"
  set todoList to every to do of list "今日"
  repeat with t in todoList
    if name of t is "'"$(echo "$NAME" | sed "s/'/'\\\\''/g")"'" then
      return "found"
    end if
  end repeat
  return "not_found"
end tell
' 2>/dev/null)

if [ "$EXISTING" = "found" ]; then
  echo "Skipped (already exists): $NAME"
  exit 0
fi

ENCODED_NAME=$(python3 -c "import urllib.parse, sys; print(urllib.parse.quote(sys.argv[1], safe=''))" "$NAME")
ENCODED_NOTES=$(python3 -c "import urllib.parse, sys; print(urllib.parse.quote(sys.argv[1], safe=''))" "$NOTES")

URL="things:///add?title=${ENCODED_NAME}&notes=${ENCODED_NOTES}&when=today"

if [ -n "$TAG" ]; then
  ENCODED_TAG=$(python3 -c "import urllib.parse, sys; print(urllib.parse.quote(sys.argv[1], safe=''))" "$TAG")
  URL="${URL}&tags=${ENCODED_TAG}"
fi

open "$URL"
echo "Added: $NAME"
