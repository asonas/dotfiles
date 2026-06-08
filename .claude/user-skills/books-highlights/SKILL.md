---
name: books-highlights
description: Apple Books.app のハイライト・メモを epub 原本のメタデータ・章構成と突き合わせ、Obsidian asonas vault の books/ に1書籍1ファイルで取り込む。Use when invoked as /books-highlights, or when asked to import Apple Books highlights into Obsidian.
---

# /books-highlights - Apple Books Highlights -> Obsidian

macOS の Books.app に付けたハイライトとメモを、ローカル SQLite から読み出し、epub 原本（OPF / 目次）のメタデータと章構成に紐づけて `~/Documents/asonas/books/` に Markdown として書き出すスキルです。raindrop-sync と同じ「依存ゼロ Ruby スクリプト」構成で、`bookmarks/` と並ぶ Raw Sources 層を構成します。

## 前提

- macOS の Books.app を使っていること。ハイライトは以下の SQLite に保存される:
  - `~/Library/Containers/com.apple.iBooksX/Data/Documents/AEAnnotation/AEAnnotation_*.sqlite`（ハイライト本体）
  - `~/Library/Containers/com.apple.iBooksX/Data/Documents/BKLibrary/BKLibrary-*.sqlite`（書誌）
- `/usr/bin/sqlite3` が使えること（macOS 標準）
- 原本が epub（展開ディレクトリ形式 or zip）なら章マッピングとメタデータ補完が効く。pdf や原本欠落時は DB の書誌のみで生成
- Ruby 4.x（stdlib のみ。追加 gem 不要。zip 形式 epub のときだけ `unzip` を使う）

## 起動方法

```bash
/Users/asonas/ghq/github.com/asonas/dotfiles/.claude/user-skills/books-highlights/books-highlights.rb --book "シンプリシティ"
```

### オプション

```
--book TITLE     # タイトル部分一致で対象書籍を絞る
--all            # 全書籍を対象にする
--out-dir DIR    # 出力先（既定 ~/Documents/asonas/books）
--dry-run        # 書き込まず内容を表示
```

## 動作

1. AEAnnotation / BKLibrary の SQLite を mktemp にコピー（Books をロックせず WAL を取り込む）
2. BKLibrary から対象書籍（ASSETID / タイトル / 著者 / 原本パス）を取得
3. AEAnnotation から該当書籍のハイライトを取得（削除フラグ除外）
4. 原本 epub の `META-INF/container.xml` → OPF を読み、メタデータ（書名・著者・訳者・出版社・ISBN・言語・刊行日）と manifest / 目次を構築
5. 各ハイライトの epubcfi 先頭ブラケット（例 `[ch03_Projects-xhtml]`）→ OPF manifest の href → 目次の章タイトルへ写像。章は spine 順、章内は物理位置順に整列
6. `books/<title>（ハイライト）.md` を生成（毎回上書き＝冪等）

## 出力書式

frontmatter（type: book-highlights / 書誌 / highlight_count / last_synced）+ 本文。本文は著者・訳者・出版社の byline、関連 wiki ページへのリンク、章見出しごとにハイライトを blockquote で並べる。メモがあれば引用直後に併記する。

ファイル名は `<title>（ハイライト）.md`。これは vault に同名の wiki 概念ページ（例 `wiki/シンプリシティ.md`）が存在しても `[[bare-name]]` の解決が衝突しないようにするための命名。本文からは関連する wiki 概念ページ `[[<title>]]` へリンクする。

## スコープと注意

- 上書き方式なので手編集は次回実行で失われる（raindrop-sync と同じ前提）
- `books/` は Raw Sources 層。将来 `/wiki-update ingest` のソースに組み込める
- 章タイトルが取れないハイライトは「（章不明）」グループに集約される

## テスト

純粋関数（CFI 解析・章マッピング・整列・frontmatter / Markdown レンダリング）は `test_books_highlights.rb` でユニットテスト済み。`ruby test_books_highlights.rb` で実行。
