#!/usr/bin/env bash
# PreToolUse(Bash) hook.
#
# git-wt (k1-lo-w/git-wt) treats its first positional argument as a branch /
# worktree name, not a subcommand. So `git wt help`, `git wt list`, `git wt ls`
# do NOT show help or list worktrees -- they CREATE a worktree+branch named
# help/list/ls. AIs habitually type these expecting subcommand semantics.
#
# This hook denies such invocations before execution and tells the caller the
# correct form (`git wt --help`, or bare `git wt` / `git worktree list`).
set -euo pipefail

input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')
[ -z "$cmd" ] && exit 0

# Match `git wt <word>` or `git-wt <word>` where <word> is exactly help/list/ls
# used as the first positional argument.
#   leading  : start-of-string or a non-identifier char (allows `&&`, `/usr/bin/`)
#   command  : `git wt` (any whitespace) or `git-wt`
#   word     : help | list | ls, NOT followed by an identifier/-/ char
#              (so `list-foo`, `help-x`, `listing` are left alone)
if printf '%s' "$cmd" | grep -Eq '(^|[^a-zA-Z0-9_-])git(-wt|[[:space:]]+wt)[[:space:]]+(help|list|ls)([^a-zA-Z0-9_/-]|$)'; then
  cat <<'JSON'
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"`git wt help|list|ls` はサブコマンドではなくブランチ名として解釈され、help/list/ls という名前のworktreeを新規作成してしまいます。ヘルプを見るなら `git wt --help`、worktree一覧は引数なしの `git wt` または `git worktree list` を使ってください。"}}
JSON
  exit 0
fi
exit 0
