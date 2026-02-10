---
name: context-save
description: Save the current conversation's plan, investigation results, or notes for later retrieval.
disable-model-invocation: true
---

# /context-save - Save context for later use

Save the current conversation's plan, investigation results, or notes for later retrieval.

## Usage

```
/context-save [name]
```

Examples:
```
/context-save                    # Uses current directory name (e.g., ivry_web_backend)
/context-save auth-refactoring   # Uses specified name
```

## Instructions

When this skill is invoked:

1. **Determine the context name**
   - If an argument is provided, use it as the name
   - If no argument is provided, extract the directory name from the current working directory
     - Example: `/Users/asonas/ghq/github.com/ivry-inc/ivry_web_backend` → `ivry_web_backend`
   - The current working directory is available in the environment information provided at the start of the conversation

2. **Summarize the current conversation**
   - Extract key findings, decisions, and plans from the conversation
   - Focus on actionable information that would be useful when resuming work
   - Include:
     - Background/context of the investigation
     - Key decisions made
     - Implementation plan or next steps
     - Related files or code locations (with line numbers)
     - Any blockers or open questions

3. **Save to second-brain (PostgreSQL)**
   - Use the `mcp__second-brain__store_memory` tool
   - Store the summarized content
   - Add tags: `["context", "<name>", "<relevant-tags>"]`
   - **source**: リポジトリ名を必ず含める
     - 形式: `<リポジトリ名>/<補足情報>`
     - 例: `ivry_web_backend/OpensearchIndexerWorker調査`
     - 例: `ivry_web_frontend/コンタクトセンター改修`
   - Add metadata: `{ "type": "context", "created": "YYYY-MM-DD", "project": "<リポジトリ名>" }`

4. **Confirm to user**
   - Report that the context was saved
   - Show a brief summary of what was captured
   - Mention the name used (especially if auto-detected from directory)

## Content Format

Structure the content clearly:

```
<Title/Name>

## Background
<Why this investigation/planning was done>

## Key Findings
<Important discoveries or decisions>

## Plan / Next Steps
<Actionable items>

## Related Files
<File paths with line numbers for easy navigation>

## Open Questions
<Unresolved items>
```

## Notes

- Obsidian への保存が必要な場合は、ユーザーが別途指示する
- second-brain のセマンティック検索で後から検索可能
