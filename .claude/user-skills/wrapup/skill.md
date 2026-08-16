---
name: wrapup
description: Use when summarizing the day's work and preparing a daily note in Obsidian.
argument-hint: "[date]"
disable-model-invocation: true
---

# /wrapup - Daily Wrap-up

Summarize the day's work and append to the daily note in Obsidian.

当日の作業記録を、Codexのセッション履歴・現在のセッション・利用可能なcman補助情報・永続メモリから整理してサマリーに含める。外部のタスク管理サービスは参照しない。

## LLM Wikiへの引き渡し

daily の `## ログ` は LLM Wikiの一次記録であり、wikiはその出典付きの派生レイヤです。ログ候補とwiki更新を混同せず、`wrapup` はdailyを確定してから `/wiki-update ingest` を呼び出します。ページの粒度、出典、外部情報と自分の考察の分離は `wiki/LLM Wiki.md` と `/wiki-update` を正典とします。

ログ候補をまとめるときは、事実・実験・設計判断・未解決事項を区別します。独立して読める実験記録、設計判断、再利用可能な手順は、wikiへ直接長文で追記せず `notes/` のソースノート候補としてユーザーに提示します。未検証の推測は事実として扱わず、仮説または保留として残します。外部情報と自分の考察を同じ段落に混ぜません。

新規ページの作成や分割の後には本文を再確認し、深掘り候補があれば「〇〇についても別ノートとして切り出して調べられそうですが、書きますか？」と提案します。候補からノートを自動作成せず、ユーザーの承認後に切り出します。

notesの新規作成、既存ページの分割、MOCの作成は自動実行しません。dailyへの追記はユーザーの承認後に行い、その後でwiki-updateを実行します。

実験候補を記録・提案する場合は、実験コード、実行コマンド、触るデバイスやリソース、想定される影響を明示します。

ユーザーの許可を得るまで、ビルド・実行・デバイスへのアクセス・外部状態を変更する操作を実行しないでください。実験を実施した場合は、`<topic>-experiment.md` の独立した記録に切り出す提案を行います。

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

セッションの現在日付（Asia/Tokyo）を使って対象日を確定する。

### Step 2: Verify Daily Note Exists

Check if the target daily note exists:
```
Read: /Users/asonas/Obsidian/asonas/daily/YYYY-MM-DD.md
```

If it doesn't exist, ask the user whether to (a) create today's note and append, (b) append to yesterday's note instead, or (c) abort.

### Step 3: Gather Codex Session History

メインスレッドの context だけでは当日の作業を取りこぼすため、Codexのローカル履歴を主な横断ソースにする。cmanが使えないことは「作業なし」を意味しない。

#### Codex履歴

次の2種類のファイルを、Readまたは読み取り専用のシェルコマンドで確認する。

```
/Users/asonas/.codex/history.jsonl
/Users/asonas/.codex/sessions/
```

1. `history.jsonl` の各レコード (`session_id`, `ts`, `text`) から、`ts` を `Asia/Tokyo` に変換して対象日のユーザー入力とセッションIDを抽出する。ファイルのディレクトリ名だけで日付を判定しない。
2. 抽出したセッションIDに対応する `sessions/YYYY/MM/DD/*.jsonl` を探し、`session_meta` の `payload.cwd`、`payload.session_id`、`payload.parent_thread_id`、`payload.source`、`payload.thread_source` を確認する。日付を跨いだセッションは、履歴レコードの時刻を優先して対象日に含める。
3. 各セッションのユーザー向けメッセージ、ツール呼び出しの結果、アシスタントの最終応答を確認する。暗号化されたreasoningや内部メタデータだけを根拠にしない。
4. 次のセッションは集計から除外する:
   - `payload.source.subagent` があるセッション、または `payload.thread_source == "subagent"` のセッション
   - 最初のユーザー入力が `/wrapup`、`/today`、`/commit` だけの運用セッション
   - セットアップや初期化だけで、作業対象がないセッション
5. 同じ親スレッド・同じ作業ディレクトリ・同じ作業内容の重複rolloutは1件に統合する。内容が食い違う場合は、保守的に「未確認」とする。サブエージェントの成果を親セッションと別成果として二重計上しない。

成果の判定はセッション終了やタイトルだけで行わない。次のような直接の証拠がある場合だけ「完了」とし、それ以外は「着手」「進行中」「未確認」などの控えめな表現にする。

- 成功したコマンドとその結果
- 通過したテストや検証結果
- 実際のファイル差分、生成物、コミットなどの確認可能な成果

ユーザーの依頼文、計画、アシスタントの「実装した」という発言、ツール呼び出しだけでは完了扱いにしない。失敗や未解決事項がある場合は、後続の成功証拠で解消されたことを確認できない限り残す。取得できた履歴が一部だけの場合、「当日の全作業」ではなく「取得できた記録の範囲」と明示する。

#### cmanの補助利用

cmanのツールが利用可能なら、Codex履歴に含まれないClaude Codeセッションを補う目的で1つのサブエージェントに調査させてもよい。cmanは補助情報源であり、利用不可・エラーの場合もCodex履歴の処理を止めない。cmanの結果も上記の除外・重複排除・完了判定を通す。

