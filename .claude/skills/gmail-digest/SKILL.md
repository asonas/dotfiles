---
name: gmail-digest
description: Summarize Linear notifications and Datadog Daily Digest from Gmail, then append to today's Obsidian daily note. Use as standalone or as part of /morning workflow.
---

# /gmail-digest - Gmail Digest Summary

Linear通知とDatadog Daily DigestをGmailから取得し、Obsidianのdaily noteにまとめて追記する。

## Workflow

### Step 1: Search for target emails

以下を並行で検索する:

```
# Linear通知（個別通知 + まとめ通知）
mcp__claude_ai_Gmail__search_threads with query: "in:inbox from:linear.app newer_than:3d"

# Datadog Daily Digest（直近のもの）
mcp__claude_ai_Gmail__search_threads with query: "in:inbox from:no-reply@dtdg.co subject:Daily Digest newer_than:3d"
```

### Step 2: Process Linear notifications

1. 検索結果の件名（subject）から通知内容を抽出する
   - 件名パターン例: `Issue [CTI-893] タイトル added to the プロジェクト名...`
   - 件名パターン例: `Linear auto-closed CTI-207, and changed the status to Canceled`
   - 件名パターン例: `N unread notifications on IVRy`（まとめ通知、詳細なし）
2. 個別通知の件名からissue ID、タイトル、アクション（追加/クローズ/ステータス変更等）を抽出する
3. まとめ通知（`N unread notifications`）は未読件数のみ記録する
4. **注意:** Linear通知メールの本文にはリンクのみで詳細がない。件名が唯一の情報源

### Step 3: Process Datadog Daily Digest

1. 最新のDigestスレッドを `get_thread` で取得する
2. Datadogメールは **HTML形式のみ** でplaintextBodyが存在しない場合がある。snippetから情報を抽出する
3. 抽出する情報:
   - 対象日付
   - Metric Alerts件数
   - Total Events件数
   - Triggered（未解決）のアラート内容
   - Recovered（解決済み）のアラート概要
   - 重要度（P1/P2/P3）
4. 前日分のDigestも取得し、傾向の変化を把握する

### Step 4: Write to Obsidian daily note

今日のdaily noteに以下のセクションを追記する:

```
mcp__mcp-obsidian__obsidian_append_content with filepath: "daily/YYYY-MM-DD.md"
```

**Linear通知セクションのフォーマット:**
```markdown
## Linear通知まとめ

[個別通知があればissue IDをwikiリンク `[[CTI-XXX]]` にして、内容を散文で記述する。]
[まとめ通知の未読件数を記載し、Linear Inboxの確認を促す。]
```

**Datadogセクションのフォーマット:**
```markdown
## Datadog Daily Digest (MM/DD分)

[アラート件数、Triggered/Recoveredの内訳、重要なアラートの内容を散文で記述する。]
[前日との比較があれば記載する。]
```

**文章スタイル:**
- 箇条書きは使わず散文で書く（Obsidianルールに従う）
- issue IDは `[[CTI-XXX]]` のwikiリンクにする
- サービス名は `[[Datadog]]`、`[[Linear]]`、`[[Step Functions]]` 等のwikiリンクにする（初出のみ）
- 冷静で論理的な文体

### Step 5: Report summary

処理結果をユーザーに簡潔に報告する:

```
### メール通知サマリー
- Linear: 個別通知N件、未読通知N件
- Datadog: [直近のアラート状況の要約]
```

## /morning への組み込み

`/morning` から呼び出す場合は、daily note作成（Step 7）の後に実行する。
daily noteが既に存在する前提で `obsidian_append_content` で追記する。

## Notes

- Linear通知メールの本文にはリンクのみ。件名が唯一の情報源
- Datadog DigestはHTML形式のみの場合がある。snippetから最大限情報を抽出する
- 該当メールがない場合はそのセクションをスキップする
- Always respond in Japanese
