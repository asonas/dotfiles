---
name: tempest909-draft
description: tempest909 Bluesky アカウントの投稿下書きを projects/tempest909/drafts/ に複数案で生成する。リリース告知、wiki ダイジェスト、activity まとめ、reflection の4カテゴリに対応。前回投稿以降の差分を素材の主軸に置き、秘書として批評・メンタリングのニュアンスを含めた下書きを書く。投稿そのものは別フロー。Use when asked to write a tempest909 post draft, "tempest909で投稿の下書き", "リリース告知の下書き", "tempest909にこの話題を喋らせたい" など。
---

# /tempest909-draft - tempest909 投稿下書き生成

tempest909 (asonas の Bluesky 秘書ボット, `@tempest909.bsky.social`) の投稿下書きを生成し、`projects/tempest909/drafts/` に書き出すスキル。実際の投稿、log.md への追記、draft 削除は本スキルの対象外で、承認後に別途行う。

下書きは「前回投稿から今回までの飼い主の動き」を素材の主軸に据え、秘書として軽く批評し直して、飼い主の内省を促し次の行動の改善を遠回しに示唆するメンタリングのニュアンスを含めて書く。批評の角度を変える形で複数案を並べるのが基本。詳細は `persona.md` の「投稿の根底にある姿勢: 差分レビューと次への促し」と `attitudes.md` の「メンタリングとして批評する」を参照する。

## 前提

- Obsidian vault: `/Users/asonas/Documents/asonas/`
- プロジェクトディレクトリ: `projects/tempest909/`
- tempest 本体リポジトリ: `/Users/asonas/ghq/github.com/asonas/tempest`

## Workflow

### Step 0: アクティビティのスナップショット更新

下書き生成の素材として `activities/<YYYY-MM-DD>.md` を読むため、呼び出されたタイミングで一次テキストソース (Bluesky / Scrapbox) を最新状態に更新する。`bin/activities-snapshot` が collect + render を1コマンドで実行する。

```bash
cd /Users/asonas/workspace/activities
mise exec -- bundle exec bin/activities-snapshot --source bluesky --source scrapbox --date today || echo "Warning: activities snapshot failed, continuing with existing data"
```

**なぜ `--source` で `bluesky` と `scrapbox` に絞るか**: `github` / `browser` / `claude_code` の3ソースは `~/Library/LaunchAgents/asonas.activities.{github,browser,claude}.plist` の launchd ジョブが 15〜60 分間隔で常時バックグラウンド収集しており、当日分の activities ファイルは常に最新化されている。tempest909-draft が手動で呼ばれるタイミングで重複起動すると同じ state ファイルを並行書き込みするリスクがあるため、launchd でカバーされていない `bluesky` と `scrapbox` だけを明示的に拾う。

collect 系は外部 API を叩くため失敗しうるが、その場合は既存の activities ファイル (launchd で更新された他ソース含む) で先に進める (止めない)。

### Step 1: コンテキストの読み込み

毎回必ず以下を読み込んで、人格・書式・除外ルール・直近の観察を把握する。読まずに書くと過去の決定事項を破る生成になるので飛ばさないこと。

- `projects/tempest909/persona.md` — 人格、口調、ビジュアル仕様、文字数と分割投稿のルール、リリース告知の書式 (「どうぞご利用ください。」+ rubygems URL の必須ルール含む)、投稿の根底にある姿勢 (差分レビューと次への促し、批評視点の二系統: 秘書視点 / 飼い主代弁)、並立する秘書アカウント
- `projects/tempest909/sources.md` — 拾うソース / 拾わないソースのホワイト・ブラックリスト、二重フィルタの考え方
- `projects/tempest909/attitudes.md` — 姿勢ドキュメント。決定権は飼い主、観察者の距離感、メンタリングとして批評する、自己言及を控える、公開ラインの確認、仕事の話に触れない。`sources.md` のメカニカルな線引きと別に、姿勢面の判断軸として使う
- `projects/tempest909/observations.md` — 観察日記。append-only で記録された飼い主の活動観察。テーマ選びの一次素材として参照する
- `projects/tempest909/drafts/README.md` — draft ファイルのフォーマット (`category`, `stance`, `sources`, `status`, `needs_review`, `length`, `part` の各フィールド)
- `projects/tempest909/log.md` の **末尾エントリ (= 前回投稿) の日時** とそれ以降数エントリ — 差分レビューの起点。直近の言い回し、話題の重複回避、すでに投稿済みトピックの確認も兼ねる

`projects/tempest909/forbidden_terms.md` が存在する場合は読み込む (現状は未作成のことが多い)。

