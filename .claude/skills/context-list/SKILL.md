---
name: context-list
description: List all saved contexts available for loading.
context: fork
---

# /context-list - List saved contexts

memory-vector に保存された context（`/context-save` で作成したもの）の一覧を表示する。

## Usage

```
/context-list
/context-list <project>    # プロジェクト名でフィルタ
```

Examples:
```
/context-list              # 全contextを最終更新順に表示
/context-list dotfiles     # sourceやtagsに "dotfiles" を含むcontextに絞る
```

## Instructions

このスキルが呼び出されたら以下の手順で実行する。

### 1. contextエントリの取得

`mcp__memory-vector__list_memories` を `tags: ["context"]` 指定で呼び出す。`list_memories` は最終更新の新しい順に並んでいる。

```
mcp__memory-vector__list_memories with tags: ["context"], limit: 50
```

引数でプロジェクト名（例: `dotfiles`）が指定された場合は、取得後にクライアント側で以下のいずれかに該当するエントリだけを残す:
- `tags` に指定名が含まれる
- `source` が指定名で始まる（`<project>/...` の形式）
- `metadata.project` が指定名と一致

### 2. 出力内容の整形

各エントリから以下を抽出する:
- **Name**: tagsの中で `context` 以外かつ project名以外のものの先頭、なければ source の `/` 以降
- **Project**: `metadata.project`、なければ source の `/` より前の部分
- **Updated**: `updatedAt` の日付部分（`YYYY-MM-DD`）
- **Tags**: `context` とproject名を除いた残りのtags（最大3つ）
- **Summary**: content先頭から1行抜粋（タイトル相当）

### 3. テーブルで提示

最終更新が新しい順に以下のテーブル形式で提示する。件数が多い場合は最新20件までにする。

```
Available Contexts (memory-vector に保存済み):

| Name | Project | Updated | Tags |
|------|---------|---------|------|
| auth-refactoring-plan | dotfiles | 2026-04-12 | auth, backend |
| api-migration-notes | my-app | 2026-04-10 | api, migration |

Load with: /context-load <name>
```

### 4. memory-vector が停止している場合

`list_memories` 呼び出しが失敗した場合は、そのままエラーを返さずに以下を表示してスキップする。

```
memory-vector が停止しているため context を取得できませんでした。
サービスを起動してから再試行してください（memory-infra の起動確認）。
```

### 5. 結果が空の場合

該当するcontextが見つからなかった場合:

```
保存済みのcontextはありません。
/context-save <name> で現在の調査内容を保存できます。
```

## Notes

- context の保存先は memory-vector（`/context-save` が使う）。Obsidianではない
- 一覧はsemantic検索ではなくtagベースのフィルタなので、部分一致で絞りたい場合は `/recall <query>` を使う
- contextに付与されるtagsは `["context", "<name>", "<relevant-tags>"]` の規約で保存されている
