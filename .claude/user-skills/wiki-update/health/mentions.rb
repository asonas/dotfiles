#!/usr/bin/env ruby
# ソースノートに言及されている既存 wiki ページを機械的に洗い出す。
# ingest のエンティティ抽出が LLM の一発読みに依存していて取りこぼす問題への対策。
#
#   ruby mentions.rb daily/2026-07-25.md activities/2026-07-25.md
#   ruby mentions.rb --json daily/2026-07-25.md
#
# 出力は4つに分かれる:
#   redlink   [[...]] と書かれているのに vault に実体が無い。著者の意思表示なので新規候補の最優先
#   linked    既存ページへ [[...]] 済み。増補の第一候補
#   plain     既存ページ名が本文に出てくるがリンクになっていない。増補候補 + リンク付与候補
#   alias     既存ページの別名で出てくる。表記揺れなので本文を読んで判断する
#
# このスクリプトは「言及がある」ことしか言わない。増補すべきかはソースを読んで判断する。
# 逆に、ここに出た語を1つも更新せずに ingest を終えたなら、その理由を log に書くこと。

require 'json'
require 'set'

VAULT = '/Users/asonas/Documents/asonas'
WIKI  = File.join(VAULT, 'wiki')
OPERATIONAL = /\A(index|log|log-.*|deferred)\.md\z/

json = ARGV.delete('--json')
candidates_mode = ARGV.delete('--candidates')
sources = ARGV
abort "usage: mentions.rb [--json] [--candidates] <vault相対パス>..." if sources.empty?

# 既存 wiki ページの名前と別名を集める
entries = []
Dir[File.join(WIKI, '*.md')].reject { |f| File.basename(f) =~ OPERATIONAL }.each do |path|
  name = File.basename(path, '.md')
  fm = File.read(path)[/\A---\n(.*?)\n---\n/m, 1] || ''
  aliases = []
  if (inline = fm[/^aliases:\s*\[(.*?)\]/m, 1])
    aliases = inline.split(',').map { |s| s.strip.delete_prefix('"').delete_suffix('"') }
  elsif fm =~ /^aliases:\s*\n((?:\s+-\s+.*\n)+)/
    aliases = $1.scan(/^\s+-\s+(.*)$/).flatten.map { |s| s.strip.delete_prefix('"').delete_suffix('"') }
  end
  entries << { name: name, aliases: aliases.reject(&:empty?).reject { |a| a == name } }
end

def matcher(term)
  # ASCII のみの語は語境界を要求する（sharp が sharpen に当たるのを防ぐ）
  if term.match?(/\A[\x20-\x7E]+\z/)
    /(?<![A-Za-z0-9_\-\/])#{Regexp.escape(term)}(?![A-Za-z0-9_\-])/
  else
    /#{Regexp.escape(term)}/
  end
end

text = sources.map { |s|
  p = File.join(VAULT, s)
  abort "存在しないソース: #{s}" unless File.exist?(p)
  File.read(p)
}.join("\n")

