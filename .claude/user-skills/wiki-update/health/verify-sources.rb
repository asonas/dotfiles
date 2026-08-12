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

# scheduled task の環境には LANG が無く default_external が US-ASCII になる。
# vault のノートは UTF-8 なので locale に関わらず UTF-8 で読む。
Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = nil

VAULT = '/Users/asonas/Obsidian/asonas'
WIKI  = File.join(VAULT, 'wiki')
OPERATIONAL = /\A(index|log|log-.*|deferred)\.md\z/

quiet = ARGV.delete('--quiet')
show_accepted = ARGV.delete('--show-accepted')
targets = ARGV

# レビュー済みで「出典は正しいがページ名が本文に現れないだけ」と判断した組を抑止する。
# aliases を歪めて黙らせるより、判断した事実を理由つきで残すほうが後から検証できる。
# 形式: <ページ名> <TAB> <出典の vault 相対パス> <TAB> <理由>
ACCEPT_FILE = File.join(__dir__, 'verify-sources-accepted.tsv')
accepted = {}
if File.exist?(ACCEPT_FILE)
  File.readlines(ACCEPT_FILE).each do |line|
    next if line.strip.empty? || line.start_with?('#')
    page, src, reason = line.chomp.split("\t", 3)
    next unless page && src
    accepted[[page.strip, src.strip]] = reason.to_s.strip
  end
end

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

  # accepted の行はここで出力せず溜めておく。ここで puts すると、そのページの
  # OK / NG ヘッダより先に出てしまい、--quiet で OK ページのヘッダが省かれたときに
  # 直前の NG ページの指摘のように見えてしまう
  accepted_here = []

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
    if accepted.key?([name, rel])
      accepted_here << "#{rel} — #{accepted[[name, rel]]}"
      next
    end
    "#{link.strip} → 「#{name}」への言及が見つからない (#{rel})"
  end

  # --show-accepted のときは、抑止した組があるページは quiet でもヘッダを出す。
  # ヘッダなしで accepted 行だけ出すと、どのページのものか分からなくなる
  if bad.empty?
    puts "OK   #{name}" if !quiet || (show_accepted && accepted_here.any?)
  else
    ng_pages += 1
    puts "NG   #{name} (#{bad.size}/#{links.size})"
    bad.each { |b| puts "       #{b}" }
  end
  accepted_here.each { |a| puts "     accepted: #{a}" } if show_accepted
end

puts
puts "#{checked} ページを検査、#{ng_pages} ページに要確認の出典あり"
exit(ng_pages.zero? ? 0 : 1)
