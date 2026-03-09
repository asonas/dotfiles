---
name: morning
description: Start your day with an organized view of tasks, calendar, and context from previous sessions.
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

### Step 3: Get GitHub Assigned Issues
Fetch open issues assigned to the user (with URL):
```
Bash: gh api '/search/issues?q=is:issue+is:open+assignee:asonas&per_page=20' --jq '.items[] | "\(.repository_url | split("/") | .[-2])/\(.repository_url | split("/") | .[-1]) #\(.number): \(.title)\t\(.html_url)"'
```

### Step 4: Get GitHub PR Review Requests
Fetch open PRs where the user is requested as reviewer (with URL):
```
Bash: gh api '/search/issues?q=is:pr+is:open+review-requested:asonas&per_page=20' --jq '.items[] | "\(.repository_url | split("/") | .[-2])/\(.repository_url | split("/") | .[-1]) #\(.number): \(.title)\t\(.html_url)"'
```

### Step 4b: Get GitHub Authored PRs
Fetch open PRs authored by the user (with URL):
```
Bash: gh api '/search/issues?q=is:pr+is:open+author:asonas&per_page=20' --jq '.items[] | "\(.repository_url | split("/") | .[-2])/\(.repository_url | split("/") | .[-1]) #\(.number): \(.title)\t\(.html_url)"'
```

取得後、各PRのリポジトリがアーカイブされていないか確認する:
```
Bash: gh api '/repos/{owner}/{repo}' --jq '.archived'
```
- `archived` が `true` のリポジトリのPRは除外する
- API エラー時もそのPRをスキップする

### Step 5: Get Linear Issues
Fetch issues assigned to the user from Linear:
```
mcp__linear-server__list_issues with assignee: "me", status: not "Done" or "Canceled"
```
- 直近のアクティブなIssueのみ取得する（完了・キャンセル済みは除外）
- Project名やTeam名も含めて取得する

### Step 6: Read Previous Daily Note(s)
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

### Step 7: Query Memory for Carryover Items
Search memory-vector for items mentioned as future tasks:
```
mcp__memory-vector__search_memory with query: "明日やる 次回 tomorrow next time TODO"
```

### Step 8: Read Current Things3 Tasks
Read existing tasks in Things3 "今日" list to avoid duplicates:
```
Bash: ~/.claude/scripts/things-today.sh
```

### Step 8b: Clean Up Completed External Tasks

Things3の既存タスクのうち、外部ソース（GitHub PR / Linear Issue）のステータスが完了済みのものを自動的にDoneにする。

Step 8 で取得した Things3 タスク一覧を走査し、以下のルールでチェックする:

#### GitHub PR タスク（タグ: "Review required" / "My PR"）
- タスク名からリポジトリ名とPR番号を抽出する（例: `[Needs Your Review] ivry_web_backend#7671: ...` → `ivry-inc/ivry_web_backend` PR `7671`）
- `gh pr view <number> --repo <owner/repo> --json state --jq '.state'` でPRの状態を確認
- state が `MERGED` または `CLOSED` であれば Things3 で完了にする:
  ```
  Bash: ~/.claude/scripts/things-complete.sh "タスク名"
  ```

#### Linear タスク（タグ: "Linear"）
- タスク名から識別子を抽出する（例: `CPE-18: Design Doc [Dev Quickstart]` → `CPE-18`）
- `mcp__linear-server__get_issue` で Issue のステータスを確認
- status が `Done`, `Canceled`, または `Duplicate` であれば Things3 で完了にする:
  ```
  Bash: ~/.claude/scripts/things-complete.sh "タスク名"
  ```

#### 注意事項
- リポジトリ名の解決: Things3のタスク名に含まれるリポジトリ名（例: `ivry_web_backend`）は、Step 4/4b で取得した GitHub PR の情報と照合して `owner/repo` 形式を特定する
- GitHub API エラー時はスキップして次のタスクに進む
- 完了したタスクは Step 11 のサマリーで報告する

### Step 9: Add TODO Items to Things3

#### 9a: カレンダーの予定 → 個別タスク（タグ: "Calendar"）

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

#### 9b: GitHub Issues → 個別タスク（タグ: "GitHub Issue"）

アサインされたIssueがある場合、各Issueを個別タスクとして追加する。notesにURLを、タグに"GitHub Issue"を設定する:
```
Bash: ~/.claude/scripts/things-add.sh "🐛 repo#123: Issue title" "https://github.com/org/repo/issues/123" "GitHub Issue"
```

- タイトルの形式: "🐛 リポジトリ名#番号: Issue名"
- 各Issueごとに1つのタスクとして追加
- Things3に既に同名のタスクが存在する場合はスキップ
- Issueがない場合はタスクを作成しない

