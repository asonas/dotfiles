#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd)
tmp_dir=$(mktemp -d)
trap 'command rm -rf "$tmp_dir"' EXIT

mkdir -p "$tmp_dir/bin" "$tmp_dir/main" "$tmp_dir/linked"
ln -s "$repo_root/test/fixtures/fake_git_worktree" "$tmp_dir/bin/git"

run_guard() {
    PATH="$tmp_dir/bin:$PATH" \
        FAKE_CURRENT_ROOT="$1" \
        FAKE_MAIN_ROOT="$tmp_dir/main" \
        "$repo_root/bin/ensure_main_worktree"
}

run_guard "$tmp_dir/main"

set +e
output=$(run_guard "$tmp_dir/linked" 2>&1)
status=$?
set -e

[ "$status" -ne 0 ]
case "$output" in
    *'must be run from the main worktree'*) ;;
    *)
        printf 'unexpected guard output:\n%s\n' "$output" >&2
        exit 1
        ;;
esac

set +e
output=$(
    PATH="$tmp_dir/bin:$PATH" \
        FAKE_CURRENT_ROOT="$tmp_dir/linked" \
        FAKE_MAIN_ROOT="$tmp_dir/main" \
        HOME="$tmp_dir/home" \
        "$repo_root/install.sh" 2>&1
)
status=$?
set -e

[ "$status" -ne 0 ]
[ ! -e "$tmp_dir/home/.gitconfig" ]
