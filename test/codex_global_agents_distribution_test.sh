#!/bin/bash
set -eu

test_tmp_root=$(mktemp -d)
trap 'command rm -rf "$test_tmp_root"' EXIT

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

create_posix_installer_fixture() {
    fixture_name="$1"
    test_home="$test_tmp_root/$fixture_name/home"
    test_repo="$test_tmp_root/$fixture_name/repo"

    mkdir -p "$test_home" "$test_repo"
    sed '/^# Codex loads APM-deployed skills directly/,$d' install.sh > "$test_repo/install.sh"
    ln -s "$PWD/bin" "$test_repo/bin"
    ln -s "$PWD/.config" "$test_repo/.config"
    printf '\nexit 0\n' >> "$test_repo/install.sh"
    git init --bare "$test_home/git-dir" >/dev/null
}

run_posix_installer_fixture() {
    HOME="$test_home" GIT_DIR="$test_home/git-dir" PATH="${test_bin:-/usr/bin:/bin}" \
        OSTYPE=unsupported bash "$test_repo/install.sh"
}

create_fake_apm() {
    test_bin="$test_tmp_root/$1/bin:/usr/bin:/bin"
    mkdir -p "${test_bin%%:*}"
    printf '%s\n' \
        '#!/bin/sh' \
        'if [ "$1" = "$APM_FAIL_COMMAND" ]; then' \
        '    exit 17' \
        'fi' \
        'exit 0' > "${test_bin%%:*}/apm"
    chmod +x "${test_bin%%:*}/apm"
}

assert_posix_agents_link() {
    expected="$test_repo/AGENTS.md"
    actual=$(readlink "$test_home/.codex/AGENTS.md")

    if [ "$actual" != "$expected" ]; then
        echo "expected Codex AGENTS.md link to target $expected, got $actual" >&2
        return 1
    fi
}

test_posix_links_global_agents_file() {
    assert_line_count 1 '^codex_agents_source="\$PWD/AGENTS.md"$' install.sh
    assert_line_count 1 '^codex_agents_target="\$HOME/.codex/AGENTS.md"$' install.sh
    assert_line_count 1 '^    ln -sfn "\$codex_agents_source" "\$codex_agents_target"$' install.sh
    assert_line_count 1 '^    echo "warning: \$codex_agents_source not found; skipping Codex global guidance\."$' install.sh
}

test_posix_installs_global_agents_link() {
    create_posix_installer_fixture new-link
    printf 'generated guidance\n' > "$test_repo/AGENTS.md"

    run_posix_installer_fixture >/dev/null

    assert_posix_agents_link
}

test_posix_skips_missing_global_agents_source() {
    create_posix_installer_fixture missing-source

    output=$(run_posix_installer_fixture 2>&1)

    case "$output" in
        *"warning: $test_repo/AGENTS.md not found; skipping Codex global guidance."*) ;;
        *)
            echo "expected missing source warning, got: $output" >&2
            return 1
            ;;
    esac
    if [ -e "$test_home/.codex/AGENTS.md" ] || [ -L "$test_home/.codex/AGENTS.md" ]; then
        echo "expected missing source not to create Codex AGENTS.md" >&2
        return 1
    fi
}

test_posix_replaces_existing_file() {
    create_posix_installer_fixture existing-file
    printf 'generated guidance\n' > "$test_repo/AGENTS.md"
    mkdir -p "$test_home/.codex"
    printf 'old guidance\n' > "$test_home/.codex/AGENTS.md"

    run_posix_installer_fixture >/dev/null

    assert_posix_agents_link
}

test_posix_replaces_existing_symlink() {
    create_posix_installer_fixture existing-symlink
    printf 'generated guidance\n' > "$test_repo/AGENTS.md"
    printf 'old guidance\n' > "$test_home/old-AGENTS.md"
    mkdir -p "$test_home/.codex"
    ln -s "$test_home/old-AGENTS.md" "$test_home/.codex/AGENTS.md"

    run_posix_installer_fixture >/dev/null

    assert_posix_agents_link
}

test_posix_replaces_dangling_symlink() {
    create_posix_installer_fixture dangling-symlink
    printf 'generated guidance\n' > "$test_repo/AGENTS.md"
    mkdir -p "$test_home/.codex"
    ln -s "$test_home/missing-AGENTS.md" "$test_home/.codex/AGENTS.md"

    run_posix_installer_fixture >/dev/null

    assert_posix_agents_link
}