#### 9c: GitHub PR Reviews → 個別タスク（タグ: "Review required"）

レビュー依頼されたPRがある場合、各PRを個別タスクとして追加する。notesにURLを、タグに"Review required"を設定する:
```
Bash: ~/.claude/scripts/things-add.sh "👀 [Needs Your Review] repo#789: PR title" "https://github.com/org/repo/pull/789" "Review required"
```

- タイトルの形式: "👀 [Needs Your Review] リポジトリ名#番号: PR名"
- 各PRごとに1つのタスクとして追加
- Things3に既に同名のタスクが存在する場合はスキップ
- PRがない場合はタスクを作成しない

#### 9c2: GitHub Authored PRs → 個別タスク（タグ: "My PR"）

自分がauthorのPRがある場合、各PRを個別タスクとして追加する。notesにURLを、タグに"My PR"を設定する:
```
Bash: ~/.claude/scripts/things-add.sh "🚀 [Author] repo#456: PR title" "https://github.com/org/repo/pull/456" "My PR"
```

- タイトルの形式: "🚀 [Author] リポジトリ名#番号: PR名"
- アーカイブ済みリポジトリのPRは除外する（Step 4bで除外済み）
- 各PRごとに `gh pr view <number> --repo <owner/repo> --json state --jq '.state'` で状態を確認し、`OPEN` のもののみ追加する（GitHub Search APIのインデックス遅延対策）
- Step 4（レビュー依頼）と重複するPRは除外する（同じPRが両方に該当する場合はレビュー依頼側を優先）
- Things3に既に同名のタスクが存在する場合はスキップ
- PRがない場合はタスクを作成しない

#### 9d: Linear Issues → 個別タスク（タグ: "Linear"）

Linearのアクティブなタスクがある場合、各Issueを個別タスクとして追加する。notesにURLを、タグに"Linear"を設定する:
```
Bash: ~/.claude/scripts/things-add.sh "💎 CPE-13: Issue title [Project Name]" "https://linear.app/team/issue/CPE-13" "Linear"
```

- タイトルの形式: "💎 識別子: Issue名 [Project名]"（例: "💎 CPE-18: Design Doc [Dev Quickstart]"）
- Projectが未設定のIssueはProject名を省略する
- 各Issueごとに1つのタスクとして追加
- Things3に既に同名のタスクが存在する場合はスキップ
- Issueがない場合はタスクを作成しない

#### 9e: 前日の未完了タスク

前日からの引き継ぎタスクは個別タスクとして追加する（従来通り）:
```
Bash: ~/.claude/scripts/things-add.sh "タスク名" "メモ（任意）"
```

- Things3に既に存在するタスクはスキップ

### Step 10: Create Today's Daily Note in Obsidian
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

### Step 11: Present Summary
Present to the user:

```
## おはようございます - YYYY年MM月DD日

### 今日の予定
[Calendar events listed with times, chronologically sorted]

### GitHub
- **Issues**: [count]件のアサイン済みIssue
  - [issue list]
- **PR Reviews**: [count]件のレビュー依頼
  - [PR list]
- **My PRs**: [count]件の自分のPR
  - [PR list]

### Linear
- [Linear issue list]

### 前日からの引き継ぎ
[Uncompleted tasks from yesterday's daily note]

### Things3の自動クリーンアップ
- [完了にしたタスク一覧（マージ済みPR、Done済みLinear Issue）]
- （なければ「自動完了したタスクはありません」）

### Things3に追加したタスク
- Calendar: [count]件の個別タスクを追加（タグ: Calendar）
- GitHub Issues: [count]件の個別タスクを追加（タグ: GitHub Issue）
- PR Reviews: [count]件の個別タスクを追加（タグ: Review required）
- My PRs: [count]件の個別タスクを追加（タグ: My PR）
- Linear: [count]件の個別タスクを追加（タグ: Linear）
- [その他個別タスク]

---
Obsidianのdaily noteを作成しました: daily/YYYY-MM-DD.md
```

### Step 12: Ask for Additional Tasks
Ask the user if they want to add any additional tasks for today.
If yes, add them to Things3 using the helper script.

## Output Format

Always respond in Japanese. Present information in a clear, organized format that helps the user start their day efficiently.

## Notes

- If yesterday's daily note doesn't exist, skip that section
- If no calendar events, mention "今日の予定はありません"
- **Daily noteの作成は必須** - 必ずObsidianに書き出すこと
- **タスク管理はThings3で行う** - Obsidianのdaily noteにはTODOセクションを書かない
- GitHub/Linearの取得でエラーが発生した場合は、その旨を報告してスキップする
- Things3への追加時、既に同名のタスクが存在する場合は重複追加しない
