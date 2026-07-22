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

test_windows_copies_global_agents_file() {
    assert_line_count 1 '^\$CodexDir = Join-Path \$HomeDir '\''.codex'\''$' install.ps1
    assert_line_count 1 '^    Copy-Item -LiteralPath \$source -Destination \$target -Force$' install.ps1
    assert_line_count 1 '^        Write-Warning "\$source not found; skipping Codex global guidance\."$' install.ps1
    assert_line_count 1 '^Copy-CodexGlobalAgents -RepoRoot \$RepoRoot -CodexDir \$CodexDir$' install.ps1

    if grep -Eq '^New-DotLink .*AGENTS\.md' install.ps1; then
        echo 'expected Windows Codex AGENTS.md distribution not to use New-DotLink' >&2
        return 1
    fi
}

test_windows_rejects_directory_global_agents_target() {
    assert_line_count 1 '^    \$existing = Get-Item -LiteralPath \$target -Force -ErrorAction SilentlyContinue$' install.ps1
    assert_line_count 1 '^    if \(\$existing -and \$existing\.PSIsContainer\) \{$' install.ps1
    assert_line_count 1 '^        throw "\$target is a directory; cannot install Codex global guidance\."$' install.ps1
}

test_windows_apm_targets_include_codex() {
    assert_line_count 1 '^        & apm update --yes --target claude,cursor,codex$' install.ps1
    assert_line_count 1 '^        & apm install -g --target claude,cursor,codex$' install.ps1
}

test_windows_compiles_before_copying() {
    compile_line=$(grep -n '^        & apm compile$' install.ps1 | cut -d: -f1)
    copy_line=$(grep -n '^Copy-CodexGlobalAgents -RepoRoot \$RepoRoot -CodexDir \$CodexDir$' install.ps1 | cut -d: -f1)

    if [ -z "$compile_line" ] || [ -z "$copy_line" ] || [ "$compile_line" -ge "$copy_line" ]; then
        echo 'expected Windows apm compile to run before Codex AGENTS.md copy' >&2
        return 1
    fi
}

test_windows_stops_when_compile_fails() {
    compile_line=$(grep -n '^        & apm compile$' install.ps1 | cut -d: -f1)
    exit_check_line=$(grep -n '^        if (\$LASTEXITCODE -ne 0) {$' install.ps1 | cut -d: -f1)

    if [ -z "$compile_line" ] || [ -z "$exit_check_line" ] || [ "$exit_check_line" -ne $((compile_line + 1)) ]; then
        echo 'expected Windows apm compile failure to stop distribution immediately' >&2
        return 1
    fi

    assert_line_count 1 '^            throw "apm compile failed with exit code \$LASTEXITCODE; refusing to distribute stale AGENTS\.md\."$' install.ps1
}

test_posix_links_global_agents_file
test_posix_fails_when_global_agents_target_is_a_directory
test_windows_copies_global_agents_file
test_windows_rejects_directory_global_agents_target
test_windows_apm_targets_include_codex
test_windows_compiles_before_copying
test_windows_stops_when_compile_fails
