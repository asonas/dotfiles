---
name: daily-log
description: End-of-day review command that helps reflect on the day's work and prepare for tomorrow.
disable-model-invocation: true
---

# /daily-log - Daily Review and Reflection

End-of-day review command that helps reflect on the day's work and prepare for tomorrow.

## Usage

```
/daily-log
```

## Instructions

When this skill is invoked, follow these steps interactively:

### Step 1: Load Today's Daily Note

1. Get today's date and load the daily note from `daily/YYYY-MM-DD.md`
2. Parse the "やること" section to get the planned tasks
3. Parse the "やったこと" section to see what was accomplished

### Step 2: Task Review (Interactive)

For each task in "やること":

1. Display the task list with numbers
2. Ask: "完了したタスクの番号を教えてください（複数可、カンマ区切り）"
3. For incomplete tasks, ask one by one:
   - "「{task}」はどうしますか？"
   - Options:
     1. 明日に繰り越し
     2. もう不要
     3. 保留

Use `AskUserQuestion` tool to collect responses.

### Step 3: Reflection (Interactive)

Ask the user:

1. **Good (うまくいったこと)**
   - "今日うまくいったことは何ですか？"

2. **Could be better (改善できること)**
   - "改善できそうなことはありますか？"

3. **Tomorrow's priorities (明日やること)**
   - "明日やりたいことはありますか？"

### Step 4: Save Daily Log

Update the daily note with:

```markdown
### 振り返り

#### Good
- {user's response}

#### Could be better
- {user's response}

### 明日やること
- {carried over tasks}
- {user's new tasks}
```

### Step 5: Save to Second Brain

Store the day's summary in second-brain for future reference:

```javascript
store_memory({
  content: "2026-02-04の振り返り: {summary}",
  tags: ["daily-log", "reflection", "YYYY-MM-DD"],
  source: "daily/YYYY-MM-DD.md"
})
```

### Step 6: Confirm Completion

Report to the user:
- Summary of completed tasks
- Tasks carried over to tomorrow
- Reminder that tomorrow's `/morning` will pick up where we left off

## Output Format

Keep the interaction conversational and low-friction. Use numbered options where possible to minimize typing.

## Notes

- This skill works in tandem with `/morning`
- The "明日やること" section feeds into the next day's `/morning`
- Reflections are stored in second-brain for long-term learning