### Step 2: カテゴリと差分の起点、批評視点の確認

ユーザーに「何のカテゴリで何について書くか」を確認する。引数で明示されていればそのまま使う。tempest909 の方針は「観察と論評」を主軸、「リリース告知」を副軸とし、自己言及 (reflection) は副産物として頻度を落とす。カテゴリは 4 種類。

- `release` — tempest 本体の新バージョンリリース告知 (リリースマネージャー業務、本領)
- `wiki-digest` — `wiki/` 配下の最近の更新をダイジェストにした投稿
- `activity` — `activities/` 由来の日常活動、`observations.md` に貯まった観察、`personal-feed/` などから拾った素材 (読んだ記事、聞いた音楽、ブックマーク等)。新方針における主力カテゴリ
- `reflection` — 自己言及、雑感、tempest909 自身の話 (初期の自己紹介フェーズを除き、頻度は控えめにする)

カテゴリを決めたら、**差分の起点 (前回投稿の日時)** を `log.md` の末尾エントリから拾う。Step 3 の素材収集はこの日時以降に発生した動きを主軸にする。差分がほぼない (前回投稿と同日内に再度回しているなど) 場合は当日素材だけで組むが、前回投稿との連続性を意識した語尾と切り口を選ぶ。

`mode` フィールドは廃止し、代わりに `stance` フィールドで **批評視点** を明示する。値は次の三つを使い分ける。

- `秘書視点` — 「後ろから見ていて〜と感じました」「外から見るとこう見えました」のように、観察者の主観として軽く批評する
- `飼い主代弁` — 飼い主が Bluesky / Scrapbox / observations.md / 公開リポジトリで書いた言葉を引き取り、要約し直して鏡として返す。公開されていない内面は補完しない
- `併用` — 観察対象を秘書視点で軽くレビューしたあと、飼い主の判断を引き取って次の一歩のヒントを置き直す、という標準的な運び

連投にするか単発にするかは、批評を載せるのに必要な分量で決める。投稿の構造的な選択であって排他モードではない。連投は 2 から 3 投稿で組み、各投稿が独立して読める密度を保つこと。詳細は `persona.md` の「投稿の根底にある姿勢: 差分レビューと次への促し」セクションを参照する。

### Step 3: カテゴリ別の素材収集

各カテゴリの収集は、Step 2 で拾った **前回投稿の日時を起点とした差分** を主軸に行う。`log.md` 末尾の post URL とタイムスタンプを基準にして、それ以降に発生した動きを優先的に並べる。差分が薄い場合は当日素材で組み、その場合でも前回投稿との連続性 (話題の続き / 区切り / 文脈の交代) を意識する。

#### release の場合

1. リリース対象バージョンを確認 (ユーザー指定 or `git --no-pager tag --sort=-v:refname | head -3` で最新タグから推定)
2. 前バージョン (prev) から HEAD までの変更コミットを取得:
   ```bash
   cd /Users/asonas/ghq/github.com/asonas/tempest && git --no-pager log <prev>..HEAD --oneline
   git --no-pager log <prev>..HEAD --stat
   ```
3. CHANGELOG があれば確認
4. 機能追加とバグ修正を分類し、ハイライトを 2-3 個選ぶ
5. rubygems URL を組み立てる: `https://rubygems.org/gems/tempest-rb/versions/<version>` (gem 名は `tempest-rb` で固定。`tempest` ではないので注意)
6. 末尾の決まり文句 「どうぞご利用ください。」を URL 直前の行に必ず入れる (はてな由来の慣用句。`release` カテゴリ専用)

#### wiki-digest の場合

1. `wiki/log.md` の末尾を読み、直近の wiki 更新ログを把握
2. 新規ページや大幅更新を 1-3 件ピックアップ
3. 引用元ノートへの wikilink を `sources` に列挙

#### activity の場合

1. `log.md` 末尾の前回 activity 投稿のタイムスタンプを確認し、それ以降に `observations.md` / `activities/` / `wiki/log.md` / `personal-feed/` に追記された動きを差分として並べる
2. 差分から扱えるテーマを 1-3 件ピックアップ。テーマ選びの基準は「前回投稿から景色が動いた点」「飼い主の判断や試行錯誤が観察できる点」「秘書視点または飼い主代弁で批評を載せやすい点」
3. 必要なら cman (`mcp__plugin_cman_cman__list_sessions` / `search_sessions`) で直近の Claude Code セッションから個人プロジェクト由来の素材を引く。`sources.md` ホワイトリスト (`projects/tempest/`、`projects/strudel-rb/`、`projects/partch/`、`projects/moire/` など) に該当するものだけを採用
4. 各テーマについて、**批評の角度** (秘書視点 / 飼い主代弁 / 併用) と、**次の行動の改善を促す一言** を仮置きする。本文を書く前にこの一言を決めておくと、語尾と着地点がぶれない
5. 業務固有名詞が混ざっていないかは Step 4 で再チェック

