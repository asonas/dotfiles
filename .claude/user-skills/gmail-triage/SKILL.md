---
name: gmail-triage
description: Triage Gmail inbox by archiving noise emails (Google Meet, Calendar invitations, dev@ivry.jp without action needed) and surfacing actionable items. Use as standalone or as part of /morning workflow.
---

# /gmail-triage - Gmail Inbox Triage

Inboxのノイズメールを自動アーカイブし、アクションが必要なものだけユーザーに通知する。

## Workflow

### Step 1: Search for target emails in INBOX

以下の3カテゴリを並行で検索する:

```
# Google Meetからのメール
mcp__claude_ai_Gmail__search_threads with query: "in:inbox from:meetings-noreply@google.com"

# Googleカレンダーの招待・更新メール
mcp__claude_ai_Gmail__search_threads with query: "in:inbox (subject:招待 OR subject:更新 OR subject:invitation OR subject:updated invitation) (subject:(JST) OR subject:(GMT) OR from:calendar-notification@google.com)"

# dev@ivry.jp からのメール
mcp__claude_ai_Gmail__search_threads with query: "in:inbox to:dev@ivry.jp"
```

**注意:** pageSize はデフォルト(20)で十分。大量にある場合はページネーションする。

### Step 2: Process each category

#### Category A: Google Meet メール
- 条件: `from:meetings-noreply@google.com`
- 処理: **無条件でアーカイブ**（INBOXラベルを除去）
- ユーザー通知: 不要（件数のみサマリーで報告）

#### Category B: Googleカレンダーの招待・更新メール
- 条件: 以下のいずれかに該当するメール
  - 件名に「招待」「更新」「invitation」「updated invitation」を含む
  - 件名に日時情報（曜日、時刻、JST/GMTなど）を含む
  - `from:calendar-notification@google.com`
  - 件名パターン例: 「招待 - 更新: [office]会議名 - 2026年 4月 14日 (火) 午後6:30 ~ 午後8時 (JST) (名前)」
  - 参加者の追加・削除通知もこのカテゴリに含む
- 処理: **アーカイブ**（INBOXラベルを除去）
- **重要:** 送信者（From）ではなくメールの内容・件名パターンで判定すること。主催者個人のメールアドレスでフィルタしてはならない
- ユーザー通知: 不要（件数のみサマリーで報告）

#### Category C: dev@ivry.jp からのメール
- 条件: `to:dev@ivry.jp`
- 処理:
  1. `get_thread` で各スレッドの本文を読む
  2. メール内容を分析し、**アクションが必要かどうか**を判定する
  3. アクション判定基準:
     - **アクション必要**: 依頼、質問、レビュー要求、障害通知、期限付きタスク、返信を求めるもの
     - **アクション不要**: 機能紹介、リリースノート、週報・月報の共有、FYI系、bot通知で対応不要なもの
  4. アクション不要 → アーカイブ（通知なし）
  5. アクション必要 → アーカイブ **しない**。ユーザーに内容を要約して通知する

### Step 3: Archive emails

各対象スレッドに対してINBOXラベルを除去する:

```
mcp__claude_ai_Gmail__unlabel_thread with threadId: "xxx", labelIds: ["INBOX"]
```

### Step 4: Report summary

処理結果をユーザーに報告する:

```
## Gmail Triage 完了

### アーカイブ済み
- Google Meet: N件
- カレンダー招待/更新: N件
- dev@ivry.jp (アクション不要): N件

### 要アクション (dev@ivry.jp)
- **[件名]**: [要約とアクション内容]
- **[件名]**: [要約とアクション内容]

（該当なしの場合: 「要アクションのメールはありません」）
```

## /morning への組み込み

`/morning` から呼び出す場合は、Step 2（カレンダー取得）の後、Step 3（前日ノート読み込み）の前に実行する。
`/morning` のサマリーに Gmail Triage の結果も含める。

## Notes

- アーカイブは INBOX ラベルの除去であり、メールの削除ではない
- 判断に迷うメール（dev@ivry.jp）はアーカイブせずユーザーに判断を委ねる
- 既に INBOX にないメール（既読・アーカイブ済み）は処理対象外
- Always respond in Japanese
