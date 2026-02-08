# テストガイド

SuperClaudeプロジェクトのテストスイートです。

## 構成

### Unit Tests（単体テスト）
`tests/unit/` - 個別コンポーネントのテスト
- テンプレート検証ロジック
- パラメータバリデーション
- ヘルパー関数

### Integration Tests（統合テスト）
`tests/integration/` - エンドツーエンドテスト
- LocalStackを使ったAWS操作
- スキルの実行テスト
- テンプレートの統合テスト

## 実行方法

### すべてのテストを実行
```bash
./tests/run-all-tests.sh
```

### 単体テストのみ
```bash
./tests/run-unit-tests.sh
```

### 統合テストのみ（LocalStack必須）
```bash
# LocalStackを起動
docker-compose up -d localstack

# テスト実行
./tests/run-integration-tests.sh
```

## テスト要件

### 単体テスト
- 依存関係なし
- 高速実行（< 10秒）
- モックデータ使用

### 統合テスト
- LocalStack必須
- AWS CLI / Azure CLI
- jq, yq

## テストカバレッジ目標

- スキルスクリプト: 80%以上
- テンプレート検証: 100%
- 重要なユーティリティ関数: 90%以上
