#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd)
tmp_dir=$(mktemp -d)
trap 'command rm -rf "$tmp_dir"' EXIT

mkdir -p "$tmp_dir/bin"

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
    'case "$1 $2" in' \
    '  "tab list") printf "%s\\n" "$HERDR_TAB_LIST_RESPONSE" ;;' \
    '  "tab create") printf "%s\\n" "$HERDR_TAB_CREATE_RESPONSE" ;;' \
    '  "pane split") printf "%s\\n" "$HERDR_PANE_SPLIT_RESPONSE" ;;' \
    '  "pane run") exit 0 ;;' \
    '  *) echo "unexpected herdr command: $*" >&2; exit 1 ;;' \
    'esac' > "$tmp_dir/bin/herdr"
chmod +x "$tmp_dir/bin/herdr"

printf '%s\n' \
    '#!/bin/sh' \
    'printf "%s\\n" "$*" > "$MISE_MDROLL_EXEC_LOG"' > "$tmp_dir/bin/mdroll-real"
chmod +x "$tmp_dir/bin/mdroll-real"

expected_tab_list="tab list --workspace w-test"

if HERDR_ENV=0 HERDR_WORKSPACE_ID= \
    "$repo_root/bin/mdroll-in-herdr" README.md >/dev/null 2>&1; then
    echo "expected mdroll-in-herdr to refuse non-Herdr environments" >&2
    exit 1
fi

HERDR_ENV=1 \
HERDR_WORKSPACE_ID=w-test \
HERDR_TAB_ID=w-test:t-test \
MISE_MDROLL_BIN="$tmp_dir/bin/mdroll-real" \
MISE_MDROLL_EXEC_LOG="$tmp_dir/mdroll-exec.log" \
PATH="$tmp_dir/bin:$PATH" \
    HERDR_CALL_LOG="$tmp_dir/direct-command-herdr-call.log" \
    HERDR_TAB_LIST_RESPONSE='{"result":{"tabs":[{"tab_id":"w-test:t-test","pane_count":1}]}}' \
    HERDR_PANE_SPLIT_RESPONSE='{"result":{"pane":{"pane_id":"w-test:p-split"}}}' \
    "$repo_root/bin/mdroll-in-herdr" README.md

[ "$(sed -n '1p' "$tmp_dir/direct-command-herdr-call.log")" = "$expected_tab_list" ]
expected_direct_split="pane split --current --direction right --cwd $repo_root --no-focus"
[ "$(sed -n '2p' "$tmp_dir/direct-command-herdr-call.log")" = "$expected_direct_split" ]
expected_split_pane="pane run w-test:p-split exec $tmp_dir/bin/mdroll-real README.md"
[ "$(sed -n '3p' "$tmp_dir/direct-command-herdr-call.log")" = "$expected_split_pane" ]
[ "$(wc -l < "$tmp_dir/direct-command-herdr-call.log")" -eq 3 ]

HERDR_ENV=1 \
HERDR_WORKSPACE_ID=w-test \
HERDR_TAB_ID=w-test:t-test \
MISE_MDROLL_BIN="$tmp_dir/bin/mdroll-real" \
MISE_MDROLL_EXEC_LOG="$tmp_dir/mdroll-exec.log" \
PATH="$tmp_dir/bin:$PATH" \
    HERDR_CALL_LOG="$tmp_dir/multiple-pane-herdr-call.log" \
    HERDR_TAB_LIST_RESPONSE='{"result":{"tabs":[{"tab_id":"w-test:t-test","pane_count":2}]}}' \
    HERDR_TAB_CREATE_RESPONSE='{"result":{"root_pane":{"pane_id":"w-test:p-tab"}}}' \
    "$repo_root/bin/mdroll-in-herdr" docs/README.md

expected_tab="tab create --workspace w-test --cwd $repo_root --label README.md --focus"
[ "$(sed -n '1p' "$tmp_dir/multiple-pane-herdr-call.log")" = "$expected_tab_list" ]
[ "$(sed -n '2p' "$tmp_dir/multiple-pane-herdr-call.log")" = "$expected_tab" ]

expected_tab_pane="pane run w-test:p-tab exec $tmp_dir/bin/mdroll-real docs/README.md"
[ "$(sed -n '3p' "$tmp_dir/multiple-pane-herdr-call.log")" = "$expected_tab_pane" ]
[ "$(wc -l < "$tmp_dir/multiple-pane-herdr-call.log")" -eq 3 ]

[ ! -e "$tmp_dir/mdroll-exec.log" ]
