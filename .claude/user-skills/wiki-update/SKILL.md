---
name: wiki-update
description: Karpathy-style LLM wiki maintenance over the Obsidian asonas vault. Ingests source notes (daily / notes / essays / 1on1) and incrementally builds and updates entity / concept / event / org pages under `wiki/`. Also supports lint and index rebuild. Use when invoked as `/wiki-update`, called from `/today` or `/wrapup`, or when the user asks to update / refresh the Obsidian wiki.
argument-hint: "[ingest <source>... | lint | rebuild-index]"
disable-model-invocation: false
---

# /wiki-update - Obsidian Wiki Maintenance

karpathy の "LLM Wiki" 方針に従い、Obsidian asonas vault の `wiki/` 配下を LLM が育てる仕組みです。3 つのモードを持ちます。

- **ingest**: 指定したソースノートを読み、抽出した固有名詞・概念に対応する wiki ページを 1 パスでまとめて作成・更新します（karpathy 流の "10〜15 ページを一度に触る" 想定）。
- **lint**: `wiki/` 配下を走査し、矛盾・古い記述・孤立ページ・解決できない wikilink を検出して `wiki/log.md` に列挙します。
- **rebuild-index**: 全 wiki ページを走査し、`wiki/index.md` を再生成します。

## 前提

- vault: `asonas`（path: `/Users/asonas/Obsidian/asonas/`）。`obsidian` CLI を使う場合は必ず `vault=asonas` を明示します。
- wiki ディレクトリ: `/Users/asonas/Obsidian/asonas/wiki/`
- wiki 配下は **フラット構造**。サブディレクトリを切らない。分類は frontmatter の `type` で行い、カタログ化は `wiki/index.md` が担います。
- 運用ファイルは 3 つ。`wiki/index.md`（カタログ）、`wiki/log.md`（操作履歴、append-only）、`wiki/deferred.md`（ページ化を見送った語の台帳、**状態を持つ唯一のファイル**）。この 3 つは qmd のインデックスから除外されています（`~/.config/qmd/index.yml` の `collections.asonas.ignore`）。固有名詞の密度が高く、検索で本来の wiki ページを押しのけるためです。除外対象を増やす場合は同じ ignore に追記すること。
- Obsidian は `[[bare-name]]` を vault 全体から解決するため、wiki 配下にあろうと top-level にあろうとリンクは壊れません。

## ページ書式

各 wiki ページは frontmatter + 本文の形を取ります。

```yaml
---
type: entity        # entity | concept | event | org | comparison | summary
aliases: []         # 別表記。例: [RubyKaigi 2025]
sources:            # このページの記述の出典 wikilink（必須）
  - "[[daily/2026-05-19]]"
  - "[[notes/rubykaigi-2025-day1]]"
updated: 2026-05-20
---
```

本文は CLAUDE.md の `## 文章スタイル` セクションに従う：です・ます調・冷静で論理的・箇条書き禁止・散文・高校生語彙。

各段落の末尾 or 末尾近くで、その段落の根拠となる daily / notes / essays への wikilink を 1〜2 個示すこと（karpathy の citation 原則）。

## モード詳細

### ingest

呼び出し:

```
/wiki-update ingest <source1> [source2 ...]
/wiki-update ingest today        # 今日の daily note
/wiki-update ingest yesterday    # 昨日の daily note
/wiki-update ingest 2026-05-19   # 指定日の daily note
```

引数解決:

- `today` / `yesterday` / `YYYY-MM-DD`: 下記6種をまとめて同じ ingest セッションのソースとして読み込む
  1. `daily/<YYYY-MM-DD>.md`（手書きの日報）
  2. `activities/<YYYY-MM-DD>.md`（machine-generated。カレンダー予定、GitHub、ブラウザ履歴、Claude Code、Bluesky 投稿などが集約されている。daily note からは transclude されているが Read ツールは transclude を展開しないため、明示的に読む必要がある）
  3. 当日 `mtime` の `projects/**/*.md`（その日に手で更新したプロジェクトノート。`find /Users/asonas/Obsidian/asonas/projects -name '*.md' -newermt <YYYY-MM-DD> -not -newermt <翌日>` で検出）
  4. 当日 `mtime` の `notes/**/*.md`（同上。単発の調査ノートも拾う）
  5. その日に `bookmarks/.last_sync` 経由で取り込まれた新着 bookmarks（`bookmarks/*.md` のうち frontmatter `last_synced` が当該日付の md）
  6. その日に `/books-highlights` で更新された読書ハイライト（`books/*.md` のうち frontmatter `last_synced` が当該日付の md）。書名・著者・章ごとのハイライトは概念ページ化の素材になる。引用は逐語なので wiki では要約・統合する
