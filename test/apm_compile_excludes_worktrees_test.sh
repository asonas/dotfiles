#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd)
fixture="$repo_root/.worktrees/apm-exclude-test/.apm/instructions"
trap 'command rm -rf "$repo_root/.worktrees/apm-exclude-test"' EXIT

mkdir -p "$fixture"
printf '%s\n' '# APM worktree exclusion test marker' > "$fixture/marker.instructions.md"

compile_output=$(apm compile --dry-run 2>&1)

if grep -Fq '.worktrees/apm-exclude-test/.apm/instructions/marker.instructions.md' <<< "$compile_output"; then
  echo "expected apm compile to exclude .worktrees" >&2
  exit 1
fi
