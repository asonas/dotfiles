---
name: git-worktree-workflow
description: Use git-wt to manage Git Worktrees for efficient parallel development. Handle feature branches, bug fixes, and experimental work in isolated worktrees for faster context switching.
context: fork
---

# Git Worktree Workflow

Leverage git-wt to create and manage Git Worktrees for parallel development environments.

## Primary Use Cases

- **Feature Development**: Develop new features in isolated worktrees
- **Bug Fixes**: Fix urgent bugs without interrupting main development flow
- **Experimental Work**: Try new ideas without affecting the main branch
- **Code Reviews**: Create dedicated worktrees for PR reviews

## Actions When Invoked

When this skill is activated, the following workflow will be executed:

### 1. Status Check
```bash
# List existing worktrees
git wt
```

### 2. Create Working Worktree

#### For Feature Development
```bash
# Create worktree for feature/feature-name
git wt feature/[feature-name]

# Create from specific branch
git wt feature/[feature-name] origin/main
```

#### For Bug Fixes
```bash
# Create worktree for hotfix/fix-description
git wt hotfix/[fix-description] origin/main
```

#### For Experimental Work
```bash
# Create worktree for experiment/experiment-name
git wt experiment/[experiment-name]
```

### 3. Switch Between Worktrees

```bash
# Switch to existing worktree
git wt [branch-name-or-worktree-name]
```

### 4. Cleanup After Work

```bash
# Safely delete worktree and branch (only if merged)
git wt -d [branch-name]

# Force delete (with unmerged changes)
git wt -D [branch-name]
```

## Recommended Workflows

### TDD Development Workflow

1. **Create Feature Worktree**
   ```bash
   git wt feature/new-component
   ```

2. **Test and Implementation**
   - Red: Write failing test
   - Green: Minimal implementation to pass
   - Refactor: Improve code quality

3. **Sync with Main Branch**
   ```bash
   # Fetch latest from main
   git fetch origin
   git merge origin/main
   ```

4. **Create and Merge PR**
   - Create PR on GitHub
   - Merge after review

5. **Cleanup Worktree**
   ```bash
   git wt -d feature/new-component
   ```

### Parallel Work Example

```bash
# While working on feature/payment-integration

# 1. Create hotfix worktree without interrupting current work
git wt hotfix/critical-security-fix origin/main

# 2. Apply fix and push
git add .
git commit -m "Fix critical security vulnerability"
git push -u origin hotfix/critical-security-fix

# 3. Return to original work
git wt feature/payment-integration

# 4. Delete worktree after fix is complete
git wt -d hotfix/critical-security-fix
```

## Configuration Customization

Configure per-project settings:

```bash
# Set worktree base directory
git config wt.basedir "../{gitroot}-worktrees"

# Copy ignored files like .env
git config wt.copyignored true

# Install dependencies after creating worktree
git config --add wt.hook "npm install"
git config --add wt.hook "bundle install"
```

## Best Practices

1. **Consistent Naming Convention**
   - feature/: New features
   - hotfix/: Emergency fixes
   - bugfix/: Regular bug fixes
   - experiment/: Experimental changes
   - chore/: Refactoring and maintenance

2. **Regular Cleanup**
   - Delete merged worktrees promptly
   - Check status regularly with `git wt`

3. **Dependency Management**
   - Keep node_modules independent per worktree
   - Auto-copy env files with `wt.copyignored`

4. **Clear Context**
   - Document what each worktree is for
   - Link to TODO lists or issue numbers

## Troubleshooting

### Cannot Delete Worktree
```bash
# Use force delete
git wt -D [branch-name]

# Manual deletion if needed
rm -rf ../[worktree-dir]
git worktree prune
```

### Lost Worktree Location
```bash
# Show detailed worktree information
git worktree list --porcelain
```

### Environment Files Not Copied
```bash
# Enable copying of gitignored files
git config wt.copyignored true
```