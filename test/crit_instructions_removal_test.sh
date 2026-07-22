#!/usr/bin/env bash
set -euo pipefail

repo_root=${CRIT_INSTRUCTIONS_REPO_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}
crit_pattern='crit-open\.sh|# crit（コードレビュー）|Profile 2'

[ ! -e "$repo_root/.apm/instructions/crit.instructions.md" ]

if grep -ERq "$crit_pattern" "$repo_root/.apm/instructions"; then
  echo "expected .apm/instructions to omit crit-specific instructions" >&2
  exit 1
else
  grep_status=$?
  if [ "$grep_status" -gt 1 ]; then
    echo "failed to inspect .apm/instructions" >&2
    exit "$grep_status"
  fi
fi

for generated_file in AGENTS.md CLAUDE.md; do
  if [ ! -r "$repo_root/$generated_file" ]; then
    echo "expected $generated_file to exist and be readable" >&2
    exit 1
  fi

  if grep -Eq "$crit_pattern" "$repo_root/$generated_file"; then
    echo "expected $generated_file to omit crit-specific instructions" >&2
    exit 1
  else
    grep_status=$?
    if [ "$grep_status" -gt 1 ]; then
      echo "failed to inspect $generated_file" >&2
      exit "$grep_status"
    fi
  fi
done
