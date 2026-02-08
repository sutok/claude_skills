# SuperClaude Skills ガイド

Claude Skills を使用してクラウドインフラを管理するための完全ガイドです。

## 📚 利用可能なスキル

### 1. provision-resource
**新しいリソースをプロビジョニング**

```bash
# 使用例: EC2 インスタンスの作成
INPUT_JSON='{
  "provider": "aws",
  "resource_type": "compute",
  "template": "aws/compute/ec2",
  "environment": "local",
  "params": {
    "instance_name": "test-instance",
    "ami_id": "ami-0c55b159cbfafe1f0",
    "instance_type": "t2.micro"
  }
}' ./skills/provision/provision.sh
```

### 2. query-resource
**リソース情報の取得**

```bash
# 使用例: VM 情報の取得
INPUT_JSON='{
  "provider": "azure",
  "template": "azure/compute/vm",
  "query_type": "show",
  "params": {
    "vm_name": "my-vm",
    "resource_group": "my-rg"
  }
}' ./skills/query/query.sh
```

### 3. configure-resource
**リソース設定の変更**

```bash
# 使用例: VM の起動
INPUT_JSON='{
  "provider": "azure",
  "template": "azure/compute/vm",
  "action": "start",
  "params": {
    "vm_name": "my-vm",
    "resource_group": "my-rg"
  }
}' ./skills/configure/configure.sh
```

### 4. destroy-resource
**リソースの削除**

```bash
# 使用例: EC2 インスタンスの削除
INPUT_JSON='{
  "provider": "aws",
  "template": "aws/compute/ec2",
  "environment": "local",
  "params": {
    "instance_name": "test-instance"
  }
}' ./skills/destroy/destroy.sh
```

### 5. validate-template
**テンプレートの検証**

```bash
# 使用例: テンプレート検証
INPUT_JSON='{
  "template": "aws/compute/ec2",
  "validation_level": "strict",
  "check_security": true,
  "params": {
    "instance_name": "test",
    "ami_id": "ami-12345678"
  }
}' ./skills/validate/validate.sh
```

## 🚀 Claude からの使用方法

Claude Code でこれらのスキルを直接使用できます：

### 例 1: LocalStack で S3 バケットを作成

```
Claude に依頼:
"provision スキルを使って LocalStack に S3 バケットを作成してください"

Claude が実行:
- templates/aws/storage/s3.yaml を読み込み
- パラメータを設定
- provision.sh を実行
```

### 例 2: Azure VM の状態を確認

```
Claude に依頼:
"my-vm という VM の状態を確認してください"

Claude が実行:
- query スキルを使用
- Azure CLI でVM情報を取得
- 結果を整形して表示
```

### 例 3: リソースの削除

```
Claude に依頼:
"test-instance という EC2 インスタンスを削除してください"

Claude が実行:
- destroy スキルを使用
- 関連リソース（NIC、ディスク等）も削除
```

## 🎯 スキルの動作フロー

### 1. Provision Skill フロー

```
ユーザーリクエスト
    ↓
パラメータ抽出
    ↓
テンプレート読み込み (templates/*/
*.yaml)
    ↓
変数置換 ({{vm_name}} → actual-value)
    ↓
環境設定 (local → LocalStack, prod → 本番)
    ↓
CLI コマンド生成
    ↓
コマンド実行 (az/aws CLI)
    ↓
結果返却 (JSON 形式)
```

### 2. Query Skill フロー

```
クエリリクエスト
    ↓
クエリタイプ判定 (show/list/status/ip)
    ↓
適切なコマンド選択
    ↓
コマンド実行
    ↓
結果整形
    ↓
JSON レスポンス
```

## 🔧 環境設定

### LocalStack (AWS ローカル開発)

```bash
# LocalStack 起動
docker-compose up -d localstack

# 環境変数設定
export AWS_ENDPOINT_URL=http://localhost:4566
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1
```

### Azure CLI

```bash
# Azure ログイン
az login

# サブスクリプション設定
az account set --subscription <subscription-id>

# 確認
az account show
```

## 📝 テンプレート変数の仕組み

テンプレート内の変数は Handlebars 風の構文を使用：

```yaml
# テンプレート例
command: |
  az vm create \
    --name {{vm_name}} \
    --resource-group {{resource_group}} \
    {{#if public_ip}}--public-ip-address {{vm_name}}-ip{{/if}} \
    --size {{size}}
```