- vault 相対パス（例: `notes/foo.md`, `projects/tempest/foo.md`, `bookmarks/123456.md`, `books/シンプリシティ（ハイライト）.md`, `activities/2026-05-20.md`）: そのまま読む。bookmark や個別ファイルを直接渡すと単一ファイル ingest になる
- 引数省略時: today にフォールバック

`activities/<YYYY-MM-DD>.md` を読む際の注意:

- セクション区切りは `<!-- BEGIN: <source> -->` 〜 `<!-- END: <source> -->` の HTML コメントで囲まれている。各セクションの中身（特に `## Bluesky` の投稿本文と `## GitHub` の PR タイトル）は固有名詞・概念の宝庫
- 「`_イベントなし_`」とだけ書かれているセクションはスキップしてよい
- カレンダーセクション（`## カレンダー`）の予定タイトルは個人の打ち合わせ名や子の送迎などプライベートが多いので、wiki 化候補からは除外する（参照のみに留める）

#### 手順

1. **deferred 台帳の読み込み**: `wiki/deferred.md` を Read する。ここに載っている語は過去の ingest で「初出だから」という理由だけでページ化を見送ったものであり、**今回のソースに出てきたかどうかに関わらず回収の対象**になる。この読み込みを省略してはならない。
2. **ソース読み込み**: 指定された note を Read で全文取得する。
3. **エンティティ抽出**: 本文を読み、wiki ページ化すべき語を列挙する。基準は CLAUDE.md の `## リンク戦略` の Step 2 と同じ:
   - プロジェクト名・リポジトリ名
   - 技術用語（ツール名・プロトコル名・フレームワーク名）
   - 人名
   - 自分が繰り返し参照する概念
   - 一般名詞・1 回限りの固有名詞はリンクにしない

   **読んだだけで済ませず、必ず機械的な突き合わせも行う。** 本文を一度読むだけの抽出は取りこぼす（実例: `Colima` は 2026-06-15 と 06-17 の daily に現れて 2ソース・ルールを満たしていたのに、ページ化も deferred 記録もされなかった）。

   ```bash
   H=~/.claude/skills/wiki-update/health
   ruby $H/mentions.rb <source>...              # 既存ページへの言及を洗い出す
   ruby $H/mentions.rb --candidates <source>... # 既存でも deferred 済みでもない新規候補
   ```

   - `mentions.rb` の `linked` / `plain` / `alias` に出た既存ページは**増補の検討対象**。手順 7 で扱う
   - `--candidates` はノイズを含むチェックリストであって、ページ化の指示ではない。列挙された語のうち固有名詞として意味があるものだけを、手順 5 の 2ソース・ルールにかける
   - 自分の読みで拾った語がスクリプトの出力に無い場合もある（表記揺れなど）。その場合は自分の読みを優先する。スクリプトは下限であって上限ではない
4. **既存ページ照合**: 各エンティティについて `/Users/asonas/Obsidian/asonas/wiki/<名前>.md` の存否を確認する。
5. **新規作成の基準（2ソース・ルール）**: 既存ページがないエンティティは、無条件にページ化せず、まず再出現の証拠を確認する:

   ```bash
   grep -rl --include='*.md' -F '<名前>' /Users/asonas/Obsidian/asonas/{daily,notes,essays,projects,weekly,1on1} | grep -v '今回のソース'
   ```

   - **別の日のソースにも登場している（2回目以降の出現）** → ページを作成する
   - **今回が初出** → ページは作らない。ソースノート側に赤リンク `[[名前]]` だけ付け、`wiki/deferred.md` の「様子見」表に行を追加する
   - 例外として、初出でもページ化してよいのは「自分のプロジェクト・リポジトリ」「継続的に関与することが確実なもの（所属組織、購入した機材など）」に限る。例外を使った場合は log の note に理由を 1 行残す

   この基準の目的は、一度きりの固有名詞による 1 段落スタブの量産を防ぎ、wiki を「繰り返し現れるトピックが積もる場所」に保つことにある。