出力はプロジェクトごとにまとめ、時系列がわかる場合は時刻を添える。

```
## 今日のセッション横断サマリー
### <リポジトリ名 / プロジェクト名>
- HH:MM 内容 (完了 / 着手 / 未確認)
### <別のリポジトリ>
- ...
```

対象日の履歴が見つからない場合は「該当なし」とする。履歴ファイルを読めない場合は、その事実を明記し、読めたソースだけで作業する。履歴確認のためにビルド、テスト、デバイスアクセス、外部状態の変更を新たに実行しない。

### Step 4: Gather Work Summary (main thread)

メインスレッドで以下のソースから「やったこと」のドラフトを組み立てる。

1. **From Step 3 (Codex session history) — 当日全体の主な網羅ソース**
   - `history.jsonl` と対応するセッションJSONLから、対象日の作業候補をプロジェクト別に整理する
   - セッションのタイトルやユーザー入力ではなく、ツール結果・差分・検証結果で成果を確認する
   - 対象ソースが一部欠けている場合は、網羅できたと断言せず、取得範囲を明示する

2. **From the current session context — 深さの補強**
   - 今 /wrapup を回しているこのセッション内の会話・作業を最も詳細に記憶している
   - 履歴に現在セッションが含まれる場合は重複を除き、session context の方で上書き・肉付けする
   - 変更・作成したファイルの一覧など、session context にしかない具体は積極的に補う

3. **From Step 3 (cman補助) — Codex履歴にないClaude Code作業**
   - cmanが利用できた場合だけ補助情報源として使う
   - Codex履歴と重複する項目はCodex側の詳細を優先し、サブエージェントを別成果として数えない

4. **From Claude Code auto memory（永続メモリ）**
   - セッションを跨いで保持されるメモリファイルを参照する
   - auto memoryディレクトリのパスはシステムプロンプトに記載されている
   - 今日の日付や作業内容に関連するエントリ、今日更新されたメモリファイルがあれば含める

5. **情報の統合**
   - 骨格はCodex履歴（当日の対象セッション）。そこへ現在 session context、cman補助、auto memoryを重ねる
   - 優先順位（同じ作業に複数ソースが触れている場合の詳細さ）: 現在セッションコンテキスト > CodexセッションJSONL > cman補助 > auto memory
   - 重複を除去し、プロジェクトごと or 時系列でグループ化する
   - 散文 1 段落 + 箇条書き の組み合わせで構わない（既存 daily note のフォーマットに合わせる）
   - セッションが多い日はログが長くなる。主要な作業を優先しつつ、Step 5 でユーザーに提示して取捨を委ねる

### Step 5: Present Summary for Review

Show the user what will be added:
```
## ログの追記内容

- HH:MM カテゴリ: 内容
- HH:MM カテゴリ: 内容
- ...

この内容でよろしいですか？
```

Wait for user confirmation or edits.

候補を提示するまではdaily note、activities、wikiを変更しない。履歴やcmanの取得範囲が不完全な場合は、その制約を候補と一緒に示す。

**承認ゲート:** 候補提示前の「分かる範囲で今すぐ追記して」「確認はいらない」「直接書いて」という依頼は、生成した候補内容への承認ではない。必ず候補を提示し、その後にユーザーが「OK」「この内容で追記して」など候補を確認した返答をするまで、daily note、activities、wikiを変更しない。候補提示後に修正依頼があった場合は、修正版を再提示してから承認を待つ。

### Step 6: Append to Daily Note

After confirmation, append under the `## ログ` heading. 公式CLIはheading指定のinsertに対応していないため、Vaultの実ファイルをReadツールで読んでEditツールで挿入する。

**ログのフォーマット:**
- 1行 1エントリ、`- HH:MM <カテゴリ>: <内容>` 形式
- カテゴリ例: `実装` / `調査` / `レビュー` / `MTG` / `学び` / `その他`
- 時刻が不明なエントリ（セッション横断的な作業など）は HH:MM を省略して `- <カテゴリ>: <内容>` でよい
- プロジェクト名 / 技術用語は wikilink (`[[asonas/foo]]`) で記述してよい

```
# Read tool:
Read: /Users/asonas/Obsidian/asonas/daily/YYYY-MM-DD.md

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

`/wrapup` を一日の終わりに回す前提なので、当日分だけ再描画すれば足りる (前日分は朝の `/today` 3a でカバーされている)。

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
```

## Output Format

Always respond in Japanese.

## Notes

- If the `## ログ` section doesn't exist (古いテンプレで作られた daily note の場合), create it at the end of the file before appending
- Keep each log entry concise (1 行 1 作業)
- Use the `- HH:MM <カテゴリ>: <内容>` format consistently
- 当日像の主な網羅は Codex のセッション履歴 (Step 3) が担う。cmanはCodex履歴にないClaude Code作業を補う情報源であり、現在 session context は該当セッションの詳細を肉付けする役割
- セッション履歴やcmanから返却された情報を daily note に書き込む前に、明らかに事実と異なるもの・幻覚が紛れ込んでいないか軽く目視確認すること。成果を断定しすぎていないか（着手止まりを完了扱いにしていないか）、取得範囲を超えて「当日の全作業」と言っていないかを確認する
