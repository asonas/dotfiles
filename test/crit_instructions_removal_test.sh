#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd)

[ ! -e "$repo_root/.apm/instructions/crit.instructions.md" ]

for generated_file in AGENTS.md CLAUDE.md; do
  if grep -Eq 'crit-open\.sh|# crit（コードレビュー）|Profile 2' "$repo_root/$generated_file"; then
    echo "expected $generated_file to omit crit-specific instructions" >&2
    exit 1
  fi
done
