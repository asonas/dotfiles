# Cross-Model PR Review Skill - Design

## Context

PR review by a single AI model has blind spots. By having Claude Code and Cursor (via cursor-agent MCP) review the same PR independently and then rally back and forth on a shared document, we get broader coverage and democratic conflict resolution. The key insight is using a file as shared state rather than ephemeral message passing, so context accumulates across rounds.

## Overview

`/cross-review <PR_URL>` creates a review document in Obsidian, fetches PR info and diff, then orchestrates alternating review rounds between Claude Code and Cursor. Each round appends findings to the document. The process continues until no new critical/major issues are found, or disagreements are documented with Pros/Cons for human decision.

## Invocation

```
/cross-review https://github.com/owner/repo/pull/123
```

## Workflow

```
1. Initialize
   - Fetch PR title, description, diff via `gh pr view` / `gh pr diff`
   - Fetch existing review comments (greptile, humans) via `gh api`
   - Create review document in Obsidian at `reviews/PR-{repo}-{number}.md`

2. Round N - Claude Code
   - Read current document state
   - Review using pr-review skill perspectives (Correctness, Design, Security, Performance, Readability, Testing)
   - Append findings to "Review Findings" section
   - Update "Current Status"

3. Round N - Cursor
   - Pass document to cursor_review MCP
   - Cursor reviews diff and previous findings
   - Append findings to "Review Findings" section
   - Update "Current Status" via cursor_continue if needed

4. Reconciliation (after each pair of rounds)
   - Compare findings from both reviewers
   - Agreements: mark as Resolved in Discussion
   - New points: add to Discussion for next round
   - Disagreements: document Pros/Cons, mark as "Human Decision Needed"

5. Termination
   - No new critical/major findings in latest round → proceed to summary
   - All items Resolved or marked Human Decision Needed → proceed to summary
   - Max 3 rounds reached → proceed to summary with note

6. Final Summary
   - Write summary of all findings, resolved items, and items needing human input
   - Link to review document from daily note
```

## Review Document Template

```markdown
# PR Review: {title}

## PR Info
- URL: {url}
- Author: {author}
- Branch: {head} -> {base}
- Created: {date}

## Description
{PR description}

## External Comments
### Greptile
{greptile comments if any}

### Human
{human comments if any}

## Diff
{diff or reference to diff file}

## Review Findings

### Round {N} - Claude Code
- [{severity}] {finding} ({file}:{line})

### Round {N} - Cursor
- [{severity}] {finding} ({file}:{line})

## Discussion

### {Topic}
- **Claude Code**: {position}
- **Cursor**: {position}
- **Status**: {Resolved | In Discussion | Human Decision Needed}

#### Pros/Cons (when disagreement)
| | Pros | Cons |
|---|------|------|
| Option A | ... | ... |
| Option B | ... | ... |

## Current Status
- Round: {N}
- Unresolved: {count}
- Resolved: {count}
- Human Decision Needed: {count}
- Next action: {description}

## Final Summary
{written after termination}
```

## Severity Levels

- **critical**: Security vulnerabilities, data loss risks, crash bugs
- **major**: Logic errors, performance issues, missing error handling
- **minor**: Code style, naming, minor improvements
- **nit**: Formatting, typos, cosmetic suggestions

Only critical and major drive continuation of review rounds. Minor and nit are recorded but don't prevent termination.

## Democratic Principles

1. Neither model "wins" by default - disagreements are documented, not resolved by attrition
2. When a reviewer changes position, the reason must be stated in the document
3. If discussion on a topic exceeds 2 rounds without convergence, it becomes "Human Decision Needed" with Pros/Cons
4. Both reviewers' perspectives are presented equally in the final summary

## Existing Skills Used

- `pr-review`: Review perspectives and methodology for Claude Code's review rounds
- `cursor_review` MCP: Delegates review to Cursor
- `cursor_continue` MCP: Continues Cursor conversation for follow-up rounds
- `obsidian_get_file_contents` / `obsidian_patch_content`: Read/write review document
- `obsidian_simple_search`: Check for existing review documents

## Obsidian Integration

- Document saved at: `reviews/PR-{repo}-{number}.md`
- After completion, link added to daily note under the work log section
- Follows existing Obsidian writing rules from CLAUDE.md (no emojis, wikilinks for technical terms)

## Limitations

- Cursor model is not specified by the skill (uses Cursor's default)
- Diff size may exceed context limits for very large PRs - in that case, review file-by-file
- cursor_review MCP availability depends on cursor-agent server running
