#!/bin/bash
set -eu

repo_root=$(cd "$(dirname "$0")/.." && pwd)
config="$repo_root/.config/git-ai-commit/config.toml"
install_script="$repo_root/install.sh"

assert_contains() {
    pattern="$1"
    file="$2"

    if ! grep -Fq -- "$pattern" "$file"; then
        echo "expected $file to contain: $pattern" >&2
        return 1
    fi
}

test_configures_codex_terra_engine() {
    assert_contains 'engine = "codex"' "$config"
    assert_contains 'args = ["exec", "--model", "gpt-5.6-terra", "--ephemeral", "-"]' "$config"
}

test_install_script_manages_config() {
    assert_contains '.config/git-ai-commit/config.toml' "$install_script"
}

test_configures_codex_terra_engine
test_install_script_manages_config
