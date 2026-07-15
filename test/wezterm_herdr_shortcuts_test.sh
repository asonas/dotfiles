#!/bin/bash
set -eu

repo_root=$(cd "$(dirname "$0")/.." && pwd)
config="$repo_root/.config/wezterm/wezterm.lua"

assert_contains() {
    pattern="$1"

    if ! grep -Fq -- "$pattern" "$config"; then
        echo "expected $config to contain: $pattern" >&2
        return 1
    fi
}

assert_contains '{ key = "j", mods = "CMD|SHIFT", action = herdr_prefix_key("o") },'
assert_contains '{ key = "k", mods = "CMD|SHIFT", action = herdr_prefix_key("u") },'
assert_contains '{ key = "n", mods = "CMD|SHIFT", action = herdr_prefix_key("t") },'
assert_contains '{ key = "u", mods = "CMD|SHIFT", action = herdr_prefix_key("g") },'

luac -p "$config"
