---
description: GitHub CLI usage policy (gh for all operations; PR and repository creation are prohibited).
---

# GitHub CLI（gh）

- GitHub の操作には `gh` コマンドを使用すること
- `gh pr create` によるPR作成は禁止。PR は人間が作成する
- `gh repo create` によるリポジトリ作成は禁止
- この2つは機微な情報を外部に出す操作なので、エージェントが実行してはならない。必要な場合はコマンド案を提示するにとどめる
