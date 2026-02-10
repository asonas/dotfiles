---
name: context-list
description: List all saved contexts available for loading.
context: fork
---

# /context-list - List saved contexts

List all saved contexts available for loading.

## Usage

```
/context-list
```

## Instructions

When this skill is invoked:

1. **List Obsidian contexts**
   - Use `mcp__mcp-obsidian__obsidian_list_files_in_dir` with `contexts/`
   - Display each context with its name

2. **Get metadata for each context**
   - Optionally read the first few lines to show creation date and tags
   - Use `mcp__mcp-obsidian__obsidian_batch_get_file_contents` for efficiency

3. **Present as a table**
   - Show: Name, Created Date, Tags/Repositories
   - Sort by most recent first

4. **Suggest next action**
   - Tell user they can load a context with `/context-load <name>`

## Output Format

```
Available Contexts:

| Name | Created | Tags |
|------|---------|------|
| auth-refactoring-plan | 2026-02-04 | auth, backend |
| api-migration-notes | 2026-02-01 | api, migration |

Load with: /context-load <name>
```
