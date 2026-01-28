---
name: commit
description: Create a commit using git ai-commit. Use this when the user asks to commit changes, make a commit, or save changes to git. Ensures each commit contains a single logical context.
allowed-tools: Bash(git:*)
context: fork
---

# Commit Skill

Create commits using `git ai-commit` command.

## Principles

### 1 Commit = 1 Context

Each commit must contain only one logical change:

1. **Single Responsibility**: One commit = one logical change
2. **Atomicity**: Each commit should be independently understandable
3. **Separate Structure from Behavior**: Following Tidy First principles, keep refactoring and feature additions in separate commits

### Good Examples
- Adding a new feature (1 commit)
- Bug fix (1 commit)
- Refactoring (1 commit)
- Adding tests (1 commit)

### Bad Examples
- Multiple unrelated changes in one commit
- Feature addition and refactoring in the same commit

## Procedure

1. Run `git status` and `git diff` to review all changes
2. Identify logical units and group related files
3. Stage only related files for one context: `git add <specific-files>`
4. Run `git ai-commit` to create the commit
5. Repeat steps 3-4 for remaining changes if necessary

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
