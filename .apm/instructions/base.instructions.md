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
- URL の取得には、実行環境で利用可能な Web 取得機能または `ax` CLI を使い、目的に合うものを選ぶ。`curl` や使い捨ての HTML 解析スクリプトは使わない。ページの探索、構造化抽出、未知の Web ページや API の調査には `/ax` スキルを使う。User-Agent を手動指定しない
- サブエージェントの起動は、ユーザーが明示的に依頼したときか、ユーザーが呼び出したスキルが手順として指示しているときに限る。モデルの判断で自動的に起動しない

## Codex CLIでのVisual Companion

- Codex CLIでbrainstormingのVisual Companionサーバーを起動するときは、`scripts/start-server.sh` を `on-request` の権限昇格付きで実行する。`exec_command` の `sandbox_permissions` に `require_escalated` を指定し、localhostポートのbindと `--open` によるブラウザ起動が必要な理由を説明する

## Codex CLIでの実行環境

- `bash -lc` や `zsh -lc` のようなネストしたログインシェルを使わず、`exec_command` からコマンドを直接実行する。ネストした非対話シェルではmacOSの`/usr/bin`がPATHの先頭に入り、mise管理のランタイムが隠れることがある
- Ruby、Node.jsなどmise管理のランタイムを使うコマンドは、`mise exec -- <command>` 経由で実行する
- ランタイムを使うテストやスクリプトの実行前に、`command -v <runtime>` と `<runtime> --version` で解決先とバージョンを確認する

## Herdrでの新しいエージェント起動

- `HERDR_ENV=1` のときは、Herdrの現在のworkspaceを使って新しいエージェントを起動する。新しいworkspaceは作成しない
- 起動前に現在のtabのpane数を確認する
- paneが1つなら、`herdr pane split --current --direction right --no-focus` で横方向に分割し、作成されたpaneで起動する
- paneが2つ以上なら、現在のworkspaceに `herdr tab create --workspace <workspace-id>` で新しいtabを作り、そのroot paneで起動する
- pane splitやtab createの結果から新しいpane IDを取得してから、`herdr pane run <pane-id> "<agent-command>"` でエージェントを起動する
- Herdr管理下でない場合は、通常の現在のターミナルで起動する
