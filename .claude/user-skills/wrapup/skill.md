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
```bash
obsidian read vault=asonas path="daily/YYYY-MM-DD.md" 2>/dev/null
```

または、Readツールで直接:
```
Read: /Users/asonas/Documents/asonas/daily/YYYY-MM-DD.md
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

4. **情報の統合**
   - 上記3つのソースを統合する
   - 優先順位: セッションコンテキスト >= Things3完了タスク > auto memory
   - セッションコンテキストには他のソースに保存されていない情報が含まれるため、特に重視する
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

After confirmation, append under the "## やったこと" heading. 公式CLIはheading指定のinsertに対応していないため、Vaultの実ファイルをReadツールで読んでEditツールで挿入する。

```
# Read tool:
Read: /Users/asonas/Documents/asonas/daily/YYYY-MM-DD.md

# Edit tool: "## やったこと" 直下に追記
# old_string: "## やったこと\n\n" (または既存の内容の末尾を含む一意なスニペット)
# new_string: "## やったこと\n\n- [Item 1]\n- [Item 2]\n...\n"
```

**注意:**
- `## やったこと` セクションに既存のエントリがある場合は、その末尾に追記する。Editツールで old_string を末尾行にし、new_string にサマリーを加えて書き戻す
- Obsidianはファイルシステムの変更を自動で検知するので、Edit後に特別な再読み込み操作は不要
- **daily note に `# YYYY-MM-DD` 等のh1ヘッディングを絶対に追加しないこと**。ファイル名がObsidian上のタイトルになるため重複する。既存ノートにh1を混入させないためEdit時は慎重に

### Step 7: Bluesky 投稿の取り込み

tempest CLI 経由でその日の自分の Bluesky 投稿を取得し、`activities/YYYY-MM-DD.md` の Bluesky セクションに反映する。`/wiki-update` がこのファイルを後段でソースとして読むため、wiki 化前に実行する。

```bash
cd /Users/asonas/workspace/activities

# 取得: state を見て前回実行以降の差分を取り込む
mise exec -- bundle exec bin/activities-collect --source bluesky --no-render || echo "Warning: bluesky collect failed, skipping"

# 描画: その日の activities ファイルを再生成
mise exec -- bundle exec bin/activities-render --source bluesky --date YYYY-MM-DD || true
```

`/wrapup` を一日の終わりに回す前提なので、当日分だけ再描画すれば足りる (前日分は朝の `/morning` 6a-2 でカバーされている)。

### Step 8: Update Obsidian Wiki

daily note への追記が完了したら、`/wiki-update` スキルを `ingest <target-date>` モードで呼び出し、当日の daily note と activities ファイルから固有名詞・概念を抽出して `wiki/` 配下のページに統合する。ユーザへの確認は不要。

```
Skill(wiki-update, args: "ingest <YYYY-MM-DD>")
```

`<YYYY-MM-DD>` は Step 1 で確定した対象日。`today` 引数で wrapup を起動した場合は `ingest today` でもよい。

### Step 9: Confirm Completion

Report to the user:
```
daily/YYYY-MM-DD.md の「やったこと」セクションに追記しました。
wiki/ を更新しました（更新 N ページ、新規 M ページ）。

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
