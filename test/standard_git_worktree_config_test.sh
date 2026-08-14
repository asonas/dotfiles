#!/bin/bash
set -eu

if grep -q 'github:k1LoW/git-wt' .config/mise/config.toml; then
    echo "expected mise not to install git-wt" >&2
    exit 1
fi

if grep -q 'asonas/skills/git-worktree-workflow' apm.yml; then
    echo "expected APM not to install the git-wt-specific skill" >&2
    exit 1
fi

if grep -Eq 'git wt|/git-worktree-workflow' .apm/instructions/git-workflow.instructions.md; then
    echo "expected Git instructions not to require git-wt" >&2
    exit 1
fi

grep -q 'git worktree add' .apm/instructions/git-workflow.instructions.md
grep -q 'git worktree remove' .apm/instructions/git-workflow.instructions.md
