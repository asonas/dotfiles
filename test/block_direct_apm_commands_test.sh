#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd)
hook="$repo_root/.claude/scripts/block-direct-apm-commands.sh"

run_hook() {
  local command=$1
  jq -cn --arg command "$command" '{tool_input: {command: $command}}' | "$hook"
}

assert_denied() {
  local command=$1
  local output
  output=$(run_hook "$command")
  [ -n "$output" ]
  jq -e '
    .hookSpecificOutput.hookEventName == "PreToolUse" and
    .hookSpecificOutput.permissionDecision == "deny" and
    (.hookSpecificOutput.permissionDecisionReason | contains("install.sh"))
  ' <<<"$output" >/dev/null
}

assert_allowed() {
  local command=$1
  local output
  output=$(run_hook "$command")
  [ -z "$output" ]
}

assert_raw_input_allowed() {
  local input=$1
  local output
  output=$(printf '%s' "$input" | "$hook")
  [ -z "$output" ]
}

output=$(run_hook 'apm update')
[ -n "$output" ]
jq -e '
  .hookSpecificOutput.hookEventName == "PreToolUse" and
  .hookSpecificOutput.permissionDecision == "deny" and
  (.hookSpecificOutput.permissionDecisionReason | contains("install.sh"))
' <<<"$output" >/dev/null

assert_denied 'apm install'
assert_denied 'apm install -g --target claude,cursor,codex'
assert_denied '/home/asonas/.local/bin/apm update --yes'
assert_denied './bin/apm install'
assert_denied 'printf ready && apm update'
assert_denied 'apm install | tee /tmp/apm.log'
assert_denied 'echo "$(apm update)"'
assert_denied 'echo `apm install`'
assert_denied 'echo "`apm update`"'
assert_denied 'echo foo#bar; apm update'
assert_denied 'apm update>/tmp/apm.log'
assert_denied $'apm \\\nupdate'
assert_denied "printf '%s\\n' 'foo\\' ; apm update"
assert_denied '"apm" update'
assert_denied 'apm "update"'
assert_denied 'FOO=bar apm update'

assert_allowed 'printf "%s\n" "apm install"'
assert_allowed 'printf "%s\n" " apm install"'
assert_allowed 'printf "%s\n" " apm install "'
assert_allowed 'apm compile'
assert_allowed 'apm --version'
assert_allowed 'echo ready # apm update'
assert_allowed "printf '%s\\n' 'apm update'"
assert_allowed './install.sh'
assert_allowed 'echo apm update'
assert_allowed 'x=/tmp/apm update'

assert_raw_input_allowed ''
assert_raw_input_allowed '{}'
