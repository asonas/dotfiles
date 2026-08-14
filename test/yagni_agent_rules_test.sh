#!/bin/sh
set -eu

base=.apm/instructions/base.instructions.md
skill=.claude/user-skills/tidy-first-conventions/SKILL.md

grep -q '^# Scope and YAGNI$' "$base"
grep -q '^# Testing Scope$' "$base"
grep -q '/tidy-first-conventions' "$base"
grep -q '全テストは、影響範囲が広い場合、またはリポジトリやCIが要求する場合に実行する' "$base"
if grep -q '/tdd-conventions' "$base"; then
    echo 'obsolete tdd-conventions reference remains in base instructions' >&2
    exit 1
fi

test -f "$skill"
grep -q '^name: tidy-first-conventions$' "$skill"
grep -q '^description: Use when ' "$skill"
grep -q '`test-driven-development` skill' "$skill"
grep -q 'Only apply commit rules when the user asks for commits.' "$skill"
if grep -Eq 'Always follow the TDD cycle|Always run all the tests' "$skill"; then
    echo 'TDD workflow leaked into tidy-first-conventions' >&2
    exit 1
fi
if test -e .claude/user-skills/tdd-conventions; then
    echo 'obsolete tdd-conventions skill remains' >&2
    exit 1
fi

echo 'PASS: YAGNI instructions and Tidy First skill contract'
