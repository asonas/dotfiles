#!/usr/bin/env ruby
# frozen_string_literal: true

# books-highlights: Apple Books のハイライトを Obsidian vault の books/ に取り込む。
# 純粋関数は BooksHighlights モジュールに置き、main とは __FILE__ == $0 で分離する。

module BooksHighlights
  module_function

  # 先頭・末尾の空白（ASCII および全角スペース U+3000）を除去する。内部の空白は保持。
  def strip_spaces(str)
    str.gsub(/\A[\s　]+|[\s　]+\z/, "")
  end

  # epubcfi の先頭ブラケット内の item id を返す。
  # 例: "epubcfi(/6/20[ch03_Projects-xhtml]!/4/54)" -> "ch03_Projects-xhtml"
  # ブラケットが無い / nil / 空文字 は nil。
  def chapter_id_from_cfi(cfi)
    return nil if cfi.nil? || cfi.empty?

    m = cfi.match(/\[([^\]]+)\]/)
    m && m[1]
  end

  # OPF manifest と 目次 xhtml から {item_id => 章タイトル} を作る。
  # 目次に無い item は manifest の href を章ラベルに代用する。
  def build_chapter_map(opf_xml, toc_xml)
    require "rexml/document"

    manifest = manifest_items(opf_xml) # id => href

    # 目次: href(アンカー除く) => 最初に現れたタイトル
    href_title = {}
    toc = REXML::Document.new(toc_xml)
    REXML::XPath.each(toc, "//a") do |a|
      href = a.attribute("href")&.value
      next unless href

      file = href.split("#").first
      title = strip_spaces(a.text.to_s)
      next if title.empty?

      href_title[file] ||= title
    end

    manifest.each_with_object({}) do |(id, href), map|
      map[id] = href_title[href] || href
    end
  end

  # OPF spine の itemref 順で item_id 配列を返す。
  def spine_order(opf_xml)
    require "rexml/document"

    doc = REXML::Document.new(opf_xml)
    REXML::XPath.match(doc, "//itemref").map { |ir| ir.attribute("idref")&.value }.compact
  end

  # OPF manifest を {item_id => href} で返す（内部ヘルパ）。
  def manifest_items(opf_xml)
    require "rexml/document"

    doc = REXML::Document.new(opf_xml)
    REXML::XPath.match(doc, "//item").each_with_object({}) do |item, h|
      id = item.attribute("id")&.value
      href = item.attribute("href")&.value
      h[id] = href if id && href
    end
  end

  CORE_DATA_EPOCH_OFFSET = 978_307_200 # 2001-01-01T00:00:00Z の unix 秒

  # Core Data 基準秒（2001-01-01 起点）を localtime の "YYYY-MM-DD" に変換する。
  def core_data_date(seconds)
    Time.at(seconds.to_i + CORE_DATA_EPOCH_OFFSET).getlocal.strftime("%Y-%m-%d")
  end

  UNKNOWN_CHAPTER = "（章不明）"

  # ハイライト配列を章順（spine 順）・章内は物理位置昇順に整列したグループ配列にする。
  # 返り値: [{ title: 章タイトル, highlights: [...] }, ...]。
  # 章 id が取れない / chapter_map に無いハイライトは末尾の「（章不明）」グループへ。
  def group_and_sort(highlights, chapter_map, spine_order)
    order_index = spine_order.each_with_index.to_h

    buckets = Hash.new { |h, k| h[k] = [] }
    highlights.each do |hl|
      cid = chapter_id_from_cfi(hl[:cfi])
      key = (cid && chapter_map.key?(cid)) ? cid : nil
      buckets[key] << hl
    end

    known = buckets.keys.compact.sort_by { |cid| order_index.fetch(cid, Float::INFINITY) }
    ordered_keys = known + (buckets.key?(nil) ? [nil] : [])

    ordered_keys.map do |key|
      title = key ? chapter_map[key] : UNKNOWN_CHAPTER
      sorted = buckets[key].sort_by { |hl| hl[:phys].to_i }
      { title: title, highlights: sorted }
    end
  end

  REQUIRED_FRONTMATTER_KEYS = %i[
    title author translator publisher isbn language published
    asset_id source format highlight_count last_synced
  ].freeze

  # 書誌 meta から YAML frontmatter 文字列を組み立てる。値が空のキーは出力しない。
  def build_frontmatter(meta)
    lines = ["---", "type: book-highlights"]
    REQUIRED_FRONTMATTER_KEYS.each do |key|
      val = meta[key]
      next if val.nil? || (val.respond_to?(:empty?) && val.empty?)

      lines << "#{key}: #{yaml_value(val)}"
    end
    lines << "---"
    "#{lines.join("\n")}\n"
  end

  # YAML スカラ値を安全に表現する。特殊文字を含む文字列のみダブルクォートする。
  def yaml_value(val)
    return val.to_s if val.is_a?(Integer)

    s = val.to_s
    if s.match?(/[:#\[\]{}&*!|>'"%@`]/) || s.start_with?(" ") || s.end_with?(" ")
      %("#{s.gsub('\\', '\\\\\\\\').gsub('"', '\\"')}")
    else
      s
    end
  end

  # グループ配列と書誌から Markdown 本文（frontmatter は含まない）を組み立てる。
  def render_markdown(meta, grouped)
    out = []
    out << "# #{meta[:title]}"
    out << ""
    out << byline(meta)
    out << ""
    out << "Apple Books から取り込んだハイライトです。"
    out << ""
    grouped.each do |group|
      out << "## #{group[:title]}"
      out << ""
      group[:highlights].each do |hl|
        date = hl[:created].to_s.empty? ? "" : "（#{hl[:created]}）"
        out << "> #{hl[:text]}#{date}"
        note = hl[:note].to_s
        out << "メモ: #{note}" unless note.empty?
        out << ""
      end
    end
    "#{out.join("\n").rstrip}\n"
  end

  # 著者・訳者・出版社・関連リンクを1行にまとめる（存在する要素のみ）。
  def byline(meta)
    parts = +""
    parts << "[[#{meta[:author]}]]" if meta[:author]
    parts << "（訳: #{meta[:translator]}）" if meta[:translator] && !meta[:translator].to_s.empty?
    parts << " / #{meta[:publisher]}" if meta[:publisher] && !meta[:publisher].to_s.empty?
    parts << "。関連: [[#{meta[:related]}]]" if meta[:related] && !meta[:related].to_s.empty?
    parts
  end
end

# ---- IO 層（端に寄せる。純粋関数は上の module でユニットテスト済み）----

module BooksHighlights
  module_function

  IBOOKS_ROOT = File.expand_path("~/Library/Containers/com.apple.iBooksX/Data/Documents")
  DEFAULT_OUT_DIR = File.expand_path("~/Documents/asonas/books")
  WIKI_DIR = File.expand_path("~/Documents/asonas/wiki")

  def locate_db(subdir, glob)
    Dir.glob(File.join(IBOOKS_ROOT, subdir, glob)).first
  end

  # Books をロックせず WAL も取り込むため、DB 一式を tmp にコピーしてからクエリする。
  def with_db_copy(src)
    require "tmpdir"
    require "fileutils"
    dir = Dir.mktmpdir("booksdb")
    [src, "#{src}-wal", "#{src}-shm"].each do |f|
      FileUtils.cp(f, dir) if File.exist?(f)
    end
    yield File.join(dir, File.basename(src))
  ensure
    FileUtils.remove_entry(dir) if dir && Dir.exist?(dir)
  end

  def sqlite_json(db, sql)
    require "json"
    require "shellwords"
    out = `/usr/bin/sqlite3 -json #{Shellwords.escape(db)} #{Shellwords.escape(sql)}`
    out.strip.empty? ? [] : JSON.parse(out)
  end

  def sql_quote(str)
    "'#{str.gsub("'", "''")}'"
  end

  def read_epub_part(epub_path, entry)
    if File.directory?(epub_path)
      path = File.join(epub_path, entry)
      File.exist?(path) ? File.read(path) : nil
    else
      require "shellwords"
      out = `/usr/bin/unzip -p #{Shellwords.escape(epub_path)} #{Shellwords.escape(entry)} 2>/dev/null`
      out.empty? ? nil : out
    end
  end

  # OPF の dc:* メタデータを正規表現で抽出する（名前空間を跨いで頑健に取るため）。
  def opf_metadata(opf_xml)
    pick = lambda do |tag|
      m = opf_xml.match(%r{<dc:#{tag}\b[^>]*>([^<]*)</dc:#{tag}>}m)
      m && strip_spaces(m[1])
    end
    translator = nil
    opf_xml.scan(%r{<dc:contributor\b([^>]*)>([^<]*)</dc:contributor>}m) do |attrs, val|
      translator ||= strip_spaces(val) if attrs.include?("trl")
    end
    {
      title: pick.call("title"),
      author: pick.call("creator"),
      publisher: pick.call("publisher"),
      language: pick.call("language"),
      published: pick.call("date"),
      isbn: pick.call("identifier"),
      translator: translator
    }
  end

  # OPF manifest から epub3 nav の href を返す（properties に "nav" を含む item）。無ければ nil。
  def nav_href(opf_xml)
    require "rexml/document"
    doc = REXML::Document.new(opf_xml)
    REXML::XPath.match(doc, "//item").each do |item|
      props = item.attribute("properties")&.value.to_s
      return item.attribute("href")&.value if props.split(/\s+/).include?("nav")
    end
    nil
  end

  def abbreviate_home(path)
    home = File.expand_path("~")
    path.start_with?(home) ? path.sub(home, "~") : path
  end

  def run(argv)
    require "optparse"
    require "fileutils"
    require "time"

    opts = { out_dir: DEFAULT_OUT_DIR, dry_run: false, book: nil, all: false }
    OptionParser.new do |o|
      o.banner = "Usage: books-highlights.rb --book TITLE [--dry-run] [--out-dir DIR]"
      o.on("--book TITLE", "対象書籍のタイトル部分一致") { |v| opts[:book] = v }
      o.on("--all", "全書籍を対象にする") { opts[:all] = true }
      o.on("--out-dir DIR", "出力先ディレクトリ") { |v| opts[:out_dir] = File.expand_path(v) }
      o.on("--dry-run", "書き込まず内容を表示") { opts[:dry_run] = true }
    end.parse!(argv)

    unless opts[:book] || opts[:all]
      warn "Error: --book TITLE か --all を指定してください"
      return 1
    end

    bk = locate_db("BKLibrary", "BKLibrary-*.sqlite")
    ae = locate_db("AEAnnotation", "AEAnnotation_*.sqlite")
    unless bk && ae
      warn "Error: Books の SQLite が見つかりません (#{IBOOKS_ROOT})"
      return 1
    end

    with_db_copy(bk) do |bkdb|
      with_db_copy(ae) do |aedb|
        where = opts[:all] ? "1=1" : "ZTITLE LIKE #{sql_quote("%#{opts[:book]}%")}"
        books = sqlite_json(bkdb, <<~SQL)
          SELECT ZASSETID AS asset_id, ZTITLE AS title, ZAUTHOR AS author, ZPATH AS path
          FROM ZBKLIBRARYASSET WHERE #{where}
        SQL

        if books.empty?
          warn "対象書籍が見つかりません: #{opts[:book]}"
          return 1
        end

        FileUtils.mkdir_p(opts[:out_dir]) unless opts[:dry_run]
        synced = Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ")

        books.each do |b|
          process_book(b, aedb, opts, synced)
        end
      end
    end
    0
  end

  def process_book(book, aedb, opts, synced)
    asset_id = book["asset_id"]
    rows = sqlite_json(aedb, <<~SQL)
      SELECT ZANNOTATIONSELECTEDTEXT AS text, ZANNOTATIONNOTE AS note,
             ZANNOTATIONSTYLE AS style, ZANNOTATIONCREATIONDATE AS cdate,
             ZANNOTATIONLOCATION AS cfi, ZPLABSOLUTEPHYSICALLOCATION AS phys
      FROM ZAEANNOTATION
      WHERE ZANNOTATIONASSETID = #{sql_quote(asset_id)}
        AND ZANNOTATIONSELECTEDTEXT IS NOT NULL
        AND (ZANNOTATIONDELETED = 0 OR ZANNOTATIONDELETED IS NULL)
    SQL

    if rows.empty?
      warn "ハイライトなし: #{book['title']}"
      return
    end

    highlights = rows.map do |r|
      {
        text: strip_spaces(r["text"].to_s),
        note: r["note"].to_s,
        created: r["cdate"] ? core_data_date(r["cdate"]) : "",
        cfi: r["cfi"].to_s,
        phys: r["phys"].to_i
      }
    end

    path = book["path"].to_s
    epub_meta, chapter_map, order = load_epub(path)

    grouped = group_and_sort(highlights, chapter_map, order)

    title = book["title"]
    related = File.exist?(File.join(WIKI_DIR, "#{title}.md")) ? title : nil
    meta = {
      title: title,
      author: (book["author"] && book["author"] != "UnknownAuthor" ? book["author"] : epub_meta[:author]),
      translator: epub_meta[:translator],
      publisher: epub_meta[:publisher],
      isbn: epub_meta[:isbn],
      language: epub_meta[:language],
      published: epub_meta[:published],
      asset_id: asset_id,
      source: abbreviate_home(path),
      format: File.extname(path).delete(".").downcase,
      highlight_count: highlights.size,
      last_synced: synced,
      related: related
    }

    doc = build_frontmatter(meta) + "\n" + render_markdown(meta, grouped)
    out_path = File.join(opts[:out_dir], "#{sanitize_filename(title)}（ハイライト）.md")

    if opts[:dry_run]
      puts "==== [dry-run] #{out_path} (#{highlights.size} highlights, #{grouped.size} chapters) ===="
      puts doc
    else
      File.write(out_path, doc)
      puts "wrote #{out_path} (#{highlights.size} highlights, #{grouped.size} chapters)"
    end
  end

  # epub から [メタデータhash, 章マップ, spine順] を返す。読めない/epubでない場合は空で返す。
  def load_epub(path)
    empty = [{}, {}, []]
    return empty unless File.extname(path).downcase == ".epub" && File.exist?(path)

    container = read_epub_part(path, "META-INF/container.xml")
    return empty unless container

    m = container.match(/full-path="([^"]+)"/)
    return empty unless m

    opf_path = m[1]
    opf_dir = File.dirname(opf_path)
    opf_xml = read_epub_part(path, opf_path)
    return empty unless opf_xml

    nav = nav_href(opf_xml) || guess_toc(opf_xml)
    toc_xml = nav ? read_epub_part(path, join_epub(opf_dir, nav)) : nil

    chapter_map = toc_xml ? build_chapter_map(opf_xml, toc_xml) : manifest_items(opf_xml)
    [opf_metadata(opf_xml), chapter_map, spine_order(opf_xml)]
  end

  # nav が manifest properties で取れない場合、*-toc.xhtml らしき href を推測する。
  def guess_toc(opf_xml)
    manifest_items(opf_xml).values.find { |href| href =~ /toc.*\.xhtml$/i }
  end

  def join_epub(dir, rel)
    dir == "." ? rel : "#{dir}/#{rel}"
  end

  def sanitize_filename(name)
    name.gsub(%r{[/\\:*?"<>|]}, "_")
  end
end

if __FILE__ == $PROGRAM_NAME
  exit BooksHighlights.run(ARGV)
end
