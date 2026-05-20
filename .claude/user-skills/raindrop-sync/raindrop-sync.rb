#!/usr/bin/env ruby
# frozen_string_literal: true

# raindrop-sync.rb
#
# Sync Raindrop.io bookmarks into the asonas Obsidian vault under bookmarks/.
# Each bookmark becomes a single markdown file named {raindrop_id}.md.
# Page content is fetched via defuddle and embedded in the body.
#
# Usage:
#   raindrop-sync                       # incremental (since last sync)
#   raindrop-sync --since YYYY-MM-DD    # explicit lower bound on lastUpdate
#   raindrop-sync --full                # ignore last_sync, fetch everything
#   raindrop-sync --collection <id>     # restrict to a single collection
#   raindrop-sync --dry-run             # print what would change, write nothing

require 'json'
require 'net/http'
require 'uri'
require 'fileutils'
require 'time'
require 'open3'
require 'optparse'
require 'timeout'

TOKEN_PATH         = File.expand_path('~/.config/raindrop/token')
VAULT_BOOKMARKS    = File.expand_path('~/Documents/asonas/bookmarks')
LAST_SYNC_PATH     = File.join(VAULT_BOOKMARKS, '.last_sync')
RAINDROP_API_BASE  = 'https://api.raindrop.io/rest/v1'
PERPAGE            = 50
DEFUDDLE_TIMEOUT_S = 30

def load_token
  unless File.exist?(TOKEN_PATH)
    warn <<~MSG
      Raindrop API token not found at #{TOKEN_PATH}.
      Create a test token at https://app.raindrop.io/settings/integrations,
      then save it with: install -m 600 /dev/stdin #{TOKEN_PATH} <<< 'YOUR_TOKEN'
    MSG
    exit 1
  end
  File.read(TOKEN_PATH).strip
end

def api_get(path, params, token)
  uri = URI("#{RAINDROP_API_BASE}#{path}")
  uri.query = URI.encode_www_form(params) unless params.empty?
  req = Net::HTTP::Get.new(uri)
  req['Authorization'] = "Bearer #{token}"
  Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
    res = http.request(req)
    raise "Raindrop API #{res.code}: #{res.body}" unless res.code == '200'

    JSON.parse(res.body)
  end
end

def fetch_bookmarks(token, collection_id: 0, since: nil)
  page = 0
  all = []
  loop do
    params = { perpage: PERPAGE, page: page, sort: '-lastUpdate' }
    params[:search] = "lastUpdate:>#{since}" if since
    body = api_get("/raindrops/#{collection_id}", params, token)
    items = body['items'] || []
    break if items.empty?

    all.concat(items)
    break if items.size < PERPAGE

    page += 1
  end
  all
end

def defuddle_markdown(url)
  out = err = status = nil
  Timeout.timeout(DEFUDDLE_TIMEOUT_S) do
    out, err, status = Open3.capture3('defuddle', 'parse', '--md', url, stdin_data: '')
  end
  return [out.strip, nil] if status&.success? && !out.to_s.strip.empty?

  msg = err.to_s.strip.lines.last&.strip
  msg = 'defuddle returned empty output' if msg.nil? || msg.empty?
  [nil, msg]
rescue Timeout::Error
  [nil, "timeout after #{DEFUDDLE_TIMEOUT_S}s"]
rescue StandardError => e
  [nil, "#{e.class}: #{e.message}"]
end

YAML_ESCAPE = ->(s) { s.to_s.gsub('"', '\\"').gsub("\n", ' ') }

def yaml_string(value)
  return 'null' if value.nil?

  s = value.to_s
  return s if s.match?(/\A[A-Za-z0-9_\-:T+.Z\/]+\z/) && !s.empty?

  %("#{YAML_ESCAPE.call(s)}")
end

def yaml_block(value)
  return "  null" if value.nil? || value.to_s.empty?

  value.to_s.lines.map { |l| "  #{l.chomp}" }.join("\n")
end

