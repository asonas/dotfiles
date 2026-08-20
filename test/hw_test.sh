#!/bin/bash
set -eu

repo_root=$(cd "$(dirname "$0")/.." && pwd)
test_root=$(mktemp -d)
trap 'command rm -rf "$test_root"' EXIT

mock_bin="$test_root/bin"
herdr_calls="$test_root/herdr-calls.log"
args_file="$test_root/args"
mkdir -p "$mock_bin"

printf '%s\n' \
    '#!/bin/bash' \
    'set -eu' \
    'case "${1:-}" in' \
    '    pane)' \
    '        case "${2:-}" in' \
    '            current)' \
    '                if [ "${HW_MOCK_NO_PANE:-0}" = "1" ]; then' \
    '                    printf "{}\n"' \
    '                else' \
    '                    printf '\''{"result":{"pane":{"pane_id":"w1:p9"}}}\n'\''' \
    '                fi' \
    '                ;;' \
    '            report-agent) printf "report-agent %s\n" "$*" >> "$HW_HERDR_CALL_LOG" ;;' \
    '            *) exit 1 ;;' \
    '        esac' \
    '        ;;' \
    '    notification)' \
    '        printf "notification %s\n" "$*" >> "$HW_HERDR_CALL_LOG"' \
    '        ;;' \
    '    *) exit 1 ;;' \
    'esac' > "$mock_bin/herdr"
chmod +x "$mock_bin/herdr"

printf '%s\n' \
    '#!/bin/bash' \
    'printf "%s\n" "$@" > "$HW_ARGS_FILE"' > "$mock_bin/capture-args"
chmod +x "$mock_bin/capture-args"

PATH="$mock_bin:$PATH" \
HW_HERDR_CALL_LOG="$herdr_calls" \
HW_ARGS_FILE="$args_file" \
    "$repo_root/bin/hw" "jbt deploy" -- "$mock_bin/capture-args" "a b" "--flag"

printf '%s\n' "a b" "--flag" > "$test_root/expected-args"
cmp -s "$test_root/expected-args" "$args_file"
grep -F -- 'report-agent w1:p9' "$herdr_calls" >/dev/null
grep -F -- '--agent jbt deploy --state working --message 実行中 --seq 1' "$herdr_calls" >/dev/null
grep -F -- '--agent jbt deploy --state idle --message OK' "$herdr_calls" >/dev/null
grep -F -- 'notification show jbt deploy 完了' "$herdr_calls" >/dev/null

printf '%s\n' \
    '#!/bin/bash' \
    'exit 7' > "$mock_bin/fail-command"
chmod +x "$mock_bin/fail-command"

failure_calls="$test_root/failure-calls.log"
set +e
PATH="$mock_bin:$PATH" \
HW_HERDR_CALL_LOG="$failure_calls" \
    "$repo_root/bin/hw" "CI #123" -- "$mock_bin/fail-command"
failure_status=$?
set -e

[ "$failure_status" -eq 7 ]
grep -F -- '--agent CI #123 --state blocked --message FAILED exit=7' "$failure_calls" >/dev/null
grep -F -- 'notification show CI #123 失敗' "$failure_calls" >/dev/null

outside_args="$test_root/outside-args"
outside_calls="$test_root/outside-calls.log"
PATH="$mock_bin:$PATH" \
HW_MOCK_NO_PANE=1 \
HW_HERDR_CALL_LOG="$outside_calls" \
HW_ARGS_FILE="$outside_args" \
    "$repo_root/bin/hw" "local command" -- "$mock_bin/capture-args" "outside"

printf '%s\n' outside > "$test_root/expected-outside-args"
cmp -s "$test_root/expected-outside-args" "$outside_args"
if grep -Fq -- 'report-agent' "$outside_calls" 2>/dev/null; then
    echo "expected Herdr reporting to be skipped outside Herdr" >&2
    exit 1
fi
