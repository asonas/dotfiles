#!/bin/bash
set -eu

repo_root=$(cd "$(dirname "$0")/.." && pwd)
startup_output=$(ZDOTDIR="$repo_root" /bin/zsh -i -c exit 2>&1)

if printf '%s\n' "$startup_output" | grep -Fq "git: 'wt' is not a git command"; then
    echo "expected interactive zsh startup not to invoke removed git-wt integration" >&2
    exit 1
fi
