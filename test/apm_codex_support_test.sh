#!/bin/bash
set -eu

assert_line_count() {
    expected="$1"
    pattern="$2"
    file="$3"
    actual=$(grep -Ec -- "$pattern" "$file" || true)

    if [ "$actual" -ne "$expected" ]; then
        echo "expected $file to contain $pattern $expected time(s), got $actual" >&2
        return 1
    fi
}

test_manifest_targets() {
    assert_line_count 1 '^  - claude$' apm.yml
    assert_line_count 1 '^  - cursor$' apm.yml
    assert_line_count 1 '^  - codex$' apm.yml
}

test_claude_session_start_normalization_drops_superpowers() {
    assert_line_count 0 'run-hook.cmd' .claude/settings.json
}

test_codex_session_start_hook_is_not_tracked() {
    [ ! -e .codex/hooks.json ]
}

test_manifest_targets
test_claude_session_start_normalization_drops_superpowers
test_codex_session_start_hook_is_not_tracked
