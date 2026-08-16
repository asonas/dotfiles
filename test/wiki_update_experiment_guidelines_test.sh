#!/usr/bin/env bash
set -euo pipefail

skill=.claude/user-skills/wiki-update/SKILL.md

assert_contains() {
  local needle=$1
  if ! grep -Fq "$needle" "$skill"; then
    printf 'missing wiki experiment guideline: %s\n' "$needle" >&2
    exit 1
  fi
}

assert_contains '手を動かす実験'
assert_contains 'ネットワーク'
assert_contains 'カーネル'
assert_contains '実行する前'
assert_contains 'コマンド'
assert_contains 'デバイスやリソース'
assert_contains 'ユーザーの許可'
assert_contains '<topic>-experiment.md'
assert_contains '目的'
assert_contains '参照したリポジトリ'
assert_contains '躓いた点'
assert_contains '実行結果'
assert_contains 'コードから読み取れること'
assert_contains '再現可能'
assert_contains '単なる感想'
assert_contains '概念ノート側からリンク'
assert_contains '必ずユーザーの許可を得る。許可を得る前に'
assert_contains '単なる感想ではなく再現可能な記録にし'

printf 'wiki-update experiment contract: PASS\n'
