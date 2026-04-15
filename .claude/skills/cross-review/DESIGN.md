# Cross-Model PR Review Skill - Design

このドキュメントは `cross-review` スキルの **設計意図** を記録する。実行手順は `SKILL.md` を正として参照すること。DESIGN.md には「なぜそうしたか」だけを書き、具体的なコマンドや出力フォーマットは重複させない。

## 問題意識

単一AIモデルによるPRレビューには盲点がある。見逃しやすい論点、モデル固有のバイアス（Claudeが保守的に指摘しすぎる／Cursorが楽観的に見過ぎる等）が存在するため、独立した2つのモデルで同一PRをレビューして比較すると、カバレッジが広がり判断の偏りが薄まる。

## 設計の核となるアイデア

**共有ドキュメントをステートとする。** メッセージパッシングで受け渡すのではなく、Obsidianのファイルを単一の正本として両モデルに追記させる。理由は以下:

1. **文脈の累積**: 会話履歴とは独立に、過去ラウンドの指摘が物理的に残る
2. **人間への可視性**: ラウンド毎の追記差分が見える。どちらのモデルが何を言ったか追跡可能
3. **再開可能性**: 途中で中断しても同じファイルから再開できる

## 民主的レビューの原則

この設計は「どちらかのモデルが勝つ」形を避ける。具体的には:

1. **No deference**: どちらも相手の指摘に自動的に同意しない
2. **Reasoned position changes**: 立場を変える場合は理由をドキュメントに残す
3. **Escalation over capitulation**: 2ラウンドで収束しなければ人間に判断を委ねる
4. **Equal presentation**: 最終サマリーに両者の視点を対等に残す
5. **Human as arbiter**: 未決定項目の最終判断は人間が下す

これらは `SKILL.md` の Reconciliation/Final Summary で具体化されている。

## Severityの4段階

`critical / major / minor / nit` の4段階は、**レビュー継続の閾値** を明確にするための設計。critical/major が残っている限り次ラウンドへ進み、minor/nit しかない状態は収束として扱う。段階がもっと細かいと収束判定が曖昧になり、粗いと「致命的ではないが見過ごせない」の扱いが難しくなる。

## 依存スキル

- `pr-review`: Claude Code側のレビュー観点（Correctness/Design/Security/Performance/Readability/Testing）を流用
- `cursor_review` MCP: Cursor側のレビュー実行
- `cursor_continue` MCP: Cursorとのフォロー対話
- Obsidian公式CLI + Read/Editツール: レビュー文書の読み書き。heading指定挿入が必要な場合は Read + Edit で vault ファイルを直接編集する（`/Users/asonas/Documents/asonas/reviews/...`）

## Obsidian統合の設計決定

**なぜObsidianを選んだか:**
- レビュー文書が後から検索可能な資産になる（`obsidian search` でPR横断検索）
- daily noteに自動リンクできるため、いつ何をレビューしたかが日報から辿れる
- Graph Viewで関連PRの可視化が可能

**なぜファイル名を `reviews/PR-{repo}-{number}.md` としたか:**
- Obsidian の wikilink で `[[PR-{repo}-{number}]]` と書きやすい
- ソートでプロジェクト毎にまとまる
- 将来のOKR/レポートで参照しやすい

## 制約と既知の限界

- Cursor側のモデル選択はスキルでは固定せず、Cursor MCPのデフォルトに従う（`composer-2` を基本とする）
- PR差分が非常に大きい場合（500行超）はファイル単位に分割して複数ラウンドに分ける必要がある
- cursor-agent サーバーが停止しているとCursor側のラウンドが実行できない。その場合はClaude Code単独レビューに縮退する選択肢もある（ただし本スキルの趣旨からは外れるため、基本はサーバー復旧を待つ）

## 具体的な手順

実行手順・コマンド・テンプレート・Severity定義・Reconciliation ルールはすべて `SKILL.md` に記載する。このファイルとの重複を避けるため、詳細はそちらを参照すること。
