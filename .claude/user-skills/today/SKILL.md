---
name: today
description: Use when starting the workday. Conducts a scrum-style daily standup (Inspect prior day, Adapt today's plan against quarterly goals), gathering calendar / Gmail / Linear / Obsidian context and creating today's Obsidian daily note.
disable-model-invocation: true
---

# /today - Daily Standup Support

スクラムのデイリースタンドアップを支援する。四半期ゴールに対する進捗の検査（Inspect）と、次の作業日の計画の適応（Adapt）を行う。

タスク管理は Things3 から手離れさせており、`/today` では Things3 を読み書きしない。代わりに **Linear** の Issue トラッキングを情報源とする。

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

取得した events 配列を JSON 配列として `/tmp/activities-calendar-events.json` に書き出す (Step 5a で activities リポジトリにインポートするため)。書き出しは Write ツールで以下のような JSON 配列形式にする:

```json
[
  {"id":"...", "summary":"...", "start":{"dateTime":"..."}, "end":{"dateTime":"..."}, "htmlLink":"...", "attendees":[...]},
  ...
]
```

### Step 3: Read Quarterly Goals (main thread)

現在の四半期ゴールファイルを読む。ファイル名は `goals/YYYY-qN.md` の形式。

**四半期の自動算出:**
Step 1で取得した現在日付から以下のルールで `YYYY-qN` を導出する:
- 1〜3月 → `YYYY-q1`
- 4〜6月 → `YYYY-q2`
- 7〜9月 → `YYYY-q3`
- 10〜12月 → `YYYY-q4`

例: 2026-04-15 → `goals/2026-q2.md`、2026-10-01 → `goals/2026-q4.md`

```bash
obsidian read vault=asonas path="goals/2026-q2.md" 2>/dev/null
```

ファイルが存在しない場合（未作成の四半期）はスキップしてユーザーに通知する。
→ ゴール一覧をメモリに保持し、Step 7のStandup Hearingで使う。

### Step 4: Parallel Information Gathering (Sonnet subagents)

以下 2 つの情報収集タスクを **一度のメッセージで並列に Agent を起動** し、Sonnet モデルに処理させる。各 subagent は調査結果を構造化された短いテキスト（200〜400 字目安）でメインスレッドに返す。すべての subagent は `model: "sonnet"`、`subagent_type: "general-purpose"` で起動する。

**並列起動の鉄則:** 2 つの Agent tool 呼び出しを **同一のメッセージ内** に配置する。1 つずつ順に呼ぶと並列にならない。

#### 4a. prior-day-summary subagent

「前日（または直近営業日）の引き継ぎ材料」を組み立てる subagent。

プロンプト要旨:
```
あなたは asonas の前営業日の作業内容を整理する任務を持つ。
以下を順に行い、最終的に Markdown のサマリーを返してほしい。

1. `~/.claude/scripts/find-recent-daily-notes.sh` を Bash 実行し、対象日付のリストを取得する
   - 月曜実行時は金/土/日の3日分が返る可能性あり、全部処理する
   - 7日遡って何もなければ「対象日なし」と返す
2. 各日付について以下を実行:
   a. Read: /Users/asonas/Documents/asonas/daily/YYYY-MM-DD.md
   b. cman:cm-search を keyword="YYYY-MM-DD" で実行し、その日のClaude Codeセッション履歴を取得
3. 抽出する情報:
   - Uncompleted tasks: `- [ ]` 行
   - 「明日」「tomorrow」「次回」を含む引き継ぎ項目
   - daily note の「やったこと」セクション + cm-search 結果を突き合わせた「昨日やったこと」のベース箇条書き
4. 出力フォーマット:

## 前日からの引き継ぎ
- 項目1
- 項目2

## 昨日やったこと（ベース）
- 作業A
- 作業B

## 対象日メタ
- target_date: YYYY-MM-DD
- heading_label: "昨日やったこと" | "先週金曜日にやったこと" | "MM/DD(曜)にやったこと"
  （対象日が前営業日なら "昨日"、月曜実行なら "先週金曜日"、それ以外なら "MM/DD(曜)"）

Wikiリンクは使わないこと（チームメイト向け情報のため）。
推測は禁止。ソースに無い情報を捏造しないこと。
```

#### 4b. linear-tracker subagent (旧 4c)

Linear MCP を叩いて「自分にアサインされたアクティブ Issue」と「自分が所属するチームの停滞 Issue」を取得する subagent。

プロンプト要旨:
```
あなたは asonas の Linear Issue トラッキングを担当する。

1. mcp__claude_ai_Linear__get_user で自分（viewer）の情報を取得し、user_id と所属チーム一覧を確定する
   - もし viewer に teams フィールドが無ければ、mcp__claude_ai_Linear__list_teams で自分が所属しているチームを取得する
2. 自分にアサインされたアクティブ Issue:
   - mcp__claude_ai_Linear__list_issues で assignee=自分、state.type が "started" または "unstarted" (open相当) なものを取得
   - 最大 50 件、updatedAt 降順
3. 所属チームの停滞 Issue:
   - 各チームについて、state.type が "started" または "unstarted" で updatedAt が **7日以上前** の Issue を取得
   - 自分がアサインされていないものも含む（チームの健全性チェックのため）
   - 各チーム最大 20 件
4. 出力フォーマット:

## 自分のアクティブIssue
- [TEAM-123] タイトル — status / updated YYYY-MM-DD
- ...

## チームの停滞Issue（7日以上 updatedAt 未更新）
### TEAM_KEY (チーム名)
- [TEAM-123] タイトル — assignee: 名前 / status / updated YYYY-MM-DD (N日前)
- ...

Linear MCP が認証されていない場合は "Linear未認証" と返してスキップ。
取得件数が多い場合でも要約せず、件数を抑えるなら updatedAt 古い順から指定件数で打ち切る。
推測は禁止。MCP の応答に無いフィールドを捏造しないこと。
```

#### 2 つの subagent 起動例

```
（同一メッセージ内に以下 2 つの Agent tool 呼び出しを並列で配置する）

Agent(
  description="Prior day summary",
  subagent_type="general-purpose",
  model="sonnet",
  prompt="<4a のプロンプト>"
)
Agent(
  description="Linear tracker",
  subagent_type="general-purpose",
  model="sonnet",
  prompt="<4b のプロンプト>"
)
```

2 つの結果をメモリに保持し、後段の Step 6 / Step 7 で利用する。

### Step 5: Update activities files (main thread)

#### 5a: カレンダー予定 → activities ファイル

Step 2 で取得した GCal events を **activities リポジトリ** にインポートし、`activities/YYYY-MM-DD.md` のカレンダーセクションに反映する。

```bash
cd /Users/asonas/ghq/github.com/asonas/activities
cat /tmp/activities-calendar-events.json | mise exec -- bundle exec bin/activities-calendar-import --date YYYY-MM-DD
mise exec -- bundle exec bin/activities-render --source calendar --date YYYY-MM-DD
```

- `activities-calendar-import` は `responseStatus="declined"` の自分のイベントを自動で除外する
- activities/YYYY-MM-DD.md の `<!-- BEGIN: calendar -->` 〜 `<!-- END: calendar -->` の中身のみが書き換えられ、他のセクション (github, claude_code, browser 等) には触れない
- 「子の送迎や会社移動の時間」「送迎で不在」のような特殊予定も activities セクションには **表示する** (活動ログとして事実を残す目的)
- 上書き方式なので `/today` を1日に複数回実行しても重複しない

#### 5b: 一次テキストソース (Bluesky / Scrapbox) → activities ファイル

asonas が自分で書いたテキストソース (Bluesky 投稿、Scrapbox ページ) を取得し、`activities/YYYY-MM-DD.md` の各セクションに反映する。前日分の投稿・編集も当日朝に確定することがあるため、yesterday と today の両方を render する。

```bash
cd /Users/asonas/ghq/github.com/asonas/activities
mise exec -- bundle exec bin/activities-snapshot --source bluesky --source scrapbox --date yesterday --date today || echo "Warning: snapshot failed, skipping"
```

**なぜ `--source` で絞るか**: `github` / `browser` / `claude_code` の3ソースは `~/Library/LaunchAgents/asonas.activities.{github,browser,claude}.plist` の launchd ジョブが 15〜60 分間隔で常時バックグラウンド収集しており、当日分の activities ファイルは常に最新化されている。/today から重複して走らせると同じ state ファイルを並行書き込みするリスクがあるため、launchd でカバーされていない `bluesky` と `scrapbox` だけを明示的に拾う。

失敗時は警告のみで `/today` 全体は止めない。`activities-snapshot` は collect + render を1コマンドで実行する薄いラッパで、各スキル (today / wrapup / tempest909-draft) から共通利用される。

### Step 6: Create Today's Daily Note in Obsidian

**IMPORTANT: Always create today's daily note.**

公式CLIで今日のdaily noteを作成する。既に存在する場合は上書きしない。**`vault=asonas` を必ず指定**:

```bash
obsidian read vault=asonas path="daily/YYYY-MM-DD.md" 2>/dev/null
```

存在しなければ作成する:
```bash
obsidian create vault=asonas path="daily/YYYY-MM-DD.md" content="<daily note本文>" 2>/dev/null
```

Daily note format:
**IMPORTANT: `# YYYY-MM-DD` のようなh1ヘッディングは絶対に含めないこと。** Obsidianではファイル名がタイトルになるため重複する。ノートは `[[IVRy]]` から直接始める。

「## 今日の予定」は activities ファイル (Step 5a で更新済み) からの transclude にする。

「## 前日からの引き継ぎ」と「## 昨日やったこと（or 先週金曜日にやったこと 等）」は **Step 4a (prior-day-summary subagent)** の出力を使う。見出しのラベルは subagent 返却の `heading_label` に従う。

```markdown
[[IVRy]]

## 今日の予定

![[activities/YYYY-MM-DD#カレンダー]]

## 前日からの引き継ぎ

- [Step 4a の「前日からの引き継ぎ」結果]

---

## 昨日やったこと（または対応するラベル）

- [Step 4a の「昨日やったこと（ベース）」結果]

## 今日やること

（Step 7 のヒアリング後に埋める）

## 困りごと・ブロッカー

（Step 7 のヒアリング後に埋める）

---

## ログ

```

**重要:**
- `## やったこと` セクションは廃止した。日中〜夜の作業ログは `## ログ` に集約される（`/wrapup` および各種 append 系スキルが書き込む）
- `## 昨日やったこと` / `## 今日やること` / `## 困りごと・ブロッカー` の3つは Slack のスタンドアップスレッドへコピペするためのブロック。前後の `---` 区切りは「ここはコピペ用」を視覚的に示すためのもの
- Linear 通知まとめ / Datadog Daily Digest は廃止した。これらは `/today` から自動生成しない

### Step 7: Standup Hearing（検査と適応）

daily noteの作成後、ユーザーに以下をヒアリングしてdaily noteの該当セクションに記入する。
**スタンドアップ3項目のセクションはチームメイト向け。Wikiリンクは使わず、箇条書きで書く。**

#### 7a. 昨日やったこと（Inspect: 実績の検査）

Step 4a で生成済みのベース箇条書きをユーザーに提示し、追加・修正がないか確認する。ユーザーの修正をマージして「## 昨日やったこと」セクション（または heading_label 通りの見出し）に書き込む。

#### 7b. 今日やること（Adapt: 計画の適応）

AskUserQuestionで以下をコンテキストとして質問文に含め、ユーザーに「今日やること」を聞く:

- **四半期ゴール**: Step 3 で読み込んだ `goals/YYYY-qN.md` の内容を簡潔に列挙
- **自分のアクティブLinear Issue**: Step 4b の結果から上位を提示
- **チームの停滞Linear Issue**: Step 4b の結果から件数と特に古いものを提示（フォローアップが必要なら今日やることに入れる候補として）
- **カレンダーの予定**: ミーティングが多い日は作業時間が限られることを示唆

ユーザーが回答した内容のみを箇条書きで daily note の「## 今日やること」に記入する。カレンダーの予定は自動的には書かない。

**適応の問いかけ:**
「今日やること」のヒアリング時に、昨日の結果を踏まえて以下を確認する:
- 昨日ブロックされたタスクがあれば、今日の計画をどう変えるか
- 四半期ゴールの達成に向けて、今日の作業が貢献しているか
- 計画の変更が必要な兆候（タスクの滞留、新たなブロッカーの発生等）がないか
- Linear のチーム停滞 Issue で自分がフォローすべきものはないか

これらは質問に織り込む形で自然に聞く（堅苦しいチェックリストにしない）。

#### 7c. 困りごと・ブロッカー（Impediments）

何かあれば自由に記入。なければ「特になし」。ブロッカーがある場合は、**誰に相談/エスカレーションするか**まで含めて記録する。

**注意:**
- ユーザーが会話の中で既に回答している場合（例:「昨日は休みだった」「今日はXXXをやる」）は、改めて聞かずにそのまま記入する
- ヒアリングが必要な場合は、サマリー表示の前にまとめて聞く

### Step 8: Present Summary

Present to the user:

```
## おはようございます - YYYY年MM月DD日

### Q2 ゴール
[四半期ゴールの一覧を簡潔に表示]

### 今日の予定
[Calendar events listed with times, chronologically sorted]

### 前日からの引き継ぎ
[Step 4a の uncompleted tasks 一覧]

### Linear トラッキング
- 自分のアクティブ: N件
- チームの停滞 (7日以上 updatedAt 未更新): M件
  - 特に古いもの: [TEAM-XXX] タイトル (N日前)
  - ...

---
Obsidianのdaily noteを作成しました: daily/YYYY-MM-DD.md
```

### Step 9: Sync Raindrop Bookmarks and Update Obsidian Wiki

Daily note の生成・サマリー表示が完了したら、Raw Sources を最新化したうえで wiki を再ingestする。順番が重要（bookmarks が先、wiki ingest が後）:

```
Skill(raindrop-sync)
Skill(wiki-update, args: "ingest yesterday")
```

ユーザへの確認は不要で、黙々と実行して結果を 1〜2 行で報告する。前日の daily note が存在しない場合は wiki-update をスキップする（raindrop-sync は実行してよい）。

### Step 9b: Weekly Wiki Lint Gate（週次 lint の自動化）

wiki ingest が終わったら、**前回 lint から 7 日以上経過していれば** `/wiki-update lint` も走らせる。これは「週次の自動 lint をスリープに影響されない形で実現する」ための仕組み。`/today` は本人が起きて作業を始める時にしか走らないため、launchd/cron のようにスリープ中に取りこぼすことがない。

前回 lint 日の判定は `wiki/log.md`（とローテーション済みの `wiki/log-*.md`）の lint エントリ見出しから取る:

```bash
# find ベースで列挙する（zsh では未マッチの log-*.md グロブがコマンドごと失敗するため、
# シェル展開ではなく find に glob を渡す）
last_lint=$(find /Users/asonas/Documents/asonas/wiki -maxdepth 1 \
  \( -name 'log.md' -o -name 'log-*.md' \) 2>/dev/null \
  | xargs grep -hoE '^## [0-9]{4}-[0-9]{2}-[0-9]{2}[^#]*lint' 2>/dev/null \
  | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' | sort -r | head -1)
echo "last_lint=${last_lint:-none}"
```

判定ルール:

- `last_lint` が空（lint 履歴なし）→ **lint を実行する**
- Step 1 で取得した今日の日付と `last_lint` の差が **7 日以上** → **lint を実行する**
- それ未満 → スキップする（その旨を 1 行報告に含める。例: 「Wiki lint: 前回 6/05、7日未満のためスキップ」）

実行する場合:

```
Skill(wiki-update, args: "lint")
```

lint は検出結果を `wiki/log.md` に記録するのみで自動修正はしない（human-in-the-loop を維持）。Step 8 のサマリーに lint を走らせた事実と検出件数の概要を 1〜2 行で添える。lint が clean なら「Wiki lint: clean」とだけ報告する。ユーザへの確認は不要。

### Step 9c: qmd 再インデックス

Wiki の処理が終わったら、Alfred の qmd 検索（`ws`/`wsq`、`/Users/asonas/workspace/qmd-alfred/`）が最新の vault を引けるよう、qmd のインデックスを更新する。差分インデックスのため低コスト。失敗してもワークフロー全体は止めない（警告のみ）。`command -v qmd` が無い／collection `asonas` 未登録ならスキップしてよい。

```bash
qmd update && qmd embed 2>&1 | tail -3 || echo "Warning: qmd reindex failed, skipping"
```

### Step 9d: cctop プラグイン週次更新チェック（subagent）

cctop の menubar アプリ（`/Applications/cctop.app` と `cctop-hook` バイナリ）は Sparkle で自動更新されるが、**Claude Code プラグイン側は自動更新されない**（手動の `claude plugin update` のみ）。放置するとプラグインがピン留めされたまま取り残され、hook バイナリとのバージョン差が広がる。これを防ぐため、**前回チェックから 7 日以上経過していれば** プラグインを更新する。Step 9b の週次 lint ゲートと同じく、スリープに影響されない「起床して作業を始める時に走る」前提でスロットルする。

スロットル判定とプラグイン更新は **subagent** に任せる（更新コマンドの出力をメインスレッドに流さず、結果だけ 1 行で受け取るため）。`model: "sonnet"`、`subagent_type: "general-purpose"` で 1 つ起動する。

プロンプト要旨:
```
あなたは cctop の Claude Code プラグインを最新に保つ任務を持つ。以下を順に実行し、最後に結果を1行で返す。

1. スロットル判定: スタンプファイル ~/.cctop/.last-plugin-update-check を見る。
   存在し、かつ最終更新から7日未満なら、何もせず
   "cctop更新: 前回チェックから7日未満のためスキップ" と返して終了する。
   判定例（ヘレドク禁止、ワンライナーで）:
   stamp="$HOME/.cctop/.last-plugin-update-check"; if [ -f "$stamp" ] && [ $(( ($(date +%s) - $(stat -f %m "$stamp")) / 86400 )) -lt 7 ]; then echo skip; fi
2. 7日以上経過 or スタンプ無し → `claude plugin update cctop@cctop` を実行する。
3. 成功・失敗にかかわらず `touch "$HOME/.cctop/.last-plugin-update-check"` でタイムスタンプを更新する。
4. 結果を1行で返す:
   - 更新あり: "cctop更新: X.Y.Z → A.B.C に更新（次回セッションから反映）"
   - 差分なし: "cctop更新: 既に最新"
   - 失敗: "cctop更新: 失敗（<理由>）"（ワークフロー全体は止めない）

推測禁止。`claude plugin update` の実際の出力に基づいて報告すること。
```

subagent の返した 1 行を Step 8 のサマリーに添える（スキップ時も含めて簡潔に）。プラグイン更新は再起動（新セッション）で反映される点に注意。失敗しても `/today` 全体は止めない。

### Step 10: Morning Coaching Question

すべての処理が終わったら、`coach-daily-question` スキルを `morning` 引数で呼び出す。

```
Skill(coach-daily-question, args: "morning")
```

このスキル内ではコーチング縛り（解決策禁止、観察と問いのみ）に従う。`/today` の実行モードを一時的に切り替えるイメージで構わない。回答が `coaching/log.md` に追記されたら `/today` 全体が終了する。

ユーザーが「今日はコーチングはスキップで」等を事前に明言している場合のみ、このステップを省略してよい。

## Output Format

Always respond in Japanese. Present information in a clear, organized format that helps the user start their day efficiently.

## Notes

- If yesterday's daily note doesn't exist, skip that section
- If no calendar events, mention "今日の予定はありません"
- **Daily noteの作成は必須** - 必ずObsidianに書き出すこと
- **タスク管理は Things3 から離脱した**。Things3 への読み書きはこのスキルでは行わない。代わりに **Linear Issue** を情報源とする
- subagent から返却された情報を daily note に書き込む前に、明らかに事実と異なるもの・幻覚が紛れ込んでいないか軽く目視確認すること
