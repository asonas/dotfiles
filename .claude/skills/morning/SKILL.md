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

### Step 3: Read Yesterday's Daily Note
Use Obsidian MCP to read yesterday's daily note:
```
mcp__mcp-obsidian__obsidian_get_file_contents with filepath: "daily/YYYY-MM-DD.md" (yesterday's date)
```

Extract from yesterday's note:
- Uncompleted tasks (lines starting with `- [ ]`)
- Items marked for tomorrow (containing "明日", "tomorrow", "次回")
- Any notes or reflections

### Step 4: Query Second Brain for Carryover Items
Search second-brain for items mentioned as future tasks:
```
mcp__second-brain__search_memory with query: "明日やる 次回 tomorrow next time TODO"
```

### Step 5: Read Current Things3 Tasks
Read existing tasks in Things3 "今日" list to avoid duplicates:
```
Bash: ~/.claude/scripts/things-today.sh
```

### Step 6: Add TODO Items to Things3
Add today's TODO items to Things3 using the helper script.
Each task is added to the "今日" list.

For each TODO item (calendar events, carryover tasks, etc.):
```
Bash: ~/.claude/scripts/things-add.sh "タスク名" "メモ（任意）"
```

- Skip tasks that already exist in Things3 (Step 5で確認済み)
- Calendar events: "イベント名 (HH:MM)" の形式で追加
- 前日の未完了タスク: そのまま追加

### Step 7: Create Today's Daily Note in Obsidian
**IMPORTANT: Always create today's daily note.**

Use Obsidian MCP to create today's daily note:
```
mcp__mcp-obsidian__obsidian_append_content with filepath: "daily/YYYY-MM-DD.md" (today's date)
```

Daily note format (TODOセクションは不要、Thingsで管理するため):
```markdown
[[IVRy]]

## 今日の予定

| 時間 | 予定 |
|------|------|
| HH:MM-HH:MM | イベント名 |
...

## 前日からの引き継ぎ

- [昨日やったことのサマリー]

### 未完了タスク
- [ ] [昨日の未完了タスク]

## やったこと



```

### Step 8: Present Summary
Present to the user:

```
## おはようございます - YYYY年MM月DD日

### 今日の予定
[Calendar events listed with times]

### 前日からの引き継ぎ
[Uncompleted tasks from yesterday's daily note]

### Things3に追加したタスク
- [追加したタスク一覧]

---
Obsidianのdaily noteを作成しました: daily/YYYY-MM-DD.md
```

### Step 9: Ask for Additional Tasks
Ask the user if they want to add any additional tasks for today.
If yes, add them to Things3 using the helper script.

## Output Format

Always respond in Japanese. Present information in a clear, organized format that helps the user start their day efficiently.

## Notes

- If yesterday's daily note doesn't exist, skip that section
- If no calendar events, mention "今日の予定はありません"
- **Daily noteの作成は必須** - 必ずObsidianに書き出すこと
- **タスク管理はThings3で行う** - Obsidianのdaily noteにはTODOセクションを書かない