linked_names = text.scan(/\[\[([^\]|#]+)/).flatten.map { |r| r.split('/').last.strip }.to_set

result = { 'sources' => sources, 'redlink' => [], 'linked' => [], 'plain' => [], 'alias' => [] }

# 赤リンク: ソース側で [[...]] と書かれているのに vault のどこにも実体が無い語。
# 著者が明示的にリンクした = ページ化の意思表示なので、新規候補として最も質が高い。
# --candidates の語彙スキャン（ASCII大文字始まり・カタカナ）では漢字語を拾えないため、
# ここを独立した経路として持つ必要がある（実例: [[認知負債]] [[技術選定]]）。
vault_basenames = Dir[File.join(VAULT, '**', '*.md')].map { |f| File.basename(f, '.md') }.to_set
deferred_known = Set.new
deferred_file = File.join(WIKI, 'deferred.md')
if File.exist?(deferred_file)
  File.read(deferred_file).scan(/^\|\s*\[\[([^\]|]+)/).flatten.each { |n| deferred_known << n.strip }
end
linked_names.each do |n|
  next if vault_basenames.include?(n)
  result['redlink'] << (deferred_known.include?(n) ? "#{n} (deferred済み)" : n)
end

entries.each do |e|
  if linked_names.include?(e[:name])
    result['linked'] << e[:name]
    next
  end
  if text.match?(matcher(e[:name]))
    result['plain'] << e[:name]
    next
  end
  hit = e[:aliases].find { |a| text.match?(matcher(a)) }
  result['alias'] << "#{e[:name]} (#{hit})" if hit
end

# --- 新規ページ候補（--candidates）---
# 既存ページでも deferred 済みでもない固有名詞らしき語を機械的に列挙する。
# 目的は「LLM の一発読みが取りこぼしても、チェックリストには載っている」状態を作ること。
# ノイズは多い。ページ化の判断は必ず本文を読んで行う。
if candidates_mode
  known = entries.flat_map { |e| [e[:name]] + e[:aliases] }.to_set
  deferred_path = File.join(WIKI, 'deferred.md')
  if File.exist?(deferred_path)
    File.read(deferred_path).scan(/^\|\s*\[\[([^\]|]+)/).flatten.each { |n| known << n.strip }
  end

  # 日本語の一般語や Markdown 由来の語はここで落とす
  stop = %w[
    TODO DONE WIP OK NG AM PM URL API CLI GUI PR MR CI CD OS PC ID IP DNS SSH HTTP HTTPS JSON YAML CSV SQL
    README CHANGELOG LICENSE Note Warning Tip The This That With From For And But Not You Your Issue
    アクションアイテム アップデート インストール インポート ウィンドウ エクスポート エラー カラム
    クライアント コミット コンテナ サーバー スクリプト タスク ダッシュボード ディレクトリ データ
    テーブル デプロイ ドキュメント パッケージ バージョン ハンドラ ファイル ブランチ プルリクエスト
    プロジェクト マージ マスター ミーティング メッセージ メソッド リポジトリ リリース リクエスト
    レコード レスポンス レビュー ロジック ワークフロー ランタイム インターフェース インフラ
  ].to_set

  # activities のセクション区切り <!-- BEGIN: ... --> は語の供給源ではないので落とす
  scan_text = text.gsub(/<!--.*?-->/m, ' ')

  ascii = scan_text.scan(/(?<![A-Za-z0-9_\-\/\[])([A-Z][A-Za-z0-9][A-Za-z0-9_.\-]{1,24})(?![A-Za-z0-9_\-])/).flatten
  katakana = scan_text.scan(/[ァ-ヴー]{4,20}/)

  counts = Hash.new(0)
  (ascii + katakana).each do |t|
    t = t.strip.sub(/[.\-]+\z/, '')
    next if t.length < 3 || stop.include?(t) || known.include?(t)
    next if t =~ /\A[A-Z]{2,}-\d+\z/ # Linear issue ID。vault では意図的に赤リンクのまま運用している
    next if known.any? { |k| k.casecmp?(t) }
    counts[t] += 1
  end

  result['candidates'] = counts.sort_by { |t, c| [-c, t] }.map { |t, c| { 'term' => t, 'count' => c } }

  unless json
    puts "sources: #{sources.join(', ')}"
    puts
    puts "新規ページ候補 (#{result['candidates'].size}) — 既存ページでも deferred 済みでもない語"
    if result['candidates'].empty?
      puts "  なし"
    else
      result['candidates'].each_slice(3) do |row|
        puts "  " + row.map { |c| "#{c['term']}(#{c['count']})" }.join('  ')
      end
    end
    puts
    puts "ノイズを含む。2ソース・ルールを満たす語だけをページ化し、初出は deferred.md の様子見へ。"
    exit 0
  end
end

if json
  puts JSON.pretty_generate(result)
else
  puts "sources: #{sources.join(', ')}"
  puts
  %w[redlink linked plain alias].each do |k|
    label = { 'redlink' => 'redlink 赤リンク（未作成。ページ化の意思表示なので最優先）',
              'linked' => 'linked  既に [[]] 済み', 'plain' => 'plain   リンクなしで言及',
              'alias'  => 'alias   別名で言及' }[k]
    puts "#{label} (#{result[k].size})"
    if result[k].empty?
      puts "  なし"
    else
      result[k].sort.each_slice(4) { |row| puts "  " + row.join(', ') }
    end
    puts
  end
  total = result.values_at('linked', 'plain', 'alias').sum(&:size)
  puts "既存ページへの言及 合計 #{total} 件。ここから増補すべきものを選ぶ。"
  puts "1件も更新しないなら、その理由を log の note に書くこと。"
end
