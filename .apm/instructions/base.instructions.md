---
description: Baseline communication, commit, and review rules that apply to every project.
---

# Base

- Always respond in Japanese
- When you write a Markdown file, run `mdroll-in-herdr <file>` to open it in a Herdr pane and preview it.
- 絵文字は使用禁止。ただしツールが emoji を必須とするパラメータ（Artifact の `favicon` 等）は対象外
- 要求された変更に先立って振る舞いを変えない構造整理が必要な場合だけ、`/tidy-first-conventions` スキルを参照する
- If you are asked to write a commit message, please write it in English.
- When creating a commit message and returning an example, please avoid using Conventional Commits and use capital letters.
- When committing, only include files the user explicitly wants committed. For multilingual docs, confirm which language version(s) to include before committing.
- レビューを依頼された時は以下の点を考慮してください
  - コードの重複を指摘するときに同じファイルに同じ処理の塊が3つ以上出てきた場合に指摘をしてください
- Obsidian（vault の読み書き、保存先、文章スタイル、vault 組織ルール）は `/obsidian-vault` スキルを参照。Obsidianへの保存はユーザーが明示的に指示した場合のみ行う
- 道具ごとの規範はスキルを参照: mairu CLI を実行するなら `/mairu`、PR description を書くなら `/pull-request-description`
- URL の取得には、実行環境で利用可能な Web 取得機能または `ax` CLI を使い、目的に合うものを選ぶ。`curl` や使い捨ての HTML 解析スクリプトは使わない。ページの探索、構造化抽出、未知の Web ページや API の調査には `/ax` スキルを使う。User-Agent を手動指定しない
- サブエージェントの起動は、ユーザーが明示的に依頼したときか、ユーザーが呼び出したスキルが手順として指示しているときに限る。モデルの判断で自動的に起動しない

## Bettr Issue updates

- When the conversation explicitly identifies an active bettr Issue as `project#number`, apply the bettr skill's conversation-update and status-review policies before finalizing a response. Never infer an Issue number. Autonomous changes are limited to comments and the narrowly defined status transitions in the bettr skill; do not change other Issue fields without explicit user instruction.

## 知識・事実の確認

- 事実や知識を問う質問（聞き覚えのない単語・固有名詞だけでなく、記憶で答えられそうな一般的な質問も含む）には、憶測や記憶だけで即答せず、回答前に少なくとも1回は Web検索・Web取得機能で裏取りする。検索結果を回答の根拠として扱い、情報の鮮度や一次情報の有無も確認する。
- 検索しても自信の持てる結果に辿り着けない場合、最初に想定したジャンルへ検索語を狭めたまま再検索し続けない。まずジャンルの決め打ち自体を疑い、固有名詞そのものだけで検索する、複数ジャンルにまたがる中立的な語を使うなど、検索語を広げて調べ直す。それでも裏取りできない内容は、確定した事実として答えず不確実性を明示する。

## 医療情報の確認

- 病気・症状・治療法などの医療トピックでは、厚生労働省および関連する国内の公的機関（薬剤の承認・適応はPMDAを含む）、e-ヘルスネットの情報を優先的な情報源として重視する。国内の医療制度、診断基準、治療方針、薬剤の承認・扱いに関わる内容は、日本国内の公的情報と突き合わせる。
- NIH/PMCなどの海外医学文献は、病態生理など国際的に共通する内容の裏取りに使ってよい。ただし海外文献の記述を、日本国内の診断・治療・薬剤の運用としてそのまま扱わず、国内情報で確認できない部分は不確実性を明示する。

# Scope and YAGNI

- 明示された要求と、その要求を満たすために必要な変更だけを実装する
- 将来の利用を想定した抽象化、設定項目、拡張ポイント、互換層を追加しない
- 依頼された変更に不要な近接コードの整理やリファクタリングを行わない
- 新しい抽象化は、現在の変更で複数の具体的な利用箇所があり、既存の重複基準にも該当する場合に限る
- 要求を満たし、関連する検証が通った時点で作業を終了する
- 改善候補が現在の要求に不要なら実装せず、ユーザーの判断に必要な場合だけ報告する

# Testing Scope

- 変更された振る舞いを実証する最小のテストだけを追加する
- 明示された要件、既存の再現ケース、確認された不具合から直接導けないテストは追加しない
- 既存テストで変更を十分に検証できる場合は、新しいテストを追加しない
- Red-Green中は対象に近いテストを実行する。全テストは、影響範囲が広い場合、またはリポジトリやCIが要求する場合に実行する
- ドキュメントや振る舞いを変えない設定変更のために、意味のないテストを作成しない

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
