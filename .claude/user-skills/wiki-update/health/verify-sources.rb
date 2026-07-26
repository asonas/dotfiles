#!/usr/bin/env ruby
# wiki ページの sources: が本当にそのページの話をしているかを検証する。
#
#   ruby verify-sources.rb                 # 全ページ
#   ruby verify-sources.rb Linear TDD      # ページ名を指定
#   ruby verify-sources.rb --quiet         # NG のみ表示
#
# なぜ必要か:
#   sources が「空でない」ことは wiki-health.rb で分かるが、書かれている出典が正しいかは分からない。
#   deferred の回収でページを起こすときは、特定のノートを読むのではなく vault 全体を grep して
#   材料を集めることになる。このとき `grep -rh` のようにファイル名が落ちる形で調べると、
#   文は手元にあるのに出典が分からないまま frontmatter を書いてしまい、
#   「もっともらしいが誤った出典」が入り込む。2026-07-26 の ingest で実際に 6 ページが該当した。
#   材料集めでは必ず `grep -rn` / `grep -rl` を使い、そのうえでこのスクリプトを通すこと。
#
# 検査内容:
#   sources の各ファイルに、ページ名または aliases のいずれかが出現するか。
#   出現しない = そのソースはページの主題に触れていない可能性が高い。
#   URL 形式など表記が異なるだけの正当なケースもあるので、NG は「要確認」であって「誤り確定」ではない。

require 'set'

VAULT = '/Users/asonas/Documents/asonas'
WIKI  = File.join(VAULT, 'wiki')
OPERATIONAL = /\A(index|log|log-.*|deferred)\.md\z/

quiet = ARGV.delete('--quiet')
targets = ARGV

def resolve(link)
  name = link.gsub(/\A"?\[\[/, '').gsub(/\]\]"?\z/, '').split('|').first.to_s.strip
  return nil if name.empty?
  direct = File.join(VAULT, "#{name}.md")
  return direct if File.exist?(direct)
  Dir[File.join(VAULT, '**', "#{File.basename(name)}.md")].first
end

pages = Dir[File.join(WIKI, '*.md')].reject { |f| File.basename(f) =~ OPERATIONAL }
pages.select! { |f| targets.include?(File.basename(f, '.md')) } unless targets.empty?

ng_pages = 0
checked = 0

pages.sort.each do |path|
  name = File.basename(path, '.md')
  fm = File.read(path)[/\A---\n(.*?)\n---\n/m, 1] || ''

  terms = [name]
  if (inline = fm[/^aliases:\s*\[(.*?)\]/m, 1])
    terms += inline.split(',').map { |s| s.strip.delete_prefix('"').delete_suffix('"') }
  elsif fm =~ /^aliases:\s*\n((?:\s+-\s+.*\n)+)/
    terms += $1.scan(/^\s+-\s+(.*)$/).flatten.map { |s| s.strip.delete_prefix('"').delete_suffix('"') }
  end
  terms.reject!(&:empty?)

  links = fm[/^sources:\s*\n((?:\s+-\s+.*\n)+)/, 1].to_s.scan(/^\s+-\s+(.*)$/).flatten
                                                    .select { |l| l.include?('[[') }
  next if links.empty?
  checked += 1

  bad = links.filter_map do |link|
    file = resolve(link)
    # 実体のないリンクは vault の設計上の赤リンク（Linear issue ID、リポジトリ名など）。
    # lint の unresolved 検査が別途扱うので、ここでは判定対象にしない
    next if file.nil?
    rel = file.sub(VAULT + '/', '')
    # ソースがそのページ名のディレクトリ配下にある場合、ファイル名に主題が現れないのは自然
    next if terms.any? { |t| rel.include?("/#{t}/") || File.basename(rel, '.md') == t }
    body = File.read(file)
    next if terms.any? { |t| body.include?(t) }
    "#{link.strip} → 「#{name}」への言及が見つからない (#{rel})"
  end

  if bad.empty?
    puts "OK   #{name}" unless quiet
  else
    ng_pages += 1
    puts "NG   #{name} (#{bad.size}/#{links.size})"
    bad.each { |b| puts "       #{b}" }
  end
end

puts
puts "#{checked} ページを検査、#{ng_pages} ページに要確認の出典あり"
exit(ng_pages.zero? ? 0 : 1)
