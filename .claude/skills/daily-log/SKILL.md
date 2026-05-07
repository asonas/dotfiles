---
name: daily-log
description: End-of-day review command that helps reflect on the day's work and prepare for tomorrow.
disable-model-invocation: true
---

# /daily-log - Daily Review and Reflection

1日の終わりに振り返りを行い、翌日への引き継ぎを整理するスキル。daily note の「振り返り」「明日やること」セクションを対話的に埋める。

`/wrapup` は「やったこと」セクションに事実を追記するのに対し、`/daily-log` は **主観的な振り返り**（Good / Could be better）と **翌日の計画** を対話で作る点が異なる。

## Usage

```
/daily-log
```

## Instructions

### Step 1: Load Today's Daily Note

今日のdaily noteを読み込む。公式CLIまたはReadツールを使う。

```bash
obsidian read path="daily/YYYY-MM-DD.md" 2>/dev/null
```

または:
```
Read: /Users/asonas/Documents/asonas/daily/YYYY-MM-DD.md
```

ノートから以下を抽出する:
- 「今日やること」セクションの箇条書き → Step 2 のタスクレビューに使う
- 「やったこと」セクションの箇条書き → Step 2 の完了判定の参考にする

daily noteが存在しない場合はユーザーに通知してスキルを終了する（`/morning` を先に実行する必要がある）。

### Step 2: Task Review (Interactive)

「今日やること」の各タスクについて、完了・繰越・不要・保留を対話で確認する。

1. タスク一覧を番号付きで提示する
2. `AskUserQuestion` で「完了したタスクの番号をカンマ区切りで教えてください」と聞く
3. 未完了タスク1つずつについて、以下の選択肢から選んでもらう:
   - 明日に繰り越し
   - もう不要
   - 保留（Things3のInbox等に戻す）

### Step 3: Reflection (Interactive)

以下を `AskUserQuestion` で順に聞く:

1. **Good (うまくいったこと)**: 「今日うまくいったことは何ですか？」
2. **Could be better (改善できること)**: 「改善できそうなことはありますか？」
3. **Tomorrow's priorities (明日やること)**: 「明日やりたいことはありますか？」（Step 2で繰り越しと判断したタスクは自動的に含める）

### Step 4: Save Daily Log

Obsidian公式CLIは heading指定のinsertに対応していないため、Vaultの実ファイルを Read + Edit ツールで編集する。

```
# Read tool:
Read: /Users/asonas/Documents/asonas/daily/YYYY-MM-DD.md

# Edit tool: ファイル末尾に「振り返り」と「明日やること」セクションを追加
# old_string: 既存ファイル末尾の一意な文字列（例: 最後のセクションの末尾行）
# new_string: 既存末尾 + 以下のセクション
```

追記するセクションの書式:

```markdown
## 振り返り

### Good
- [ユーザーの回答]

### Could be better
- [ユーザーの回答]

## 明日やること

- [Step 2 で繰り越したタスク]
- [Step 3 で追加されたタスク]
```

**注意:**
- `# YYYY-MM-DD` のようなh1ヘッディングは絶対に追加しないこと（ファイル名がタイトルになるため）
- 既に「振り返り」「明日やること」セクションが存在する場合は上書きではなく、既存項目の末尾に追記するか、ユーザーに確認してから上書きする
- Obsidianはファイルシステムの変更を自動で検知するため、Edit後に再読み込み操作は不要

### Step 6: Confirm Completion

ユーザーに以下を報告する:
- 完了したタスク数
- 明日に繰り越したタスク一覧
- daily note に追記したこと
- 翌日の `/morning` が明日やることを引き継ぐこと

## Output Format

対話は低摩擦を優先する。選択肢がある場合は番号付きで提示して、最小限のタイピングで回答できるようにする。Always respond in Japanese.

## Notes

- `/morning` と対になる運用: `/morning` が「今日やること」を作り、`/daily-log` がその結果をレビューする
- 「明日やること」セクションは翌日の `/morning` が Step 3 の「前日からの引き継ぎ」として参照する
