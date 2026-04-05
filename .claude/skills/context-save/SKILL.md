---
name: context-save
description: Save the current conversation's plan, investigation results, or notes for later retrieval.
argument-hint: "[name]"
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
/context-save                    # Uses current directory name (e.g., dotfiles)
/context-save auth-refactoring   # Uses specified name
```

## Instructions

When this skill is invoked:

1. **Determine the context name**
   - If an argument is provided, use it as the name
   - If no argument is provided, extract the directory name from the current working directory
     - Example: `~/ghq/github.com/asonas/dotfiles` → `dotfiles`
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

3. **Save to memory-vector**
   - Use the `mcp__memory-vector__store_memory` tool
   - Store the summarized content
   - Add tags: `["context", "<name>", "<relevant-tags>"]`
   - **source**: リポジトリ名を必ず含める
     - 形式: `<リポジトリ名>/<補足情報>`
     - 例: `dotfiles/zsh設定の整理`
     - 例: `my-app/認証フロー改修`
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
- memory-vector のセマンティック検索で後から検索可能
