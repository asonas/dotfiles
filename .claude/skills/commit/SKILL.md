---
name: commit
description: Create a commit using git ai-commit. Use this when the user asks to commit changes, make a commit, or save changes to git. Ensures each commit contains a single logical context.
allowed-tools: Bash(git:*), Bash(echo:*), Read, Glob, Grep
context: fork
---

# Commit Skill

Create commits using `git ai-commit` command. Do NOT use `git commit` directly. Always use `git ai-commit`.

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

1. Run `git status` to see all changes and show the output to the user
2. Run `git diff` to review the content of changes and show the output to the user
3. Identify logical units and group related files. Explain the grouping to the user
4. Stage only related files for one context: `git add <specific-files>`
5. Run `git ai-commit` to create the commit
6. If there are remaining unstaged changes, ask the user if they want to continue with another commit

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
