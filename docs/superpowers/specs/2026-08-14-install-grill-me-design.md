# Install grill-me

## Goal

Manage Matt Pocock's `grill-me` workflow through the existing global APM setup, while retiring the repository's mandatory `git ai-commit` workflow.

## Changes

- Add `mattpocock/skills/skills/productivity/grill-me` to `apm.yml`.
- Add `mattpocock/skills/skills/productivity/grilling` because `grill-me` delegates its implementation to that skill.
- Remove `asonas/skills/commit` from `apm.yml`.
- Remove the global instruction that requires `/commit` and `git ai-commit`.

## Deployment

Use the repository's existing `install.sh` workflow. It compiles the distributed instructions, updates APM dependencies, and deploys skills globally for Claude Code, Cursor, and Codex. No skill-specific installer logic will be added.

## Verification

- Confirm the generated agent instructions no longer require `git ai-commit`.
- Confirm APM resolves and deploys both `grill-me` and `grilling`.
- Confirm the retired `commit` skill is no longer declared or deployed by APM.
- Run the relevant repository tests for APM distribution and bootstrap behavior.
