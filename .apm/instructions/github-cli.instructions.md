---
description: GitHub CLI usage policy (read via ghro, write via gh).
---

# GitHub CLI（gh / ghro）

- 読み取り操作（PR/issue/ファイル内容の取得など）には `ghro` コマンドを使用すること
- 書き込み操作（PR作成、issueコメント、マージなど）には通常の `gh` コマンドを使用すること
- `ghro` は読み取り専用トークンで認証されたラッパー（`~/bin/ghro`）
