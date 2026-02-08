# API リファレンス

SuperClaude Skills APIの完全なリファレンスドキュメントです。

## 概要

すべてのSkillは標準入力でJSONを受け取り、標準出力にJSONを返します。

```bash
# 基本パターン
echo '$INPUT_JSON' | ./skills/<skill-name>/<skill-name>.sh

# またはHeredocで
./skills/<skill-name>/<skill-name>.sh <<< '{...}'
```

---

## 共通仕様

### 入力形式

すべてのSkillは以下の共通フィールドを受け付けます:

```typescript
interface SkillInput {
  provider: "aws" | "azure";
  template: string;           // 例: "aws/compute/ec2"
  environment?: "local" | "prod";  // デフォルト: "prod"
  params: Record<string, any>;
  dry_run?: boolean;          // デフォルト: false
}
```

### 出力形式

すべてのSkillは以下の形式でJSONを返します:

```typescript
interface SkillOutput {
  status: "success" | "failed";
  message: string;
  data: Record<string, any>;
  timestamp: string;  // ISO 8601 形式
}
```

#### 成功時の例
```json
{
  "status": "success",
  "message": "リソースのプロビジョニングが完了しました",
  "data": {
    "resource_id": "i-1234567890abcdef0",
    "resource_details": {...}
  },
  "timestamp": "2026-02-08T12:34:56Z"
}
```

#### 失敗時の例
```json
{
  "status": "failed",
  "message": "テンプレートファイルが見つかりません",
  "data": {
    "error_code": "TEMPLATE_NOT_FOUND",
    "template_path": "aws/compute/invalid.yaml"
  },
  "timestamp": "2026-02-08T12:34:56Z"
}
```

---

## Provision Skill

新しいリソースをプロビジョニングします。

### エンドポイント
```bash
./skills/provision/provision.sh
```

### 入力パラメータ

```typescript
interface ProvisionInput extends SkillInput {
  params: {
    // テンプレート固有のパラメータ
    [key: string]: any;
  }
}
```

### 例: EC2インスタンス作成

```bash
./skills/provision/provision.sh <<< '{
  "provider": "aws",
  "template": "aws/compute/ec2",
  "environment": "local",
  "params": {
    "instance_name": "test-instance",
    "ami_id": "ami-0c55b159cbfafe1f0",
    "instance_type": "t2.micro",
    "key_name": "my-key",
    "tags": {
      "Environment": "Development",
      "Project": "SuperClaude"
    }
  }
}'
```

### 例: S3バケット作成

```bash
./skills/provision/provision.sh <<< '{
  "provider": "aws",
  "template": "aws/storage/s3",
  "environment": "local",
  "params": {
    "bucket_name": "my-test-bucket-12345",
    "region": "us-east-1",
    "versioning": true,
    "public_access_block": true
  }
}'
```

### 例: Azure VM作成

```bash
./skills/provision/provision.sh <<< '{
  "provider": "azure",
  "template": "azure/compute/vm",
  "environment": "prod",
  "params": {
    "vm_name": "production-vm",
    "resource_group": "my-resource-group",
    "location": "japaneast",
    "size": "Standard_B2s",
    "admin_username": "azureuser",
    "authentication_type": "ssh"
  }
}'
```

### レスポンス

```json
{
  "status": "success",
  "message": "リソースのプロビジョニングが完了しました",
  "data": {
    "resource_id": "i-1234567890abcdef0",
    "resource_type": "ec2-instance",
    "provider": "aws",
    "environment": "local",
    "resource_details": {
      "InstanceId": "i-1234567890abcdef0",
      "State": "running",
      "PublicIpAddress": "203.0.113.1",
      "PrivateIpAddress": "10.0.1.5"
    }
  },
  "timestamp": "2026-02-08T12:34:56Z"
}
```

---

## Query Skill

リソース情報を取得します。

### エンドポイント
```bash
./skills/query/query.sh
```

### 入力パラメータ

