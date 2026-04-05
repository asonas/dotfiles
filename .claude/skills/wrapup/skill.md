---
name: wrapup
description: Summarize the day's work and append to the daily note in Obsidian.
argument-hint: "[date]"
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

Collect information about what was done from the following sources. Each source captures different aspects of the day's work, so all should be checked.

1. **From Things3 (Step 3)**
   - Completed tasks are the primary source for "やったこと"
   - Open tasks become carry-over items

2. **From the current session context**
   - Claude Codeは現在のセッション内で行われた全ての会話・作業を記憶している
   - セッション中に実施した実装、調査、修正、意思決定を抽出する
   - 変更・作成したファイルの一覧を含める
   - memory-*に明示的に保存していない内容もここから拾える

3. **From Claude Code auto memory（永続メモリ）**
   - セッションを跨いで保持されるメモリファイルを参照する
   - auto memoryディレクトリのパスはシステムプロンプトに記載されている（「You have a persistent auto memory directory at ...」の箇所）
   - そのディレクトリ内のMEMORY.mdおよびトピック別ファイル（例: debugging.md, patterns.md）を確認する
   - 今日の日付や作業内容に関連するエントリがないか確認する
   - 今日のセッションで更新されたメモリファイルがあれば、その内容も作業実績として含める

4. **From memory-vector / memory-graph**
   - 必ず両方を検索して、今日の作業内容を収集する
   - 複数のクエリで検索を行い、漏れがないようにする:
   ```
   # memory-vector: 日付ベースの検索
   mcp__memory-vector__search_memory with query: "2026-02-05" (対象日付)

   # memory-vector: 作業内容ベースの検索
   mcp__memory-vector__search_memory with query: "today work investigation implementation fix"

   # memory-vector: リポジトリ名での検索
   mcp__memory-vector__search_memory with query: "dotfiles" など
   # カレントディレクトリからリポジトリ名を取得して検索に使用する

   # memory-graph: 関連エンティティの検索
   mcp__memory-graph__graphiti_search with query: 対象日付や作業キーワード
   ```
   - `createdAt` フィールドを確認し、対象日に作成された記録を優先する
   - `source` フィールドにリポジトリ名が含まれている記録を優先する
   - 検索結果から重複を除いて、今日実施した作業を抽出する

5. **情報の統合**
   - 上記4つのソースを統合する
   - 優先順位: セッションコンテキスト >= Things3完了タスク > auto memory > memory-vector/memory-graph
   - セッションコンテキストにはmemory-*に保存されていない情報が含まれるため、特に重視する
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
