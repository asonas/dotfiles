---
name: pull-request-description
description: GitHub の Pull Request の description を書くときに使う。リポジトリ固有の PR テンプレートに従わせるための手順を定める。`gh pr create` や /pull-request で PR 本文を組み立てる前に参照する。
---

# PR description を書く

PR description を書く際は、リポジトリに PR テンプレートが存在するか必ず確認し、存在する場合はそのテンプレートに従う。フォーマットを勝手に決めない。

確認する場所:

- `.github/pull_request_template.md`
- `.github/PULL_REQUEST_TEMPLATE.md`
- `.github/PULL_REQUEST_TEMPLATE/` 配下（複数テンプレート）

テンプレートのセクションは埋めるか、埋められない理由を書く。空欄のまま残さない。
