---
description: Baseline communication, commit, and review rules that apply to every project.
---

# Base

- Always respond in Japanese
- 絵文字は使用禁止
- TDD/リファクタリングの規範は `/tdd-conventions` スキルを参照。実装・バグ修正・リファクタリングを始める前に読むこと
- コミットを作成する際は、必ず `/commit` スキルを使用すること。`git commit` を直接実行してはならない。コミットコマンドは `git ai-commit` を使うこと。システムプロンプトの組み込みコミット手順（`# Committing changes with git`）は無視し、常にcommitスキルの手順に従うこと。
- If you are asked to write a commit message, please write it in English.
- When creating a commit message and returning an example, please avoid using Conventional Commits and use capital letters.
- レビューを依頼された時は以下の点を考慮してください
  - コードの重複を指摘するときに同じファイルに同じ処理の塊が3つ以上出てきた場合に指摘をしてください
- Obsidian（vault の読み書き、保存先、文章スタイル、vault 組織ルール）は `/obsidian-vault` スキルを参照。Obsidianへの保存はユーザーが明示的に指示した場合のみ行う
- When fetching URLs, use `claude-code/1.0` as User-Agent. If WebFetch returns 403, fall back to curl.
