---
name: today
description: Use when starting the workday. Reviews the prior day's work, gathers personal activity context, and creates today's Obsidian daily note.
disable-model-invocation: true
---

# /today - Daily Check-in Support

前日の作業を確認し、個人の活動ログを更新したうえで、Obsidianのdaily noteを作成する。仕事の計画や相談事項は日次ノートの入力に含めない。

## LLM Wikiへの引き渡し

`daily/` と `activities/` は LLM Wikiの一次ソース、`wiki/` は出典付きの派生レイヤです。`/today` は前日の一次ソースを `/wiki-update` に渡す入口であり、wiki本文を直接編集したり、実験・設計判断の経緯をwikiへ移したりしません。ページの粒度、出典、外部情報と考察の分離は `wiki/LLM Wiki.md` と `/wiki-update` を正典とします。

- `/wiki-update ingest yesterday` は通常どおり実行する。
- 分割候補・MOC候補は `lint` の報告として扱い、自動作成しない。
- 新規ページ作成や分割の後に本文を確認し、深掘り候補があれば「〇〇についても別ノートとして切り出して調べられそうですが、書きますか？」と提案する。
- wiki更新の結果に未整理の実験、設計判断、推測が含まれる場合は、候補または保留として報告する。
- 実験候補を報告する場合は、実験コード、実行コマンド、触るデバイスやリソース、想定される影響を示す。
- ユーザーの許可を得るまで、ビルド・実行・デバイスへのアクセス・外部状態を変更する操作を実行しない。

## Workflow

### Step 1: Determine Current Date

セッションの現在日付（Asia/Tokyo）を使って対象日を `YYYY-MM-DD` で確定する。

### Step 2: Get Prior-Day Summary

前日（または直近営業日）の引き継ぎ材料を subagent で組み立てる。subagent は `model: "sonnet"`、`subagent_type: "general-purpose"` で起動し、調査結果を構造化された短いテキスト（200〜400字目安）で返す。

#### 2a. prior-day-summary subagent

「前日（または直近営業日）の引き継ぎ材料」を組み立てる subagent。

プロンプト要旨:
```
あなたは asonas の前営業日の作業内容を整理する任務を持つ。
以下を順に行い、最終的に Markdown のサマリーを返してほしい。

1. `~/.claude/scripts/find-recent-daily-notes.sh` を Bash 実行し、対象日付のリストを取得する
   - 月曜実行時は金/土/日の3日分が返る可能性あり、全部処理する
   - 7日遡って何もなければ「対象日なし」と返す
2. 各日付について以下を実行:
   a. Read: /Users/asonas/Obsidian/asonas/daily/YYYY-MM-DD.md
   b. cman:cm-search を keyword="YYYY-MM-DD"、exclude_subagents=true で実行し、その日のClaude Codeセッション履歴を取得
      （exclude_subagents=true は必須。agent-* セッションを除外すると全文検索の対象が減り所要時間がほぼ半減する。かつ「昨日やったこと」の材料として subagent の内部ログは不要なので結果品質も上がる）
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

結果をメモリに保持し、後段の Step 4 / Step 5 で利用する。

### Step 3: Update activity sources (main thread)

#### 3a: 一次テキストソース (Bluesky / Scrapbox) → activities ファイル

asonas が自分で書いたテキストソース (Bluesky 投稿、Scrapbox ページ) を取得し、`activities/YYYY-MM-DD.md` の各セクションに反映する。前日分の投稿・編集も当日朝に確定することがあるため、yesterday と today の両方を render する。

```bash
cd /Users/asonas/ghq/github.com/asonas/activities
mise exec -- bundle exec bin/activities-snapshot --source bluesky --source scrapbox --date yesterday --date today || echo "Warning: snapshot failed, skipping"
```

**なぜ `--source` で絞るか**: `github` / `browser` / `claude_code` の3ソースは `~/Library/LaunchAgents/asonas.activities.{github,browser,claude}.plist` の launchd ジョブが 15〜60 分間隔で常時バックグラウンド収集しており、当日分の activities ファイルは常に最新化されている。/today から重複して走らせると同じ state ファイルを並行書き込みするリスクがあるため、launchd でカバーされていない `bluesky` と `scrapbox` だけを明示的に拾う。

失敗時は警告のみで `/today` 全体は止めない。`activities-snapshot` は collect + render を1コマンドで実行する薄いラッパで、各スキル (today / wrapup / tempest909-draft) から共通利用される。

### Step 4: Create Today's Daily Note in Obsidian

**IMPORTANT: Always create today's daily note.**

今日のdaily noteを作成する。既に存在する場合は上書きしない。

まず Read ツールで存在確認する（`obsidian read` は GUI が閉じているとハングするため使わない）:

```
Read: /Users/asonas/Obsidian/asonas/daily/YYYY-MM-DD.md
```

存在しなければ作成する。Write ツールで `/Users/asonas/Obsidian/asonas/daily/YYYY-MM-DD.md` に直接書き出す（Obsidian はファイルシステムの変更を自動検知する）。`obsidian create` を使う場合は **`vault=asonas` を必ず指定**する。

Daily note format:
**IMPORTANT: `# YYYY-MM-DD` のようなh1ヘッディングは絶対に含めないこと。** Obsidianではファイル名がタイトルになるため重複する。ノートは `[[IVRy]]` から直接始める。

