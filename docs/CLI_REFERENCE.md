# CLI リファレンス

SuperClaudeのコマンドラインツールの完全なリファレンスです。

## 目次

- [execute-template.sh](#execute-templatesh)
- [setup-localstack.sh](#setup-localstacksh)
- [テストツール](#テストツール)
- [ユーティリティ](#ユーティリティ)

---

## execute-template.sh

テンプレートを実行するメインCLIツール。

### 概要

```bash
./scripts/execute-template.sh [OPTIONS]
```

### オプション

| オプション | 必須 | 説明 | デフォルト |
|-----------|------|------|-----------|
| `--provider` | ✓ | クラウドプロバイダー (`aws`\|`azure`) | - |
| `--template` | ✓ | テンプレートパス | - |
| `--action` | ✓ | 実行するアクション | - |
| `--params` | | パラメータファイル（JSON） | - |
| `--environment` | | 環境 (`local`\|`prod`) | `local` |
| `--dry-run` | | コマンド表示のみ（実行しない） | `false` |
| `--validate-only` | | 検証のみ実行 | `false` |
| `--output` | | 出力形式 (`json`\|`yaml`\|`table`) | `json` |
| `--help` | | ヘルプメッセージ表示 | - |

### アクション

| アクション | 説明 |
|-----------|------|
| `create` | リソース作成 |
| `delete` | リソース削除 |
| `query` | リソース情報取得 |
| `configure` | リソース設定変更 |

### 使用例

#### 基本的な使用

```bash
# S3バケット作成（LocalStack）
./scripts/execute-template.sh \
  --provider aws \
  --template templates/aws/storage/s3.yaml \
  --action create \
  --params params/s3-bucket.json \
  --environment local
```

#### パラメータファイルの例

```json
{
  "bucket_name": "my-test-bucket-12345",
  "region": "us-east-1",
  "versioning": true,
  "public_access_block": true,
  "tags": {
    "Environment": "Development",
    "Project": "SuperClaude"
  }
}
```

#### Dry-runモード

```bash
# コマンド確認のみ（実行しない）
./scripts/execute-template.sh \
  --provider aws \
  --template templates/aws/compute/ec2.yaml \
  --action create \
  --params params/ec2.json \
  --dry-run
```

**出力例**:
```
[DRY-RUN] 以下のコマンドが実行されます:

aws ec2 run-instances \
  --image-id ami-0c55b159cbfafe1f0 \
  --instance-type t2.micro \
  --region us-east-1 \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=test-instance}]' \
  --endpoint-url http://localhost:4566 \
  --output json
```

#### 検証のみ

```bash
# テンプレートとパラメータの検証
./scripts/execute-template.sh \
  --provider azure \
  --template templates/azure/compute/vm.yaml \
  --action create \
  --params params/vm.json \
  --validate-only
```

**出力例**:
```json
{
  "validation": "passed",
  "template": "templates/azure/compute/vm.yaml",
  "checks": [
    "YAML syntax: OK",
    "Required parameters: OK",
    "Parameter types: OK",
    "Parameter constraints: OK"
  ]
}
```

#### 本番環境での実行

```bash
# Azure VMを本番環境に作成
./scripts/execute-template.sh \
  --provider azure \
  --template templates/azure/compute/vm.yaml \
  --action create \
  --params params/production-vm.json \
  --environment prod
```

#### 出力形式の変更

```bash
# YAML形式で出力
./scripts/execute-template.sh \
  --provider aws \
  --template templates/aws/compute/ec2.yaml \
  --action query \
  --params params/ec2-query.json \
  --output yaml

# テーブル形式で出力
./scripts/execute-template.sh \
  --provider aws \
  --template templates/aws/storage/s3.yaml \
  --action query \
  --output table
```

### エラーハンドリング

```bash
#!/bin/bash

set -e  # エラー時に停止

# execute-template.sh実行
if ./scripts/execute-template.sh \
  --provider aws \
  --template templates/aws/storage/s3.yaml \
  --action create \
  --params params/s3.json; then
  echo "成功"
else
  echo "失敗: 終了コード $?" >&2
  exit 1
fi
```

### 環境変数

スクリプトは以下の環境変数を参照します:

```bash
# AWS（LocalStack）
export AWS_ENDPOINT_URL=http://localhost:4566
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1

# Azure
# az login で認証済みであれば不要

# デバッグモード
export DEBUG=1  # 詳細ログ出力
```

---

## setup-localstack.sh

LocalStackのセットアップスクリプト。

### 概要

```bash
./scripts/setup-localstack.sh [OPTIONS]
```

### オプション

| オプション | 説明 | デフォルト |
|-----------|------|-----------|
| `--start` | LocalStackを起動 | - |
| `--stop` | LocalStackを停止 | - |
| `--restart` | LocalStackを再起動 | - |
| `--status` | ステータス確認 | - |
| `--logs` | ログ表示 | - |
| `--clean` | データクリーンアップ | - |

### 使用例

#### LocalStack起動

```bash
# 起動
./scripts/setup-localstack.sh --start

# 起動確認
./scripts/setup-localstack.sh --status
```

**出力例**:
```
✓ LocalStack is running
  Container ID: abc123def456
  Ports: 0.0.0.0:4566->4566/tcp
  Services: s3,ec2,lambda,dynamodb,cloudformation,iam,sts
```

#### ログ確認

```bash
# 最新100行
./scripts/setup-localstack.sh --logs

# リアルタイム表示
./scripts/setup-localstack.sh --logs --follow
```

#### データクリーンアップ

```bash
# LocalStackのデータを削除して再起動
./scripts/setup-localstack.sh --clean
```

**警告**: すべてのLocalStackデータが削除されます

#### 完全な再起動

```bash
# 停止 → クリーンアップ → 起動
./scripts/setup-localstack.sh --stop
./scripts/setup-localstack.sh --clean
./scripts/setup-localstack.sh --start
```

---

## テストツール

### run-all-tests.sh

すべてのテストを実行。

```bash
./tests/run-all-tests.sh
```

**出力例**:
```
========================================
SuperClaude Test Suite
========================================

1. Running Unit Tests...
----------------------------------------
✓ Unit tests completed successfully

2. Running Integration Tests...
----------------------------------------
✓ Integration tests completed successfully

========================================
Final Test Summary
========================================
✓✓ All tests passed! ✓✓
```

### run-unit-tests.sh

単体テストのみ実行。

```bash
./tests/run-unit-tests.sh
```

依存関係: なし（標準Bashコマンドのみ）

### run-integration-tests.sh

統合テストのみ実行。

```bash
./tests/run-integration-tests.sh
```

依存関係:
- LocalStack（起動済み）
- AWS CLI
- curl

---

## ユーティリティ

### jq によるJSON処理

SuperClaudeの出力をjqで処理:

```bash
# リソースIDの抽出
OUTPUT=$(./skills/provision/provision.sh <<< "$INPUT_JSON")
RESOURCE_ID=$(echo "$OUTPUT" | jq -r '.data.resource_id')

# ステータスチェック
STATUS=$(echo "$OUTPUT" | jq -r '.status')
if [ "$STATUS" = "success" ]; then
  echo "成功"
fi

# 複数フィールド抽出
echo "$OUTPUT" | jq -r '.data | "\(.resource_id) - \(.resource_type)"'
```

### パラメータファイル生成

```bash
# Heredocでパラメータファイル作成
cat > params/my-ec2.json <<EOF
{
  "instance_name": "my-instance",
  "ami_id": "ami-0c55b159cbfafe1f0",
  "instance_type": "t2.micro",
  "tags": {
    "Environment": "$(echo $ENVIRONMENT)",
    "Timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  }
}
EOF

# 使用
./scripts/execute-template.sh \
  --provider aws \
  --template templates/aws/compute/ec2.yaml \
  --action create \
  --params params/my-ec2.json
```

### バッチ実行

```bash
# 複数リソースを順次作成
for instance in web-1 web-2 web-3; do
  cat > params/temp-$instance.json <<EOF
{
  "instance_name": "$instance",
  "ami_id": "ami-0c55b159cbfafe1f0",
  "instance_type": "t2.micro"
}
EOF

  ./scripts/execute-template.sh \
    --provider aws \
    --template templates/aws/compute/ec2.yaml \
    --action create \
    --params params/temp-$instance.json

  # 次の実行まで待機
  sleep 2
done
```

### ラッパースクリプト例

```bash
#!/bin/bash
# my-deploy.sh - デプロイ自動化スクリプト

set -e

ENVIRONMENT="${1:-local}"

echo "デプロイ開始: $ENVIRONMENT"

# 1. 検証
echo "1. テンプレート検証..."
./skills/validate/validate.sh <<< '{
  "template": "aws/compute/ec2",
  "params": {...}
}'

# 2. VPC作成
echo "2. VPC作成..."
./scripts/execute-template.sh \
  --provider aws \
  --template templates/aws/network/vpc.yaml \
  --action create \
  --params params/vpc.json \
  --environment $ENVIRONMENT

# 3. EC2作成
echo "3. EC2インスタンス作成..."
./scripts/execute-template.sh \
  --provider aws \
  --template templates/aws/compute/ec2.yaml \
  --action create \
  --params params/ec2.json \
  --environment $ENVIRONMENT

echo "デプロイ完了"
```

---

## 高度な使用例

### 条件付き実行

```bash
#!/bin/bash

# 環境変数に応じて実行
if [ "$ENVIRONMENT" = "production" ]; then
  echo "本番環境へのデプロイ"
  read -p "続行しますか？ (yes/no): " confirm
  [ "$confirm" != "yes" ] && exit 1

  PARAMS="params/production.json"
else
  PARAMS="params/development.json"
fi

./scripts/execute-template.sh \
  --provider aws \
  --template templates/aws/compute/ec2.yaml \
  --action create \
  --params $PARAMS \
  --environment $ENVIRONMENT
```

### エラーリカバリー

```bash
#!/bin/bash

MAX_RETRIES=3
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
  if ./scripts/execute-template.sh \
    --provider aws \
    --template templates/aws/storage/s3.yaml \
    --action create \
    --params params/s3.json; then
    echo "成功"
    break
  else
    RETRY_COUNT=$((RETRY_COUNT + 1))
    echo "失敗。リトライ $RETRY_COUNT/$MAX_RETRIES"
    sleep 5
  fi
done

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
  echo "最大リトライ回数に達しました" >&2
  exit 1
fi
```

### ログ記録

```bash
#!/bin/bash

LOG_DIR="logs"
mkdir -p $LOG_DIR

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="$LOG_DIR/deploy_$TIMESTAMP.log"

# ログファイルとコンソール両方に出力
./scripts/execute-template.sh \
  --provider aws \
  --template templates/aws/compute/ec2.yaml \
  --action create \
  --params params/ec2.json 2>&1 | tee $LOG_FILE

echo "ログ: $LOG_FILE"
```

### パイプライン統合

```bash
#!/bin/bash
# CI/CD パイプライン例

# 1. テスト
./tests/run-all-tests.sh || exit 1

# 2. ステージング環境デプロイ
./scripts/execute-template.sh \
  --provider aws \
  --template templates/aws/compute/ec2.yaml \
  --action create \
  --params params/staging.json \
  --environment prod

# 3. 承認待機（手動）
echo "ステージング環境を確認してください"
read -p "本番デプロイを続行しますか？ (yes/no): " approval

if [ "$approval" = "yes" ]; then
  # 4. 本番環境デプロイ
  ./scripts/execute-template.sh \
    --provider aws \
    --template templates/aws/compute/ec2.yaml \
    --action create \
    --params params/production.json \
    --environment prod
fi
```

---

## トラブルシューティング

### デバッグモード有効化

```bash
# bashのデバッグモード
bash -x ./scripts/execute-template.sh [OPTIONS]

# または環境変数
export DEBUG=1
./scripts/execute-template.sh [OPTIONS]
```

### 詳細ログ出力

```bash
# AWS CLI詳細ログ
export AWS_DEBUG=1

# Azure CLI詳細ログ
export AZURE_CLI_DIAGNOSTICS=1
```

### 干渉する環境変数のクリア

```bash
# AWS関連
unset AWS_PROFILE
unset AWS_DEFAULT_REGION
unset AWS_ENDPOINT_URL

# すべてのAWS_*変数をクリア
for var in $(env | grep ^AWS_ | cut -d= -f1); do
  unset $var
done
```

---

## 関連ドキュメント

- [API_REFERENCE.md](API_REFERENCE.md) - Skills APIリファレンス
- [ARCHITECTURE.md](ARCHITECTURE.md) - システムアーキテクチャ
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - トラブルシューティング
- [CLAUDE.md](../CLAUDE.md) - プロジェクト概要
