#!/bin/bash
set -eu

repo_root=$(cd "$(dirname "$0")/.." && pwd)
tmp_dir=$(mktemp -d)
trap 'command rm -rf "$tmp_dir"' EXIT

mkdir -p "$tmp_dir/bin" "$tmp_dir/home/.claude/hooks" "$tmp_dir/repo/.claude"
touch "$tmp_dir/home/.claude/hooks/herdr-agent-state.sh"

printf '%s\n' \
    '#!/bin/sh' \
    'set -eu' \
    'printf "%s\\n" "$*" > "$HERDR_CALL_LOG"' \
    'tmp=$(mktemp)' \
    'jq '\'' .hooks.SessionStart += [{matcher: "*", hooks: [{type: "command", command: "duplicate", timeout: 10}]}] '\'' "$HERDR_SETTINGS_FILE" > "$tmp"' \
    'command mv "$tmp" "$HERDR_SETTINGS_FILE"' > "$tmp_dir/bin/herdr"
chmod +x "$tmp_dir/bin/herdr"

printf '%s\n' \
    '{"hooks":{"SessionStart":[' \
    '{"matcher":"startup|resume|clear|compact","hooks":[{"type":"command","command":"old"}]}' \
    ']}}' > "$tmp_dir/repo/.claude/settings.json"

HOME="$tmp_dir/home" \
PATH="$tmp_dir/bin:$PATH" \
HERDR_CALL_LOG="$tmp_dir/herdr-call.log" \
HERDR_SETTINGS_FILE="$tmp_dir/repo/.claude/settings.json" \
    "$repo_root/bin/install_herdr_claude_integration" "$tmp_dir/repo/.claude/settings.json"

[ "$(cat "$tmp_dir/herdr-call.log")" = "integration install claude" ]

jq -e '
  .hooks.SessionStart == [
    {
      matcher: "startup|resume|clear|compact",
      hooks: [{
        type: "command",
        command: "\"$HOME/.claude/hooks/herdr-agent-state.sh\" session"
      }]
    }
  ]
' "$tmp_dir/repo/.claude/settings.json" >/dev/null
