#!/usr/bin/env bash
set -euo pipefail

today=".claude/user-skills/today/SKILL.md"
wrapup=".claude/user-skills/wrapup/skill.md"

assert_contains() {
  local file="$1"
  local needle="$2"
  if ! grep -Fq "$needle" "$file"; then
    echo "Expected '$needle' in $file" >&2
    exit 1
  fi
}

assert_absent() {
  local file="$1"
  local needle="$2"
  if grep -Fq "$needle" "$file"; then
    echo "Did not expect '$needle' in $file" >&2
    exit 1
  fi
}

for file in "$today" "$wrapup"; do
  for forbidden in \
    "Google Calendar" \
    "mcp__google-calendar" \
    "calendar" \
    "予定" \
    "goals/" \
    "四半期ゴール" \
    "Linear" \
    "linear" \
    "今日やること" \
    "困りご" \
    "ブロッカー" \
    "AskUserQuestion"; do
    assert_absent "$file" "$forbidden"
  done
done

assert_contains "$today" "## 前日からの引き継ぎ"
assert_contains "$today" "## 昨日やったこと"
assert_contains "$today" "Skill(wiki-update, args: \"ingest yesterday\")"
assert_contains "$today" "activities-snapshot --source bluesky --source scrapbox"
assert_contains "$today" "Skill(raindrop-sync)"
assert_contains "$wrapup" "cman-sessions"
assert_contains "$wrapup" "## ログの追記内容"
assert_contains "$wrapup" "Skill(wiki-update, args: \"ingest <YYYY-MM-DD>\")"
assert_contains "$wrapup" "activities-snapshot --source bluesky --source scrapbox"

echo "today/wrapup leave-mode contract: PASS"