6. **deferred の回収（毎回必ず実行）**: 手順 1 で読んだ `wiki/deferred.md` の「ページ化待ち（sources >= 2）」表を処理する。この表に載っている時点で 2ソース・ルールは既に満たしているので、再度の grep は不要。

   - 今回のソースにも出てきた語を最優先で処理する。次いで、上から順に **最低 3 件**をページ化する。1 回の ingest で全部を消化する必要はないが、ゼロで終わらせてはならない
   - ページ化したら deferred.md から**その行を削除**し、log の `created:` に載せる
   - ページ化しないと判断した語は「見送り」表へ移し、理由を 1 行書く。判断を書かずに「ページ化待ち」に残置しない
   - 「様子見（sources == 1）」表の語が今回のソースに出てきたら、sources を数え直して 2 以上なら「ページ化待ち」へ移す

   この手順が deferred の唯一の回収経路である。ここを飛ばすと 2ソース・ルールは「作らない」だけのルールになり、未回収の語が無限に溜まる（2026-07 時点で 100 語が滞留していた実績がある）。
7. **更新 or 新規作成**:
   - **既存ページがある場合**: 本文に新しい事実を統合する。重複は避け、既存記述と矛盾する場合は両論併記したうえで「2026-05-20 時点では後者が正しい」のように日付付きで判断を残す。frontmatter の `sources` と `updated` を更新する。新規作成よりも既存ページの増補を常に優先する
   - **新規作成の場合**: 上記の frontmatter + 散文本文で作成する。本文は最低 1 段落、根拠 wikilink 必須。

   **材料集めの grep は必ずファイル名が出る形で行う。** `grep -rn` か `grep -rl` を使い、`grep -rh` は使わない。`-h` はファイル名を落とすため、文だけが手元に残って出典が分からなくなり、それでも frontmatter は書けてしまうので「もっともらしいが誤った出典」が入り込む。deferred の回収は特定のノートを読むのではなく vault 全体を grep して材料を集める作業になるため、この事故が起きやすい。2026-07-26 の ingest では実際に 6 ページで誤った出典を書き、事後に修正した。

   ページを書き終えたら、その場で検証する:

   ```bash
   ruby ~/.claude/skills/wiki-update/health/verify-sources.rb <ページ名>...
   ```
8. **横断更新**: karpathy 流に「1 回の ingest で 10〜15 ページを更新する」想定で、抽出した全エンティティを一度のセッションで処理する。1 ページずつユーザに確認しない。

   手順 3 の `mentions.rb` が挙げた既存ページを上から順に検討し、**ソースに新しい事実があるものはすべて増補する**。「言及はあったが増補しなかった」ページについては、それでよい理由が自分の中にあるはずなので、まとめて log の note に 1 行で書く（「◯◯と△△は言及のみで新事実なし」で足りる）。

   実績値として 2026-07 時点の 1 ingest あたりの page touch は 3.47 で、想定の 10〜15 に遠く届いていない。**触ったページ数が 3 未満で終わる ingest は、ソースが薄いのか自分が拾えていないのかを判断して、log の note にどちらかを明記すること。** 数を目的にして薄い追記を積むのは逆効果なので、無理に埋めない。埋まらない理由が記録に残っていれば、それが次の改善の材料になる。