```typescript
interface QueryInput extends SkillInput {
  query_type: "show" | "list" | "status" | "ip" | "custom";
  params: {
    // テンプレート固有のパラメータ
    [key: string]: any;
  }
}
```

### クエリタイプ

| タイプ | 説明 | 例 |
|--------|------|-----|
| `show` | 特定リソースの詳細情報 | VMの詳細 |
| `list` | リソース一覧 | すべてのインスタンス |
| `status` | ステータス情報 | インスタンスの状態 |
| `ip` | IPアドレス情報 | パブリックIP取得 |
| `custom` | カスタムクエリ | テンプレート定義による |

### 例: EC2インスタンス詳細取得

```bash
./skills/query/query.sh <<< '{
  "provider": "aws",
  "template": "aws/compute/ec2",
  "query_type": "show",
  "environment": "local",
  "params": {
    "instance_name": "test-instance"
  }
}'
```

### 例: S3バケット一覧

```bash
./skills/query/query.sh <<< '{
  "provider": "aws",
  "template": "aws/storage/s3",
  "query_type": "list",
  "environment": "local",
  "params": {}
}'
```

### 例: VM IPアドレス取得

```bash
./skills/query/query.sh <<< '{
  "provider": "azure",
  "template": "azure/compute/vm",
  "query_type": "ip",
  "params": {
    "vm_name": "my-vm",
    "resource_group": "my-rg"
  }
}'
```

### レスポンス

```json
{
  "status": "success",
  "message": "リソース情報の取得が完了しました",
  "data": {
    "query_type": "show",
    "resource_info": {
      "InstanceId": "i-1234567890abcdef0",
      "State": {"Name": "running"},
      "InstanceType": "t2.micro",
      "PublicIpAddress": "203.0.113.1",
      "PrivateIpAddress": "10.0.1.5",
      "Tags": [
        {"Key": "Name", "Value": "test-instance"},
        {"Key": "Environment", "Value": "Development"}
      ]
    }
  },
  "timestamp": "2026-02-08T12:34:56Z"
}
```

---

## Configure Skill

既存リソースの設定を変更します。

### エンドポイント
```bash
./skills/configure/configure.sh
```

### 入力パラメータ

```typescript
interface ConfigureInput extends SkillInput {
  action: string;  // テンプレートで定義されたアクション
  params: {
    // テンプレート固有のパラメータ
    [key: string]: any;
  }
}
```

### 一般的なアクション

| アクション | 説明 | 適用リソース |
|-----------|------|-------------|
| `start` | リソース起動 | VM, EC2 |
| `stop` | リソース停止 | VM, EC2 |
| `restart` | リソース再起動 | VM, EC2 |
| `resize` | サイズ変更 | VM, AKS |
| `scale` | スケーリング | AKS, Auto Scaling Group |
| `update` | 設定更新 | 全般 |

### 例: EC2インスタンス停止

```bash
./skills/configure/configure.sh <<< '{
  "provider": "aws",
  "template": "aws/compute/ec2",
  "action": "stop",
  "environment": "local",
  "params": {
    "instance_name": "test-instance"
  }
}'
```

### 例: Azure VM起動

```bash
./skills/configure/configure.sh <<< '{
  "provider": "azure",
  "template": "azure/compute/vm",
  "action": "start",
  "params": {
    "vm_name": "my-vm",
    "resource_group": "my-rg"
  }
}'
```

### 例: AKSクラスタースケール

```bash
./skills/configure/configure.sh <<< '{
  "provider": "azure",
  "template": "azure/compute/aks",
  "action": "scale",
  "params": {
    "cluster_name": "my-aks",
    "resource_group": "my-rg",
    "node_count": 5
  }
}'
```

### レスポンス

```json
{
  "status": "success",
  "message": "リソースの設定変更が完了しました",
  "data": {
    "action": "stop",
    "resource_id": "i-1234567890abcdef0",
    "previous_state": "running",
    "current_state": "stopped"
  },
  "timestamp": "2026-02-08T12:34:56Z"
}
```

---

## Destroy Skill

