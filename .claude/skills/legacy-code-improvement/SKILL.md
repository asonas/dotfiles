---
name: legacy-code-improvement
description: レガシーコードを段階的に改善する。テスト自動化、モデルの分離、アーキテクチャの整理を通じて、保守性と拡張性の高いコードベースへ変換する。
---

# レガシーコード改善スキル

レガシーコードを段階的に改善し、テスタブルで保守しやすいコードへ変換します。

## 改善の実行順序

### 1. テスト自動化
- 既存の動作を確認するCharacterization Testから開始
- 簡単なテストから段階的にカバレッジを拡大
- Extract（抽出）とSprout（芽生え）テクニックでテスタブルな構造へ

### 2. モデルの分離
- ドメインロジックと技術的実装を分離
- 技術に依存しないコアドメインモデルを作成
- アダプターパターンで技術層とドメイン層を接続

### 3. アーキテクチャの整理
- 単一責任の原則に基づくレイヤー分離
- 依存関係の明確化と逆転
- インターフェースによる疎結合化

## TDD実践手順

### Red-Green-Refactorサイクル
1. **Red**: 失敗するテストを1つ書く
2. **Green**: テストを通す最小限のコードを実装
3. **Refactor**: テストを維持しながらコードを改善

### テスト作成の指針
- 振る舞いを説明する名前をつける（例: shouldCalculateTotalWithTax）
- 1つのテストで1つの振る舞いのみを検証
- Arrange-Act-Assertパターンを使用

## リファクタリングテクニック

### メソッドレベル
- Extract Method: 長いメソッドを分割
- Inline Method: 不要な間接層を削除
- Replace Temp with Query: 一時変数をメソッド呼び出しに置換

### クラスレベル
- Extract Class: 責任過多のクラスを分割
- Move Method: メソッドを適切なクラスへ移動
- Extract Interface: インターフェースを抽出して依存を緩和

### 依存性の改善
```javascript
// Before: 直接依存
class OrderService {
  process(order) {
    const db = new Database();
    const mailer = new EmailService();
    db.save(order);
    mailer.send(order.userEmail, 'Order confirmed');
  }
}

// After: 依存性注入
class OrderService {
  constructor(database, emailService) {
    this.database = database;
    this.emailService = emailService;
  }

  process(order) {
    this.database.save(order);
    this.emailService.send(order.userEmail, 'Order confirmed');
  }
}
```

## 実行時のアクション

このスキルを実行する際は以下の順序で進めます：

1. **現状分析**
   - ファイル構造とコードの複雑度を確認
   - 既存テストの有無と実行状況を確認
   - 主要な問題点と改善機会を特定

2. **改善計画の作成**
   - TodoWriteツールで段階的な改善タスクを作成
   - 各タスクは独立して実行可能な単位に分割
   - 優先度と依存関係を明確化

3. **TDDサイクルの実行**
   - 各機能に対してRed-Green-Refactorを実践
   - コミットは小さく頻繁に（構造変更と振る舞い変更を分離）
   - 常にテストが通る状態を維持

4. **段階的なアーキテクチャ改善**
   - ドメインロジックの抽出
   - 技術的関心事の分離
   - インターフェースによる疎結合化

## 品質チェックリスト

改善後のコードが満たすべき基準：
- [ ] 全テストが通る
- [ ] 単一責任の原則を守る
- [ ] 依存関係が明確
- [ ] テストしやすい構造
- [ ] 重複コードが最小限
- [ ] 名前が意図を明確に表現