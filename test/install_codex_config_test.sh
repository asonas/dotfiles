#!/bin/bash
set -eu

repo_root=$(cd "$(dirname "$0")/.." && pwd)
installer="$repo_root/bin/install_codex_config"
managed_config="$repo_root/.config/codex/config.toml"
test_root=$(mktemp -d)
trap 'command rm -rf "$test_root"' EXIT

assert_contains() {
    pattern="$1"
    file="$2"

    if ! grep -Fq -- "$pattern" "$file"; then
        echo "expected $file to contain: $pattern" >&2
        return 1
    fi
}

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

test_preserves_existing_codex_state() {
    config="$test_root/preserves-state.toml"
    printf '%s\n' \
        '[projects."/work/project"]' \
        'trust_level = "trusted"' \
        '' \
        '[hooks.state]' \
        'trusted_hash = "sha256:example"' > "$config"

    "$installer" "$managed_config" "$config"

    assert_contains 'sandbox_mode = "workspace-write"' "$config"
    assert_contains 'approval_policy = "on-request"' "$config"
    assert_contains '[projects."/work/project"]' "$config"
    assert_contains 'trust_level = "trusted"' "$config"
    assert_contains '[hooks.state]' "$config"
    assert_contains 'trusted_hash = "sha256:example"' "$config"
}

test_updates_existing_managed_values() {
    config="$test_root/updates-values.toml"
    printf '%s\n' \
        'sandbox_mode = "read-only"' \
        'approval_policy = "never"' \
        '' \
        '[projects."/work/project"]' \
        'trust_level = "trusted"' > "$config"

    "$installer" "$managed_config" "$config"

    assert_line_count 1 '^sandbox_mode = "workspace-write"$' "$config"
    assert_line_count 1 '^approval_policy = "on-request"$' "$config"
    assert_line_count 0 '^sandbox_mode = "read-only"$' "$config"
    assert_line_count 0 '^approval_policy = "never"$' "$config"
}

test_preserves_other_tui_settings() {
    config="$test_root/preserves-tui.toml"
    printf '%s\n' \
        '[tui]' \
        'animations = false' \
        'status_line = ["current-dir"]' \
        '' \
        '[projects."/work/project"]' \
        'trust_level = "trusted"' > "$config"

    "$installer" "$managed_config" "$config"

    assert_line_count 1 '^\[tui\]$' "$config"
    assert_contains 'animations = false' "$config"
    assert_contains 'status_line = ["model-with-reasoning", "context-remaining", "five-hour-limit", "weekly-limit", "git-branch"]' "$config"
    assert_line_count 0 '^status_line = \["current-dir"\]$' "$config"
    assert_contains '[projects."/work/project"]' "$config"
}

test_is_idempotent() {
    config="$test_root/idempotent.toml"
    first_result="$test_root/idempotent-first.toml"
    printf '%s\n' \
        '[projects."/work/project"]' \
        'trust_level = "trusted"' > "$config"

    "$installer" "$managed_config" "$config"
    command cp "$config" "$first_result"
    "$installer" "$managed_config" "$config"

    if ! cmp -s "$first_result" "$config"; then
        echo "expected repeated installation to leave $config unchanged" >&2
        return 1
    fi
    assert_line_count 1 '^sandbox_mode = ' "$config"
    assert_line_count 1 '^approval_policy = ' "$config"
}

file_mode() {
    file="$1"
    stat -c '%a' "$file" 2>/dev/null || stat -f '%Lp' "$file"
}

test_creates_missing_user_config() {
    config="$test_root/new-config.toml"

    "$installer" "$managed_config" "$config"

    assert_line_count 1 '^sandbox_mode = "workspace-write"$' "$config"
    assert_line_count 1 '^approval_policy = "on-request"$' "$config"
    if [ "$(file_mode "$config")" != "600" ]; then
        echo "expected $config to have mode 600" >&2
        return 1
    fi
}

test_install_script_deploys_managed_config() {
    install_script="$repo_root/install.sh"

    assert_line_count 1 '^"\$PWD/bin/install_codex_config" \\$' "$install_script"
    assert_line_count 1 '^    "\$PWD/.config/codex/config.toml" \\$' "$install_script"
    assert_line_count 1 '^    "\$HOME/.codex/config.toml"$' "$install_script"
}

test_managed_config_shows_usage_in_status_line() {
    assert_contains '[tui]' "$managed_config"
    assert_contains 'status_line = ["model-with-reasoning", "context-remaining", "five-hour-limit", "weekly-limit", "git-branch"]' "$managed_config"
}

test_managed_config_uses_low_model_verbosity() {
    assert_contains 'model_verbosity = "low"' "$managed_config"
}

test_preserves_existing_codex_state
test_updates_existing_managed_values
test_preserves_other_tui_settings
test_is_idempotent
test_creates_missing_user_config
test_install_script_deploys_managed_config
test_managed_config_shows_usage_in_status_line
test_managed_config_uses_low_model_verbosity
