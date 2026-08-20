#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd)
tmp_dir=$(mktemp -d)
trap 'command rm -rf "$tmp_dir"' EXIT

mkdir -p "$tmp_dir/bin" "$tmp_dir/work"

printf '%s\n' \
    '#!/bin/sh' \
    'set -eu' \
    'case "${1:-}" in' \
    '  which) printf "%s\\n" "$MISE_MDROLL_BIN" ;;' \
    '  *) echo "unexpected mise command: $*" >&2; exit 1 ;;' \
    'esac' > "$tmp_dir/bin/mise"
chmod +x "$tmp_dir/bin/mise"

printf '%s\n' \
    '#!/bin/sh' \
    'set -eu' \
    'printf "%s\\n" "$*" >> "$HERDR_CALL_LOG"' \
    'if [ "$1" = tab ] && [ "$2" = create ]; then' \
    '  printf "%s\\n" '\''{"result":{"root_pane":{"pane_id":"w-test:p-test"}}}'\''' \
    'elif [ "$1" = pane ] && [ "$2" = run ]; then' \
    '  exit 0' \
    'else' \
    '  echo "unexpected herdr command: $*" >&2' \
    '  exit 1' \
    'fi' > "$tmp_dir/bin/herdr"
chmod +x "$tmp_dir/bin/herdr"

printf '%s\n' \
    '#!/bin/sh' \
    'printf "%s\\n" "$*" > "$MISE_MDROLL_EXEC_LOG"' > "$tmp_dir/bin/mdroll-real"
chmod +x "$tmp_dir/bin/mdroll-real"

printf '%s\n' \
    '#!/bin/sh' \
    'exit 0' > "$tmp_dir/bin/mdroll"
chmod +x "$tmp_dir/bin/mdroll"

function_source=$(awk '
    /^mdroll\(\) \{/ { found=1 }
    found { print }
    found && /^\}$/ { exit }
' "$repo_root/.zshrc")
printf '%s\n' "$function_source" > "$tmp_dir/mdroll-function.zsh"

HERDR_ENV=1 \
HERDR_WORKSPACE_ID=w-test \
HERDR_CALL_LOG="$tmp_dir/herdr-call.log" \
MISE_MDROLL_BIN="$tmp_dir/bin/mdroll-real" \
MISE_MDROLL_EXEC_LOG="$tmp_dir/mdroll-exec.log" \
MDROLL_FUNCTION="$tmp_dir/mdroll-function.zsh" \
MDROLL_TEST_WORKDIR="$tmp_dir/work" \
PATH="$tmp_dir/bin:$PATH" \
    /bin/zsh -f -c '
        source "$MDROLL_FUNCTION"
        cd "$MDROLL_TEST_WORKDIR"
        mdroll README.md
    '

expected_tab="tab create --workspace w-test --cwd $tmp_dir/work --focus"
[ "$(sed -n '1p' "$tmp_dir/herdr-call.log")" = "$expected_tab" ]

expected_pane="pane run w-test:p-test exec $tmp_dir/bin/mdroll-real README.md"
[ "$(sed -n '2p' "$tmp_dir/herdr-call.log")" = "$expected_pane" ]

[ ! -e "$tmp_dir/mdroll-exec.log" ]