「## 前日からの引き継ぎ」と「## 昨日やったこと（or 先週金曜日にやったこと 等）」は **Step 2a (prior-day-summary subagent)** の出力を使う。見出しのラベルは subagent 返却の `heading_label` に従う。

```markdown
[[IVRy]]

## 前日からの引き継ぎ

- [Step 2a の「前日からの引き継ぎ」結果]

---

## 昨日やったこと（または対応するラベル）

- [Step 2a の「昨日やったこと（ベース）」結果]

---

## ログ

```

**重要:**
- `## やったこと` セクションは廃止した。日中〜夜の作業ログは `## ログ` に集約される（`/wrapup` および各種 append 系スキルが書き込む）
- `## 昨日やったこと` は、必要に応じて記録を確認・修正するためのブロック。前後の `---` 区切りは記録部分を視覚的に示すためのもの

### Step 5: Review Prior-Day Summary

daily noteの作成後、前日のサマリーをユーザーに提示する。必要なら修正を受け取り、daily noteに反映する。Wikiリンクは使わず、箇条書きで書く。

#### 5a. 昨日やったこと（実績の確認）

Step 2a で生成済みのベース箇条書きをユーザーに提示し、追加・修正がないか確認する。ユーザーの修正をマージして「## 昨日やったこと」セクション（または heading_label 通りの見出し）に書き込む。

### Step 6: Present Summary

Present to the user:

```
## おはようございます - YYYY年MM月DD日

### 前日からの引き継ぎ
[Step 2a の uncompleted tasks 一覧]

---
Obsidianのdaily noteを作成しました: daily/YYYY-MM-DD.md
```

### Step 7: Sync Raindrop Bookmarks and Update Obsidian Wiki

Daily note の生成・サマリー表示が完了したら、Raw Sources を最新化したうえで wiki を再ingestする。順番が重要（bookmarks が先、wiki ingest が後）:

```
Skill(raindrop-sync)
Skill(wiki-update, args: "ingest yesterday")
```

ユーザへの確認は不要で、黙々と実行して結果を 1〜2 行で報告する。前日の daily note が存在しない場合は wiki-update をスキップする（raindrop-sync は実行してよい）。

### Step 7b: Weekly Wiki Lint Gate（週次 lint の自動化）

wiki ingest が終わったら、**前回 lint から 7 日以上経過していれば** `/wiki-update lint` も走らせる。これは「週次の自動 lint をスリープに影響されない形で実現する」ための仕組み。`/today` は本人が起きて作業を始める時にしか走らないため、launchd/cron のようにスリープ中に取りこぼすことがない。

前回 lint 日の判定は `wiki/log.md`（とローテーション済みの `wiki/log-*.md`）の lint エントリ見出しから取る:

