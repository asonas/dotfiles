---
name: wrapup
description: Summarize the day's work and append to the daily note in Obsidian.
disable-model-invocation: true
---

# /wrapup - Daily Wrap-up

Summarize the day's work and append to the daily note in Obsidian.

## Usage

```
/wrapup [date]
```

Examples:
```
/wrapup                  # Today's daily note
/wrapup yesterday        # Yesterday's daily note
/wrapup 2026-02-05       # Specific date
```

## Instructions

### Step 1: Determine Target Date

Parse the argument to determine which daily note to update:
- No argument → today's date
- `yesterday` → yesterday's date
- `YYYY-MM-DD` → specified date

Use `mcp__google-calendar__get-current-time` to get the current date for reference.

### Step 2: Verify Daily Note Exists

Check if the target daily note exists:
```
mcp__mcp-obsidian__obsidian_get_file_contents with filepath: "daily/YYYY-MM-DD.md"
```

If it doesn't exist, inform the user and offer to create it.

### Step 3: Read Completed Tasks from Things3

Read tasks completed today from Things3:
```
Bash: ~/.claude/scripts/things-completed-today.sh
```

Also read current open tasks in "今日" to report remaining items:
```
Bash: ~/.claude/scripts/things-today.sh
```

### Step 4: Gather Work Summary

Collect information about what was done:

1. **From Things3 (Step 3)**
   - Completed tasks are the primary source for "やったこと"
   - Open tasks become carry-over items

2. **From the current conversation**
   - Extract completed tasks, investigations, fixes, implementations
   - Note any decisions made
   - List files modified or created

3. **From second-brain（必須）**
   - 必ずsecond-brainを検索して、今日の作業内容を収集する
   - 複数のクエリで検索を行い、漏れがないようにする:
   ```
   # 日付ベースの検索
   mcp__second-brain__search_memory with query: "2026-02-05" (対象日付)

   # 作業内容ベースの検索
   mcp__second-brain__search_memory with query: "today work investigation implementation fix"

   # リポジトリ名での検索（sourceフィールドに保存されているため効果的）
   mcp__second-brain__search_memory with query: "ivry_web_backend" など
   # カレントディレクトリからリポジトリ名を取得して検索に使用する
   ```
   - `createdAt` フィールドを確認し、対象日に作成された記録を優先する
   - `source` フィールドにリポジトリ名が含まれている記録を優先する
   - 検索結果から重複を除いて、今日実施した作業を抽出する

4. **情報の統合**
   - Things3の完了タスク、現在のセッションの内容、second-brainの内容を統合
   - 重複を除去し、時系列または論理的にグループ化する

### Step 5: Present Summary for Review

Show the user what will be added:
```
## やったこと（追記予定）

- [Item 1]
- [Item 2]
- ...

## 未完了タスク（Things3に残っているタスク）

- [Open task 1]
- [Open task 2]

この内容でよろしいですか？
```

Wait for user confirmation or edits.

### Step 6: Append to Daily Note

After confirmation, append to the "やったこと" section:
```
mcp__mcp-obsidian__obsidian_patch_content with:
  filepath: "daily/YYYY-MM-DD.md"
  operation: "append"
  target_type: "heading"
  target: "やったこと"
  content: [the summary]
```

### Step 7: Confirm Completion

Report to the user:
```
daily/YYYY-MM-DD.md の「やったこと」セクションに追記しました。

Things3の未完了タスク:
- [remaining tasks]
```

## Output Format

Always respond in Japanese.

## Notes

- If the "やったこと" section doesn't exist, append to the end of the file
- Keep the summary concise but informative
- Use bullet points for readability
- **Things3の完了タスクを主な情報源として使う**
- Things3の未完了タスクは翌日への引き継ぎとして報告する
