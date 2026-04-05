---
name: cross-review
description: Cross-model PR review. Claude Code and Cursor review a PR alternately on a shared Obsidian document, rallying until issues converge or disagreements are documented for human decision.
argument-hint: "<PR_URL>"
allowed-tools: Bash(ghro:*), mcp__cursor-agent__cursor_review, mcp__cursor-agent__cursor_continue, mcp__mcp-obsidian__obsidian_get_file_contents, mcp__mcp-obsidian__obsidian_patch_content, mcp__mcp-obsidian__obsidian_append_content, mcp__mcp-obsidian__obsidian_simple_search, mcp__mcp-obsidian__obsidian_get_periodic_note
user-invocable: true
context: fork
---

# Cross-Model PR Review

Claude Code and Cursor review a PR alternately on a shared Obsidian document. Each reviewer appends findings independently. Disagreements are documented with Pros/Cons for human decision — neither model wins by attrition.

**Language**: All content written to the Obsidian document MUST be in English. This applies to PR descriptions, findings, discussion entries, and the final summary.

## Usage

```
/cross-review <PR_URL>
```

## Severity Levels

- **critical**: Security vulnerabilities, data loss risks, crash bugs
- **major**: Logic errors, performance issues, missing error handling
- **minor**: Code style, naming, minor improvements
- **nit**: Formatting, typos, cosmetic suggestions

Only critical and major drive continuation of rounds.

## Procedure

### Step 1: Initialize

Fetch PR information using `ghro` (read-only):

```bash
# PR metadata
ghro pr view <PR_URL> --json title,body,author,baseRefName,headRefName,additions,deletions,changedFiles,number
ghro pr view <PR_URL> --comments
ghro api repos/{owner}/{repo}/pulls/{number}/comments

# Diff
ghro pr diff <PR_URL>
```

Extract repo name and PR number from the URL for the document filename.

### Step 2: Create Obsidian Review Document

Create `reviews/PR-{repo}-{number}.md` in Obsidian using `obsidian_append_content`.

Use this template — fill in the PR Info, Description, External Comments, and Diff sections. Leave the rest empty for now:

```markdown
## PR Info
- URL: {url}
- Author: {author}
- Branch: {head} -> {base}
- Changes: +{additions}/-{deletions} across {changedFiles} files

## Description
{PR body}

## External Comments
{Existing review comments from greptile, humans, etc. Write "None" if empty}

## Diff
{Full diff, or for very large PRs: file-by-file summary with key sections}

## Review Findings

## Discussion

## Current Status
- Round: 0
- Unresolved: 0
- Resolved: 0
- Human Decision Needed: 0
- Next action: Claude Code Round 1

## Final Summary
```

### Step 3: Claude Code Review (Round N)

Read the current document from Obsidian. Review the diff using the pr-review skill perspectives:

1. **Correctness**: Bugs, logic errors, unhandled edge cases
2. **Design**: Abstraction, separation of concerns, dependencies
3. **Security**: Injection, auth issues, data exposure
4. **Performance**: N+1 queries, unnecessary computation, memory leaks
5. **Readability**: Naming, structure, comments
6. **Testing**: Adequate test coverage for changes

Also read previous round findings (if any) and respond to Cursor's points in the Discussion section.

Use `obsidian_patch_content` with `target: "Review Findings"` to add your findings under that section. Do NOT create a new `## Review Findings` header — patch the existing one.

```markdown
### Round {N} - Claude Code
- [{severity}] {finding} ({file}:{line})
- [{severity}] {finding} ({file}:{line})
```

**Bullet point guidelines**:
- Keep each bullet to 1-2 sentences maximum
- State the problem and affected location concisely
- If detailed reasoning is needed, add it to the Discussion section instead

Use `obsidian_patch_content` with `target: "Current Status"` to replace the status values. Do NOT create a new `## Current Status` header.

### Step 4: Cursor Review (Round N)

Pass the full review document content to `cursor_review` MCP:

- **content**: The full review document text
- **model**: `composer-2`
- **focus**: "Review the PR diff and previous findings. Add your own findings under 'Round {N} - Cursor'. For existing findings from Claude Code, state whether you agree or disagree in the Discussion section. If you disagree, explain why. Use severity levels: critical, major, minor, nit."
- **context**: "This is a cross-model PR review. You are reviewing independently. Do not defer to Claude Code's findings — if you disagree, document your position clearly. Democratic review: neither side wins by attrition."

Read the response and use `obsidian_patch_content` with `target: "Review Findings"` to add Cursor's findings under that section as `### Round {N} - Cursor`. Do NOT create a new `## Review Findings` header.

If Cursor's response needs follow-up, use `cursor_continue` to ask for clarification.

### Step 5: Reconciliation

After each pair of rounds (Claude Code + Cursor), reconcile:

1. **Agreements**: Both found the same issue → mark as Resolved in Discussion
2. **New points**: One found something the other didn't → add to Discussion, ask the other's view in the next round
3. **Disagreements**: Conflicting positions → document both sides

For disagreements, write in the Discussion section:

```markdown
### {Topic}
- **Claude Code**: {position with reasoning}
- **Cursor**: {position with reasoning}
- **Status**: In Discussion
```

If a disagreement persists for 2 rounds, escalate:

```markdown
- **Status**: Human Decision Needed

| | Pros | Cons |
|---|------|------|
| Option A ({who proposed}) | ... | ... |
| Option B ({who proposed}) | ... | ... |
```

IMPORTANT: If a reviewer changes position, the reason MUST be stated. No silent capitulation.

### Step 6: Termination Check

After reconciliation, check if the review should continue:

- **Continue** if: new critical/major findings in the latest round, OR unresolved discussion items that haven't reached 2 rounds yet
- **Stop** if: no new critical/major findings, AND all items are Resolved or Human Decision Needed, OR max 3 rounds reached

### Step 7: Final Summary

Use `obsidian_patch_content` with `target: "Final Summary"` to write the final summary into the existing section. Do NOT create a new `## Final Summary` header.

```markdown
## Final Summary

### Resolved Issues
{List of issues both reviewers agreed on, with recommended fixes}

### Human Decision Needed
{List of disagreements with Pros/Cons tables}

### All Findings by Severity
- Critical: {count}
- Major: {count}
- Minor: {count}
- Nit: {count}

### Reviewer Agreement
- Agreed: {count}
- Disagreed (human decides): {count}
```

### Step 8: Link to Daily Note

Use `obsidian_get_periodic_note` to find today's daily note, then append a link:

```markdown
- Reviewed [[PR-{repo}-{number}]] ({critical} critical, {major} major, {disagreements} disagreements)
```

## Democratic Principles

These rules are non-negotiable:

1. **No deference**: Neither model automatically defers to the other
2. **Reasoned position changes**: If changing position, state why in the document
3. **Escalation over capitulation**: After 2 rounds of disagreement, escalate to human rather than one side giving in
4. **Equal presentation**: Both reviewers' perspectives appear equally in the final summary
5. **Human as arbiter**: The human makes final calls on unresolved disagreements

## Notes

- For very large diffs (>500 lines), consider reviewing file-by-file rather than the entire diff at once
- Check existing review comments to avoid duplicating what greptile or humans already found
- The document is the single source of truth — all findings must be written there, not just discussed in conversation
