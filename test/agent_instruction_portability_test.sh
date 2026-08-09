#!/bin/bash
set -eu

instruction_files='
.apm/instructions/base.instructions.md
.apm/instructions/shell.instructions.md
'

if grep -En 'WebFetch|Write ツール|Edit ツール|Bash ?ツール|Bash tool|Claude Code設定ファイル' $instruction_files; then
    echo "expected agent instructions not to depend on Claude Code tool names" >&2
    exit 1
fi

grep -q '実行環境で利用可能な Web 取得機能' .apm/instructions/base.instructions.md
grep -q '`ax` CLI' .apm/instructions/base.instructions.md
grep -q '/ax.*スキル' .apm/instructions/base.instructions.md
grep -q 'Codex CLIでbrainstormingのVisual Companionサーバーを起動するとき' .apm/instructions/base.instructions.md
grep -q 'sandbox_permissions.*require_escalated' .apm/instructions/base.instructions.md
