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

### Step 3: Parallel Information Gathering (Sonnet subagents)

メインスレッドが持っている session context は「今 /wrapup を回しているこの 1 セッション」の範囲でしかない。asonas は 1 日のうちに複数のリポジトリ・複数のセッションを跨いで作業するため、現在セッションのコンテキストだけでは当日の作業を取りこぼす。そこで外部情報は **2 つの Sonnet サブエージェントを並列で** 取りに行く。どちらも `model: "sonnet"` の Agent tool で、Step 3a と Step 3b を **同時に** 起動する。

- **3a. linear-today**: Linear で今日更新した Issue を抽出（外部 API）
- **3b. cman-sessions**: cman で当日の Claude Code セッションを全プロジェクト横断でさらい、プロジェクト別の作業サマリーを返す（これが「やったこと」の主たる網羅ソース）

メインスレッドはこの 2 つの subagent 起動と同時に **Step 4 (現在 session context からのサマリー組み立て)** を進めてよい。3 者の結果は Step 4 で統合する。

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

#### 3b. cman-sessions subagent

当日 asonas が回した Claude Code セッションを全プロジェクト横断で拾い、プロジェクト別の作業サマリーを返す。セッションを跨いだ作業を取りこぼさないための中核ステップ。

プロンプト要旨:
```
あなたは asonas が今日 Claude Code で行った作業を全プロジェクト横断でまとめる任務を持つ。
対象日は YYYY-MM-DD (Step 1 で確定した日付)。

1. まず ToolSearch で cman のツールをロードする
   (query 例: "select:mcp__plugin_cman_cman__list_sessions,mcp__plugin_cman_cman__search_sessions")
2. mcp__plugin_cman_cman__list_sessions (limit=60 程度) で直近セッションを列挙する。
   各エントリの相対時刻 ("X hours ago" 等) と対象日を突き合わせ、対象日のセッションだけを対象にする。
3. 次のセッションは除外する:
   - `agent-*` で始まるサブエージェントのセッション (実作業の主体ではない)
   - 最初のメッセージが "Base directory for this skill: .../commit" の /commit スキル単独セッション
   - 最初のメッセージが /wrapup や /today など日報運用スキル自体のセッション
4. 残った各セッションについて、何をしたのかを把握する。セッションタイトル(最初のユーザーメッセージ)
   だけでは着手した話題しか分からないので、成果まで書くには中身の確認が要る。必要に応じて
   mcp__plugin_cman_cman__search_sessions を keyword=対象日付 や keyword=プロジェクト固有語 で叩き、
   マッチしたスニペットから「実際に何が完了/前進したか」を読み取る。
   確認しても成果が判然としないセッションは、成果を捏造せず「〜に着手」「〜を調査」など
   着手した作業内容として記述する (推測で完了扱いにしない)。
5. 出力フォーマット (プロジェクトごとにまとめ、時系列がわかる場合は時刻を添える):

## 今日のセッション横断サマリー
### <リポジトリ名 / プロジェクト名>
- HH:MM 内容 (成果 or 着手した作業)
- ...
### <別のリポジトリ>
- ...

対象日のセッションが無ければ "該当なし" を返す。
cman が使えない (ツール未ロード・エラー) 場合は "cman利用不可" を返す。
推測は禁止。セッションに実在しない成果を書かないこと。リポジトリ名・Issue番号は実データに従う。
```

返ってきたサマリーは、現在 session context と重なる部分がある(まさに今のセッションも含まれる)。Step 4 で重複を排除して統合する。

### Step 4: Gather Work Summary (main thread)

メインスレッドで以下のソースから「やったこと」のドラフトを組み立てる。

1. **From Step 3b (cman-sessions subagent) — 当日全体の網羅ソース**
   - 全プロジェクト横断のセッションサマリーが返ってくる。これを「やったこと」の骨格として最初に据える
   - asonas は 1 日に複数リポジトリを跨ぐため、現在セッションだけでは必ず取りこぼす。cman サマリーが当日像の主たる情報源になる
   - "cman利用不可" が返ったときのみ、フォールバックとしてメインスレッドから `cman:cm-search` を keyword=対象日付 で直接叩く

2. **From the current session context — 深さの補強**
   - Claude Code は今 /wrapup を回しているこのセッション内の会話・作業を最も詳細に記憶している
   - cman サマリーは各セッションを外から要約したものなので、現在セッションに該当する項目は session context の方が正確で詳しい。該当項目は session context で上書き・肉付けする
   - 変更・作成したファイルの一覧など、session context にしかない具体は積極的に補う

3. **From Claude Code auto memory（永続メモリ）**
   - セッションを跨いで保持されるメモリファイルを参照する
   - auto memoryディレクトリのパスはシステムプロンプトに記載されている
   - 今日の日付や作業内容に関連するエントリ、今日更新されたメモリファイルがあれば含める

