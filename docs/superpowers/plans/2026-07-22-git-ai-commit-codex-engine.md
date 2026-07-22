# git-ai-commit Codex Engine Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Configure git-ai-commit to use Codex with `gpt-5.6-terra` for ephemeral commit-message generation.

**Architecture:** Track the git-ai-commit TOML configuration in the dotfiles repository and symlink it into the user configuration directory through the existing `install.sh` path loop. Shell tests define the expected configuration and installation behavior.

**Tech Stack:** TOML, Bash

## Global Constraints

- Use the Codex engine with `gpt-5.6-terra`.
- Run Codex with `--ephemeral` and read the prompt from standard input.
- Preserve the existing dotfiles installation pattern.
- Follow Red-Green-Refactor one test at a time.

---

### Task 1: Manage the git-ai-commit Codex configuration

**Files:**
- Create: `.config/git-ai-commit/config.toml`
- Modify: `install.sh`
- Create: `test/git_ai_commit_config_test.sh`

**Interfaces:**
- Consumes: git-ai-commit's `engine` and `engines.codex.args` TOML settings.
- Produces: `~/.config/git-ai-commit/config.toml` as a symlink managed by `install.sh`.

- [x] **Step 1: Write the failing configuration test**

```bash
assert_contains 'engine = "codex"' "$config"
assert_contains 'args = ["exec", "--model", "gpt-5.6-terra", "--ephemeral", "-"]' "$config"
assert_contains '.config/git-ai-commit/config.toml' "$install_script"
```

- [x] **Step 2: Run the test to verify it fails**

Run: `bash test/git_ai_commit_config_test.sh`

Expected: FAIL because `.config/git-ai-commit/config.toml` does not exist.

- [x] **Step 3: Add the minimal managed configuration**

```toml
engine = "codex"

[engines.codex]
args = ["exec", "--model", "gpt-5.6-terra", "--ephemeral", "-"]
```

Add `.config/git-ai-commit/config.toml` to the `required_dirs` list in `install.sh`.

- [x] **Step 4: Run the targeted and full test suites**

Run: `bash test/git_ai_commit_config_test.sh`

Expected: PASS.

Run: `for test_file in test/*_test.sh; do bash "$test_file" || exit 1; done`

Expected: all tests exit successfully.

- [x] **Step 5: Install and use the configuration**

Create `~/.config/git-ai-commit` and link its `config.toml` to the tracked configuration without running unrelated installation steps. Verify the link resolves to `.config/git-ai-commit/config.toml`.

Create the implementation commit with `git ai-commit`. Its successful Codex invocation verifies that the configured Terra engine works end to end.