```bash
# find ベースで列挙する（zsh では未マッチの log-*.md グロブがコマンドごと失敗するため、
# シェル展開ではなく find に glob を渡す）
last_lint=$(find /Users/asonas/Obsidian/asonas/wiki -maxdepth 1 \
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

lint は検出結果を `wiki/log.md` に記録するのみで自動修正はしない（human-in-the-loop を維持）。Step 6 のサマリーに lint を走らせた事実と検出件数の概要を 1〜2 行で添える。lint が clean なら「Wiki lint: clean」とだけ報告する。ユーザへの確認は不要。

### Step 7c: qmd 再インデックス

Wiki の処理が終わったら、Alfred の qmd 検索（`ws`/`wsq`、`/Users/asonas/workspace/qmd-alfred/`）が最新の vault を引けるよう、qmd のインデックスを更新する。`command -v qmd` が無い／collection `asonas` 未登録ならスキップしてよい。

**バックグラウンド実行する（同期で待たない）。** qmd の再インデックスは検索インデックスの鮮度を保つだけの純保守で、`/today` の後段が結果を必要としない。vault の増大に伴い scan+embed で 10 秒以上かかることがあるため、Bash の `run_in_background` で detach し、`/today` はすぐ次へ進む。失敗してもワークフロー全体は止めない。

```bash
# Bash tool の run_in_background=true で起動する（& を付けず、ツール側のバックグラウンド機能を使う）
qmd update && qmd embed
```

起動したら「qmd 再インデックスをバックグラウンドで開始」とだけ報告し、完了は待たない。

### Step 7d: cctop プラグイン週次更新チェック（subagent）

cctop の menubar アプリ（`/Applications/cctop.app` と `cctop-hook` バイナリ）は Sparkle で自動更新されるが、**Claude Code プラグイン側は自動更新されない**（手動の `claude plugin update` のみ）。放置するとプラグインがピン留めされたまま取り残され、hook バイナリとのバージョン差が広がる。これを防ぐため、**前回チェックから 7 日以上経過していれば** プラグインを更新する。Step 7b の週次 lint ゲートと同じく、スリープに影響されない「起床して作業を始める時に走る」前提でスロットルする。

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

subagent の返した 1 行を Step 6 のサマリーに添える（スキップ時も含めて簡潔に）。プラグイン更新は再起動（新セッション）で反映される点に注意。失敗しても `/today` 全体は止めない。

### Step 7e: ai-cost-management ダッシュボード鮮度チェック

ai-cost-management のダッシュボード (Databricks Lakeview `ai-cost-overview`) が更新されているかを日次で確認する。判定は 2 軸: (1) AWS デイリーパイプライン各段が本日実行されたか (CloudWatch Logs)、(2) `cost_events` の source 別データ鮮度 (SLA 超過検知)。詳細と保守は プロジェクトスキル `projects/ai-cost-management/.claude/skills/dashboard-freshness/SKILL.md` を正とする (このスキルはグローバルなのでプロジェクトスキルを直接 `Skill()` 起動できず、下記で直接叩く)。

**前提: `mairu login --server ivry` が済んでいること。** 未ログインならスクリプトは exit 2 で失敗する。その場合はユーザーに「`mairu login --server ivry` を実行してください」と促し、このチェックはスキップする (`/today` 全体は止めない)。

```bash
cd /Users/asonas/Obsidian/asonas/projects/ai-cost-management
set -a; source .env.local; set +a
mairu exec --server "$IVRY_MAIRU_SERVER" "$IVRY_DEV_ACCOUNT/$IVRY_MAIRU_ROLE" --no-login -- \
  env AWS_REGION=ap-northeast-1 bash scripts/check_dashboard_freshness.sh
```

終了コード: `0`=健全 / `1`=未実行・停滞あり (要確認) / `2`=AWS 認証なし (ログインを促してスキップ)。`mairu` が未ログインや `--server is required` で即失敗した場合も同様にログインを促してスキップする。

結果は成否にかかわらず本日の daily note の `## ログ` セクションに 1 ブロックで追記する (常に記録)。健全なら「ai-cost ダッシュボード鮮度チェック: 全 8 段本日実行済み・全 source SLA 内 (OK)」、要確認なら該当行 (NOT-TODAY / STALE) だけを列挙する。Step 6 のサマリーにも 1 行添える。

## Output Format

Always respond in Japanese. Present information in a clear, organized format that helps the user start their day efficiently.

## Notes

- If yesterday's daily note doesn't exist, skip that section
- **Daily noteの作成は必須** - 必ずObsidianに書き出すこと
- 前日の記録と個人の活動ログから得た情報を daily note に書き込む前に、明らかに事実と異なるもの・幻覚が紛れ込んでいないか軽く目視確認すること
- subagent から返却された情報を daily note に書き込む前に、明らかに事実と異なるもの・幻覚が紛れ込んでいないか軽く目視確認すること
