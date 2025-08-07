#!/bin/bash

# csrutil statusコマンドの出力を取得
output=$(csrutil status 2>/dev/null)

# エラーチェック
if [ $? -ne 0 ]; then
    echo "SIP ❗"
    exit 0
fi

# 必要な条件をチェック
filesystem_disabled=$(echo "$output" | grep "Filesystem Protections: disabled")
debugging_disabled=$(echo "$output" | grep "Debugging Restrictions: disabled")
nvram_disabled=$(echo "$output" | grep "NVRAM Protections: disabled")

# 3つの条件が全て満たされているかチェック
if [[ -n "$filesystem_disabled" && -n "$debugging_disabled" && -n "$nvram_disabled" ]]; then
    echo "SIP✅"
else
    echo "SIP❗"
fi
