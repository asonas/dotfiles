#!/bin/bash
set -eu

repo_root=$(cd "$(dirname "$0")/.." && pwd)
fixer="$repo_root/bin/fix_codex_agent_description"
test_root=$(mktemp -d)
trap 'command rm -rf "$test_root"' EXIT

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

test_fixes_blank_security_reviewer_description() {
    agent_file="$test_root/blank-description.toml"
    printf '%s\n' \
        'name = "security-reviewer"' \
        'description = ""' \
        'developer_instructions = "Review code."' > "$agent_file"

    "$fixer" "$agent_file"

    assert_line_count 1 '^description = "Reviews code changes for security vulnerabilities and reports findings\."$' "$agent_file"
    assert_line_count 0 '^description = ""$' "$agent_file"
}

file_inode() {
    file="$1"
    stat -c '%i' "$file" 2>/dev/null || stat -f '%i' "$file"
}

test_preserves_non_blank_description() {
    agent_file="$test_root/non-blank-description.toml"
    original_file="$test_root/non-blank-description-original.toml"
    printf '%s\n' \
        'name = "security-reviewer"' \
        'description = "Upstream description."' \
        'developer_instructions = "Review code."' > "$agent_file"
    command cp "$agent_file" "$original_file"
    original_inode=$(file_inode "$agent_file")

    "$fixer" "$agent_file"

    if ! cmp -s "$original_file" "$agent_file"; then
        echo "expected $agent_file content to remain unchanged" >&2
        return 1
    fi
    if [ "$(file_inode "$agent_file")" != "$original_inode" ]; then
        echo "expected $agent_file not to be replaced" >&2
        return 1
    fi
}

test_ignores_missing_file() {
    agent_file="$test_root/missing.toml"
    error_file="$test_root/missing-error.txt"

    "$fixer" "$agent_file" 2> "$error_file"

    if [ -e "$agent_file" ]; then
        echo "expected $agent_file not to be created" >&2
        return 1
    fi
    if [ -s "$error_file" ]; then
        echo "expected missing file to produce no error output" >&2
        return 1
    fi
}

test_install_script_fixes_project_and_user_roles_after_apm() {
    install_script="$repo_root/install.sh"
    apm_install_line=$(grep -n 'apm install -g --target claude,cursor,codex' "$install_script" | tail -1 | cut -d: -f1)
    project_fix_line=$(grep -n '^"\$PWD/bin/fix_codex_agent_description" "\$PWD/.codex/agents/security-reviewer.toml"$' "$install_script" | cut -d: -f1)
    user_fix_line=$(grep -n '^"\$PWD/bin/fix_codex_agent_description" "\$HOME/.codex/agents/security-reviewer.toml"$' "$install_script" | cut -d: -f1)

    if [ -z "$project_fix_line" ] || [ -z "$user_fix_line" ]; then
        echo "expected install.sh to fix project and user security-reviewer roles" >&2
        return 1
    fi
    if [ "$project_fix_line" -le "$apm_install_line" ] || [ "$user_fix_line" -le "$apm_install_line" ]; then
        echo "expected role fixes to run after APM installation" >&2
        return 1
    fi
}

test_fixes_blank_security_reviewer_description
test_preserves_non_blank_description
test_ignores_missing_file
test_install_script_fixes_project_and_user_roles_after_apm
