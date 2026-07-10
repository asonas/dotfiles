---
name: cross-review
description: Cross-model PR review. Claude Code and Cursor review a PR alternately on a shared Obsidian document, rallying until issues converge or disagreements are documented for human decision.
argument-hint: "<PR_URL>"
allowed-tools: Bash(ghro:*), Bash(obsidian:*), Read, Edit, Write, mcp__cursor-agent__cursor_review, mcp__cursor-agent__cursor_continue
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

Extract repo name and PR number from the URL for the document filename. `{repo}` is the bare repository name (owner excluded) — e.g. URL `https://github.com/acme-corp/widget-api/pull/427` → `widget-api`, `427`. If you anticipate cross-org collision on the same bare repo name (rare), prefix the filename with the owner: `PR-{owner}-{repo}-{number}.md`. Otherwise use `PR-{repo}-{number}.md`.

### Step 2: Create Obsidian Review Document

Create `pr-reviews/PR-{repo}-{number}.md` in Obsidian using the official CLI:

```bash
obsidian create vault=asonas path="pr-reviews/PR-{repo}-{number}.md" content="<template below>" 2>/dev/null
```

If an existing file must be overwritten, pass the `overwrite` flag. Use this template — fill in the PR Info, Description, External Comments, and Diff sections. Leave the rest empty for now:

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

Read the current document from Obsidian with the Read tool: `/Users/asonas/Documents/asonas/pr-reviews/PR-{repo}-{number}.md`（`obsidian read` は Obsidian GUI が閉じているとハングするため使わない）. Review the diff using the pr-review skill perspectives:

1. **Correctness**: Bugs, logic errors, unhandled edge cases
2. **Design**: Abstraction, separation of concerns, dependencies
3. **Security**: Injection, auth issues, data exposure
4. **Performance**: N+1 queries, unnecessary computation, memory leaks
5. **Readability**: Naming, structure, comments
6. **Testing**: Adequate test coverage for changes

Also read previous round findings (if any) and respond to Cursor's points in the Discussion section.

heading指定の挿入はReadツールでファイルを読み、Editツールで `## Review Findings` 直下に追加する。Do NOT create a new `## Review Findings` header — edit the existing section.

```markdown
### Round {N} - Claude Code
- [{severity}] {finding} ({file}:{line})
- [{severity}] {finding} ({file}:{line})
```

**Bullet point guidelines**:
- Keep each bullet to 1-2 sentences maximum
- State the problem and affected location concisely
- If detailed reasoning is needed, add it to the Discussion section instead

In Step 3, update `## Current Status` only to bump `Round` to the in-progress number and set `Next action` to "Cursor Round {N}". Do NOT recompute Unresolved/Resolved/Human Decision Needed counts here — those are reconciled in Step 5 after the pair. Read + Edit existing values; do NOT create a new `## Current Status` header.

### Step 4: Cursor Review (Round N)

Pass the full review document content to `cursor_review` MCP:

- **content**: The full review document text
- **model**: `composer-2`
- **focus**: "Review the PR diff and previous findings. Add your own findings under 'Round {N} - Cursor'. For existing findings from Claude Code, state whether you agree or disagree in the Discussion section. If you disagree, explain why. Use severity levels: critical, major, minor, nit."
- **context**: "This is a cross-model PR review. You are reviewing independently. Do not defer to Claude Code's findings — if you disagree, document your position clearly. Democratic review: neither side wins by attrition."

Read the response and use Read + Edit tools on `/Users/asonas/Documents/asonas/pr-reviews/PR-{repo}-{number}.md` to add Cursor's findings under the existing `## Review Findings` section as `### Round {N} - Cursor`. Do NOT create a new `## Review Findings` header.

If Cursor's response needs follow-up, use `cursor_continue` to ask for clarification.

### Step 5: Reconciliation

A "Round N" consists of one Claude Code review followed by one Cursor review, then this reconciliation pass. After each Round, classify each finding into exactly one bucket:

