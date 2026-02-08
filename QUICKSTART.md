# SuperClaude クイックスタート

5分で始める SuperClaude の使い方

## 🚀 セットアップ（初回のみ）

### 1. LocalStack の起動（AWS ローカル開発用）

```bash
# Docker Compose で起動
docker-compose up -d localstack

# 起動確認
docker ps | grep localstack
```

### 2. 環境変数の設定

```bash
# AWS LocalStack
export AWS_ENDPOINT_URL=http://localhost:4566
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1
```

## 💡 基本的な使い方

### ステップ 1: テンプレートを検証

```bash
INPUT_JSON='{
  "template": "aws/compute/ec2",
  "validation_level": "standard"
}' ./skills/validate/validate.sh
```

### ステップ 2: リソースを作成

```bash
INPUT_JSON='{
  "provider": "aws",
  "template": "aws/compute/ec2",
  "environment": "local",
  "params": {
    "instance_name": "my-instance",
    "ami_id": "ami-0c55b159cbfafe1f0",
    "instance_type": "t2.micro"
  }
}' ./skills/provision/provision.sh
```

### ステップ 3: リソースを確認

```bash
INPUT_JSON='{
  "provider": "aws",
  "template": "aws/compute/ec2",
  "query_type": "show",
  "environment": "local",
  "params": {
    "instance_name": "my-instance"
  }
}' ./skills/query/query.sh
```

### ステップ 4: リソースを削除

```bash
INPUT_JSON='{
  "provider": "aws",
  "template": "aws/compute/ec2",
  "environment": "local",
  "params": {
    "instance_name": "my-instance"
  }
}' ./skills/destroy/destroy.sh
```

## 🎯 よく使うコマンド

### S3 バケット作成（LocalStack）

```bash
INPUT_JSON='{
  "provider": "aws",
  "template": "aws/storage/s3",
  "environment": "local",
  "params": {
    "bucket_name": "my-test-bucket",
    "region": "us-east-1"
  }
}' ./skills/provision/provision.sh
```

### Azure VM 作成

```bash
INPUT_JSON='{
  "provider": "azure",
  "template": "azure/compute/vm",
  "environment": "prod",
  "params": {
    "vm_name": "production-vm",
    "resource_group": "my-rg",
    "location": "japaneast",
    "size": "Standard_B2s",
    "admin_username": "azureuser",
    "authentication_type": "ssh"
  }
}' ./skills/provision/provision.sh
```

### VM の起動/停止

```bash
# 起動
INPUT_JSON='{
  "provider": "azure",
  "template": "azure/compute/vm",
  "action": "start",
  "params": {"vm_name": "my-vm", "resource_group": "my-rg"}
}' ./skills/configure/configure.sh

# 停止
INPUT_JSON='{
  "provider": "azure",
  "template": "azure/compute/vm",
  "action": "stop",
  "params": {"vm_name": "my-vm", "resource_group": "my-rg"}
}' ./skills/configure/configure.sh
```

## 🧪 デモスクリプトの実行

すべてのスキルを一度に試すには：

```bash
./examples/skill-demo.sh
```

## 📝 Claude Code での使用

Claude に自然言語で依頼するだけ：

```
"LocalStack で S3 バケットを作成してください"
"production-vm という VM の状態を確認してください"
"test-instance という EC2 インスタンスを削除してください"
```

Claude が自動的に適切なスキルを選択して実行します。

## 🔍 トラブルシューティング

### LocalStack に接続できない

```bash
# LocalStack の状態確認
docker ps | grep localstack

# ログ確認
docker logs localstack

# 再起動
docker-compose restart localstack
```

### Azure CLI 認証エラー

```bash
# ログイン
az login

# アカウント確認
az account show

# サブスクリプション設定
az account set --subscription <your-subscription-id>
```

## 📚 次のステップ

1. [SKILLS_GUIDE.md](skills/SKILLS_GUIDE.md) - 詳細な使用方法
2. [CLAUDE.md](CLAUDE.md) - プロジェクト全体の説明
3. [templates/README.md](templates/README.md) - テンプレートの作成方法

## 💬 サポート

問題が発生した場合：
1. [GitHub Issues](https://github.com/your-repo/issues) で報告
2. `validate` スキルでテンプレートをチェック
3. dry-run モードでコマンドを確認

---

**Happy Clouding! ☁️**
