#!/usr/bin/env bash
set -euo pipefail

today_skill=".claude/user-skills/today/SKILL.md"
wrapup_skill=".claude/user-skills/wrapup/skill.md"

require_text() {
  local file="$1"
  local expected="$2"
  if ! grep -Fq "$expected" "$file"; then
    printf 'missing daily wiki guideline in %s: %s\n' "$file" "$expected" >&2
    exit 1
  fi
}

require_order() {
  local file="$1"
  local first="$2"
  local second="$3"
  local first_line
  local second_line

  first_line=$(grep -nF "$first" "$file" | head -1 | cut -d: -f1)
  second_line=$(grep -nF "$second" "$file" | head -1 | cut -d: -f1)
  if [ -z "$first_line" ] || [ -z "$second_line" ] || [ "$first_line" -ge "$second_line" ]; then
    printf 'expected %s before %s in %s\n' "$first" "$second" "$file" >&2
    exit 1
  fi
}

require_text "$today_skill" "LLM Wikiの一次ソース"
require_text "$today_skill" "分割候補"
require_text "$today_skill" "MOC候補"
require_text "$today_skill" "自動作成しない"
require_text "$today_skill" "深掘り候補"
require_text "$today_skill" "書きますか"
require_text "$today_skill" "実験コード"
require_text "$today_skill" "想定される影響"
require_text "$today_skill" "ビルド"
require_text "$today_skill" "デバイスへのアクセス"
require_text "$today_skill" "外部状態を変更"
require_text "$today_skill" "ユーザーの許可"
require_text "$today_skill" "実行しない"
require_order "$today_skill" "実験コード" "ユーザーの許可"

require_text "$wrapup_skill" "事実・実験・設計判断・未解決事項"
require_text "$wrapup_skill" "notes/\` のソースノート候補"
require_text "$wrapup_skill" "外部情報と自分の考察"
require_text "$wrapup_skill" "daily の \`## ログ\`"
require_text "$wrapup_skill" "LLM Wikiの一次記録"
require_text "$wrapup_skill" "ユーザーの承認後"
require_text "$wrapup_skill" "深掘り候補"
require_text "$wrapup_skill" "書きますか"
require_text "$wrapup_skill" "実験コード"
require_text "$wrapup_skill" "想定される影響"
require_text "$wrapup_skill" "ビルド"
require_text "$wrapup_skill" "デバイスへのアクセス"
require_text "$wrapup_skill" "外部状態を変更"
require_text "$wrapup_skill" "ユーザーの許可"
require_text "$wrapup_skill" "実行しない"
require_order "$wrapup_skill" "実験コード" "ユーザーの許可"
require_order "$wrapup_skill" "ユーザーの承認後" "Update Obsidian Wiki"

printf '%s\n' "today/wrapup wiki contract: PASS"
