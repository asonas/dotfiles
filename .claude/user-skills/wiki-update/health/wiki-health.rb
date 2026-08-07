#!/usr/bin/env ruby
# wiki の育ち具合を測る。検索品質は vault-rag/bench の担当で、こちらは wiki 自体の健康診断。
#
#   ruby wiki-health.rb            # 人が読む形式
#   ruby wiki-health.rb --json     # 記録・比較用
#
# 見るべき指標:
#   pages_touched_per_ingest  1回の ingest で作成・更新したページ数。スキルの想定は 10〜15
#   staleness                 最終更新からの経過日数の分布。「積もる場所」なら短い側に寄る
#   deferred                  ページ化待ちの滞留。増え続けているなら回収が回っていない
#   merge_candidates          単一ソースかつ2段落以下。スキルが「過剰分割」と呼ぶ状態

require 'json'
require 'date'
require 'set'

# scheduled task の環境には LANG が無く default_external が US-ASCII になる。
# vault のノートは UTF-8 なので locale に関わらず UTF-8 で読む。
Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = nil

VAULT = '/Users/asonas/Documents/asonas'
WIKI  = File.join(VAULT, 'wiki')
OPERATIONAL = /\A(index|log|log-.*|deferred)\.md\z/
SOURCE_DIRS = %w[daily notes essays projects weekly 1on1]
TODAY = Date.today

pages = Dir[File.join(WIKI, '*.md')].reject { |f| File.basename(f) =~ OPERATIONAL }

infos = pages.map do |path|
  text = File.read(path)
  fm   = text[/\A---\n(.*?)\n---\n/m, 1] || ''
  body = text.sub(/\A---\n.*?\n---\n/m, '').strip
  {
    name: File.basename(path, '.md'),
    type: fm[/^type:\s*(\S+)/, 1],
    updated: (Date.parse(fm[/^updated:\s*(\S+)/, 1]) rescue nil),
    sources: fm.scan(/\[\[([^\]]+)\]\]/).flatten.size,
    chars: body.length,
    paragraphs: body.split(/\n\s*\n/).reject { |p| p.strip.empty? }.size
  }
end

# --- staleness ---
stale = Hash.new(0)
infos.each do |i|
  if i[:updated].nil?
    stale['missing'] += 1
  else
    d = (TODAY - i[:updated]).to_i
    stale[d <= 7 ? '0-7d' : d <= 30 ? '8-30d' : d <= 60 ? '31-60d' : d <= 90 ? '61-90d' : '90d+'] += 1
  end
end

# --- ingest あたりの page touch ---
logs = Dir[File.join(WIKI, 'log*.md')]
ingests = 0
created = 0
updated = 0
logs.each do |f|
  txt = File.read(f)
  ingests += txt.scan(/^## \d{4}-\d{2}-\d{2}[^\n]*ingest/).size
  txt.scan(/^- created:\s*(.+)$/).flatten.each { |l| created += l.scan(/\[\[/).size }
  txt.scan(/^- updated:\s*(.+)$/).flatten.each { |l| updated += l.scan(/\[\[/).size }
end

# --- deferred 台帳 ---
deferred = { 'ページ化待ち' => 0, '様子見' => 0, '見送り' => 0 }
deferred_path = File.join(WIKI, 'deferred.md')
if File.exist?(deferred_path)
  section = nil
  File.readlines(deferred_path).each do |line|
    if (m = line.match(/^##\s*(\S+?)(?:（|$)/))
      key = deferred.keys.find { |k| m[1].start_with?(k) }
      section = key
      next
    end
    next unless section
    deferred[section] += 1 if line.start_with?('| [[')
  end
end

# --- 被リンク ---
name_set = infos.map { |i| i[:name] }.to_set
from_source = Hash.new(0)
SOURCE_DIRS.each do |d|
  Dir[File.join(VAULT, d, '**', '*.md')].each do |f|
    (File.read(f) rescue '').scan(/\[\[([^\]|#]+)/).flatten.each do |raw|
      n = raw.split('/').last.strip
      from_source[n] += 1 if name_set.include?(n)
    end
  end
end

sizes = infos.map { |i| i[:chars] }.sort
report = {
  'date' => TODAY.to_s,
  'pages' => infos.size,
  'body_chars' => {
    'median' => sizes[sizes.size / 2],
    'p25' => sizes[sizes.size / 4],
    'p75' => sizes[sizes.size * 3 / 4]
  },
  'ingests' => ingests,
  'pages_touched_total' => created + updated,
  'pages_touched_per_ingest' => ingests.zero? ? 0 : ((created + updated).to_f / ingests).round(2),
  'created_total' => created,
  'updated_total' => updated,
  'staleness' => stale,
  'deferred' => deferred,
  'merge_candidates' => infos.count { |i| i[:sources] <= 1 && i[:paragraphs] <= 2 },
  'never_linked_from_source' => name_set.count { |n| from_source[n].zero? }
}

if ARGV.include?('--json')
  puts JSON.pretty_generate(report)
else
  puts "wiki health (#{report['date']})"
  puts "  ページ数            #{report['pages']}"
  puts "  本文文字数          median=#{report['body_chars']['median']} (p25=#{report['body_chars']['p25']} p75=#{report['body_chars']['p75']})"
  puts
  puts "  ingest 回数         #{report['ingests']}"
  puts "  page touch 合計     #{report['pages_touched_total']} (created #{report['created_total']} / updated #{report['updated_total']})"
  puts "  1 ingest あたり     #{report['pages_touched_per_ingest']}  ← スキルの想定は 10〜15"
  puts
  puts "  staleness           " + %w[0-7d 8-30d 31-60d 61-90d 90d+ missing].map { |k| "#{k}:#{stale[k]}" }.join('  ')
  puts "  deferred            " + deferred.map { |k, v| "#{k}:#{v}" }.join('  ')
  puts "  過剰分割の候補      #{report['merge_candidates']}（単一ソースかつ2段落以下）"
  puts "  ソース未被リンク    #{report['never_linked_from_source']}（daily/notes 等から一度も [[]] されていない）"
end
