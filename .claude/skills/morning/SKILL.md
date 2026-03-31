---
name: morning
description: Use when starting the day. Organizes tasks, calendar, and context from previous sessions, then coaches through blockers on Linear issues via interactive dialogue.
disable-model-invocation: true
---

# /morning - Morning Task Organization

Start your day with an organized view of tasks, calendar, and context from previous sessions.

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

### Step 3: Read Previous Daily Note(s)
直前の営業日（または直近でdaily noteが存在する日）のノートを読む。

**探索ロジック:**
1. 前日の日付から遡って最大7日間、daily noteを探す
2. `mcp__mcp-obsidian__obsidian_get_file_contents` で `daily/YYYY-MM-DD.md` を試行し、404なら1日前に遡る
3. 見つかったノートを「直近のdaily note」として使用する
4. 月曜日の場合は金曜・土曜・日曜の3日分すべてを探し、見つかったものすべてを読む（土日に作業した場合の引き継ぎ漏れを防ぐ）
5. 7日遡っても見つからない場合はスキップする

```
# 月曜日の例:
mcp__mcp-obsidian__obsidian_get_file_contents with filepath: "daily/2026-03-06.md" (金曜)
mcp__mcp-obsidian__obsidian_get_file_contents with filepath: "daily/2026-03-07.md" (土曜)
mcp__mcp-obsidian__obsidian_get_file_contents with filepath: "daily/2026-03-08.md" (日曜)

# 火〜日曜日の例:
# 前日から遡って最初に見つかったノートを使う
```

Extract from the note(s):
- Uncompleted tasks (lines starting with `- [ ]`)
- Items marked for tomorrow (containing "明日", "tomorrow", "次回")
- Any notes or reflections
- 複数日分のノートが見つかった場合はすべてマージして引き継ぎ情報を抽出する

### Step 4: Query Memory for Carryover Items
Search memory-vector for items mentioned as future tasks:
```
mcp__memory-vector__search_memory with query: "明日やる 次回 tomorrow next time TODO"
```

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

Use Obsidian MCP to create today's daily note:
```
mcp__mcp-obsidian__obsidian_append_content with filepath: "daily/YYYY-MM-DD.md" (today's date)
```

Daily note format (TODOセクションは不要、Thingsで管理するため):
**IMPORTANT: `# YYYY-MM-DD` のようなh1ヘッディングは絶対に含めないこと。** Obsidianではファイル名がタイトルになるため重複する。また、h1ヘッディングがあると `obsidian_patch_content` で `## やったこと` 等のh2ヘッディングをターゲットにする際に `YYYY-MM-DD::やったこと` のような階層パス指定が必要になり、/wrapup との連携が壊れる。ノートは `[[IVRy]]` から直接始めること。
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



```

### Step 8: Present Summary
Present to the user:

```
## おはようございます - YYYY年MM月DD日

### 今日の予定
[Calendar events listed with times, chronologically sorted]

### 前日からの引き継ぎ
[Uncompleted tasks from yesterday's daily note]

### Things3に追加したタスク
- Calendar: [count]件の個別タスクを追加（タグ: Calendar）
- [その他個別タスク]

---
Obsidianのdaily noteを作成しました: daily/YYYY-MM-DD.md
```

### Step 9: Coaching Session

サマリー提示後、Linearのイシューをもとに対話型のコーチングを行い、行動に移せる状態にする。

**基本姿勢:**
- 答えを与えるのではなく、質問で本人の中から答えを引き出す
- 「やるべき」ではなく「やれる」「やりたい」にフォーカスする
- 判断を急がない。「分からない」も受け入れる
- 必ず具体的な行動まで落とし込んで終える

#### 9a: Linearイシューの取得

`mcp__linear-server__list_issues` で自分にアサインされたイシューを取得する（ステータス: In Progress, Todo）。
Linear MCPが利用不可の場合は「今抱えているタスクや気になっていることを教えてください」とフリーテキストで聞く。

#### 9b: 気になるものを選ぶ

AskUserQuestionでイシュー一覧を提示する（最大4件。5件以上ある場合は優先度・更新日時で上位を選び、残りは「その他」で入力可能にする）:

> この中で、今日気になっているもの・引っかかっているものはどれですか?
> 全部でなくていいです。直感で選んでください。

- ユーザーが「特にない」「順調」と答えた場合 → 9fに進む
- 複数選択された場合は1つずつ順番に9c〜9eを行う

#### 9c: 状況を聞く

選んだイシューについてオープンに聞く。ここからはフリーテキストの対話で進める。

> [イシュー名]について、今どんな状態ですか?

ユーザーの返答をよく聞き、次のステップで使うブロッカーのパターンを識別する。

#### 9d: ブロッカーに応じたコーチング

ユーザーの言葉から以下のパターンを識別し、対応する問いかけで掘り下げる:

| パターン | シグナル | 問いかけの例 |
|----------|----------|-------------|
| 技術的不確実性 | 「どうすればいいか分からない」「調べないと」 | 分からないのは全体のアプローチ? それとも特定の部分? 30分調べるとしたら何を調べる? |
| スコープの曖昧さ | 「何が求められているか不明確」「仕様が...」 | 誰に聞けば明確になりそう? 自分で決められる範囲は? |
| 外部依存 | 「〇〇待ち」「誰かの確認が必要」 | 待っている間にできることは? 別タスクに切り替えるのもあり? |
| エネルギー不足 | 「重い」「面倒」「やる気が出ない」 | このタスクの中で、5分だけやるとしたらどの部分? 何が一番嫌? |
| 圧倒感 | 「多すぎる」「どこから手を付ければ」 | 今日これだけやれば"進んだ"と思えるものは何? |
| 完璧主義 | 「ちゃんとやらないと」「間違えたくない」 | まず60点のものを出すとしたら何を省ける? 最悪何が起きる? |

**注意:**
- 上記はあくまでガイド。決めつけず、対話を続けること
- 1つのパターンに収まらないことも多い
- ユーザーが話したいだけの場合は聞き役に徹してよい
- 問いかけは1回につき1つまで。矢継ぎ早に質問しない

#### 9e: 最初の一歩を決める

ブロッカーが見えてきたら、具体的なアクションに落とし込む:

> 今日の最初の一歩として、30分以内にできることを1つ決めましょう。
> できるだけ具体的に: 何を、どこで、どうやって。

決まったアクションをThings3に追加する:
```
Bash: ~/.claude/scripts/things-add.sh "アクション名" "メモ（任意）"
```

複数イシューを選んだ場合は9cに戻って次のイシューへ。

#### 9f: 追加タスクと締め

> 他に今日追加しておきたいタスクはありますか?

追加がある場合はThings3に登録する。最後に:

> いい一日にしましょう。困ったらいつでも声をかけてください。

## Output Format

Always respond in Japanese. Present information in a clear, organized format that helps the user start their day efficiently.

## Notes

- If yesterday's daily note doesn't exist, skip that section
- If no calendar events, mention "今日の予定はありません"
- **Daily noteの作成は必須** - 必ずObsidianに書き出すこと
- **タスク管理はThings3で行う** - Obsidianのdaily noteにはTODOセクションを書かない
- Things3への追加時、既に同名のタスクが存在する場合は重複追加しない