test_posix_fails_when_global_agents_target_is_a_directory() {
    create_posix_installer_fixture real-directory
    touch "$test_repo/AGENTS.md"
    mkdir -p "$test_home/.codex/AGENTS.md"

    if run_posix_installer_fixture >/dev/null 2>&1; then
        echo "expected installation to fail when Codex AGENTS.md target is a directory" >&2
        return 1
    fi
}

test_posix_replaces_directory_symlink() {
    create_posix_installer_fixture directory-symlink
    printf 'generated guidance\n' > "$test_repo/AGENTS.md"
    mkdir -p "$test_home/existing-directory"
    mkdir -p "$test_home/.codex"
    ln -s "$test_home/existing-directory" "$test_home/.codex/AGENTS.md"

    run_posix_installer_fixture >/dev/null

    assert_posix_agents_link
}

test_posix_continues_when_apm_update_fails() {
    create_posix_installer_fixture apm-update-failure
    create_fake_apm apm-update-failure
    printf 'generated guidance\n' > "$test_repo/AGENTS.md"

    APM_FAIL_COMMAND=update run_posix_installer_fixture >/dev/null 2>&1

    assert_posix_agents_link
    unset test_bin
}

test_posix_continues_when_apm_install_fails() {
    create_posix_installer_fixture apm-install-failure
    create_fake_apm apm-install-failure
    printf 'generated guidance\n' > "$test_repo/AGENTS.md"

    APM_FAIL_COMMAND=install run_posix_installer_fixture >/dev/null 2>&1

    assert_posix_agents_link
    unset test_bin
}

test_posix_stops_when_apm_compile_fails() {
    create_posix_installer_fixture apm-compile-failure
    create_fake_apm apm-compile-failure
    printf 'stale guidance\n' > "$test_repo/AGENTS.md"

    if APM_FAIL_COMMAND=compile run_posix_installer_fixture >/dev/null 2>&1; then
        echo "expected apm compile failure to stop before Codex guidance distribution" >&2
        return 1
    fi
    if [ -e "$test_home/.codex/AGENTS.md" ] || [ -L "$test_home/.codex/AGENTS.md" ]; then
        echo "expected apm compile failure not to distribute stale Codex guidance" >&2
        return 1
    fi
    unset test_bin
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
    copy_function="$test_tmp_root/Copy-CodexGlobalAgents.ps1"
    sed -n '/^function Copy-CodexGlobalAgents {/,/^}/p' install.ps1 > "$copy_function"

    assert_line_count 1 '^    \$existing = Get-Item -LiteralPath \$target -Force -ErrorAction SilentlyContinue$' "$copy_function"
    assert_line_count 1 '^        if \(\$existing\.LinkType\) \{ \$existing\.Delete\(\) \}$' "$copy_function"
    assert_line_count 1 '^        elseif \(\$existing\.PSIsContainer\) \{$' "$copy_function"
    assert_line_count 1 '^            throw "\$target is a directory; cannot install Codex global guidance\."$' "$copy_function"
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

test_windows_execution_suite_is_available() {
    windows_test=test/codex_global_agents_distribution_windows_test.ps1

    if [ ! -f "$windows_test" ]; then
        echo "expected Windows execution test suite at $windows_test" >&2
        return 1
    fi
    assert_line_count 1 '^    Test-CopiesToNewTarget$' "$windows_test"
    assert_line_count 1 '^    Test-OverwritesExistingFile$' "$windows_test"
    assert_line_count 1 '^    Test-ReplacesFileSymlinkWithoutChangingLinkTarget$' "$windows_test"
    assert_line_count 1 '^    Test-ReplacesDanglingFileSymlink$' "$windows_test"
    assert_line_count 1 '^    Test-ReplacesDirectorySymlinkWithoutChangingLinkTarget$' "$windows_test"
    assert_line_count 1 '^    Test-RejectsRealDirectory$' "$windows_test"
    assert_line_count 1 '^    Test-SkipsMissingSource$' "$windows_test"

    if command -v pwsh >/dev/null 2>&1; then
        pwsh -NoProfile -File "$windows_test"
    fi
}

test_posix_links_global_agents_file
test_posix_installs_global_agents_link
test_posix_skips_missing_global_agents_source
test_posix_replaces_existing_file
test_posix_replaces_existing_symlink
test_posix_replaces_dangling_symlink
test_posix_fails_when_global_agents_target_is_a_directory
test_posix_replaces_directory_symlink
test_posix_continues_when_apm_update_fails
test_posix_continues_when_apm_install_fails
test_posix_stops_when_apm_compile_fails
test_windows_copies_global_agents_file
test_windows_rejects_directory_global_agents_target
test_windows_apm_targets_include_codex
test_windows_compiles_before_copying
test_windows_stops_when_compile_fails
test_windows_execution_suite_is_available
