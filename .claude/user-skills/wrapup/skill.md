---
name: wrapup
description: Summarize the day's work and append to the daily note in Obsidian.
argument-hint: "[date]"
disable-model-invocation: true
---

# /wrapup - Daily Wrap-up

Summarize the day's work and append to the daily note in Obsidian.

タスク管理は Things3 から手離れさせているため、`/wrapup` でも Things3 は読み書きしない。代わりに **Linear** で「今日自分が更新した Issue」を取得してサマリーに含める。

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
```
Read: /Users/asonas/Documents/asonas/daily/YYYY-MM-DD.md
```

If it doesn't exist, ask the user whether to (a) create today's note and append, (b) append to yesterday's note instead, or (c) abort.

### Step 3: Parallel Information Gathering (Sonnet subagent)

メインスレッドが session context（今日の会話・作業）を持っている一方で、Linear のデータは外部 API なので並列に取りに行く。`model: "sonnet"` の Agent tool で起動する。

メインスレッドはこの subagent 起動と同時に **Step 4 (session context からのサマリー組み立て)** を進めて構わない。

#### 3a. linear-today subagent

プロンプト要旨:
```
あなたは asonas が今日 Linear で更新した Issue を抽出する任務を持つ。
対象日は YYYY-MM-DD (Step 1 で確定した日付)。

1. mcp__claude_ai_Linear__get_user で自分（viewer）の user_id を取得
2. mcp__claude_ai_Linear__list_issues で以下を取得:
   - assignee=自分、updatedAt が対象日のもの
   - 加えて、自分がコメント/編集した Issue があれば（API で取れる範囲で）含める
3. 出力フォーマット:

## 今日更新したLinear Issue
- [TEAM-123] タイトル — status: started / updatedAt: HH:MM
- ...

該当なしなら "該当なし" を返す。
Linear MCP が認証されていない場合は "Linear未認証" を返す。
推測は禁止。MCP の応答に無いフィールドを捏造しないこと。
```

### Step 4: Gather Work Summary (main thread)

メインスレッドで以下のソースから「やったこと」のドラフトを組み立てる。

1. **From the current session context**
   - Claude Codeは現在のセッション内で行われた全ての会話・作業を記憶している
   - セッション中に実施した実装、調査、修正、意思決定を抽出する
   - 変更・作成したファイルの一覧を含める
   - **最も信頼できる主情報源** として扱う

2. **From Claude Code auto memory（永続メモリ）**
   - セッションを跨いで保持されるメモリファイルを参照する
   - auto memoryディレクトリのパスはシステムプロンプトに記載されている
   - 今日の日付や作業内容に関連するエントリ、今日更新されたメモリファイルがあれば含める

3. **From cm-search (フレッシュセッションで /wrapup を回す場合の補強)**
   - 現在のセッションが /wrapup 単独で起動された等で session context が乏しい場合は、`cman:cm-search` を keyword=対象日付 で叩いて当日のセッション履歴を補強する
   - session context が十分にある場合はスキップ可

4. **From Step 3a (linear-today subagent)**
   - Linear 側で更新したものを「やったこと」のソースとして取り込む
   - 該当 Issue を `[[TEAM-XXX]]` の wikilink 付きで言及

5. **情報の統合**
   - 優先順位: セッションコンテキスト >= cm-search > auto memory ≒ Linear today
   - 重複を除去し、時系列または論理的にグループ化する
   - 散文 1 段落 + 箇条書き の組み合わせで構わない（既存 daily note のフォーマットに合わせる）

### Step 5: Present Summary for Review

Show the user what will be added:
```
## やったこと（追記予定）

- [Item 1]
- [Item 2]
- ...

## 今日更新したLinear Issue
- [TEAM-123] タイトル
- ...

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
- Linear Issue を含める場合は `[[TEAM-XXX]]` の wikilink 形式で本文中に埋め込む
- Obsidianはファイルシステムの変更を自動で検知するので、Edit後に特別な再読み込み操作は不要
- **daily note に `# YYYY-MM-DD` 等のh1ヘッディングを絶対に追加しないこと**。ファイル名がObsidian上のタイトルになるため重複する。既存ノートにh1を混入させないためEdit時は慎重に

### Step 7: 一次テキストソース (Bluesky / Scrapbox) の取り込み

asonas が自分で書いたテキストソース (Bluesky 投稿、Scrapbox ページ) を取得し、`activities/YYYY-MM-DD.md` の各セクションに反映する。`/wiki-update` がこのファイルを後段でソースとして読むため、wiki 化前に実行する。

```bash
cd /Users/asonas/workspace/activities
mise exec -- bundle exec bin/activities-snapshot --source bluesky --source scrapbox --date YYYY-MM-DD || echo "Warning: snapshot failed, skipping"
```

`/wrapup` を一日の終わりに回す前提なので、当日分だけ再描画すれば足りる (前日分は朝の `/today` 5b でカバーされている)。

**なぜ `--source` で絞るか**: `github` / `browser` / `claude_code` の3ソースは `~/Library/LaunchAgents/asonas.activities.{github,browser,claude}.plist` の launchd ジョブが 15〜60 分間隔で常時バックグラウンド収集しており、当日分の activities ファイルは常に最新化されている。/wrapup から重複して走らせると同じ state ファイルを並行書き込みするリスクがあるため、launchd でカバーされていない `bluesky` と `scrapbox` だけを明示的に拾う。

`activities-snapshot` は collect + render を1コマンドで実行する薄いラッパで、各スキル (today / wrapup / tempest909-draft) から共通利用される。

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

今日更新したLinear Issue: N件
- [TEAM-XXX] タイトル
- ...
```

Linear が「該当なし」または「未認証」だった場合はその旨を 1 行で報告する。

### Step 10: Evening Coaching Question

完了報告のあとで、`coach-daily-question` スキルを `evening` 引数で呼び出す。

```
Skill(coach-daily-question, args: "evening")
```

このスキル内ではコーチング縛り（解決策禁止、観察と問いのみ）に従う。回答が `coaching/log.md` に追記されたら `/wrapup` 全体が終了する。

ユーザーが「今日はコーチングはスキップで」等を事前に明言している場合のみ、このステップを省略してよい。なお、過去30日の節目（月初）であれば、夜の問いではなく `/coach-monthly` を回すのが望ましい旨を1行だけ提案してよい（提案であって押し付けではない）。

## Output Format

Always respond in Japanese.

## Notes

- If the "やったこと" section doesn't exist, append to the end of the file
- Keep the summary concise but informative
- Use bullet points for readability
- **タスク管理は Things3 から離脱した**。`/wrapup` では Things3 を読まない・書かない・残タスクを表示しない
- Linear の今日更新分は補助情報。session context が主情報源
- subagent から返却された情報を daily note に書き込む前に、明らかに事実と異なるもの・幻覚が紛れ込んでいないか軽く目視確認すること
