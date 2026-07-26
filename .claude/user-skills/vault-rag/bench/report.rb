require 'json'

# 使い方: ruby bench_report.rb <a.json> [b.json]
# 1引数なら型別の内訳を表示。2引数なら b - a の差分を表示。

def load(path)
  JSON.parse(File.read(path))
end

def by_type(d)
  # results: [{query: {id,type,...}, backends: {name => metrics}}] 形式を吸収する
  rows = d['results']
  out = Hash.new { |h, k| h[k] = Hash.new { |h2, k2| h2[k2] = [] } }
  rows.each do |r|
    q = r['query'] || r
    type = q['type'] || r['type']
    backends = r['backends'] || r['results'] || {}
    backends.each do |bname, m|
      next unless m.is_a?(Hash)
      out[type][bname] << m
    end
  end
  out
end

def mean(arr, key)
  vals = arr.map { |m| m[key] }.compact
  return 0.0 if vals.empty?
  vals.sum.to_f / vals.size
end

a = load(ARGV[0])

if ARGV[1].nil?
  puts "== 全体 =="
  a['summary'].each do |bname, m|
    puts format("  %-8s R@1=%.3f R@3=%.3f MRR=%.3f", bname, m['avg_recall_at_1'], m['avg_recall_at_3'], m['avg_mrr'])
  end
  puts
  puts "== type 別（full バックエンド）=="
  by_type(a).sort_by { |t, _| t.to_s }.each do |type, backends|
    m = backends['full']
    next if m.nil? || m.empty?
    puts format("  %-13s n=%d R@1=%.3f R@3=%.3f MRR=%.3f", type, m.size, mean(m, 'recall_at_1'), mean(m, 'recall_at_3'), mean(m, 'mrr'))
  end
else
  b = load(ARGV[1])
  puts "== 全体（#{File.basename(ARGV[0])} → #{File.basename(ARGV[1])}）=="
  a['summary'].each do |bname, ma|
    mb = b['summary'][bname]
    next unless mb
    puts format("  %-8s R@3 %.3f → %.3f (%+.3f)   MRR %.3f → %.3f (%+.3f)",
                bname, ma['avg_recall_at_3'], mb['avg_recall_at_3'], mb['avg_recall_at_3'] - ma['avg_recall_at_3'],
                ma['avg_mrr'], mb['avg_mrr'], mb['avg_mrr'] - ma['avg_mrr'])
  end
  puts
  puts "== type 別 R@3（full）=="
  ta = by_type(a)
  tb = by_type(b)
  (ta.keys | tb.keys).sort_by(&:to_s).each do |type|
    ma = ta[type]['full']
    mb = tb[type]['full']
    next if ma.nil? || ma.empty? || mb.nil? || mb.empty?
    va = mean(ma, 'recall_at_3')
    vb = mean(mb, 'recall_at_3')
    puts format("  %-13s %.3f → %.3f (%+.3f)", type, va, vb, vb - va)
  end
end
