---
name: morning
description: Use when starting the day. Organizes tasks, calendar, and context from previous sessions, then coaches through blockers on Linear issues via interactive dialogue.
disable-model-invocation: true
---

# /morning - Daily Standup Support

スクラムのデイリースタンドアップを支援する。四半期ゴールに対する進捗の検査（Inspect）と、次の作業日の計画の適応（Adapt）を行う。

## Workflow

### Step 1: Get Current Date and Time
Use the Google Calendar MCP to get the current time:
```
mcp__google-calendar__get-current-time
```

### Step 2: Get Today's Calendar Events
Fetch today's calendar events:
```
mcp__google-calendar__list-events with calendarId: "primary", timeMin: today 00:00, timeMax: today 23:59
```

### Step 2.5: Gmail Triage
`/gmail-triage` スキルを実行してInboxを整理する。結果は Step 8 のサマリーに含める。

### Step 3: Read Previous Daily Note(s)
直前の営業日（または直近でdaily noteが存在する日）のノートを読む。

**探索ロジック:**
`~/.claude/scripts/find-recent-daily-notes.sh` を実行して対象日付を取得する。スクリプトは以下のロジックを封じ込めている:
- 月曜日実行時: 金・土・日の3日分それぞれ存在するものを全て出力（土日作業の引き継ぎ漏れ防止）
- 火〜日曜日実行時: 前日から最大7日遡り、最初に見つかった1日を出力
- 見つからなければ exit 1

```bash
# 対象日一覧を取得
~/.claude/scripts/find-recent-daily-notes.sh
# → 2026-04-13  のように日付が1行ずつ出力される
```

取得した各日付について daily note を読む:

```bash
obsidian read path="daily/YYYY-MM-DD.md" 2>/dev/null
```

スクリプトが非0終了（7日遡っても見つからない）の場合はこのステップをスキップする。

Extract from the note(s):
- Uncompleted tasks (lines starting with `- [ ]`)
- Items marked for tomorrow (containing "明日", "tomorrow", "次回")
- Any notes or reflections
- 複数日分のノートが見つかった場合はすべてマージして引き継ぎ情報を抽出する

### Step 3.5: Read Quarterly Goals and Linear Active Issues

**四半期ゴールの読み込み:**
現在の四半期ゴールファイルを読む。ファイル名は `goals/YYYY-qN.md` の形式。

**四半期の自動算出:**
Step 1で取得した現在日付から以下のルールで `YYYY-qN` を導出する:
- 1〜3月 → `YYYY-q1`
- 4〜6月 → `YYYY-q2`
- 7〜9月 → `YYYY-q3`
- 10〜12月 → `YYYY-q4`

例: 2026-04-15 → `goals/2026-q2.md`、2026-10-01 → `goals/2026-q4.md`

```bash
# 例（2026-q2の場合）
obsidian read path="goals/2026-q2.md" 2>/dev/null
```

ファイルが存在しない場合（未作成の四半期）はスキップしてユーザーに通知する。
→ ゴール一覧をメモリに保持し、Step 8のStandup Hearingで使う。

**Linear アクティブIssueの取得（Phase 1）:**
Linear MCPが認証済みであれば、自分にアサインされたアクティブなissueを取得する。
認証されていない場合はスキップし、Things3のタスク一覧で代替する。

→ 取得したissue一覧はStep 8の「今日やること」ヒアリング時のコンテキストに使う。

### Step 4: Query Memory for Carryover Items
Search memory-vector for items mentioned as future tasks:
```
mcp__memory-vector__search_memory with query: "明日やる 次回 tomorrow next time TODO"
```

**memory-vector が停止している場合:** エラーが返ったらこのステップをスキップして次へ進む。Step 3で読んだdaily noteからの引き継ぎ情報とThings3のタスクがあれば最低限の運用は可能。

### Step 5: Read Current Things3 Tasks
Read existing tasks in Things3 "今日" list to avoid duplicates:
```
Bash: ~/.claude/scripts/things-today.sh
```