リソースを削除します。

### エンドポイント
```bash
./skills/destroy/destroy.sh
```

### 入力パラメータ

```typescript
interface DestroyInput extends SkillInput {
  params: {
    // テンプレート固有のパラメータ
    [key: string]: any;
  };
  force?: boolean;  // 確認なしで削除（デフォルト: false）
}
```

### 例: EC2インスタンス削除

```bash
./skills/destroy/destroy.sh <<< '{
  "provider": "aws",
  "template": "aws/compute/ec2",
  "environment": "local",
  "params": {
    "instance_name": "test-instance"
  }
}'
```

### 例: S3バケット削除（中身も含む）

```bash
./skills/destroy/destroy.sh <<< '{
  "provider": "aws",
  "template": "aws/storage/s3",
  "environment": "local",
  "params": {
    "bucket_name": "my-test-bucket"
  },
  "force": true
}'
```

### 例: Azure リソースグループ削除

```bash
./skills/destroy/destroy.sh <<< '{
  "provider": "azure",
  "template": "azure/resourcegroup",
  "params": {
    "resource_group": "temp-rg"
  },
  "force": true
}'
```

### レスポンス

```json
{
  "status": "success",
  "message": "リソースの削除が完了しました",
  "data": {
    "resource_id": "i-1234567890abcdef0",
    "resource_type": "ec2-instance",
    "deletion_time": "2026-02-08T12:35:00Z",
    "cleanup": {
      "volumes_deleted": 1,
      "network_interfaces_deleted": 1
    }
  },
  "timestamp": "2026-02-08T12:35:05Z"
}
```

---

## Validate Skill

テンプレートとパラメータを検証します。

### エンドポイント
```bash
./skills/validate/validate.sh
```

### 入力パラメータ

```typescript
interface ValidateInput {
  template: string;
  params?: Record<string, any>;
  validation_level?: "basic" | "standard" | "strict";  // デフォルト: "standard"
  check_security?: boolean;  // デフォルト: false
}
```

### バリデーションレベル

| レベル | 説明 |
|--------|------|
| `basic` | YAML構文チェックのみ |
| `standard` | 構文 + パラメータ型チェック |
| `strict` | 構文 + パラメータ + セキュリティチェック |

### 例: テンプレート検証

```bash
./skills/validate/validate.sh <<< '{
  "template": "aws/compute/ec2",
  "validation_level": "standard"
}'
```

### 例: パラメータ付き検証

```bash
./skills/validate/validate.sh <<< '{
  "template": "aws/storage/s3",
  "params": {
    "bucket_name": "My_Invalid_Bucket_Name",
    "region": "us-east-1"
  },
  "validation_level": "strict",
  "check_security": true
}'
```

### レスポンス（成功）

```json
{
  "status": "success",
  "message": "テンプレート検証が完了しました",
  "data": {
    "template": "aws/compute/ec2",
    "validation_level": "standard",
    "checks_performed": [
      "yaml_syntax",
      "template_structure",
      "parameter_types",
      "parameter_constraints"
    ],
    "warnings": [],
    "passed": true
  },
  "timestamp": "2026-02-08T12:34:56Z"
}
```

### レスポンス（失敗）

```json
{
  "status": "failed",
  "message": "バリデーションエラーが検出されました",
  "data": {
    "template": "aws/storage/s3",
    "validation_level": "strict",
    "errors": [
      {
        "field": "bucket_name",
        "message": "Bucket name must match pattern ^[a-z0-9-]+$",
        "invalid_value": "My_Invalid_Bucket_Name"
      }
    ],
    "warnings": [
      {
        "field": "public_access_block",
        "message": "Public access block is recommended for security"
      }
    ],
    "passed": false
  },
  "timestamp": "2026-02-08T12:34:56Z"
}
```

---

## エラーコード

### 共通エラーコード

