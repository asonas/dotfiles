---
description: Obsidian workflow rules (CLI choice, writing style, link strategy) for personal note-taking.
---

# Obsidian

## 基本ルール
- Obsidianへの保存はユーザーが明示的に指示した場合のみ行う
- `/morning` でdaily noteを作成、`/wrapup` で追記
- 作成した記事はObsidianの `daily/` 配下にある作業日の日報に記事のリンクを追記する
- リポジトリ名に紐付くMarkdownのドキュメントはObsidianから検索して読み取る
- Obsidianにドキュメントを書くよう指示がない場合はリポジトリで指示されているディレクトリに保存する

## ツール選択方針（2026-04-15 移行済み）
- **Obsidian公式CLI (`obsidian` コマンド) を第一選択とする**。旧 `mcp-obsidian` (REST API依存) は廃止済み
- Vault は2つある: `asonas`（個人ノート / daily / 仕事メモ。path: `/Users/asonas/Documents/asonas/`）と `ason.as`（公開ブログ用。path: `/Users/asonas/ghq/github.com/asonas/ason.as/`）
- **すべての obsidian コマンドで `vault=<name>` を必ず明示すること**。省略するとアクティブな vault が使われ、daily note などが意図せず `ason.as` 側に作られる事故が起きる
- daily note / 個人ノート / 仕事関連は `vault=asonas`、ブログ記事は `vault=ason.as` を指定する
- 主要コマンド: `obsidian read vault=asonas path=...`, `obsidian append vault=asonas path=... content=...`, `obsidian create vault=asonas path=... content=...`, `obsidian search vault=asonas query=...`, `obsidian files vault=asonas folder=...`, `obsidian daily:read vault=asonas`
- stderr の "installer out of date" 警告は `2>/dev/null` で抑制してよい（stdoutは正常）
- **heading指定のinsertは公式CLI非対応**。特定セクション下への追記が必要な場合は Read + Edit ツールで `/Users/asonas/Documents/asonas/<path>` を直接編集する（Obsidianはファイルシステムの変更を自動検知する）
- daily note に `# YYYY-MM-DD` 等の h1 ヘッディングを追加しない（ファイル名がタイトルになるため重複する）

## 文章スタイル
Obsidianに記事を書く際は、以下のスタイルで書くこと:
- 文体は冷静で論理的にし、感情的・扇動的な表現は避ける
- 無駄な改行やぶつ切りの短文を避け、意味段落を意識する
- 各段落は、主題文とそれを補助する説明文から構成する
- 語彙は高校生が理解できる水準にする
- 句構造文法を意識し、主語と述語、係り受けを明確にする
- 箇条書きは使わず、散文（地の文）で書く
- です・ます調で書く

## リンク戦略（Graph View対応）
Obsidianの記事を書く際は、以下のハイブリッド戦略でwikiリンク `[[...]]` を付与する:

**Step 1: 既存ノートとのマッチング**
記事を書く前に Obsidian 公式CLI (`obsidian search vault=asonas query="..."` / `obsidian files vault=asonas folder="..."`) でvault内の既存ノートタイトルを把握し、本文中に一致する語が出現したらリンクにする。

**Step 2: 重要な未作成ノートへのスタブリンク**
既存ノートがなくても、以下のカテゴリに該当する語はスタブリンク `[[語]]` を張る（Obsidianは未作成ノートもGraph Viewに表示する）:
- プロジェクト名・リポジトリ名（例: `[[asonas/dotfiles]]`）
- 技術用語（ツール名、プロトコル名、フレームワーク名など。例: `[[USB Gadget]]`, `[[WirePlumber]]`）
- 人名（例: `[[t-wada]]`）
- 自分が繰り返し参照する概念（例: `[[TDD]]`, `[[iAP通信]]`）

**リンクにしないもの:**
- 一般的すぎる名詞（「ファイル」「設定」「問題」など）
- 文脈に依存しすぎて単独ノートにならない語
- 1回しか出現せず、今後も参照されなさそうな固有名詞

**注意:** 同一記事内で同じリンクが複数回出現する場合、初出のみリンクにする。

vault組織ルールは `obsidian-vault.instructions.md` を参照。
