---
name: linear-issue
description: Create Linear issues following the Linear Method principles. Use when the user wants to create an issue, task, or ticket in Linear. Enforces clear task descriptions instead of user stories.
argument-hint: "[description]"
allowed-tools: mcp__claude_ai_Linear__list_teams, mcp__claude_ai_Linear__list_issues, mcp__claude_ai_Linear__save_issue, mcp__claude_ai_Linear__list_issue_labels, mcp__claude_ai_Linear__list_issue_statuses, mcp__claude_ai_Linear__list_projects, mcp__claude_ai_Linear__list_cycles
user-invocable: true
context: fork
---

# Linear Issue Skill

Linear Methodの原則に基づいてLinearのイシューを作成する。

## 基本原則: ユーザーストーリーではなくイシューを書く

Linear Methodはユーザーストーリー形式（「As a user, I want...」）をアンチパターンとして明確に否定している。
代わりに、具体的なタスクを簡潔に記述したイシューを作成する。

参照: ~/workspace/linear-methods/report.md

## イシュー作成ルール

### タイトル
- 具体的なタスクを短く直接的に記述する
- リストやボード上でスキャンしやすい長さにする（目安: 50文字以内）
- 動詞で始める（Add, Fix, Update, Remove, Implement など）
- ユーザーストーリー形式は禁止

### タイトルの良い例
- "Add password reset flow"
- "Fix timezone offset in event display"
- "Update billing page to show tax breakdown"
- "Remove deprecated API v1 endpoints"

### タイトルの悪い例
- "As a user, I want to reset my password so that I can regain access to my account"
- "User authentication improvements"（曖昧すぎる）
- "Bug"（情報がない）

### 説明（Description）
- 必須ではない。タイトルで十分なら省略してよい
- 書く場合は必要最小限のコンテキストのみ含める
- ユーザーフィードバックがある場合は要約せず直接引用する
- 関連するリンク（PR、Figma、Slack スレッドなど）があれば含める

### 分類: イネーブラー vs ブロッカー
イシュー作成時に、以下の分類を意識する:
- **Enabler**: 新しい機能を追加し、プロダクト価値を高めるもの
- **Blocker**: ユーザーの利用を妨げる摩擦やギャップを解消するもの

### スコープ
- 1イシューは1つの具体的なタスクに対応する
- 数時間から数日で完了できる粒度にする
- 大きすぎる場合はサブイシューに分解する

## 手順

### 1. ユーザーからの入力を受け取る

ユーザーが以下のいずれかの形式で入力する:
- チーム指定あり（例: 「Appチームに: ログイン画面にパスワードリセットを追加したい」）
- チーム指定なし（例: 「ログイン画面にパスワードリセットを追加したい」）
- 具体的なタスク記述
- バグ報告
- 機能リクエスト

### 2. チームを決定する

以下の優先順位でチームを決定する:

**A. 直接指定がある場合**
ユーザーがチーム名を明示していれば（例: 「Appチームに」「Foundationで」）、そのチームを使用する。
部分一致でもよい（例: 「App」→「App Development」）。

**B. 直接指定がない場合 -- 内容から推測する**
イシューの内容に含まれるキーワードからチームを推測し、上位2-3個を提案する。
推測の根拠も簡潔に示す。

推測のヒント:
- アプリ/モバイル関連 → App, App Development
- AI/機械学習関連 → AI Dialogue, AI Ops, AI Enablement
- インフラ/データ基盤 → Data Engineering, Data Infrastructure, Foundation
- デザイン関連 → Design Group, Design Guideline
- 社内IT/セキュリティ → Corp IT
- 対話/コミュニケーション → Dialogue, Dialogue Group
- サイト関連 → SiteRenewal
- QA/テスト → QA

提案例:
```
チーム候補:
1. App Development（アプリのログイン機能に関連するため）
2. Foundation（認証基盤に関連する可能性）
→ どちらに作成しますか？ または別のチームを指定してください。
```

**C. 推測が困難な場合**
「どのチームに作成しますか？」と直接聞く。
その際、全チーム一覧は出さず、関連しそうなチームがあればいくつか挙げる程度にとどめる。

### 3. イシュー内容を整理する

ユーザーの入力から以下を抽出・整理する:
- タイトル（短く、動詞始まり、具体的）
- 説明（必要な場合のみ）
- 優先度の示唆（Urgent / High / Medium / Low / No priority）
- ラベルの候補（Bug, Feature, Improvement など）

### 4. ユーザーに確認する

作成前に以下を提示して確認を取る:

```
Team: [チーム名]
Title: [タイトル]
Description: [説明（あれば）]
Priority: [優先度の提案]
Label: [ラベルの提案]
```

### 5. Linear MCPでイシューを作成する

ユーザーの承認後、Linear MCPツールを使ってイシューを作成する。

### 6. 作成結果を報告する

作成したイシューのタイトルとURLを報告する。

## バリデーションチェックリスト

イシュー作成前に以下を確認する:

- [ ] タイトルがユーザーストーリー形式になっていないか
- [ ] タイトルが具体的で、スキャン可能な長さか
- [ ] 1つのイシューが1つのタスクに対応しているか
- [ ] スコープが数時間〜数日で完了可能な粒度か
- [ ] 説明に不要な情報が含まれていないか

## 複数イシューの一括作成

大きな機能要件が与えられた場合:

1. まずスコープを分解してイシュー一覧を提示する
2. 各イシューが独立して完了可能な粒度であることを確認する
3. ユーザーの承認後に一括作成する
4. 必要に応じてプロジェクトやサイクルへの紐付けを提案する
