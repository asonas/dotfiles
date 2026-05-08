---
name: commit
description: Create a commit using git ai-commit. Use this when the user asks to commit changes, make a commit, or save changes to git. Ensures each commit contains a single logical context.
argument-hint: "[path]"
allowed-tools: Bash(git:*), Bash(echo:*), Read, Glob, Grep
context: fork
---

# Commit Skill

Create commits using `git ai-commit` command. Do NOT use `git commit` directly. Always use `git ai-commit`.

## Usage

```
/commit                          # CWDで実行
/commit .worktrees/feature/xxx   # 指定パスで実行
```

## IMPORTANT

- You MUST execute the procedure below step by step. Do NOT skip any steps.
- You MUST use `git ai-commit` to create commits. Never use `git commit` directly.
- You MUST show the user the output of each step.
- Do NOT complete without actually running the commands.

## Principles

### 1 Commit = 1 Context

Each commit must contain only one logical change:

1. **Single Responsibility**: One commit = one logical change
2. **Atomicity**: Each commit should be independently understandable
3. **Separate Structure from Behavior**: Following Tidy First principles, keep refactoring and feature additions in separate commits

## Procedure

Execute these steps in order:

### Step 0: Determine working directory

- If a path argument is provided (e.g., `/commit .worktrees/feature/xxx`), use that as the target directory. All subsequent git commands MUST use `git -C <path>`.
- If no argument is provided, use the current working directory (no `-C` flag needed).

### Step 1: Check for changes

1. Run `git status` (or `git -C <path> status`) to see all changes and show the output to the user
2. **If there are no changes (clean working tree)**:
   - Do NOT auto-detect or search other worktrees
   - Display: "ワーキングディレクトリに差分がありません。worktreeで作業している場合はパスを指定してください: `/commit .worktrees/feature/xxx`"
   - Run `git worktree list` to show available worktrees as a reference
   - Stop here
3. Run `git diff` (or `git -C <path> diff`) to review the content of changes and show the output to the user

### Step 2: Group and stage changes

1. Identify logical units and group related files. Explain the grouping to the user
2. Stage only related files for one context: `git add <specific-files>` (or `git -C <path> add <specific-files>`)
3. **Commit ordering**: When you have both structural (refactor/rename/format) and behavioral (feature/bugfix) groups, commit **structural first, then behavioral** (Tidy First). For groups that are all structural or all behavioral, any order is fine — pick one and proceed without asking the user.
4. **Sub-file splits (intermingled hunks in a single file)**: When a single file's diff mixes contexts that must be split, use one of these **non-interactive** techniques (do NOT use `git add -p` or `git restore -p` — they block on TTY input):
   - **Rewrite-to-intermediate**: temporarily edit the file to contain only the first context's changes, `git add <file>`, `git ai-commit`, then restore the full edited content and `git add <file>` + `git ai-commit` again.
   - **Stash + partial apply**: `git stash`, edit the file to add back only the first context, commit, `git stash pop`, commit the rest.
   Pick whichever is simpler for the case at hand. Both avoid interactive prompts.

### Step 3: Commit

1. Run `git ai-commit` (or `git -C <path> ai-commit`) to create the commit
   - **CLAUDE.mdルール準拠**: `cd <path> && git ...` は禁止。パス指定が必要な場合は必ず `git -C <path>` を使う
2. If there are remaining unstaged changes, ask the user if they want to continue with another commit

## Commands

```bash
# Basic usage (commit staged changes)
git ai-commit

# Stage all changes and commit (use only when all changes are one context)
git ai-commit -a

# Add context information
git ai-commit --context "description of the change"

# Amend the previous commit
git ai-commit --amend
```

## Checklist Before Committing

- [ ] All tests pass
- [ ] All compiler/linter warnings are resolved
- [ ] Changes represent a single logical unit of work
- [ ] Related files are staged together
