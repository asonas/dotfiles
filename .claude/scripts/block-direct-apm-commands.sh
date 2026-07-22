#!/usr/bin/env bash
set -euo pipefail

shell_code_only() {
  awk '
    BEGIN {
      quote = ""
      escaped = 0
      comment = 0
      command_sub = 0
      backtick_sub = 0
      command_start = 1
      preserve_quote = 0
    }
    {
      line = $0 "\n"
      for (i = 1; i <= length(line); i++) {
        ch = substr(line, i, 1)
        if (backtick_sub && quote == "" && ch == "`") {
          backtick_sub = 0
          printf ";"
          command_start = 1
        } else if (command_sub && quote == "" && ch == ")") {
          command_sub = 0
          quote = "\""
          printf ";"
          command_start = 1
        } else if (comment) {
          if (ch == "\n") {
            comment = 0
            command_start = 1
            printf "\n"
          } else {
            printf " "
          }
        } else if (quote == "\047") {
          if (ch == quote) {
            quote = ""
            preserve_quote = 0
            printf " "
          } else if (preserve_quote) {
            printf "%s", ch
          } else {
            printf " "
          }
        } else if (escaped) {
          printf "%s", ch
          escaped = 0
        } else if (ch == "\\" && substr(line, i + 1, 1) == "\n") {
          i++
        } else if (ch == "\\") {
          printf "%s", ch
          escaped = 1
        } else if (quote != "") {
          if (quote == "\"" && ch == "$" && substr(line, i + 1, 1) == "(") {
            quote = ""
            command_sub = 1
            printf ";"
            command_start = 1
            i++
          } else {
            if (ch == quote) {
              quote = ""
              preserve_quote = 0
              printf " "
            } else if (preserve_quote) {
              printf "%s", ch
            } else {
              printf " "
            }
          }
        } else if (ch == "`") {
          backtick_sub = 1
          printf ";"
          command_start = 1
        } else if (ch == "\"" || ch == "\047") {
          quote = ch
          preserve_quote = command_start
          if (preserve_quote) { command_start = 0 }
          printf " "
        } else if (ch == "#" && (i == 1 || substr(line, i - 1, 1) ~ /[;&|()<>[:space:]]/)) {
          comment = 1
          printf " "
        } else {
          printf "%s", ch
          if (ch ~ /[;&|(]/) {
            command_start = 1
          } else if (ch !~ /[[:space:]]/) {
            command_start = 0
          }
        }
      }
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
code=$(printf '%s' "$cmd" | shell_code_only)
if ! printf '%s' "$code" | grep -Eq '(^|[;&|(])[[:space:]]*([^;&|()[:space:]]*/)?apm[[:space:]]+(update|install)([;&|()<>[:space:]]|$)'; then
  exit 0
fi

deny_direct_apm