4. **From Step 3a (linear-today subagent)**
   - Linear 側で更新したものを「やったこと」のソースとして取り込む
   - 該当 Issue を `[[TEAM-XXX]]` の wikilink 付きで言及

5. **情報の統合**
   - 骨格は cman サマリー(当日の全セッション)。そこへ現在 session context の詳細を重ね、auto memory と Linear を補う
   - 優先順位（同じ作業に複数ソースが触れている場合の詳細さ）: 現在セッションコンテキスト > cman サマリー > auto memory ≒ Linear today。ただし **網羅性は cman サマリーが担う**（現在セッションに無い作業も必ず拾う）
   - 重複を除去し、プロジェクトごと or 時系列でグループ化する
   - 散文 1 段落 + 箇条書き の組み合わせで構わない（既存 daily note のフォーマットに合わせる）
   - セッションが多い日はログが長くなる。主要な作業を優先しつつ、Step 5 でユーザーに提示して取捨を委ねる

### Step 5: Present Summary for Review

Show the user what will be added:
```
## ログに追記予定

- HH:MM カテゴリ: 内容
- HH:MM カテゴリ: 内容
- ...

## 今日更新したLinear Issue
- [TEAM-123] タイトル
- ...

この内容でよろしいですか？
```

Wait for user confirmation or edits.

### Step 6: Append to Daily Note

After confirmation, append under the `## ログ` heading. 公式CLIはheading指定のinsertに対応していないため、Vaultの実ファイルをReadツールで読んでEditツールで挿入する。

**ログのフォーマット:**
- 1行 1エントリ、`- HH:MM <カテゴリ>: <内容>` 形式
- カテゴリ例: `実装` / `調査` / `レビュー` / `MTG` / `学び` / `その他`
- 時刻が不明なエントリ（セッション横断的な作業など）は HH:MM を省略して `- <カテゴリ>: <内容>` でよい
- Linear Issue / プロジェクト名 / 技術用語は wikilink (`[[TEAM-XXX]]`, `[[asonas/foo]]`) で記述してよい

```
# Read tool:
Read: /Users/asonas/Documents/asonas/daily/YYYY-MM-DD.md

# Edit tool: "## ログ" セクション末尾に追記
# old_string: "## ログ\n" (空セクションの場合) または既存ログ末尾の一意なスニペット
# new_string: "## ログ\n\n- HH:MM 実装: ...\n- HH:MM レビュー: ...\n"
```

**注意:**
- `## ログ` セクションに既存のエントリがある場合は、その末尾に**時系列順で**追記する
- 既存エントリと重複する内容は追加しない（同じ作業が複数の append 経路で記録されている場合がある）
- Obsidianはファイルシステムの変更を自動で検知するので、Edit後に特別な再読み込み操作は不要
- **daily note に `# YYYY-MM-DD` 等のh1ヘッディングを絶対に追加しないこと**。ファイル名がObsidian上のタイトルになるため重複する
- **`## やったこと` セクションは廃止した**。古い daily note にこのセクションが残っていても新規追記はしない

### Step 7: 一次テキストソース (Bluesky / Scrapbox) の取り込み

asonas が自分で書いたテキストソース (Bluesky 投稿、Scrapbox ページ) を取得し、`activities/YYYY-MM-DD.md` の各セクションに反映する。`/wiki-update` がこのファイルを後段でソースとして読むため、wiki 化前に実行する。

```bash
cd /Users/asonas/ghq/github.com/asonas/activities
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

### Step 8b: qmd 再インデックス

wiki ingest のあとで、Alfred の qmd 検索（`ws`/`wsq`、`/Users/asonas/workspace/qmd-alfred/`）が最新の vault を引けるよう、qmd のインデックスを更新する。差分インデックスのため低コスト。失敗してもワークフロー全体は止めない（警告のみ）。collection `asonas` が未登録なら（`command -v qmd` も含め）スキップしてよい。

```bash
qmd update && qmd embed 2>&1 | tail -3 || echo "Warning: qmd reindex failed, skipping"
```

### Step 9: Confirm Completion

Report to the user:
```
daily/YYYY-MM-DD.md の「ログ」セクションに追記しました。
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

- If the `## ログ` section doesn't exist (古いテンプレで作られた daily note の場合), create it at the end of the file before appending
- Keep each log entry concise (1 行 1 作業)
- Use the `- HH:MM <カテゴリ>: <内容>` format consistently
- **タスク管理は Things3 から離脱した**。`/wrapup` では Things3 を読まない・書かない・残タスクを表示しない
- 当日像の網羅は cman-sessions subagent (Step 3b) が担う。現在 session context は該当セッションの詳細を肉付けする役割、Linear は補助
- subagent から返却された情報を daily note に書き込む前に、明らかに事実と異なるもの・幻覚が紛れ込んでいないか軽く目視確認すること。特に cman サマリーは各セッションを外から要約したものなので、成果を断定しすぎていないか（着手止まりを完了扱いにしていないか）を確認する
