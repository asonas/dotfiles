---
description: Obsidian workflow rules (CLI choice, writing style, link strategy) for personal note-taking.
---

# Obsidian

## 基本ルール
- Obsidianへの保存はユーザーが明示的に指示した場合のみ行う
- `/today` でdaily noteを作成、`/wrapup` で追記
- 作成した記事はObsidianの `daily/` 配下にある作業日の日報に記事のリンクを追記する
- リポジトリ名に紐付くMarkdownのドキュメントはObsidianから検索して読み取る
- Obsidianにドキュメントを書くよう指示がない場合はリポジトリで指示されているディレクトリに保存する

## ツール選択方針（2026-04-15 移行 / 2026-07-08 更新）
- **読み取り（read）は Read ツールで絶対パスを直読することを第一選択とする**。`/Users/asonas/Documents/asonas/<path>` を Read で開く。`obsidian read` / `obsidian daily:read` は **使わない**
  - 理由: `obsidian` CLI は Obsidian GUI 本体（Electron バイナリ）そのもので、GUI が起動していない瞬間に呼ぶと本体をヘッドレスで冷間起動しようとしてハングする（2026-07-08 に再現確認: exit 124、stderr に `IMKCFRunLoopWakeUpReliable` エラー）。GUI 起動中なら 0.25 秒で返るが、閉じている保証がないため read には使わない
- **書き込み（create / append）も Write / Edit ツールで絶対パスを直接編集することを推奨する**。`obsidian create` / `obsidian append` も同じ理由でハングし得る。Obsidian はファイルシステムの変更を自動検知するため、直接書けば GUI にも反映される
- `obsidian search` / `obsidian files` など Read/Write ツールで代替できない操作に限り `obsidian` CLI を使う。その場合も GUI が起動している前提でのみ確実に動く点に注意する
- 旧 `mcp-obsidian` (REST API依存) は廃止済み
- Vault は2つある: `asonas`（個人ノート / daily / 仕事メモ。path: `/Users/asonas/Documents/asonas/`）と `ason.as`（公開ブログ用。path: `/Users/asonas/ghq/github.com/asonas/ason.as/`）
- **`obsidian` コマンドを使う場合は `vault=<name>` を必ず明示すること**。省略するとアクティブな vault が使われ、daily note などが意図せず `ason.as` 側に作られる事故が起きる
- daily note / 個人ノート / 仕事関連は `vault=asonas`、ブログ記事は `vault=ason.as` を指定する
- stderr の "installer out of date" 警告は `2>/dev/null` で抑制してよい（stdoutは正常）
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
