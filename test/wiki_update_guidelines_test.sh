#!/usr/bin/env bash
set -euo pipefail

skill_path=".claude/user-skills/wiki-update/SKILL.md"

require_text() {
  local expected="$1"
  if ! grep -Fq "$expected" "$skill_path"; then
    printf 'missing wiki-update guideline: %s\n' "$expected" >&2
    exit 1
  fi
}

require_text "ページの粒度と分割"
require_text "実験"
require_text "設計判断"
require_text "MOC候補"
require_text "3つ"
require_text "承認"
require_text "type: summary"
require_text "3つ以上"
require_text "lint"
require_text "外部情報"
require_text "自分の考察"
require_text "推測"
require_text "完全一致"
require_text "過去のソース note"
require_text "後続の出現箇所へ移って"
require_text "自動分割せず"
require_text "自動作成せず"
require_text "一括リンク追加は行わない"
require_text "wiki/LLM Wiki.md"
require_text "links:"

printf '%s\n' "wiki-update guideline contract: PASS"
