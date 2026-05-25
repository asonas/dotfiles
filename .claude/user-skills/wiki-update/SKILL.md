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

- vault: `asonas`（path: `/Users/asonas/Documents/asonas/`）。`obsidian` CLI を使う場合は必ず `vault=asonas` を明示します。
- wiki ディレクトリ: `/Users/asonas/Documents/asonas/wiki/`
- wiki 配下は **フラット構造**。サブディレクトリを切らない。分類は frontmatter の `type` で行い、カタログ化は `wiki/index.md` が担います。
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

- `today` / `yesterday` / `YYYY-MM-DD`: 下記5種をまとめて同じ ingest セッションのソースとして読み込む
  1. `daily/<YYYY-MM-DD>.md`（手書きの日報）
  2. `activities/<YYYY-MM-DD>.md`（machine-generated。カレンダー予定、GitHub、ブラウザ履歴、Claude Code、Bluesky 投稿などが集約されている。daily note からは transclude されているが Read ツールは transclude を展開しないため、明示的に読む必要がある）
  3. 当日 `mtime` の `projects/**/*.md`（その日に手で更新したプロジェクトノート。`find /Users/asonas/Documents/asonas/projects -name '*.md' -newermt <YYYY-MM-DD> -not -newermt <翌日>` で検出）
  4. 当日 `mtime` の `notes/**/*.md`（同上。単発の調査ノートも拾う）
  5. その日に `bookmarks/.last_sync` 経由で取り込まれた新着 bookmarks（`bookmarks/*.md` のうち frontmatter `last_synced` が当該日付の md）
- vault 相対パス（例: `notes/foo.md`, `projects/tempest/foo.md`, `bookmarks/123456.md`, `activities/2026-05-20.md`）: そのまま読む。bookmark や個別ファイルを直接渡すと単一ファイル ingest になる
- 引数省略時: today にフォールバック

`activities/<YYYY-MM-DD>.md` を読む際の注意:

- セクション区切りは `<!-- BEGIN: <source> -->` 〜 `<!-- END: <source> -->` の HTML コメントで囲まれている。各セクションの中身（特に `## Bluesky` の投稿本文と `## GitHub` の PR タイトル）は固有名詞・概念の宝庫
- 「`_イベントなし_`」とだけ書かれているセクションはスキップしてよい
- カレンダーセクション（`## カレンダー`）の予定タイトルは個人の打ち合わせ名や子の送迎などプライベートが多いので、wiki 化候補からは除外する（参照のみに留める）

#### 手順

1. **ソース読み込み**: 指定された note を Read で全文取得する。
2. **エンティティ抽出**: 本文を読み、wiki ページ化すべき語を列挙する。基準は CLAUDE.md の `## リンク戦略` の Step 2 と同じ:
   - プロジェクト名・リポジトリ名
   - 技術用語（ツール名・プロトコル名・フレームワーク名）
   - 人名
   - 自分が繰り返し参照する概念
   - 一般名詞・1 回限りの固有名詞はリンクにしない
3. **既存ページ照合**: 各エンティティについて `/Users/asonas/Documents/asonas/wiki/<名前>.md` の存否を確認する。
4. **更新 or 新規作成**:
   - **既存ページがある場合**: 本文に新しい事実を統合する。重複は避け、既存記述と矛盾する場合は両論併記したうえで「2026-05-20 時点では後者が正しい」のように日付付きで判断を残す。frontmatter の `sources` と `updated` を更新する。
   - **新規作成の場合**: 上記の frontmatter + 散文本文で作成する。本文は最低 1 段落、根拠 wikilink 必須。
5. **横断更新**: karpathy 流に「1 回の ingest で 10〜15 ページを更新する」想定で、抽出した全エンティティを一度のセッションで処理する。1 ページずつユーザに確認しない。
6. **ソースノート側へのリンク追加**: ソース note 本文に該当語が出現していて wikilink になっていない場合、CLAUDE.md のリンク戦略に従って初出のみ `[[語]]` を付ける。
7. **log.md への記録**: `wiki/log.md` の先頭セクション直下に新エントリを追加（append-only。古いエントリは削除しない）:

   ```markdown
   ## YYYY-MM-DD HH:MM ingest

   - sources: [[daily/2026-05-19]], [[activities/2026-05-19]], [[projects/tempest/2026-05-19 ...]] (+ bookmarks: 2 件)
   - updated: [[RubyKaigi 2025]], [[asonas/strudel-rb]], [[Strudel]]
   - created: [[Live Coding]]
   - note: <特筆事項。矛盾検出・統合した主張など>
   ```

   日付指定の ingest で実際に読んだソース一覧をすべて記載すること。activities や projects/notes/bookmarks のいずれかが空（該当日に更新ファイルなし）でも、空であることを `(なし)` の形で残しておくと運用上のトレースが楽になる。

### lint

呼び出し:

```
/wiki-update lint
```

#### 手順

1. `wiki/` 配下の全 .md を列挙（`index.md`, `log.md` は除外）。
2. 各ページについて以下をチェック:
   - **孤立ページ**: vault 内のどのノートからも `[[name]]` で参照されていない
   - **未解決リンク**: 本文中の `[[X]]` で `X.md` が vault 内に存在しない
   - **古い `updated`**: 90 日以上更新されていない
   - **矛盾**: 同一トピックに対して相反する記述が含まれる
   - **frontmatter 欠落**: `type` または `sources` が未定義
3. 検出結果を `wiki/log.md` の先頭に新エントリとして追加:

   ```markdown
   ## YYYY-MM-DD HH:MM lint

   - orphan: [[X]], [[Y]]
   - unresolved: [[X]] が [[Y]] を参照しているが Y は存在しない
   - stale: [[Z]] (last updated 2026-01-15)
   - contradiction: [[W]] 内で〜と〜が矛盾
   - missing frontmatter: [[V]]
   ```

4. 何も検出されなければ「clean」と 1 行だけ記録する。

### rebuild-index

呼び出し:

```
/wiki-update rebuild-index
```

#### 手順

1. `wiki/` 配下の全 .md を frontmatter の `type` ごとに分類する。`index.md`, `log.md` は除外。
2. `wiki/index.md` を上書き再生成する。type の順は `entity → concept → event → org → comparison → summary → orphan`。各 type の下に該当ページを `- [[name]] — frontmatter から拾った 1 行 description（先頭段落の 1 文目を要約）` 形式で並べる。
3. 孤立ページ（lint で検出されたもの）は `## orphan` セクションに集める。

## 起動経路

- **手動**: `/wiki-update ingest today` 等を直接実行。
- **`/today` から**: その日の daily note 作成・前日まとめが終わった直後に `/wiki-update ingest yesterday` を呼ぶ。
- **`/wrapup` から**: 当日 wrapup の追記が終わった直後に `/wiki-update ingest today` を呼ぶ。

today / wrapup から呼ばれた際は、対話を増やさず黙々と ingest を完了させること（ユーザは別の作業に移っている前提）。

## 注意

- `wiki/` 配下の編集はすべて Read + Edit / Write で `/Users/asonas/Documents/asonas/wiki/<file>.md` を直接編集する。Obsidian 公式 CLI は heading 指定の insert をサポートしないため、本文への精密な追記は filesystem 直接編集の方が確実。
- daily / notes 等の **ソース側ノートには新しい事実を書き足さない**。wiki はソースを要約・統合する派生レイヤであり、源泉ではない。例外はソース側で漏れていた wikilink の付与のみ。
- LLM の創作を避けるため、ソースに書かれていない事実を wiki に追加しない。各記述は必ず `sources` の wikilink で裏付けられること。