def render_markdown(item, body_md, body_error)
  tags = item['tags'] || []
  highlights = item['highlights'] || []
  title = item['title'].to_s
  excerpt = item['excerpt'].to_s
  note = item['note'].to_s

  lines = []
  lines << '---'
  lines << 'type: bookmark'
  lines << "raindrop_id: #{item['_id']}"
  lines << "url: #{yaml_string(item['link'])}"
  lines << "title: #{yaml_string(title)}"
  lines << "domain: #{yaml_string(item['domain'])}"
  lines << "collection: #{item.dig('collection', '$id') || 0}"
  lines << 'tags:'
  if tags.empty?
    lines[-1] = 'tags: []'
  else
    tags.each { |t| lines << "  - #{yaml_string(t)}" }
  end
  lines << "saved: #{item['created']}"
  lines << "last_updated: #{item['lastUpdate']}"
  lines << "last_synced: #{Time.now.utc.iso8601}"
  lines << "defuddle_status: #{body_error ? "error: #{yaml_string(body_error)}" : 'ok'}"
  lines << '---'
  lines << ''
  lines << "# #{title}"
  lines << ''
  lines << "<#{item['link']}>"
  lines << ''
  unless excerpt.empty?
    lines << '## Excerpt'
    lines << ''
    lines << excerpt
    lines << ''
  end
  unless note.empty?
    lines << '## My Note'
    lines << ''
    lines << note
    lines << ''
  end
  unless highlights.empty?
    lines << '## Highlights'
    lines << ''
    highlights.each do |h|
      lines << "- #{h['text']}"
      lines << "  - note: #{h['note']}" if h['note'] && !h['note'].empty?
    end
    lines << ''
  end
  lines << '## Content'
  lines << ''
  if body_md
    lines << body_md
  else
    lines << "_(defuddle failed: #{body_error})_"
  end
  lines << ''
  lines.join("\n")
end

def write_bookmark(item, dry_run:)
  path = File.join(VAULT_BOOKMARKS, "#{item['_id']}.md")
  body_md, body_error = defuddle_markdown(item['link'])
  content = render_markdown(item, body_md, body_error)
  if dry_run
    action = File.exist?(path) ? 'UPDATE' : 'CREATE'
    puts "[dry-run] #{action} #{path} (defuddle: #{body_error ? 'error' : 'ok'})"
    return
  end
  FileUtils.mkdir_p(VAULT_BOOKMARKS)
  File.write(path, content)
  puts "wrote #{File.basename(path)} (defuddle: #{body_error ? 'error' : 'ok'})"
end

options = { full: false, dry_run: false, collection: 0, since: nil }
OptionParser.new do |o|
  o.banner = 'Usage: raindrop-sync [options]'
  o.on('--full',          'Ignore last_sync and fetch everything')                  { options[:full] = true }
  o.on('--dry-run',       'Print what would change, write nothing')                 { options[:dry_run] = true }
  o.on('--collection ID', Integer, 'Restrict to a single collection (default: 0)')  { |v| options[:collection] = v }
  o.on('--since DATE',    'Lower bound on lastUpdate (YYYY-MM-DD)')                 { |v| options[:since] = v }
end.parse!

token = load_token
FileUtils.mkdir_p(VAULT_BOOKMARKS)

since =
  if options[:full]
    nil
  elsif options[:since]
    options[:since]
  elsif File.exist?(LAST_SYNC_PATH)
    File.read(LAST_SYNC_PATH).strip
  end

puts "Fetching bookmarks (collection=#{options[:collection]}, since=#{since || 'beginning'})..."
items = fetch_bookmarks(token, collection_id: options[:collection], since: since)
puts "Found #{items.size} bookmark(s) to sync."

started_at = Time.now.utc
items.each_with_index do |item, i|
  puts "[#{i + 1}/#{items.size}] #{item['title']} (#{item['domain']})"
  write_bookmark(item, dry_run: options[:dry_run])
end

unless options[:dry_run]
  File.write(LAST_SYNC_PATH, started_at.strftime('%Y-%m-%dT%H:%M:%S'))
  puts "Updated last_sync to #{started_at.iso8601}."
end