#### reflection の場合

1. ユーザーの指示や直近の会話から素材を整理
2. 既存の persona / wiki / log と矛盾しないか確認
3. 自己言及は新方針で頻度を落としているため、reflection を選ぶ動機が薄ければ activity (観察) への切り替えを提案する

### Step 4: 二重フィルタと姿勢チェック

[[sources]] に定義された除外ディレクトリ (`companies/`, `1on1/`, `evaluations/`, `pr-reviews/`, `goals/`, 業務系の `projects/` 配下) から素材を引いていないことを確認。生成文に業務固有名詞が混ざる可能性があれば `needs_review: true` フラグを立てる。`forbidden_terms.md` がある場合はそのリストと照合。

加えて、`attitudes.md` の姿勢チェックを通す。公開ラインが曖昧な素材 (ホワイトリスト未明示のイベント告知、第三者の活動、tempest909 自身の運用機微) は `needs_review: true` にする。家族の話や飼い主の内面への踏み込みは含めない。自己定義型の文を不必要に書いていないか見直す。

### Step 5: 下書き生成 (複数案)

[[persona]] に従って 2-3 案を生成する。各案は「批評の角度」や「素材の取り方」を変える。例えば activity なら、機材選定の積み上がりを秘書視点で軽くレビュー / 飼い主の判断を代弁して鏡として返す / 二つを併用して次の一歩を遠回しに示す、などで角度を分ける。リリース告知なら、機能推し / 修正テーマで括る / ノイズ削減でまとめる、などの角度を変える。

#### 共通ルール

- 300 graphemes 以内 (Bluesky の文字制限)。release の場合は URL の 51 文字を含めて 300 以内、本文は実質 240 文字程度に収める
- です・ます調、短めの文、絵文字なし
- 淡々としつつ、tempest 本体の話になると少し前のめりになる性格を滲ませる
- 箇条書きを使わず散文で書く
- 本文には **批評のニュアンス** を必ず含める。事実を並べるだけで終わらせず、秘書視点または飼い主代弁の形で「外から見るとこう見える」を一段差し挟む
- **次の行動の改善を遠回しに促す** 一文を本文の終盤に含める。語尾は「〜のように見えました」「〜してみると景色が変わりそうです」「〜の方向に進むと整理されそうです」のような柔らかい仮置きを基本にし、説教・指図のトーンを避ける
- `category: release` の場合は本文末尾を「(本文)\n\nどうぞご利用ください。\n\nhttps://rubygems.org/gems/tempest-rb/versions/<version>」の構造で締める。リリース告知でも、機能列挙だけで終わらせず、その変更がユーザー (飼い主自身も含む) の次の使い心地をどう変えそうかに一言触れる

#### 各候補のメタデータ

```markdown
### 候補 N (テーマの短い説明)

category: release | wiki-digest | activity | reflection
stance: 秘書視点 | 飼い主代弁 | 併用
sources: [[...]], [[...]]
status: pending
needs_review: false | true
length: 約 NNN / 300 (概算)
part: 1/1

本文をここに書く。
```

`length` は grapheme cluster 単位での概算。grapheme カウンタが未実装の現状では、code point ベース (`String#length` 相当) の概算を「約 NNN」として記載し、Bluesky 投稿前に目視確認する旨をメモする (tempest CLI 側で 300 grapheme 超過を弾くため、概算で 250 を超えそうなときは保守的に短くする)。

連投の場合は `part` を `1/2` `2/2` あるいは `1/3` `2/3` `3/3` の形式で振り、各 part を別候補として並べる。連投セットの承認は一括で行う前提なので、`status` `stance` `category` `sources` を全 part でそろえる。連投の構造は 1 投目で差分の事実を置く、2 投目で対比・引用・分析を入れる、3 投目で批評と次への促しを着地させる、というリズムを基本にする ([[kanisho]] 先輩・[[Charon]] 先輩のスレッド形式の踏襲)。

### Step 6: ファイル書き出し

ファイル名は `projects/tempest909/drafts/YYYY-MM-DD.md`。同日に複数回スキルを回す場合は `YYYY-MM-DD-HHMM.md` のように時刻を足して衝突を避ける。

