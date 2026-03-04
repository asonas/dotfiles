#!/bin/bash
# Add a task to Things3 via URL scheme
# Usage: things-add.sh "タスク名" ["メモ/URL"] ["タグ名"]
# Task is always added to "今日"

NAME="$1"
NOTES="${2:-}"
TAG="${3:-}"

if [ -z "$NAME" ]; then
  echo "Usage: things-add.sh 'task name' ['notes'] ['tag']" >&2
  exit 1
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
