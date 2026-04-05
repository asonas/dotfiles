---
name: context-load
description: Load previously saved context to resume work or apply knowledge from past investigations.
argument-hint: "[name]"
context: fork
---

# /context-load - Load saved context

Load previously saved context to resume work or apply knowledge from past investigations.

## Usage

```
/context-load [name]
```

Examples:
```
/context-load                    # Uses current directory name (e.g., dotfiles)
/context-load auth-refactoring   # Loads specific context by name
```

## Instructions

When this skill is invoked:

1. **Determine the context name**
   - If an argument is provided, use it as the name
   - If no argument is provided, extract the directory name from the current working directory
     - Example: `~/ghq/github.com/asonas/dotfiles` → `dotfiles`
   - The current working directory is available in the environment information provided at the start of the conversation

2. **Search memory-vector for context**
   - Use `mcp__memory-vector__search_memory` tool with the context name as query
   - Also try `mcp__memory-vector__get_context` with the topic
   - Look for entries with tags containing "context" and the name
   - **リポジトリ名での検索を優先**: sourceフィールドにリポジトリ名が含まれているため、リポジトリ名をクエリに含めると関連度が上がる
     - 例: `dotfiles zsh設定` のようにリポジトリ名+キーワードで検索

3. **Present the context to the user**
   - Display the loaded context clearly
   - Highlight:
     - The original plan/decisions
     - Next steps that were identified
     - Any open questions
   - Ask if they want to proceed with the plan or need clarification

4. **If context not found**
   - Suggest searching with different keywords
   - Offer to list recent memories with related tags

## Notes

- Contexts are stored in memory-vector with semantic search
- Use tags like "context", project name, feature name for better retrieval
