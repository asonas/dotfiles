#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd)
hook="$repo_root/.claude/scripts/block-direct-apm-commands.sh"

run_hook() {
  local command=$1
  jq -cn --arg command "$command" '{tool_input: {command: $command}}' | "$hook"
}

output=$(run_hook 'apm update')
jq -e '
  .hookSpecificOutput.hookEventName == "PreToolUse" and
  .hookSpecificOutput.permissionDecision == "deny" and
  (.hookSpecificOutput.permissionDecisionReason | contains("install.sh"))
' <<<"$output" >/dev/null
