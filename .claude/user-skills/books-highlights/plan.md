# plan.md — books-highlights TDD test list

純粋関数を Red-Green-Refactor で1つずつ。IO（sqlite/epub読み）は端に寄せ、テスト対象から外す。

## Test List

- [x] `chapter_id_from_cfi`: 先頭ブラケットの item id を返す（`epubcfi(/6/20[ch03_Projects-xhtml]!/4/54)` → `"ch03_Projects-xhtml"`）
- [x] `chapter_id_from_cfi`: ブラケットが無い CFI は nil
- [x] `chapter_id_from_cfi`: nil/空文字は nil
- [x] `build_chapter_map`: OPF manifest と目次 xhtml から `{item_id => 章タイトル}` を作る
- [x] `build_chapter_map`: 目次に無い item は manifest の href を章ラベルに代用
- [x] `spine_order`: OPF spine の itemref 順で item_id 配列を返す
- [x] `group_and_sort`: ハイライトを章id→章順、章内は物理位置昇順にグループ化
- [x] `group_and_sort`: 章id が nil のハイライトは「（章不明）」グループへ
- [x] `build_frontmatter`: 書誌から YAML frontmatter 文字列（必須キーを含む）
- [x] `render_markdown`: grouped + 書誌 → 期待 Markdown（章見出し + blockquote、メモ併記、関連リンク）
- [x] `render_markdown`: メモが空のハイライトは「メモ:」行を出さない
- [x] `core_data_date`: Core Data 秒(+978307200)を `YYYY-MM-DD` に変換

## 実装メモ

- 純粋関数は `module BooksHighlights` に置き、`if __FILE__ == $0` で main を分離してテストから require 可能にする
- テストは minitest（default gem）。`ruby test_books_highlights.rb` で実行
