#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd)
tmp_dir=$(mktemp -d)
trap 'command rm -rf "$tmp_dir"' EXIT

mkdir -p "$tmp_dir/repo" "$tmp_dir/home"
"$repo_root/bin/link_legacy_dotfiles" "$tmp_dir/repo" "$tmp_dir/home"

[ "$(readlink "$tmp_dir/home/.gitconfig")" = "$tmp_dir/repo/.gitconfig" ]
[ "$(readlink "$tmp_dir/home/.config/starship.toml")" = "$tmp_dir/repo/.config/starship.toml" ]

test_keeps_expected_symlink() {
    case_root="$tmp_dir/keeps-expected-symlink"
    mkdir -p "$case_root/repo" "$case_root/home"
    ln -s "$case_root/repo/.gitconfig" "$case_root/home/.gitconfig"

    "$repo_root/bin/link_legacy_dotfiles" "$case_root/repo" "$case_root/home"

    [ "$(readlink "$case_root/home/.gitconfig")" = "$case_root/repo/.gitconfig" ]
}

test_refuses_existing_file() {
    case_root="$tmp_dir/refuses-existing-file"
    mkdir -p "$case_root/repo" "$case_root/home"
    printf 'user-managed configuration\n' > "$case_root/home/.gitconfig"

    set +e
    output=$("$repo_root/bin/link_legacy_dotfiles" "$case_root/repo" "$case_root/home" 2>&1)
    status=$?
    set -e

    [ "$status" -ne 0 ]
    [ "$(cat "$case_root/home/.gitconfig")" = 'user-managed configuration' ]
    [ ! -e "$case_root/home/.zshrc" ]
    case "$output" in
        *'refusing to replace existing path'*) ;;
        *)
            printf 'unexpected output:\n%s\n' "$output" >&2
            exit 1
            ;;
    esac
}

test_replaces_unrelated_symlink_without_touching_target() {
    case_root="$tmp_dir/replaces-unrelated-symlink"
    mkdir -p "$case_root/repo" "$case_root/home"
    mkdir -p "$case_root/another-checkout"
    printf 'keep this target\n' > "$case_root/another-checkout/.gitconfig"
    ln -s "$case_root/another-checkout/.gitconfig" "$case_root/home/.gitconfig"

    "$repo_root/bin/link_legacy_dotfiles" "$case_root/repo" "$case_root/home" >/dev/null

    [ "$(readlink "$case_root/home/.gitconfig")" = "$case_root/repo/.gitconfig" ]
    [ "$(cat "$case_root/another-checkout/.gitconfig")" = 'keep this target' ]
}

test_keeps_expected_symlink
test_refuses_existing_file
test_replaces_unrelated_symlink_without_touching_target