1. **Agreements**: Both found the same issue → mark as `Resolved` in Discussion. If the two reviewers assigned different severities to the same issue, this is still an Agreement (not a Disagreement). Record both severities in the Discussion entry (not in the original Findings bullets), and use the higher severity for termination logic in Step 6.

   Worked example of a different-severity agreement:
   ```markdown
   ### has_next detection after removing `+1`
   - **Claude Code**: [major] Risk of next-page detection breaking if derived from row count.
   - **Cursor**: [nit] `has_next` uses a separate count query; cosmetic only.
   - **Status**: Resolved (Agreement; severity recorded as [major] per the higher-of-two rule)
   ```
2. **New points**: One found something the other didn't → add to Discussion as `In Discussion`, ask the other's view in the next round.
3. **Disagreements**: Conflicting positions on whether/how to fix (not severity-only differences) → document both sides as `In Discussion`.

**Status counts scope**: `## Current Status` counts cover ALL findings regardless of severity:
- `Unresolved`: items in Discussion currently marked `In Discussion`
- `Resolved`: items both reviewers agreed on (including different-severity agreements)
- `Human Decision Needed`: escalated disagreements (see below)

Termination logic in Step 6 considers only critical/major findings within `Unresolved`. minor/nit findings count toward `Unresolved` but do not by themselves continue the rally.

For disagreements, write in the Discussion section:

```markdown
### {Topic}
- **Claude Code**: {position with reasoning}
- **Cursor**: {position with reasoning}
- **Status**: In Discussion
```

**Escalation timing**: If the same critical/major disagreement appears in two consecutive Reconciliation passes (i.e., it was `In Discussion` after Round N's Reconciliation and remains `In Discussion` after Round N+1's Reconciliation with no position change supported by new reasoning), escalate at the end of Round N+1's Reconciliation — do not run another round to "re-confirm". For typical use this means: surfaced in Round 1, still disputed in Round 2 → escalate after Round 2. Escalation applies only to critical/major; minor/nit disagreements are never escalated — they are normalized by Step 6's cleanup pass instead.

```markdown
- **Status**: Human Decision Needed

| | Pros | Cons |
|---|------|------|
| Option A ({who proposed}) | ... | ... |
| Option B ({who proposed}) | ... | ... |
```

IMPORTANT: If a reviewer changes position, the reason MUST be stated. No silent capitulation.

### Step 6: Termination Check

Execute the following in order — do not skip or reorder:

1. **Continue check**: continue to the next round if EITHER (a) new critical/major findings appeared in the latest round, OR (b) unresolved critical/major discussion items have not yet reached 2 rounds (Step 5's escalation threshold).
2. **Stop check**: stop if neither (a) nor (b) above holds, OR if Round count has reached 3 (hard cap).
3. **If continuing**: skip the cleanup pass below and return to Step 3 for the next round.
4. **If stopping — cleanup pass on remaining `In Discussion` items** (run before Step 7):
   - If the item is critical/major → it must already have been escalated to `Human Decision Needed` per Step 5 (re-check; if not, escalate now with a Pros/Cons table).
   - If the item is minor/nit → mark it `Resolved (defer to author)` in Discussion with a one-line rationale. Do NOT leave any item as `In Discussion` past this point.
5. **Recompute Current Status counts** to reflect the sweep, then proceed to Step 7.

### Step 7: Final Summary

Read + Edit ツールで既存の `## Final Summary` セクションの直後に本文を挿入する。Do NOT create a new `## Final Summary` header. The snippet below shows the body content; the leading `## Final Summary` line is the EXISTING header in the document — match against it as Edit's `old_string`, do not duplicate it.

```markdown
## Final Summary
<!-- everything below is inserted under the existing header above; do not duplicate the header -->

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

今日の daily note の `## ログ` セクション末尾に追記する。公式CLIはheading指定のinsert非対応なので、Read + Edit で直接編集する:

```
# Read tool:
Read: /Users/asonas/Documents/asonas/daily/YYYY-MM-DD.md

# Edit tool: "## ログ" セクション末尾に挿入
# new entry: "- HH:MM レビュー: [[PR-{repo}-{number}]] ({critical} critical, {major} major, {disagreements} disagreements)"
```

`## ログ` セクションが存在しない場合（古いテンプレの daily note）はファイル末尾に新規セクションを作って追記する。

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
