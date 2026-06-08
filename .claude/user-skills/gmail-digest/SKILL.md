---
name: gmail-digest
description: Summarize Linear notifications and Datadog Daily Digest from Gmail. Standalone only — explicitly invoke when needed. No longer auto-called from /today.
---

# /gmail-digest - Gmail Digest Summary

Linear通知とDatadog Daily DigestをGmailから取得して要約する。

**運用状況 (2026-05-26 更新):** Linear通知 / Datadog Daily Digest の daily note 自動追記は廃止した。`/today` フローからの呼び出しは外され、現在は明示的に `/gmail-digest` と叩いた時のみ動作する。Daily note への append が必要な場合は `## ログ` セクション末尾に Read + Edit で挿入すること（旧フォーマットの `## Linear通知まとめ` / `## Datadog Daily Digest` セクションは新規作成しない）。

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

今日のdaily noteに以下のセクションを追記する。Obsidian公式CLIを使う:

```bash
obsidian append vault=asonas path="daily/YYYY-MM-DD.md" content="<セクション本文>" 2>/dev/null
```

- 改行は `\n` でエスケープする

**追記位置について:**

Obsidian公式CLIの `append` は **ファイル末尾への追記のみ** 対応する（heading指定の挿入不可）。このスキルは末尾への追記を前提に設計している。

- daily note は /today のテンプレで「予定 → 引き継ぎ → やったこと → 昨日やったこと → 今日やること → 困りごと」のセクション順になっており、末尾にLinear通知/Datadog Digestが追加される配置で問題ない
- スタンドアップ3項目（やったこと/今日やること/困りごと）をLinear/Datadogより上に表示したい場合、`/today` の実行順序は **Step 7 (daily note作成) → Step 7.5 (gmail-digest) → Step 8 (Standup Hearing)** を守ること。Step 8 のRead+Editでスタンドアップ項目を埋めた後にgmail-digestを実行すると順序が崩れる
- 特定セクションの下に挿入したい場合は、`obsidian append` ではなく `/Users/asonas/Documents/asonas/daily/YYYY-MM-DD.md` を Read + Edit ツールで直接編集する（`wrapup` や `daily-log` と同じパターン）

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

## /today への組み込み

`/today` から呼び出す場合は、daily note作成（Step 7）の後に実行する。
daily noteが既に存在する前提で `obsidian append` で追記する。

## Notes

- Linear通知メールの本文にはリンクのみ。件名が唯一の情報源
- Datadog DigestはHTML形式のみの場合がある。snippetから最大限情報を抽出する
- 該当メールがない場合はそのセクションをスキップする
- Always respond in Japanese
