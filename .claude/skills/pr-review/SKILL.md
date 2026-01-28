---
name: pr-review
description: Review GitHub Pull Requests. When given a PR URL, fetches diff and comments using gh command, then performs objective and critical code review.
allowed-tools: Bash(gh:*), WebFetch, WebSearch
user-invocable: true
context: fork
---

# PR Review Skill

Perform objective code reviews for GitHub Pull Requests.

## Principles

### Objectivity and Critical Stance

- **No flattery**: Skip pleasantries like "looks good" or "great work". Focus on issues and improvements
- **Evidence-based**: Base feedback on actual code behavior and official documentation, not assumptions
- **Constructive**: Provide specific improvement suggestions, not just criticism

### Review Perspectives

1. **Correctness**: Check for bugs, logic errors, and unhandled edge cases
2. **Design**: Evaluate abstraction, separation of concerns, and dependencies
3. **Security**: Identify vulnerabilities (injection, auth issues, etc.)
4. **Performance**: Look for N+1 queries, unnecessary computation, memory leaks
5. **Readability**: Assess naming, structure, and comments
6. **Testing**: Verify adequate test coverage for changes

## Procedure

### 1. Fetch PR Information

```bash
# Get PR overview
gh pr view <PR_URL> --json title,body,author,baseRefName,headRefName,additions,deletions,changedFiles

# Get diff
gh pr diff <PR_URL>

# Get existing comments
gh pr view <PR_URL> --comments

# Get review comments (inline comments on files)
gh api repos/{owner}/{repo}/pulls/{pr_number}/comments
```

### 2. Analyze Changes

- List changed files and understand scope
- Understand the purpose from PR description
- Identify impact areas

### 3. Technical Verification

- Check official documentation for libraries/APIs used (use WebSearch/WebFetch)
- Compare against best practices
- Verify consistency with existing codebase

### 4. Create Review Comments

## Review Output Format

```markdown
## Summary

[1-2 sentence summary of PR changes]

## Critical Issues

[Security vulnerabilities, data loss risks, serious bugs that must be fixed before merge]

## Improvement Suggestions

[Better implementation approaches, performance improvements, readability enhancements]

## Questions

[Points requiring clarification on design intent or requirements]

## Minor Issues

[Typos, formatting, naming - issues that don't block merge]
```

## Notes

- For large PRs, focus on the most important files
- Check existing review comments to avoid duplicates
- Reference related issues or discussions if available

## Command Examples

```bash
# Get full PR information
gh pr view https://github.com/owner/repo/pull/123

# Get diff for specific file only
gh pr diff https://github.com/owner/repo/pull/123 -- path/to/file.ts

# Post comment on PR
gh pr comment https://github.com/owner/repo/pull/123 --body "Review comment"

# Submit PR review
gh pr review https://github.com/owner/repo/pull/123 --comment --body "Review content"
```
