---
name: entire
description: "Entire CLIを使ってAIコーディングセッションの履歴を検索・確認する。コミットハッシュやチェックポイントを指定してセッションの説明や復元ができる。"
argument-hint: "<subcommand> [args]"
context: fork
---

# /entire - AIコーディングセッション履歴の検索・操作

Entire CLIを使って、過去のAIコーディングセッションの内容を確認・復元する。

## Usage

```
/entire explain [commit-hash]    # セッションの説明を生成
/entire rewind [options]         # チェックポイントの一覧・復元
/entire status                   # リポジトリのEntire状態を表示
/entire doctor                   # 問題のあるセッションを検出・修復
```

Examples:
```
/entire explain                  # 直近セッションの説明
/entire explain abc1234          # 特定コミットのセッション説明
/entire explain --full           # 詳細な説明を生成
/entire rewind --list            # チェックポイント一覧
/entire status                   # 現在の状態確認
/entire doctor                   # スタックしたセッションの修復
```

## Instructions

### 1. サブコマンドの判定

引数からサブコマンドを判定する:
- `explain` → セッション説明の生成
- `rewind` → チェックポイントの操作
- `status` → 状態表示
- `doctor` → セッション修復
- 引数なし → `entire status` を実行して状態を表示

### 2. サブコマンドの実行

#### explain

セッションの内容をAIで説明する。

```bash
# 直近セッション
entire explain --generate

# 特定コミットのセッション
entire explain --commit <hash> --generate

# 特定チェックポイント
entire explain -c <checkpoint> --generate

# 短い説明
entire explain --generate -s

# 詳細な説明
entire explain --generate --full

# 生のトランスクリプト
entire explain --commit <hash> --raw-transcript
```

- `--generate` フラグを付けるとAIによる説明が生成される
- コミットハッシュが指定された場合は `--commit <hash>` を付ける
- チェックポイント番号が指定された場合は `-c <number>` を付ける

#### rewind

チェックポイントの一覧表示・復元。

```bash
# チェックポイント一覧
entire rewind --list

# 特定チェックポイントに復元
entire rewind --to <checkpoint>

# ログのみ表示
entire rewind --logs-only

# リセット
entire rewind --reset
```

**注意**: `--to` による復元はファイルの変更を伴うため、実行前にユーザーに確認すること。

#### status

```bash
entire status
entire status --detailed
```

現在のリポジトリのEntire状態を表示する。

#### doctor

```bash
entire doctor
```

問題のあるセッション（1時間以上ACTIVEのまま等）を検出し、修復オプションを提示する。
修復アクション（condense/discard/skip）はユーザーに確認してから実行すること。

### 3. 結果の提示

- コマンドの出力をそのまま表示する
- explainの場合、セッションで何が行われたかを要約する
- 関連する記憶がmemory-vector/memory-graphにありそうな場合は `/recall` での追加検索を提案する

### 4. エラーハンドリング

- `entire` コマンドが見つからない場合: インストール方法を案内する
- リポジトリでEntireが有効でない場合: `entire enable` の実行を提案する
- セッションが見つからない場合: 別のコミットハッシュやブランチでの検索を提案する
