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

test_install_targets() {
    assert_line_count 1 '^    \(cd "\$HOME/.apm" && apm update --yes --target claude,cursor,codex\)$' install.sh
    assert_line_count 1 '^    echo "==> apm install -g --target claude,cursor,codex \(deploy skills, agents, commands\)"$' install.sh
    assert_line_count 1 '^    if ! \(cd "\$HOME/.apm" && apm install -g --target claude,cursor,codex\); then$' install.sh
}

test_codex_session_start_hooks_are_removed() {
    assert_line_count 1 '^command rm -f "\$PWD/.codex/hooks.json" "\$HOME/.codex/hooks.json"$' install.sh
    assert_line_count 1 "canonical_cmd='\"\\\$HOME/.claude/hooks/superpowers/hooks/run-hook.cmd\" session-start'" install.sh
}

test_codex_session_start_hook_is_not_tracked() {
    [ ! -e .codex/hooks.json ]
}

test_manifest_targets
test_install_targets
test_codex_session_start_hooks_are_removed
test_codex_session_start_hook_is_not_tracked
