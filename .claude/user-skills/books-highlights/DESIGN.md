# books-highlights 設計

Apple Books.app のハイライト（とメモ）を、epub 原本のメタデータ・章構成と突き合わせて Obsidian asonas vault の `books/` に取り込むスキル。raindrop-sync と同型の「依存ゼロ Ruby スクリプト + SKILL.md」構成。今回のスコープは書籍「シンプリシティ」1冊。

## データソース（調査済みの実データ）

- ハイライト本体: `~/Library/Containers/com.apple.iBooksX/Data/Documents/AEAnnotation/AEAnnotation_*.sqlite`
  - `ZAEANNOTATION`: `ZANNOTATIONSELECTEDTEXT`(本文) / `ZANNOTATIONNOTE`(メモ) / `ZANNOTATIONASSETID`(書籍ID) / `ZANNOTATIONSTYLE`(色) / `ZANNOTATIONCREATIONDATE`(Core Data時刻=+978307200でunix) / `ZANNOTATIONLOCATION`(epubcfi) / `ZPLABSOLUTEPHYSICALLOCATION`(並び順) / `ZANNOTATIONDELETED`(削除フラグ)
- 書誌: `~/Library/Containers/com.apple.iBooksX/Data/Documents/BKLibrary/BKLibrary-*.sqlite`
  - `ZBKLIBRARYASSET`: `ZTITLE` / `ZAUTHOR` / `ZGENRE` / `ZYEAR` / `ZASSETID` / `ZPATH`(原本パス)
- 原本: `ZPATH` の epub（シンプリシティは**展開済みディレクトリ形式**: `META-INF/container.xml` → OPF → manifest/spine + 目次 xhtml）。zip 形式なら `unzip` フォールバック。

epubcfi の先頭ブラケット（例 `epubcfi(/6/20[ch03_Projects-xhtml]!...)`）の `ch03_Projects-xhtml` は OPF manifest の item id。manifest で `href=ch03_Projects.xhtml` に解決し、目次 xhtml の `<a href="ch03_Projects.xhtml">3章 …</a>` から章タイトルを得る。

## 依存

追加 gem なし。`/usr/bin/sqlite3` にシェルアウト、epub はディレクトリ読み（zip は `unzip` フォールバック）、XML は stdlib REXML。Ruby 4.x で動作。

## CLI

```
books-highlights.rb --book "シンプリシティ"   # title 部分一致でフィルタ
books-highlights.rb --book "シンプリシティ" --dry-run
```

`--all`（全書籍）は将来拡張の口だけ用意。`--out-dir`（既定 `~/Documents/asonas/books`）。

## データフロー

1. 2つの SQLite を mktemp ディレクトリへ `cp`（`-wal`/`-shm` も）。Books をロックせず WAL を取り込む。`rm -rf` は使わない。
2. BKLibrary から `--book` 一致の書籍を取得（ASSETID / ZPATH / 書誌）。
3. AEAnnotation から該当 ASSETID のハイライトを取得。`ZANNOTATIONDELETED=1` を除外、`ZANNOTATIONSELECTEDTEXT IS NOT NULL`。
4. ZPATH が epub なら container.xml→OPF を読み、メタデータ・manifest(id→href)・目次(href→章タイトル) を構築。
5. 各ハイライトの epubcfi 先頭ブラケット→章id→章タイトルへ写像。章は spine 順、章内は `ZPLABSOLUTEPHYSICALLOCATION` 昇順。
6. `books/<title>.md` を生成（毎回上書き＝冪等）。

## 出力書式

```markdown
---
type: book-highlights
title: シンプリシティ
author: Dave Thomas
translator: 島田 浩二
publisher: 株式会社オライリー・ジャパン
isbn: 9784814401710
language: ja
published: 2026-05-29
asset_id: C67D230E52B1DF94A59C49A2FCA13B77
source: ~/Library/Mobile Documents/iCloud~com~apple~iBooks/Documents/シンプリシティ.epub
format: epub
highlight_count: 28
last_synced: 2026-06-08T11:30:00Z
---

# シンプリシティ

[[Dave Thomas]]（訳: 島田 浩二） / 株式会社オライリー・ジャパン。関連: [[シンプリシティ]]

Apple Books から取り込んだハイライトです。

## 3章 プロジェクトをシンプルにする

> あまりにも多くのチームが場当たり的になっている。…（2026-06-02）

> 結合したコードをうまく扱うのは…（2026-06-02）
```

- ハイライトは逐語引用なので blockquote のまま。メモがあれば引用直後に `メモ: …` を併記。
- 色(style)は v1 では省略。
- リンク: `[[Dave Thomas]]`（著者スタブ）と既存 wiki ページ `[[シンプリシティ]]`。

## エラー処理

- ZPATH が pdf / 実体なし → DB 書誌のみで生成、章は「（章情報なし）」単一グループ。
- 目次が無い → manifest href を章ラベルに代用。
- epubcfi にブラケットが無い → 「（章不明）」グループ。
- 対象書籍が見つからない / ハイライト0件 → メッセージを出して終了（ファイルは作らない）。

## テスト（TDD, pure 関数中心）

IO（sqlite/epub読み）は端に寄せ、以下の純粋関数を fixture でユニットテスト:

1. `chapter_id_from_cfi(cfi)` → epubcfi 先頭ブラケットの id 抽出（ブラケット無しは nil）
2. `build_chapter_map(opf_xml, toc_xml)` → {item_id => 章タイトル}
3. `group_and_sort(highlights, chapter_map, spine_order)` → 章順・章内位置順に整列したグループ
4. `render_markdown(book_meta, grouped)` → 期待 Markdown 文字列
5. `build_frontmatter(book_meta)` → 期待 YAML

実 DB/epub はモックせず、OPF/目次/CFI の小さなサンプル断片で検証する。

## 補足

`books/` は obsidian-vault ルールに未登録の新 Raw Sources 層。ルール文書への `books/` 追記は別途反映する。将来 `/wiki-update ingest` のソースに組み込める。
