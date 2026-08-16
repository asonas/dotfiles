#!/usr/bin/env bash
set -euo pipefail

instructions=.apm/instructions/base.instructions.md

assert_contains() {
  local needle=$1
  if ! grep -Fq "$needle" "$instructions"; then
    printf 'missing knowledge research guideline: %s\n' "$needle" >&2
    exit 1
  fi
}

assert_contains '事実や知識を問う質問'
assert_contains 'Web検索・Web取得機能'
assert_contains '少なくとも1回'
assert_contains '憶測'
assert_contains 'ジャンル'
assert_contains '固有名詞そのもの'
assert_contains '検索語を広げ'
assert_contains '医療'
assert_contains '厚生労働省'
assert_contains 'PMDA'
assert_contains 'e-ヘルスネット'
assert_contains 'NIH/PMC'
assert_contains '診断基準'
assert_contains '薬剤'
assert_contains '回答前に少なくとも1回は Web検索・Web取得機能で裏取りする'
assert_contains '検索しても自信の持てる結果に辿り着けない場合'
assert_contains 'まずジャンルの決め打ち自体を疑い'
assert_contains '海外医学文献は、病態生理など国際的に共通する内容の裏取りに使ってよい。ただし'

printf 'knowledge research contract: PASS\n'