| コード | 説明 |
|--------|------|
| `TEMPLATE_NOT_FOUND` | テンプレートファイルが見つからない |
| `INVALID_JSON` | 入力JSONが不正 |
| `MISSING_PARAMETER` | 必須パラメータが不足 |
| `INVALID_PARAMETER` | パラメータが不正 |
| `PROVIDER_NOT_SUPPORTED` | サポートされていないプロバイダー |
| `AUTHENTICATION_FAILED` | 認証失敗 |
| `AUTHORIZATION_FAILED` | 認可失敗（権限不足） |
| `RESOURCE_NOT_FOUND` | リソースが見つからない |
| `RESOURCE_ALREADY_EXISTS` | リソースが既に存在 |
| `QUOTA_EXCEEDED` | クォータ超過 |
| `NETWORK_ERROR` | ネットワークエラー |
| `TIMEOUT` | タイムアウト |
| `INTERNAL_ERROR` | 内部エラー |

---

## 環境変数

### AWS関連

```bash
# 必須（LocalStack使用時）
export AWS_ENDPOINT_URL=http://localhost:4566
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1

# オプション
export AWS_PROFILE=default
export AWS_CONFIG_FILE=~/.aws/config
export AWS_SHARED_CREDENTIALS_FILE=~/.aws/credentials
```

### Azure関連

```bash
# Azure CLIでログイン済みの場合は不要
# サービスプリンシパル使用時
export AZURE_CLIENT_ID=<client-id>
export AZURE_CLIENT_SECRET=<client-secret>
export AZURE_TENANT_ID=<tenant-id>
export AZURE_SUBSCRIPTION_ID=<subscription-id>
```

### SuperClaude固有

```bash
# 環境設定
export ENVIRONMENT=local  # または prod

# デバッグモード
export DEBUG=1

# ドライランモード
export DRY_RUN=1
```

---

## レート制限

各クラウドプロバイダーのAPI制限に準拠します:

- **AWS**: サービスごとに異なる（例: EC2 RunInstances = 5 req/sec）
- **Azure**: 通常 12,000 requests/hour

連続実行時は適切な間隔を空けてください:

```bash
# 例: 複数リソース作成時
for i in {1..10}; do
  ./skills/provision/provision.sh <<< "{...}"
  sleep 2  # 2秒待機
done
```

---

## ベストプラクティス

### 1. エラーハンドリング

```bash
#!/bin/bash

OUTPUT=$(./skills/provision/provision.sh <<< "$INPUT_JSON")
STATUS=$(echo "$OUTPUT" | jq -r '.status')

if [ "$STATUS" = "success" ]; then
  echo "成功: $(echo "$OUTPUT" | jq -r '.message')"
  RESOURCE_ID=$(echo "$OUTPUT" | jq -r '.data.resource_id')
else
  echo "失敗: $(echo "$OUTPUT" | jq -r '.message')" >&2
  exit 1
fi
```

### 2. パラメータ検証

```bash
# 実行前に validate skill でチェック
VALIDATE_RESULT=$(./skills/validate/validate.sh <<< '{
  "template": "aws/compute/ec2",
  "params": {...}
}')

if [ "$(echo "$VALIDATE_RESULT" | jq -r '.status')" = "success" ]; then
  # プロビジョニング実行
  ./skills/provision/provision.sh <<< "$INPUT_JSON"
fi
```

### 3. 冪等性の確保

```bash
# 既存リソース確認
QUERY_RESULT=$(./skills/query/query.sh <<< '{
  "query_type": "show",
  "params": {"instance_name": "my-instance"}
}')

if [ "$(echo "$QUERY_RESULT" | jq -r '.status')" = "failed" ]; then
  # リソースが存在しない場合のみ作成
  ./skills/provision/provision.sh <<< "$INPUT_JSON"
fi
```

---

## 関連ドキュメント

- [ARCHITECTURE.md](ARCHITECTURE.md) - システムアーキテクチャ
- [CLI_REFERENCE.md](CLI_REFERENCE.md) - CLIツールリファレンス
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - トラブルシューティング
- [テンプレートガイド](../templates/README.md) - テンプレート作成方法
