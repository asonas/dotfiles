#!/bin/bash
# Add a task with checklist items to Things3 via URL scheme
# Usage: things-add-with-checklist.sh "タスク名" "item1" "item2" "item3" ...
# Task is always added to "今日"
# Checklist items are added in the order provided.

NAME="$1"
shift

if [ -z "$NAME" ]; then
  echo "Usage: things-add-with-checklist.sh 'task name' 'item1' 'item2' ..." >&2
  exit 1
fi

ENCODED_NAME=$(python3 -c "import urllib.parse, sys; print(urllib.parse.quote(sys.argv[1], safe=''))" "$NAME")

# Build checklist items (newline-separated, URL-encoded)
CHECKLIST=""
for item in "$@"; do
  if [ -n "$CHECKLIST" ]; then
    CHECKLIST="${CHECKLIST}
${item}"
  else
    CHECKLIST="${item}"
  fi
done

ENCODED_CHECKLIST=$(python3 -c "import urllib.parse, sys; print(urllib.parse.quote(sys.argv[1], safe=''))" "$CHECKLIST")

if [ -n "$ENCODED_CHECKLIST" ]; then
  open "things:///add?title=${ENCODED_NAME}&checklist-items=${ENCODED_CHECKLIST}&when=today"
else
  open "things:///add?title=${ENCODED_NAME}&when=today"
fi

echo "Added: $NAME"
if [ -n "$CHECKLIST" ]; then
  echo "Checklist items:"
  for item in "$@"; do
    echo "  - $item"
  done
fi