9. **ソースノート側へのリンク追加**: ソース note 本文に該当語が出現していて wikilink になっていない場合、CLAUDE.md のリンク戦略に従って初出のみ `[[語]]` を付ける。
10. **log.md への記録**: `wiki/log.md` の先頭セクション直下に新エントリを追加（append-only。古いエントリは削除しない）:

   ```markdown
   ## YYYY-MM-DD HH:MM ingest

   - sources: [[daily/2026-05-19]], [[activities/2026-05-19]], [[projects/tempest/2026-05-19 ...]] (+ bookmarks: 2 件)
   - updated: [[RubyKaigi 2025]], [[asonas/strudel-rb]], [[Strudel]]
   - created: [[Live Coding]]（今回のソース由来）, [[TDD]], [[Datadog]]（deferred 回収）
   - deferred: +[[新たに見送った語]] / -[[回収してページ化した語]] / 残 42 件
   - mentions: 既存ページへの言及 12 件中 5 件を増補（残りは言及のみで新事実なし）
   - note: <特筆事項。矛盾検出・統合した主張など>
   ```

   日付指定の ingest で実際に読んだソース一覧をすべて記載すること。activities や projects/notes/bookmarks のいずれかが空（該当日に更新ファイルなし）でも、空であることを `(なし)` の形で残しておくと運用上のトレースが楽になる。

   `deferred:` 行は log では**増減の記録**に徹する。状態の正本は `wiki/deferred.md` であり、log を遡って未回収の語を数えてはならない。残件数を毎回書いておくと、滞留が増えているのか減っているのかが log を読むだけで分かる。
11. **index 再生成**: ingest の最後に必ず `rebuild-index` の手順を実行して `wiki/index.md` を最新化する。ページの作成・更新が 1 件もなかった場合のみ省略してよい。

### lint

呼び出し:

```
/wiki-update lint
```

#### 手順

lint は「検出して終わり」にせず、機械的に直せる問題はその場で修復する。判断が必要な問題のみ報告に留める。

1. `wiki/` 配下の全 .md を列挙（`index.md`, `log.md`, `log-*.md`, `deferred.md` は除外）。
2. 各ページについて以下をチェック:
   - **孤立ページ**: vault 内のどのノートからも `[[name]]` で参照されていない
   - **未解決リンク**: 本文中の `[[X]]` で `X.md` が vault 内に存在しない
   - **古い `updated`**: 90 日以上更新されていない
   - **矛盾**: 同一トピックに対して相反する記述が含まれる
   - **frontmatter 欠落**: `type`、`sources`、`updated` のいずれかが未定義または空
   - **過剰分割**: 単一の同じソースのみを出典とし、本文が 2 段落以下で、被リンクが wiki 内の相互リンクと index に限られるページ群。統合候補として報告する
3. **自動修復（その場で直すもの）**:
   - `type` 欠落 → 本文から判断して補完する
   - `updated` 欠落 → ファイルの mtime の日付で補完する
   - `sources` が空 → vault を grep してそのページ名に言及している daily / notes / projects を探し、見つかれば `sources` に追記する。見つからなければ報告に残す
   - **`sources` が空でないページは中身も検証する**。`ruby ~/.claude/skills/wiki-update/health/verify-sources.rb --quiet` を実行し、出典に挙げたファイルがそのページの主題に触れているかを確認する。`sources` が埋まっていることと、その出典が正しいことは別の話であり、`wiki-health.rb` は前者しか見ていない
   - 検出された出典は「誤り確定」ではなく「要確認」。表記が違うだけの正当なケース（`Datadog` に対する `datadoghq` など）は aliases に追記すれば解消する。本当に主題に触れていない出典は差し替えるか、その記述ごと削除する
   - 修復したページは lint エントリの `fixed:` 行に列挙する
4. **deferred 台帳の棚卸し**: `wiki/deferred.md` を読み、各語の sources 数を数え直す。

   - 「様子見」で sources が 2 以上になった語 → 「ページ化待ち」へ移す
   - 「ページ化待ち」で sources が 0 になった語（ソース側の記述が消えた・表記が変わった） → 「見送り」へ移し、理由を書く
   - **同じ語が 3 回以上の lint をまたいで「ページ化待ち」に残っている** → その場でページを作るか「見送り」へ落とすかを決める。残置は選べない
   - 棚卸しの結果は lint エントリの `deferred:` 行に残件数の推移として記録する
