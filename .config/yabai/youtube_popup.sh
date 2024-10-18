#!/bin/bash

WINDOW_ID=$(yabai -m query --windows --window | jq -r '.id')

DISPLAY_WIDTH=$(yabai -m query --displays | jq -r '.[] | select(.index==2) | .frame.w')

NEW_WIDTH=$DISPLAY_WIDTH
NEW_HEIGHT=$((DISPLAY_WIDTH * 9 / 16))

yabai -m window --display 2
yabai -m window --focus $WINDOW_ID --resize abs:$NEW_WIDTH:$NEW_HEIGHT
yabai -m display --focus 2
yabai -m window --grid 36:1:0:18:1:12
