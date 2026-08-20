#!/bin/bash
set -eu

test_tmp_root=$(mktemp -d)
trap 'command rm -rf "$test_tmp_root"' EXIT

create_posix_installer_fixture() {
    fixture_name="$1"
    test_home="$test_tmp_root/$fixture_name/home"
    test_repo="$test_tmp_root/$fixture_name/repo"
    test_bin="$test_tmp_root/$fixture_name/bin:/usr/bin:/bin"

    mkdir -p "$test_home" "$test_repo" "${test_bin%%:*}"
    ln -s "$PWD/test/fixtures/fake_git_worktree" "${test_bin%%:*}/git"
    sed '/^"\$PWD\/bin\/install_apm_environment"$/,$d' install.sh > "$test_repo/install.sh"
    ln -s "$PWD/bin" "$test_repo/bin"
    ln -s "$PWD/.config" "$test_repo/.config"
    ln -s "$PWD/.gnupg" "$test_repo/.gnupg"
    printf '%s\n' \
        '"$PWD/bin/install_apm_environment"' \
        'exit 0' >> "$test_repo/install.sh"
}

run_posix_installer_fixture() {
    HOME="$test_home" \
        FAKE_CURRENT_ROOT="$test_repo" \
        FAKE_MAIN_ROOT="$test_repo" \
        PATH="${test_bin:-/usr/bin:/bin}" \
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

test_posix_refuses_existing_file() {
    create_posix_installer_fixture existing-file
    printf 'generated guidance\n' > "$test_repo/AGENTS.md"
    mkdir -p "$test_home/.codex"
    printf 'old guidance\n' > "$test_home/.codex/AGENTS.md"

    if run_posix_installer_fixture >/dev/null 2>&1; then
        echo "expected installation to refuse an existing Codex AGENTS.md file" >&2
        return 1
    fi

    [ "$(cat "$test_home/.codex/AGENTS.md")" = 'old guidance' ]
}

test_posix_replaces_existing_symlink_without_changing_target() {
    create_posix_installer_fixture existing-symlink
    printf 'generated guidance\n' > "$test_repo/AGENTS.md"
    printf 'old guidance\n' > "$test_home/old-AGENTS.md"
    mkdir -p "$test_home/.codex"
    ln -s "$test_home/old-AGENTS.md" "$test_home/.codex/AGENTS.md"

    run_posix_installer_fixture >/dev/null

    assert_posix_agents_link
    [ "$(cat "$test_home/old-AGENTS.md")" = 'old guidance' ]
}

test_posix_replaces_dangling_symlink() {
    create_posix_installer_fixture dangling-symlink
    printf 'generated guidance\n' > "$test_repo/AGENTS.md"
    mkdir -p "$test_home/.codex"
    ln -s "$test_home/missing-AGENTS.md" "$test_home/.codex/AGENTS.md"

    run_posix_installer_fixture >/dev/null

    assert_posix_agents_link
    [ ! -e "$test_home/missing-AGENTS.md" ]
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

test_posix_replaces_directory_symlink_without_changing_target() {
    create_posix_installer_fixture directory-symlink
    printf 'generated guidance\n' > "$test_repo/AGENTS.md"
    mkdir -p "$test_home/existing-directory"
    printf 'keep directory target\n' > "$test_home/existing-directory/sentinel.txt"
    mkdir -p "$test_home/.codex"
    ln -s "$test_home/existing-directory" "$test_home/.codex/AGENTS.md"

    run_posix_installer_fixture >/dev/null

    assert_posix_agents_link
    [ "$(cat "$test_home/existing-directory/sentinel.txt")" = 'keep directory target' ]
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

write_skill() {
    mkdir -p "$1"
    printf '%s\n' \
        '---' \
        "name: $(basename "$1")" \
        "description: $2" \
        '---' \
        '' \
        "$2" > "$1/SKILL.md"
}

test_posix_removes_only_duplicated_project_skills() {
    create_posix_installer_fixture project-skill-mirror
    create_fake_apm project-skill-mirror
    printf 'generated guidance\n' > "$test_repo/AGENTS.md"
    write_skill "$test_repo/.agents/skills/brainstorming" "shared body"
    write_skill "$test_home/.agents/skills/brainstorming" "shared body"
    write_skill "$test_repo/.agents/skills/project-only" "project body"

    run_posix_installer_fixture >/dev/null

    if [ -e "$test_repo/.agents/skills/brainstorming" ]; then
        echo "expected duplicated project Skill to be removed" >&2
        return 1
    fi
    if [ ! -d "$test_repo/.agents/skills/project-only" ]; then
        echo "expected project-only Skill to remain available" >&2
        return 1
    fi
    unset test_bin
}

test_posix_keeps_project_skill_when_contents_differ() {
    create_posix_installer_fixture project-skill-divergent
    create_fake_apm project-skill-divergent
    printf 'generated guidance\n' > "$test_repo/AGENTS.md"
    write_skill "$test_repo/.agents/skills/brainstorming" "newer project body"
    write_skill "$test_home/.agents/skills/brainstorming" "older global body"

    output=$(run_posix_installer_fixture 2>&1)

    if [ ! -f "$test_repo/.agents/skills/brainstorming/SKILL.md" ]; then
        echo "expected a diverging project Skill to be kept" >&2
        return 1
    fi
    case "$output" in
        *"keeping project-local Codex Skill 'brainstorming'"*) ;;
        *)
            echo "expected a warning about the diverging Skill, got: $output" >&2
            return 1
            ;;
    esac
    unset test_bin
}

# A partial 'apm install' can leave a global entry that exists by name but holds
# nothing usable. Matching on the name alone would delete the only good copy.
test_posix_keeps_project_skill_when_global_copy_is_unusable() {
    create_posix_installer_fixture project-skill-unusable-global
    create_fake_apm project-skill-unusable-global
    printf 'generated guidance\n' > "$test_repo/AGENTS.md"
    write_skill "$test_repo/.agents/skills/empty-global" "project body"
    write_skill "$test_repo/.agents/skills/dangling-global" "project body"
    mkdir -p "$test_home/.agents/skills/empty-global"
    ln -s "$test_tmp_root/does-not-exist" "$test_home/.agents/skills/dangling-global"

    run_posix_installer_fixture >/dev/null

    for unusable_skill in empty-global dangling-global
    do
        if [ ! -f "$test_repo/.agents/skills/$unusable_skill/SKILL.md" ]; then
            echo "expected project Skill '$unusable_skill' to survive an unusable global copy" >&2
            return 1
        fi
    done
    unset test_bin
}

test_posix_keeps_project_skills_when_apm_install_fails() {
    create_posix_installer_fixture project-skill-install-failure
    create_fake_apm project-skill-install-failure
    printf 'generated guidance\n' > "$test_repo/AGENTS.md"
    write_skill "$test_repo/.agents/skills/brainstorming" "shared body"
    write_skill "$test_home/.agents/skills/brainstorming" "shared body"

    APM_FAIL_COMMAND=install run_posix_installer_fixture >/dev/null

    if [ ! -f "$test_repo/.agents/skills/brainstorming/SKILL.md" ]; then
        echo "expected a failed apm install to leave project Skills alone" >&2
        return 1
    fi
    unset test_bin
}

test_posix_installs_global_agents_link
test_posix_skips_missing_global_agents_source
test_posix_refuses_existing_file
test_posix_replaces_existing_symlink_without_changing_target
test_posix_replaces_dangling_symlink
test_posix_fails_when_global_agents_target_is_a_directory
test_posix_replaces_directory_symlink_without_changing_target
test_posix_continues_when_apm_update_fails
test_posix_continues_when_apm_install_fails
test_posix_stops_when_apm_compile_fails
test_posix_removes_only_duplicated_project_skills
test_posix_keeps_project_skill_when_contents_differ
test_posix_keeps_project_skill_when_global_copy_is_unusable
test_posix_keeps_project_skills_when_apm_install_fails

if command -v pwsh >/dev/null 2>&1; then
    pwsh -NoProfile -File test/codex_global_agents_distribution_windows_test.ps1
fi
