#!/bin/bash
set -eu

repo_root=$(cd "$(dirname "$0")/.." && pwd)
pruner="$repo_root/bin/prune_stale_apm_paths"
test_root=$(mktemp -d)
trap 'command rm -rf "$test_root"' EXIT

assert_missing() {
    path="$1"

    if [ -L "$path" ] || [ -e "$path" ]; then
        echo "expected $path to be pruned" >&2
        return 1
    fi
}

assert_exists() {
    path="$1"

    if [ ! -e "$path" ]; then
        echo "expected $path to remain" >&2
        return 1
    fi
}

assert_symlink() {
    path="$1"

    if [ ! -L "$path" ]; then
        echo "expected $path to remain a symlink" >&2
        return 1
    fi
}

test_prunes_listed_real_paths() {
    case_root="$test_root/prunes-listed"
    mkdir -p "$case_root/skills/brainstorming" "$case_root/skills/writing-plans"
    : > "$case_root/skills/brainstorming/SKILL.md"
    : > "$case_root/skills/writing-plans/SKILL.md"

    "$pruner" "$case_root/skills" brainstorming writing-plans

    assert_missing "$case_root/skills/brainstorming"
    assert_missing "$case_root/skills/writing-plans"
}

test_keeps_unlisted_real_paths() {
    case_root="$test_root/keeps-unlisted"
    mkdir -p "$case_root/skills/keep-me"
    : > "$case_root/skills/keep-me/SKILL.md"

    "$pruner" "$case_root/skills" brainstorming

    assert_exists "$case_root/skills/keep-me"
}

test_keeps_symlinked_paths() {
    case_root="$test_root/keeps-symlink"
    mkdir -p "$case_root/skills-source"
    ln -s "$case_root/skills-source" "$case_root/skills"

    "$pruner" "$case_root" skills

    assert_symlink "$case_root/skills"
}

test_tolerates_missing_directory() {
    "$pruner" "$test_root/does-not-exist" brainstorming
}

test_prunes_listed_real_paths
test_keeps_unlisted_real_paths
test_keeps_symlinked_paths
test_tolerates_missing_directory
