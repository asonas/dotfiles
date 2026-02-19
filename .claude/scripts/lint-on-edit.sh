#!/bin/bash
# PostToolUse hook: Run formatter and linter on edited files
# Reads JSON from stdin, extracts file_path, runs appropriate tools

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [ -z "$FILE_PATH" ] || [ ! -f "$FILE_PATH" ]; then
  exit 0
fi

PROJECT_DIR=$(echo "$INPUT" | jq -r '.cwd // empty')
if [ -z "$PROJECT_DIR" ]; then
  exit 0
fi

case "$FILE_PATH" in
  *.ts|*.tsx|*.js|*.jsx)
    # Format first, then lint
    if [ -f "$PROJECT_DIR/node_modules/.bin/prettier" ]; then
      cd "$PROJECT_DIR" && npx prettier --write "$FILE_PATH" 2>&1
    fi
    if [ -f "$PROJECT_DIR/node_modules/.bin/eslint" ]; then
      cd "$PROJECT_DIR" && npx eslint --fix "$FILE_PATH" 2>&1
    fi
    ;;
  *.rb)
    if [ -f "$PROJECT_DIR/Gemfile" ] && grep -q "rubocop" "$PROJECT_DIR/Gemfile"; then
      cd "$PROJECT_DIR" && bundle exec rubocop -a "$FILE_PATH" 2>&1
    fi
    ;;
  *.rs)
    if [ -f "$PROJECT_DIR/Cargo.toml" ]; then
      cd "$PROJECT_DIR" && cargo clippy --fix --allow-dirty --allow-staged -- -W clippy::all 2>&1
    fi
    ;;
  *.css|*.json)
    if [ -f "$PROJECT_DIR/node_modules/.bin/prettier" ]; then
      cd "$PROJECT_DIR" && npx prettier --write "$FILE_PATH" 2>&1
    fi
    ;;
esac

exit 0
