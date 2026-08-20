#!/bin/bash
set -eu

repo_root=$(cd "$(dirname "$0")/.." && pwd)
config="$repo_root/.gnupg/gpg-agent.conf"
installer="$repo_root/bin/install_gpg_agent_config"
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

test_configures_passphrase_cache() {
    assert_contains 'default-cache-ttl 28800' "$config"
    assert_contains 'max-cache-ttl 86400' "$config"
}

test_preserves_existing_agent_options() {
    target="$test_root/gpg-agent.conf"
    printf '%s\n' \
        'pinentry-program /opt/homebrew/opt/pinentry-touchid/bin/pinentry-touchid' \
        'default-cache-ttl 60' \
        'max-cache-ttl 120' > "$target"

    "$installer" "$config" "$target"

    assert_contains 'pinentry-program /opt/homebrew/opt/pinentry-touchid/bin/pinentry-touchid' "$target"
    assert_contains 'default-cache-ttl 28800' "$target"
    assert_contains 'max-cache-ttl 86400' "$target"

    if grep -Fq -- 'default-cache-ttl 60' "$target" || grep -Fq -- 'max-cache-ttl 120' "$target"; then
        echo "expected stale cache settings to be replaced" >&2
        return 1
    fi
}

test_installation_is_idempotent() {
    target="$test_root/idempotent.conf"
    first_result="$test_root/first-result.conf"
    printf '%s\n' 'pinentry-program /usr/bin/pinentry' > "$target"

    "$installer" "$config" "$target"
    command cp "$target" "$first_result"
    "$installer" "$config" "$target"

    if ! cmp -s "$first_result" "$target"; then
        echo "expected repeated installation to leave the config unchanged" >&2
        return 1
    fi
}

test_preserves_existing_symlink() {
    target="$test_root/symlink-target.conf"
    link="$test_root/symlink.conf"
    printf '%s\n' 'pinentry-program /usr/bin/pinentry' > "$target"
    ln -s "$target" "$link"

    "$installer" "$config" "$link"

    [ -L "$link" ]
    assert_contains 'default-cache-ttl 28800' "$target"
    assert_contains 'max-cache-ttl 86400' "$target"
}

test_configures_passphrase_cache
test_preserves_existing_agent_options
test_installation_is_idempotent
test_preserves_existing_symlink
