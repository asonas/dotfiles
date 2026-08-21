---
description: Safety boundaries for installer execution and verification.
---

# Installer Safety

- Treat `install.sh` as a user-environment mutation, not as a normal build or test command.
- Never run `install.sh` from a linked Git worktree, including any directory under `.worktrees/`. The installer can change files and symlinks outside the checkout, and a worktree is not the canonical installation context.
- Do not run `install.sh` automatically after editing files, during ordinary tests, or merely to regenerate generated agent instructions.
- If installation is explicitly requested, first verify that the current directory is the canonical main worktree and that the user has authorized the environment changes. Otherwise, do not run it.
- Regenerate generated agent instructions with `apm compile --clean`; do not use `install.sh` as a compilation or documentation-generation step.
- In a worktree, validate installer behavior through helper scripts and temporary fixture roots. Do not use the real home directory or existing user symlinks for routine tests.
- Test installer behavior at the process boundary: verify exit status, relevant stdout and stderr, files, symlinks, permissions, and idempotence. Replace external commands only at external process boundaries.
