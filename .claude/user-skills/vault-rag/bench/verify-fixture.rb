#!/usr/bin/env ruby
# fixture の健全性チェック。bench を回す前に必ず通すこと。
#   ruby verify-fixture.rb [fixture.json]
#
# 検査項目:
#   1. expected_files が vault に実在するか（1文字ずれると静かにスコア0になる）
#   2. 各クエリに lex: と vec: の両方があるか（lex 欠落は bm25 バックエンドが空を返す）
#   3. expected_files がコレクション相対のフルパスか（pathsMatch はサフィックス一致なので誤爆する）
#   4. id の重複

require 'json'

VAULT = '/Users/asonas/Documents/asonas'
path = ARGV[0] || File.join(__dir__, 'vault-fixture.json')
fixture = JSON.parse(File.read(path))

errors = []
warnings = []
seen_ids = {}

fixture['queries'].each_with_index do |q, i|
  label = q['id'] || "##{i}"

  errors << "#{label}: id が重複している" if seen_ids[q['id']]
  seen_ids[q['id']] = true

  types = q['query'].to_s.lines.filter_map { |l| l[/^\s*(lex|vec|hyde|intent):/, 1] }
  errors << "#{label}: lex: 行がない（bm25 バックエンドが空を返す）" unless types.include?('lex')
  errors << "#{label}: vec: 行がない" unless types.include?('vec')

  q['query'].to_s.lines.reject { |l| l.strip.empty? }.each_with_index do |line, n|
    unless line =~ /^\s*(lex|vec|hyde|intent):/
      errors << "#{label}: #{n + 1}行目に型プレフィックスがない: #{line.strip.inspect}"
    end
  end

  Array(q['expected_files']).each do |f|
    errors << "#{label}: 存在しないパス: #{f}" unless File.exist?(File.join(VAULT, f))
    warnings << "#{label}: ディレクトリを含まないパス（サフィックス一致で誤爆しうる）: #{f}" unless f.include?('/')
  end

  errors << "#{label}: expected_files が空" if Array(q['expected_files']).empty?
  errors << "#{label}: expected_in_top_k が未設定" unless q['expected_in_top_k'].is_a?(Integer)
end

by_type = fixture['queries'].group_by { |q| q['type'] }
puts "queries: #{fixture['queries'].size}"
by_type.sort_by { |k, _| k.to_s }.each { |t, qs| puts "  #{t}: #{qs.size}" }
puts

warnings.each { |w| puts "WARN  #{w}" }
errors.each { |e| puts "ERROR #{e}" }

if errors.empty?
  puts "OK: fixture は健全です"
  exit 0
else
  puts "\n#{errors.size} 件のエラー"
  exit 1
end