5. **報告のみ（判断が必要なもの）**: 孤立ページ・矛盾・統合候補・出典が見つからないページ。検出結果を `wiki/log.md` の先頭に新エントリとして追加:

   ```markdown
   ## YYYY-MM-DD HH:MM lint

   - fixed: [[V]] (type 補完), [[U]] (sources 補完)
   - orphan: [[X]], [[Y]]
   - unresolved: [[X]] が [[Y]] を参照しているが Y は存在しない
   - stale: [[Z]] (last updated 2026-01-15)
   - contradiction: [[W]] 内で〜と〜が矛盾
   - merge-candidate: [[A]] + [[B]] → [[C]] に統合可能（同一ソース・相互リンクのみ）
   - deferred: ページ化待ち 45 → 42、様子見 36 → 34、見送りへ 3 件
   ```

6. **健康診断の記録**: `ruby ~/.claude/skills/wiki-update/health/wiki-health.rb` を実行し、結果を lint エントリの `health:` 行に 1 行で残す。

   ```
   - health: 169ページ 1ingestあたり3.47 stale(0-7d)=4 deferred待ち=45 過剰分割=26
   ```

   ベースラインは `health/baseline-2026-07-26.json`。**1 ingest あたりの page touch と deferred の残件数が改善しているかを毎回見る。** 悪化しているなら、その週の ingest で何が起きていたかを log から確認して note に書く。
7. 何も検出されなければ「clean」と 1 行だけ記録する。
8. 前回の lint エントリに残っている報告項目が今回も未解決のままなら、エントリの note に「前回からの持ち越し」と明記する。同じ項目を 2 回持ち越したら、その場で対処するかページを削除するかを決める。

### rebuild-index

呼び出し:

```
/wiki-update rebuild-index
```

#### 手順

1. `wiki/` 配下の全 .md を frontmatter の `type` ごとに分類する。`index.md`, `log.md`, `log-*.md`, `deferred.md` は除外。
2. `wiki/index.md` を上書き再生成する。type の順は `entity → concept → event → org → comparison → summary → orphan`。各 type の下に該当ページを `- [[name]] — frontmatter から拾った 1 行 description（先頭段落の 1 文目を要約）` 形式で並べる。
3. 孤立ページ（lint で検出されたもの）は `## orphan` セクションに集める。

## log.md のローテーション

log.md は append-only のまま無限に肥大化するため、月単位でローテーションする。

- ingest / lint / rebuild-index のいずれかを月初に最初に実行したとき、log.md に前月以前のエントリが残っていたら、それらを `wiki/log-YYYY-MM.md`（エントリの属する月ごと）へ移動する。log.md には冒頭の説明文と当月分のエントリだけを残す
- `log-*.md` は lint・rebuild-index の走査対象から除外する（frontmatter 不要）
- 移動はエントリ単位で行い、内容の書き換えはしない
- `deferred.md` はローテーションしない。状態ファイルであって履歴ではないので、消化した行は削除して常に「今の未回収分」だけを保つ

## 起動経路

- **手動**: `/wiki-update ingest today` 等を直接実行。
- **`/today` から**: その日の daily note 作成・前日まとめが終わった直後に `/wiki-update ingest yesterday` を呼ぶ。
- **`/wrapup` から**: 当日 wrapup の追記が終わった直後に `/wiki-update ingest today` を呼ぶ。
- **週次 lint**: 金曜の `/wrapup` 経由の ingest が終わったあと、続けて `lint` を実行する。直近 7 日以内に lint 実行記録が log.md にある場合はスキップしてよい。

today / wrapup から呼ばれた際は、対話を増やさず黙々と ingest を完了させること（ユーザは別の作業に移っている前提）。

## 注意

- `wiki/` 配下の編集はすべて Read + Edit / Write で `/Users/asonas/Obsidian/asonas/wiki/<file>.md` を直接編集する。Obsidian 公式 CLI は heading 指定の insert をサポートしないため、本文への精密な追記は filesystem 直接編集の方が確実。
- daily / notes 等の **ソース側ノートには新しい事実を書き足さない**。wiki はソースを要約・統合する派生レイヤであり、源泉ではない。例外はソース側で漏れていた wikilink の付与のみ。
- LLM の創作を避けるため、ソースに書かれていない事実を wiki に追加しない。各記述は必ず `sources` の wikilink で裏付けられること。
