# Install grill-me Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Install the complete `grill-me` workflow through APM and retire the mandatory `git ai-commit` workflow.

**Architecture:** Declare both the user-facing `grill-me` skill and its `grilling` implementation as focused APM subpath dependencies. Remove the obsolete commit skill dependency and its generated global instruction, then use the existing bootstrap workflow to compile and deploy the new state globally.

**Tech Stack:** YAML, Markdown instructions, Ruby standard library, Minitest, APM 0.28.0, shell verification

## Global Constraints

- Manage skills through `apm.yml`; do not add skill-specific download logic to `install.sh`.
- Install both `grill-me` and `grilling`.
- Remove both `asonas/skills/commit` and the instruction requiring `/commit` or `git ai-commit`.
- Preserve the user's existing `.claude/settings.json` change in the main checkout.

---

### Task 1: Update and deploy the global skill set

**Files:**
- Modify: `test/apm_skill_subset_test.rb`
- Modify: `apm.yml`
- Modify: `.apm/instructions/base.instructions.md`
- Create: `docs/superpowers/plans/2026-08-14-install-grill-me.md`

**Interfaces:**
- Consumes: APM subpath dependency entries and compiled global instructions.
- Produces: Globally deployed `grill-me` and `grilling` skills with no APM-managed `commit` skill or mandatory `git ai-commit` instruction.

- [ ] **Step 1: Write the failing manifest contract tests**

Add constants for both Matt Pocock skill paths and `asonas/skills/commit`. Add one test asserting both new paths are present exactly once and another asserting the retired dependency and instruction text are absent.

- [ ] **Step 2: Run the focused test to verify RED**

Run: `mise exec -- ruby test/apm_skill_subset_test.rb`

Expected: FAIL because the new dependencies are absent and the retired commit dependency/instruction remain.

- [ ] **Step 3: Apply the minimal configuration changes**

Add these dependencies to `apm.yml`:

```yaml
    - mattpocock/skills/skills/productivity/grill-me
    - mattpocock/skills/skills/productivity/grilling
```

Remove `asonas/skills/commit` and remove the single global instruction that mandates `/commit` and `git ai-commit`.

- [ ] **Step 4: Run focused and repository tests**

Run:

```bash
mise exec -- ruby test/apm_skill_subset_test.rb
for test_file in test/*_test.sh; do bash "$test_file"; done
bash -n install.sh
git diff --check
```

Expected: all commands exit 0 without warnings attributable to this change.

- [ ] **Step 5: Integrate the worktree before global deployment**

Complete the feature branch and integrate it into the main checkout before running the bootstrap. Running `install.sh` from a linked worktree would repoint home-directory dotfile symlinks at that temporary worktree.

Expected: the main checkout contains the tested manifest and instruction changes.

- [ ] **Step 6: Deploy from the main checkout and verify**

Run `sh install.sh` from the main checkout. APM compiles instructions, updates dependencies, and installs globally for Claude Code, Cursor, and Codex.

Verify that `~/.agents/skills/grill-me/SKILL.md` and `~/.agents/skills/grilling/SKILL.md` exist, `~/.agents/skills/commit` is absent, and generated global instructions contain no `git ai-commit` requirement.
