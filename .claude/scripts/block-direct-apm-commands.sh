#!/usr/bin/env bash
set -euo pipefail

normalize_command() {
  awk '
    {
      line = $0
      continued = sub(/\\$/, "", line)
      gsub(/["\047]/, "", line)
      if (NR > 1 && !previous_continued) { printf "\n" }
      printf "%s", line
      previous_continued = continued
    }
  '
}

deny_direct_apm() {
  cat <<'JSON'
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"`apm update` と `apm install` は直接実行できません。APMの更新と配備には、このリポジトリの `install.sh` を実行してください。"}}
JSON
}

input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')
normalized=$(printf '%s' "$cmd" | normalize_command)
if ! printf '%s' "$normalized" | grep -Eq '(^|[^[:alnum:]_])([^;&|()<>[:space:]]*/)?apm[[:space:]]+(update|install)([;&|()<>`[:space:]]|$)'; then
  exit 0
fi

deny_direct_apm
