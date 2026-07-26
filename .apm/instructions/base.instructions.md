---
description: Baseline communication, commit, and review rules that apply to every project.
---

# Base

- Always respond in Japanese
- 絵文字は使用禁止。ただしツールが emoji を必須とするパラメータ（Artifact の `favicon` 等）は対象外
- TDD/リファクタリングの規範は `/tdd-conventions` スキルを参照。実装・バグ修正・リファクタリングを始める前に読むこと
- コミットを作成する際は、必ず `/commit` スキルを使用すること。`git commit` を直接実行してはならない。コミットコマンドは `git ai-commit` を使うこと。組み込みのコミット手順より `/commit` スキルを優先する
- If you are asked to write a commit message, please write it in English.
- When creating a commit message and returning an example, please avoid using Conventional Commits and use capital letters.
- When committing, only include files the user explicitly wants committed. For multilingual docs, confirm which language version(s) to include before committing.
- レビューを依頼された時は以下の点を考慮してください
  - コードの重複を指摘するときに同じファイルに同じ処理の塊が3つ以上出てきた場合に指摘をしてください
- Obsidian（vault の読み書き、保存先、文章スタイル、vault 組織ルール）は `/obsidian-vault` スキルを参照。Obsidianへの保存はユーザーが明示的に指示した場合のみ行う
- 道具ごとの規範はスキルを参照: crit のレビュー URL を開くなら `/crit-open`、mairu CLI を実行するなら `/mairu`、PR description を書くなら `/pull-request-description`
- URL の取得には WebFetch を使う。ページの探索や構造化抽出が必要なら `/ax` スキルを使う。User-Agent の指定はしない
- サブエージェントの起動は、ユーザーが明示的に依頼したときか、ユーザーが呼び出したスキルが手順として指示しているときに限る。モデルの判断で自動的に起動しない