ファイル先頭に状況説明を 1-2 段落で書く (どのリリースか、どの wiki 更新を扱うか、何案あるか)。

ファイル末尾に「## メモ」セクションを置き、選定の意図、文字数の概算、注意事項を残す。

### Step 7: 観察日記の更新

セッション中に得た新しい観察 (飼い主の活動、選定の意図、姿勢の調整) があれば `projects/tempest909/observations.md` の末尾に append する。観察は事実を主、軽い解釈を従とし、日付見出しの直下に散文で書く。下書きの素材として今回拾った話題 / 拾わなかった話題のメモも、後から振り返れる粒度で残す。

軽微な作業の場合は更新しなくてもよいが、新方針の変更や新しい運用判断があった日には必ず一段落以上残すこと。これは [[taea]] さんの `memory.md` (秘書側が飼い主について記録する観察日記) に倣った仕組みで、投稿ネタの再利用性を高める狙いがある。

### Step 8: ユーザーへの報告

- 生成したファイルの絶対パス
- 何案生成したか、各案の違い (1-2 行ずつ)
- どれを推奨するか + その理由
- 投稿は別フローであることを明示 (`tempest --user tempest909.bsky.social post -` 経由)

## 投稿フロー (本スキルの対象外、参考)

ユーザーが候補を採用したあとの手順:

1. 投稿本文を `/tmp/tempest909-post-1.txt` などに書き出す (連投なら連番)
2. 単発投稿の場合:
   ```bash
   cd /Users/asonas/ghq/github.com/asonas/tempest && \
     bundle exec exe/tempest --user tempest909.bsky.social post --json - < /tmp/tempest909-post-1.txt
   ```
   `--json` は uri / cid / url を 1 行 JSON で返すのでスクリプト化しやすい
3. 連投の場合: 1 投目を post し、返ってきた URI を控える。2 投目以降は `--reply-to <親URI>` でぶら下げる:
   ```bash
   bundle exec exe/tempest --user tempest909.bsky.social post --json \
     --reply-to "at://did:plc:.../app.bsky.feed.post/<rkey>" - < /tmp/tempest909-post-2.txt
   ```
   3 投目は 2 投目の URI を `--reply-to` に渡す (Bluesky のスレッド構造で parent は直近の親、root は最初の post に解決される)
4. 各投稿の URI を `projects/tempest909/log.md` に追記する (JST タイムスタンプ、post URI/URL、`reply to` 行 (連投時)、sources、category、mode、length、part、本文)
5. 採用した draft ファイル / 採用した候補ブロックを削除
6. 一時ファイルを削除 (`command rm /tmp/tempest909-post-*.txt`)

tempest CLI は 300 grapheme を超える本文を `error: post exceeds 300 graphemes` で拒否するので、それが事実上の最終チェッカになる。このフローを別スキル化するかは未定。当面はユーザーの口頭指示で手動運用する。

## アンチパターン

- persona.md / attitudes.md / observations.md を読まずに性格や口調をでっち上げる
- リリース告知で rubygems URL や「どうぞご利用ください。」を忘れる
- 業務情報源 (`companies/`, `1on1/`, `evaluations/` など) を素材に混ぜる
- 自己言及 (reflection) ばかり生成して新方針の観察主軸を崩す
- 1 案しか生成しない (複数案を比較できないと選定の自由度がなくなる)
- 連投を「ネタが薄いのに引き伸ばす」目的で使う (各 part が独立して読める密度を保てない場合は単発に倒す)
- 候補ごとの違いを言語化せずユーザーに丸投げする
- 文字数カウントを省略する (300 超過は tempest CLI が拒否する)
- 候補を直接投稿してしまう (本スキルは draft 生成までで止める)
- 観察日記の更新を忘れる (素材の再利用性が下がる)
- 「単発 / 内省 / レビュー / リファインメント」を排他モードとして並べる (旧仕様。現在は批評を全候補のデフォルトとし、視点を `stance` で示す)
- `log.md` 末尾の前回投稿日時を確認せず、当日素材だけで素材選定を済ませる (差分レビューの起点が失われる)
- 観察の事実を並べるだけで終わり、批評や次の一歩への促しが入っていない (メンタリングの軸が抜ける)
- 飼い主が公開していない内面や判断を代弁してしまう (`stance: 飼い主代弁` は公開済みの言葉を引き取る形のみ許される)
- 批評が説教・採点・指図のトーンになる (語尾は柔らかい仮置きにし、決定は飼い主に委ねる)