### Step 6: Add TODO Items to Things3

#### 6a: カレンダーの予定 → 個別タスク（タグ: "Calendar"）

カレンダーイベントを各予定ごとに個別タスクとして追加する。タイトルの先頭に絵文字を付け、時刻を含め、タグに"Calendar"を設定する:
```
Bash: ~/.claude/scripts/things-add.sh "📅 10:00-10:30 朝会" "" "Calendar"
```

- タイトルの形式: "📅 HH:MM-HH:MM イベント名"（終了時刻がない場合は "📅 HH:MM イベント名"）
- 終日イベントは "📅 終日: イベント名" とする
- Things3に既に同名のタスクが存在する場合はスキップ
- 以下のイベントはThings3に追加しない:
  - 「子の送迎や会社移動の時間（予定をいれたい場合はご一報ください）」（ブロッカー）
  - 「送迎で不在」（ブロッカー）
  - 自分（asonas@ivry.jp）の `responseStatus` が `"declined"` のイベント（不参加を明示済み）
- `responseStatus` が `"accepted"`, `"needsAction"`, `"tentative"` のイベント、または attendees がないイベントは追加する

#### 6b: 前日の未完了タスク

前日からの引き継ぎタスクは個別タスクとして追加する（従来通り）:
```
Bash: ~/.claude/scripts/things-add.sh "タスク名" "メモ（任意）"
```

- Things3に既に存在するタスクはスキップ

### Step 7: Create Today's Daily Note in Obsidian
**IMPORTANT: Always create today's daily note.**

公式CLIで今日のdaily noteを作成する。既に存在する場合は上書きしない。
```bash
# 存在チェック（exit code 0 かつ非空なら存在）
obsidian read path="daily/YYYY-MM-DD.md" 2>/dev/null
```

存在しなければ作成する:
```bash
obsidian create path="daily/YYYY-MM-DD.md" content="<daily note本文>" 2>/dev/null
```

Daily note format (TODOセクションは不要、Thingsで管理するため):
**IMPORTANT: `# YYYY-MM-DD` のようなh1ヘッディングは絶対に含めないこと。** Obsidianではファイル名がタイトルになるため重複する。ノートは `[[IVRy]]` から直接始めること。
```markdown
[[IVRy]]

## 今日の予定

| 時間 | 予定 |
|------|------|
| HH:MM-HH:MM | イベント名 |
...

## 前日からの引き継ぎ

- [直近のdaily noteからのサマリー（複数日分ある場合はまとめて記載）]

## やったこと



## 昨日やったこと

**見出しは対象日に応じて変えること:**
- 前日が通常の営業日 → `## 昨日やったこと`
- 月曜日に実行 → `## 先週金曜日にやったこと`
- 前日（または前日以降の直近日）が祝日/休日の場合 → 直近の営業日まで遡り、見出しをその日を指す表現に変更する（例: `## 先週金曜日にやったこと`、`## 月曜日にやったこと`、`## MM/DD(曜)にやったこと`）

**対象日の決定ロジック:**
1. 前日から1日ずつ遡る
2. 日本の祝日、土日、daily noteが存在しない日はスキップ
3. cm-searchで作業セッションが見つかる、またはdaily noteが存在する最初の日を対象日とする

cm-searchとdaily noteを突き合わせて箇条書きで記載する。**Wikiリンクは使わない**（チームメイト向けの情報のため）。

- 作業項目A
- 作業項目B
- 作業項目C

## 今日やること

**カレンダーの予定は書かない。** ユーザーにヒアリングした結果のみを箇条書きで記載する。**Wikiリンクは使わない。**

- タスクA
- タスクB

## 困りごと・ブロッカー

[ユーザーにヒアリングして記載。なければ「特になし」]
[ブロッカーがある場合は、誰に相談/エスカレーションするかまで記載する]

