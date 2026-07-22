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

test_posix_links_global_agents_file() {
    assert_line_count 1 '^codex_agents_source="\$PWD/AGENTS.md"$' install.sh
    assert_line_count 1 '^codex_agents_target="\$HOME/.codex/AGENTS.md"$' install.sh
    assert_line_count 1 '^    ln -sfn "\$codex_agents_source" "\$codex_agents_target"$' install.sh
    assert_line_count 1 '^    echo "warning: \$codex_agents_source not found; skipping Codex global guidance\."$' install.sh
}

test_posix_links_global_agents_file
