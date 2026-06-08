#!/usr/bin/env ruby
# frozen_string_literal: true

require "minitest/autorun"
require_relative "books-highlights"

class TestBooksHighlights < Minitest::Test
  def test_chapter_id_from_cfi_extracts_first_bracket
    cfi = "epubcfi(/6/20[ch03_Projects-xhtml]!/4/54/1,:0,:93)"
    assert_equal "ch03_Projects-xhtml", BooksHighlights.chapter_id_from_cfi(cfi)
  end

  def test_chapter_id_from_cfi_returns_nil_when_no_bracket
    assert_nil BooksHighlights.chapter_id_from_cfi("epubcfi(/6/20!/4/54)")
  end

  def test_chapter_id_from_cfi_returns_nil_for_blank
    assert_nil BooksHighlights.chapter_id_from_cfi(nil)
    assert_nil BooksHighlights.chapter_id_from_cfi("")
  end

  OPF = <<~XML
    <?xml version="1.0" encoding="UTF-8"?>
    <package xmlns="http://www.idpf.org/2007/opf" version="3.0">
      <manifest>
        <item id="ch03_Projects-xhtml" href="ch03_Projects.xhtml" media-type="application/xhtml+xml"/>
        <item id="ch04_Automate-xhtml" href="ch04_Automate.xhtml" media-type="application/xhtml+xml"/>
        <item id="orphan-xhtml" href="orphan.xhtml" media-type="application/xhtml+xml"/>
      </manifest>
      <spine>
        <itemref idref="ch03_Projects-xhtml"/>
        <itemref idref="ch04_Automate-xhtml"/>
        <itemref idref="orphan-xhtml"/>
      </spine>
    </package>
  XML

  TOC = <<~XML
    <?xml version="1.0" encoding="UTF-8"?>
    <html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">
      <body>
        <nav epub:type="toc">
          <ol>
            <li><a href="ch03_Projects.xhtml">　3章　プロジェクトをシンプルにする</a></li>
            <li><a href="ch03_Projects.xhtml#practice_4">　　プラクティス4</a></li>
            <li><a href="ch04_Automate.xhtml">　4章　自動化する</a></li>
          </ol>
        </nav>
      </body>
    </html>
  XML

  def test_build_chapter_map_maps_item_id_to_toc_title
    map = BooksHighlights.build_chapter_map(OPF, TOC)
    assert_equal "3章　プロジェクトをシンプルにする", map["ch03_Projects-xhtml"]
    assert_equal "4章　自動化する", map["ch04_Automate-xhtml"]
  end

  def test_build_chapter_map_falls_back_to_href_when_not_in_toc
    map = BooksHighlights.build_chapter_map(OPF, TOC)
    assert_equal "orphan.xhtml", map["orphan-xhtml"]
  end

  def test_spine_order_returns_item_ids_in_spine_sequence
    assert_equal %w[ch03_Projects-xhtml ch04_Automate-xhtml orphan-xhtml],
                 BooksHighlights.spine_order(OPF)
  end

  def test_core_data_date_applies_reference_offset
    # Core Data 基準時刻 0 = 2001-01-01T00:00:00Z（JST/UTC いずれでも日付は 2001-01-01）
    assert_equal "2001-01-01", BooksHighlights.core_data_date(0)
  end

  def test_group_and_sort_orders_by_spine_then_physical_location
    chapter_map = { "ch03_Projects-xhtml" => "3章 P", "ch04_Automate-xhtml" => "4章 A" }
    order = %w[ch03_Projects-xhtml ch04_Automate-xhtml]
    highlights = [
      { text: "a", cfi: "epubcfi(/6[ch04_Automate-xhtml]!)", phys: 50, note: "", created: "2026-06-05" },
      { text: "b", cfi: "epubcfi(/6[ch03_Projects-xhtml]!)", phys: 200, note: "", created: "2026-06-02" },
      { text: "c", cfi: "epubcfi(/6[ch03_Projects-xhtml]!)", phys: 100, note: "", created: "2026-06-02" },
      { text: "d", cfi: "epubcfi(/6!)", phys: 10, note: "", created: "2026-06-01" }
    ]
    grouped = BooksHighlights.group_and_sort(highlights, chapter_map, order)
    assert_equal ["3章 P", "4章 A", "（章不明）"], grouped.map { |g| g[:title] }
    assert_equal %w[c b], grouped[0][:highlights].map { |h| h[:text] }
    assert_equal %w[d], grouped[2][:highlights].map { |h| h[:text] }
  end

  def test_build_frontmatter_includes_required_keys
    meta = { title: "シンプリシティ", author: "Dave Thomas", highlight_count: 28,
             asset_id: "ABC", format: "epub", last_synced: "2026-06-08T11:30:00Z" }
    fm = BooksHighlights.build_frontmatter(meta)
    assert fm.start_with?("---\n")
    assert fm.end_with?("---\n")
    assert_includes fm, "type: book-highlights"
    assert_includes fm, "title: シンプリシティ"
    assert_includes fm, "highlight_count: 28"
  end

  def test_render_markdown_builds_body_with_chapters_and_quotes
    meta = { title: "シンプリシティ", author: "Dave Thomas", translator: "島田 浩二",
             publisher: "オライリー", related: "シンプリシティ" }
    grouped = [{ title: "3章 P", highlights: [
      { text: "本文A", note: "", created: "2026-06-02" },
      { text: "本文B", note: "メモX", created: "2026-06-05" }
    ] }]
    md = BooksHighlights.render_markdown(meta, grouped)
    assert_includes md, "# シンプリシティ"
    assert_includes md, "[[Dave Thomas]]（訳: 島田 浩二） / オライリー。関連: [[シンプリシティ]]"
    assert_includes md, "## 3章 P"
    assert_includes md, "> 本文A（2026-06-02）"
    assert_includes md, "> 本文B（2026-06-05）"
    assert_includes md, "メモ: メモX"
    assert_equal 1, md.scan("メモ:").size # 空メモはメモ行を出さない
  end
end