パラメータ:
```json
{
  "vm_name": "my-vm",
  "resource_group": "my-rg",
  "public_ip": true,
  "size": "Standard_B2s"
}
```

生成されるコマンド:
```bash
az vm create \
  --name my-vm \
  --resource-group my-rg \
  --public-ip-address my-vm-ip \
  --size Standard_B2s
```

## 🔐 セキュリティベストプラクティス

1. **認証情報の管理**
   - 環境変数を使用
   - .env ファイルに保存（.gitignore に追加）
   - Azure Key Vault / AWS Secrets Manager を活用

2. **テンプレート設計**
   - パスワードにデフォルト値を設定しない
   - 認証パラメータは required: true に設定
   - 平文パスワードを避ける

3. **実行前の検証**
   - validate スキルで事前チェック
   - dry-run モードで確認
   - 本番環境では force: false を推奨

## 🧪 テスト方法

### 単体テスト

```bash
# validate スキルのテスト
./skills/validate/validate.sh <<< '{
  "template": "aws/compute/ec2",
  "validation_level": "basic"
}'
```

### 統合テスト (LocalStack)

```bash
# LocalStack 起動確認
docker ps | grep localstack

# S3 バケット作成テスト
INPUT_JSON='{
  "provider": "aws",
  "template": "aws/storage/s3",
  "environment": "local",
  "params": {
    "bucket_name": "test-bucket-12345",
    "region": "us-east-1"
  }
}' ./skills/provision/provision.sh

# 作成確認
aws s3 ls --endpoint-url http://localhost:4566
```

## 📊 出力形式

すべてのスキルは統一された JSON 形式で結果を返します：

```json
{
  "status": "success|failed",
  "message": "操作の説明",
  "data": {
    // スキル固有のデータ
  },
  "timestamp": "2026-02-08T12:34:56Z"
}
```

### Success の例

```json
{
  "status": "success",
  "message": "リソースのプロビジョニングが完了しました",
  "data": {
    "resource_details": {
      "InstanceId": "i-1234567890abcdef0",
      "State": "running"
    },
    "environment": "local",
    "provider": "aws"
  },
  "timestamp": "2026-02-08T12:34:56Z"
}
```

### Error の例

```json
{
  "status": "failed",
  "message": "テンプレートファイルが見つかりません",
  "data": {},
  "timestamp": "2026-02-08T12:34:56Z"
}
```

## 🛠️ トラブルシューティング

### エラー: テンプレートが見つからない

```
解決策:
- テンプレートパスを確認
- .yaml 拡張子の有無を確認
- templates/ ディレクトリからの相対パスか確認
```

### エラー: AWS CLI コマンド失敗

```
解決策:
- LocalStack が起動しているか確認
- AWS_ENDPOINT_URL が正しく設定されているか確認
- 環境変数を確認: echo $AWS_ENDPOINT_URL
```

### エラー: Azure CLI 認証エラー

```
解決策:
- az login を実行
- az account show でサブスクリプション確認
- az account set --subscription <id> でサブスクリプション設定
```

## 🔄 スキル拡張方法

新しいスキルを追加する場合：

1. `skills/<skill-name>/` ディレクトリ作成
2. `skill.yaml` でスキル定義
3. `<skill-name>.sh` でハンドラー実装
4. 実行権限付与: `chmod +x <skill-name>.sh`
5. このガイドに使用例を追加

## 📚 参考リソース

- [Azure CLI Documentation](https://docs.microsoft.com/cli/azure/)
- [AWS CLI Documentation](https://docs.aws.amazon.com/cli/)
- [LocalStack Documentation](https://docs.localstack.cloud/)
- [Claude Skills Framework](https://www.anthropic.com/claude-skills)

## 💡 Tips

1. **dry-run を活用**
   ```bash
   # コマンド確認のみ
   INPUT_JSON='{"...", "dry_run": true}' ./skills/provision/provision.sh
   ```

2. **環境変数での設定**
   ```bash
   # INPUT_JSON の代わりに環境変数も使用可能
   PROVIDER=aws TEMPLATE=aws/compute/ec2 ./skills/provision/provision.sh
   ```

3. **ログ出力の制御**
   ```bash
   # エラーのみ表示
   ./skills/provision/provision.sh 2>&1 | grep ERROR

   # JSON 結果のみ取得（ログを stderr へ）
   ./skills/provision/provision.sh 2>/dev/null
   ```

---

**作成者**: SuperClaude
**バージョン**: 1.0.0
**最終更新**: 2026-02-08
