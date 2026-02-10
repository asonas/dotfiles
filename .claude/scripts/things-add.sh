#!/bin/bash
# Add a task to Things3 via URL scheme
# Usage: things-add.sh "タスク名" ["メモ"]
# Task is always added to "今日"

NAME="$1"
NOTES="${2:-}"

if [ -z "$NAME" ]; then
  echo "Usage: things-add.sh 'task name' ['notes']" >&2
  exit 1
fi

# URL encode using python3
encode() {
  python3 -c "import urllib.parse; print(urllib.parse.quote('$1', safe=''))"
}

ENCODED_NAME=$(python3 -c "import urllib.parse, sys; print(urllib.parse.quote(sys.argv[1], safe=''))" "$NAME")
ENCODED_NOTES=$(python3 -c "import urllib.parse, sys; print(urllib.parse.quote(sys.argv[1], safe=''))" "$NOTES")

open "things:///add?title=${ENCODED_NAME}&notes=${ENCODED_NOTES}&when=today"
echo "Added: $NAME"
