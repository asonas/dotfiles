---
name: raindrop-sync
description: Sync Raindrop.io bookmarks into the asonas Obsidian vault under bookmarks/, one markdown file per bookmark with frontmatter metadata and defuddle-extracted page content. Use when invoked as `/raindrop-sync`, called from `/morning`, or when the user asks to import / refresh raindrop bookmarks into Obsidian.
argument-hint: "[--full | --since YYYY-MM-DD | --collection ID | --dry-run]"
disable-model-invocation: true
---

# /raindrop-sync - Raindrop -> Obsidian Bookmarks Sync

Raindrop.io API から取得したブックマークを `~/Documents/asonas/bookmarks/` に 1 ファイル 1 ブックマークの markdown として書き出すスキルです。各ファイルは raindrop_id を名前に持ち、frontmatter にメタデータ、本文に defuddle で抽出した記事本文を含みます。

karpathy の "LLM Wiki" 3 層モデルで言う **Raw Sources 層の拡張**です。daily / notes / essays に並ぶ第 4 のソースとして `/wiki-update ingest` から参照されます。

## 前提

- token: `~/.config/raindrop/token` にプレーンファイル（perms 600）で保存されていること。raindrop の test token は https://app.raindrop.io/settings/integrations で発行する
- defuddle: node 経由でインストール済み（`which defuddle` で確認）
- ruby: 4.x で動作確認済み（標準ライブラリのみ使用、外部 gem 不要）
- 出力先: `~/Documents/asonas/bookmarks/` (`/Users/asonas/Documents/asonas/bookmarks/`)
- 同期状態: `~/Documents/asonas/bookmarks/.last_sync` に最終同期時刻が ISO 8601 で書かれる

## 起動方法

スキルから呼ぶ場合は内部の Ruby スクリプトを Bash で起動します:

```
/Users/asonas/ghq/github.com/asonas/dotfiles/.claude/user-skills/raindrop-sync/raindrop-sync.rb [options]
```

### オプション

```
（引数なし）             # 前回 sync 以降の更新のみ取得（インクリメンタル）
--full                  # last_sync を無視して全件取得
--since YYYY-MM-DD      # lastUpdate のロワーバウンドを明示
--collection ID         # 特定 collection のみ (デフォルトは 0 = 全件)
--dry-run               # 書き込みせずに対象を表示
```

## 動作

1. `~/.config/raindrop/token` を読み込み Bearer トークンとして使用
2. `GET /raindrops/0?sort=-lastUpdate&search=lastUpdate:>{since}` でブックマークを取得（50 件 / ページでページング）
3. 各ブックマークについて:
   - `defuddle parse --md <url>` で本文を markdown 化（タイムアウト 30 秒）
   - frontmatter（raindrop_id, url, title, domain, collection, tags, saved, last_updated, last_synced, defuddle_status）+ 本文 + raindrop の excerpt / note / highlights を組み立て
   - `bookmarks/{raindrop_id}.md` に上書き保存
4. `bookmarks/.last_sync` を更新

## 出力ファイル書式

```yaml
---
type: bookmark
raindrop_id: 123456
url: "https://example.com/article"
title: "Article Title"
domain: example.com
collection: 0
tags:
  - llm
  - knowledge-base
saved: 2026-05-19T10:30:00.000Z
last_updated: 2026-05-20T08:15:00.000Z
last_synced: 2026-05-20T20:10:00Z
defuddle_status: ok
---

# Article Title

<https://example.com/article>

## Excerpt

raindrop が抽出した excerpt（無ければ省略）

## My Note

raindrop に書いた note（無ければ省略）

## Highlights

- raindrop で引いた highlight
  - note: 各 highlight に紐付いたメモがあれば

## Content

defuddle で抽出した本文 markdown
```

## エラー処理

- token 未設定: ファイルパスを案内して exit 1
- API 404/401/429: `Raindrop API <code>: <body>` で raise
- defuddle 失敗: 当該ブックマークは frontmatter の `defuddle_status: error: <理由>` を立て、本文セクションには `_(defuddle failed: ...)_` を書き込む。同期自体は止めない

## 既存ファイルとの関係

- 同じ raindrop_id のファイルは毎回上書き。手で編集した内容は失われる前提
- ブックマークを raindrop 側で削除した場合、vault からは消えない（ゴーストファイルとして残る）。整理は別途 `/wiki-update lint` で検出する想定

## /morning との連携

`/morning` Step 10 で wiki-update を呼ぶ前に raindrop-sync をインクリメンタル実行する:

```
Skill(raindrop-sync)         # 引数なし = 増分同期
Skill(wiki-update, args: "ingest yesterday")
```

これにより前日に raindrop 側で追加・編集したブックマークが当日の wiki ingest 対象に含まれる。

## 手動運用

```
# 初回フル同期（時間がかかる。全ブックマーク数 × defuddle）
raindrop-sync.rb --full

# 何件取得されるかだけ確認
raindrop-sync.rb --dry-run

# 特定 collection だけ
raindrop-sync.rb --collection 12345

# 過去 7 日分を強制再取得
raindrop-sync.rb --since $(date -v-7d +%Y-%m-%d)
```

## Vault 規約

`bookmarks/` ディレクトリは `dotfiles/.apm/instructions/obsidian-vault.instructions.md` の Directory Layout で「Raw Sources 層: raindrop からの自動同期。手編集禁止」と定義されている。手で書き換えると次回 sync で上書きされる。
