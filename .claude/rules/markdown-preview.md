---
description: Preview Markdown files with mdv after writing them.
globs: "**/*.md"
---

# Markdown Preview

Markdownファイル（*.md）を Write ツールで新規作成または全体書き換えした後、`mdv` コマンドでプレビューをユーザに表示すること。

```bash
mdv /path/to/file.md
```

ただし以下の場合はプレビューを省略してよい:
- 連続して複数のMarkdownファイルを書き込む場合（最後の1つだけプレビュー）
- CLAUDE.md や MEMORY.md などのClaude Code設定ファイル
- 明らかに短い変更（Edit ツールでの部分編集）
