---
name: vault-rag
description: Obsidian asonas vault（wiki / daily / notes / projects / bookmarks / books）を qmd で検索し、出典つきで回答する RAG スキル。ユーザーが「いつ〜した？」「〜ってどう解決したっけ」「ノートに書いてあるはず」「vault / wiki / 日報から探して」など、過去の自分の記録・知識ベースに答えがありそうな質問をしたとき、または /vault-rag として明示的に呼ばれたときに使う。
argument-hint: "<質問>"
---

# /vault-rag - Obsidian Vault RAG検索

qmd（collection `asonas`、vault 全体の `**/*.md` をインデックス済み）を retriever として、Obsidian vault から出典つきで回答する。vault は「wiki = 出典つき要約の派生レイヤ、daily / notes / activities = 一次ソース」という2層構造を持つため、検索も **wiki-first の2段階** で行う。

## 前提

- qmd 2.5+ がインストール済み。インデックスは `/today`（Step 9c）と `/wrapup`（Step 8b）で毎日差分更新される
- collection は `asonas`（`qmd://asonas/` = `/Users/asonas/Documents/asonas/`）
- vault の実ファイルは `qmd://asonas/<path>` を `/Users/asonas/Documents/asonas/<path>` に読み替えて Read ツールで読める

## 検索ワークフロー

### Step 1: クエリ設計

ユーザーの質問をそのまま `qmd query "..."` に貼らない。自分でクエリドキュメントを組み立てる。

```bash
qmd query $'intent: <ユーザーが本当に知りたいこと1文>\nlex: <固有名詞・Issue ID・コマンド名など正確な語>\nvec: <意味で探すための言い換え文>' -c asonas -n 8 --format files
```

- `lex:` にはリポジトリ名、ツール名、`AIEN-148` のような Issue ID、日本語の固有名詞を入れる。vault は固有名詞が多いので lex が効く
- `vec:` には「何が起きて何を知りたいか」を文で書く
- `intent:` は**検索クエリではない**。候補の取得は lex / vec / hyde の行だけが行い、出力の「N queries」にも intent は数えられない。ただしリランカーへの入力には含まれ、スコアと順位を動かす（実測確認済み）。リランキングを使うときだけ付ける意味がある
- Issue ID やファイル名など**正確な語が分かっている場合は BM25 で十分**。高速な `qmd search "<語>" -c asonas -n 10` を先に試す
- 速度が必要なら `--no-rerank` または `-C 20` で候補数を絞る（リランキングは10秒前後かかる）。**`--no-rerank` 時は intent: が完全に無視される**ので、intent 行は書かず lex / vec に情報を畳み込む

### Step 2: wiki-first 展開

検索結果を上から評価し、次の分岐で原文に降りる。

- **`wiki/` のページがヒットした場合（優先）**: そのページを Read で全文読む。wiki ページは frontmatter `sources:` に根拠ノートの wikilink（`[[daily/2026-07-02]]` 等）を必ず持つ。質問に対して日付・経緯・数値などの精度が必要なら、該当しそうな sources を 1〜3 件選んで原文（`daily/`, `notes/`, `activities/`）も Read する
- **wiki ヒットがない場合**: 上位の `daily/` / `notes/` ヒットを直接 Read する。同じトピックが複数日に散っていそうなら `qmd multi-get` でまとめて取る

スニペットだけで回答しない。事実・日付・引用・判断の経緯を答えるときは必ず全文を取得してから答える。

### Step 3: 出典つき回答

- 回答には必ず出典を添える。vault 相対パス（`daily/2026-07-02`、`wiki/karukan`、`notes/2026-07-03-herdr-agent-skill-apm` 等）で示す
- wiki の記述と一次ソースが食い違う場合は一次ソースを優先し、食い違いがあった事実も報告する（wiki の直し込みは `/wiki-update` の仕事であり、このスキルからは vault を書き換えない）
- 見つからなかった場合は正直に「vault に記録が見当たらない」と答える。推測で補完しない
- **リランクスコアの高さは「答えが存在する」ことの証拠にならない**。vault に記録がない話題でも、語彙が近いだけの無関係ノートに 0.8 以上が付くことがある（実測済み）。全文を読んで質問に答えられる内容かを必ず確認し、合わなければヒットなしとして扱う。セッション中の出来事は vault ではなく Claude Code の auto-memory 側にしか残っていない場合もある

## ソース層ごとの扱い

- `wiki/`: 出典つき要約。概要質問はここで完結してよいが、精密な事実は sources に降りる
- `daily/` / `activities/` / `notes/` / `projects/`: 一次ソース（ground truth）
- `bookmarks/` / `books/`: 他者のテキストの逐語取り込み。**「自分が何をしたか」系の質問では無視してよい**。ヒットを使う場合は「ブックマークした記事によると」のように自分の記録と区別して示す
- `coaching/` / `1on1/` / `evaluations/`: センシティブ寄り。質問が明確にこの領域を指すときだけ参照する

## 鮮度の注意

インデックスは `/today` と `/wrapup` のタイミングでしか更新されない。**当日の出来事**を聞かれたら、qmd に頼らず今日の `daily/YYYY-MM-DD.md` と `activities/YYYY-MM-DD.md` を直接 Read する。検索結果が古い気がする場合は `qmd update && qmd embed` を実行してから引き直してよい（差分更新なので低コスト）。

## 注意

- このスキルは読み取り専用。vault への書き込み・修正は行わない
- 回答スタイルは通常の会話ルールに従う（日本語、簡潔、出典明示）
- `qmd query` の初回実行はモデルロードで数秒〜十数秒かかることがある。タイムアウトは 120 秒を目安に設定する
