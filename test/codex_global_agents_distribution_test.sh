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

test_posix_fails_when_global_agents_target_is_a_directory() {
    test_home=$(mktemp -d)
    test_repo=$(mktemp -d)
    trap 'command rm -rf "$test_home" "$test_repo"' EXIT

    sed '/^# Codex loads APM-deployed skills directly/,$d' install.sh > "$test_repo/install.sh"
    ln -s "$PWD/bin" "$test_repo/bin"
    ln -s "$PWD/.config" "$test_repo/.config"
    touch "$test_repo/AGENTS.md"
    printf '\nexit 0\n' >> "$test_repo/install.sh"
    mkdir -p "$test_home/.codex/AGENTS.md"
    git init --bare "$test_home/git-dir" >/dev/null

    if HOME="$test_home" GIT_DIR="$test_home/git-dir" PATH=/usr/bin:/bin \
        OSTYPE=unsupported bash "$test_repo/install.sh" >/dev/null 2>&1; then
        echo "expected installation to fail when Codex AGENTS.md target is a directory" >&2
        return 1
    fi
}

test_posix_links_global_agents_file
test_posix_fails_when_global_agents_target_is_a_directory
