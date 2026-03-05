#!/bin/bash
# Complete a task in Things3 by name
# Usage: things-complete.sh "タスク名"
# Searches in "今日" list and marks the matching task as completed

NAME="$1"

if [ -z "$NAME" ]; then
  echo "Usage: things-complete.sh 'task name'" >&2
  exit 1
fi

RESULT=$(osascript -e '
tell application "Things3"
  set todoList to every to do of list "今日"
  repeat with t in todoList
    if name of t is "'"$(echo "$NAME" | sed "s/'/'\\\\''/g")"'" then
      set status of t to completed
      return "completed"
    end if
  end repeat
  return "not_found"
end tell
' 2>/dev/null)

if [ "$RESULT" = "completed" ]; then
  echo "Completed: $NAME"
else
  echo "Not found: $NAME"
fi