```

### Step 7.5: Gmail Digest
`/gmail-digest` スキルを実行してLinear通知とDatadog Daily Digestをdaily noteに追記する。

### Step 8: Standup Hearing（検査と適応）
daily noteの作成後、ユーザーに以下をヒアリングしてdaily noteの該当セクションに記入する。
**スタンドアップ3項目のセクションはチームメイト向け。Wikiリンクは使わず、箇条書きで書く。**

#### 8a. 昨日やったこと（Inspect: 実績の検査）
対象日は「前営業日」(前日→土日祝日はスキップ)。まず `cm-search` スキル(`Skill: cman:cm-search`)で対象日のセッション履歴を引き、さらに対象日のdaily noteの「やったこと」セクションも参照してベースを作成する。両方を突き合わせて箇条書きで提示し、追加・修正がないかユーザーに確認する。どちらも無ければユーザーに聞く。
- daily noteのセクション見出しは対象日に応じて変える:
  - 前日が通常の営業日 → `## 昨日やったこと`
  - 月曜日実行 → `## 先週金曜日にやったこと`
  - 祝日等で前日より前に遡った場合 → `## 月曜日にやったこと` / `## MM/DD(曜)にやったこと` のように対象日を明示

#### 8b. 今日やること（Adapt: 計画の適応）
AskUserQuestionで以下をコンテキストとして質問文に含め、ユーザーに「今日やること」を聞く:
- **四半期ゴール**: Step 3.5で読み込んだ `goals/YYYY-qN.md` の内容を簡潔に列挙
- **Things3のタスク一覧**: Step 5で取得したタスク
- **Linear アクティブIssue**: Step 3.5で取得できた場合
- **カレンダーの予定**: ミーティングが多い日は作業時間が限られることを示唆

ユーザーが回答した内容のみを箇条書きでdaily noteに記入する。カレンダーの予定は自動的には書かない。

**適応の問いかけ（Phase 3）:**
「今日やること」のヒアリング時に、昨日の結果を踏まえて以下を確認する:
- 昨日ブロックされたタスクがあれば、今日の計画をどう変えるか
- 四半期ゴールの達成に向けて、今日の作業が貢献しているか
- 計画の変更が必要な兆候（タスクの滞留、新たなブロッカーの発生等）がないか

これらは質問に織り込む形で自然に聞く（堅苦しいチェックリストにしない）。

#### 8c. 困りごと・ブロッカー（Impediments）
何かあれば自由に記入。なければ「特になし」。
ブロッカーがある場合は、**誰に相談/エスカレーションするか**まで含めて記録する。
四半期ゴールに対して障害になっているものがないかも確認する。

**注意:**
- ユーザーが会話の中で既に回答している場合（例:「昨日は休みだった」「今日はXXXをやる」）は、改めて聞かずにそのまま記入する
- ヒアリングが必要な場合は、サマリー表示の前にまとめて聞く

### Step 9: Present Summary
Present to the user:

```
## おはようございます - YYYY年MM月DD日

### Q2 ゴール
[四半期ゴールの一覧を簡潔に表示]

### 今日の予定
[Calendar events listed with times, chronologically sorted]

### 前日からの引き継ぎ
[Uncompleted tasks from yesterday's daily note]

### Things3に追加したタスク
- Calendar: [count]件の個別タスクを追加（タグ: Calendar）
- [その他個別タスク]

### メール通知サマリー
- Linear: [要約]
- Datadog: [要約]

---
Obsidianのdaily noteを作成しました: daily/YYYY-MM-DD.md
```

## Output Format

Always respond in Japanese. Present information in a clear, organized format that helps the user start their day efficiently.

## Notes

- If yesterday's daily note doesn't exist, skip that section
- If no calendar events, mention "今日の予定はありません"
- **Daily noteの作成は必須** - 必ずObsidianに書き出すこと
- **タスク管理はThings3で行う** - Obsidianのdaily noteにはTODOセクションを書かない
- Things3への追加時、既に同名のタスクが存在する場合は重複追加しない
