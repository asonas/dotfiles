#!/bin/bash
# find-recent-daily-notes.sh
#
# 直近の営業日のObsidian daily noteを探して日付(YYYY-MM-DD)を出力する。
#
# ルール:
# - 月曜日実行時: 金土日の3日分それぞれ存在するものを全て出力
# - それ以外の曜日: 前日から最大7日遡り、最初に見つかったdaily noteの日付を1件出力
# - どれも見つからなければ exit code 1
#
# 環境変数:
#   OBSIDIAN_VAULT: Obsidian vaultのルートパス (デフォルト: /Users/asonas/Documents/asonas)

set -u

VAULT_DIR="${OBSIDIAN_VAULT:-/Users/asonas/Documents/asonas}"
DAILY_DIR="$VAULT_DIR/daily"

if [ ! -d "$DAILY_DIR" ]; then
  echo "Error: daily directory not found: $DAILY_DIR" >&2
  exit 2
fi

TODAY_DOW=$(date +%u)  # 1=Mon ... 7=Sun

found=0

if [ "$TODAY_DOW" = "1" ]; then
  # 月曜日: 金(3日前)、土(2日前)、日(1日前) をそれぞれチェック
  for i in 3 2 1; do
    DATE=$(date -v-${i}d +%Y-%m-%d)
    if [ -f "$DAILY_DIR/$DATE.md" ]; then
      echo "$DATE"
      found=1
    fi
  done
else
  # 火〜日曜: 最大7日遡って最初に見つかった1日のみ出力
  for i in $(seq 1 7); do
    DATE=$(date -v-${i}d +%Y-%m-%d)
    if [ -f "$DAILY_DIR/$DATE.md" ]; then
      echo "$DATE"
      found=1
      break
    fi
  done
fi

if [ "$found" = "0" ]; then
  exit 1
fi
