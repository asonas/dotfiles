#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd)
checker="$repo_root/test/crit_instructions_removal_test.sh"
fixture=$(mktemp -d)
trap 'command rm -rf "$fixture"' EXIT

mkdir -p "$fixture/.apm/instructions"

if CRIT_INSTRUCTIONS_REPO_ROOT="$fixture" bash "$checker"; then
  echo "expected missing generated files to fail" >&2
  exit 1
fi

: > "$fixture/AGENTS.md"
: > "$fixture/CLAUDE.md"
printf '%s\n' '# crit（コードレビュー）' > "$fixture/.apm/instructions/reintroduced.instructions.md"

if CRIT_INSTRUCTIONS_REPO_ROOT="$fixture" bash "$checker"; then
  echo "expected renamed crit instructions to fail" >&2
  exit 1
fi
