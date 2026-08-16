#!/usr/bin/env bash
set -euo pipefail

skill=.claude/user-skills/wiki-update/SKILL.md

assert_contains() {
  local needle=$1
  if ! grep -Fq "$needle" "$skill"; then
    printf 'missing wiki deep-dive guideline: %s\n' "$needle" >&2
    exit 1
  fi
}

assert_contains '新規作成'
assert_contains '本文'
assert_contains '独立ノート'
assert_contains '深掘り候補'
assert_contains '書きますか'
assert_contains '分割'
assert_contains '自動作成しない'
assert_contains 'ユーザーの承認後'
assert_contains '候補の提示は提案に留め、深掘り候補のノート作成・分割・MOCは自動作成しない'
assert_contains '既存ページを分割した直後も、分割後の各本文を同じ観点で確認する'

printf 'wiki-update deep-dive contract: PASS\n'
