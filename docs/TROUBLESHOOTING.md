# トラブルシューティングガイド

よくある問題と解決方法をまとめています。

## 目次

- [LocalStack関連](#localstack関連)
- [AWS CLI関連](#aws-cli関連)
- [Azure CLI関連](#azure-cli関連)
- [テンプレート関連](#テンプレート関連)
- [スキル実行関連](#スキル実行関連)
- [認証・権限関連](#認証権限関連)
- [ネットワーク関連](#ネットワーク関連)

---

## LocalStack関連

### ❌ LocalStackに接続できない

**症状**:
```
Could not connect to the endpoint URL: "http://localhost:4566"
```

**原因と解決方法**:

1. **LocalStackが起動していない**
   ```bash
   # 確認
   docker ps | grep localstack

   # 起動
   docker-compose up -d localstack

   # ログ確認
   docker logs localstack
   ```

2. **ポートが既に使用されている**
   ```bash
   # ポート使用状況確認
   lsof -i :4566

   # 既存コンテナを停止
   docker stop localstack
   docker rm localstack

   # 再起動
   docker-compose up -d localstack
   ```

3. **環境変数が設定されていない**
   ```bash
   # 必須環境変数
   export AWS_ENDPOINT_URL=http://localhost:4566
   export AWS_ACCESS_KEY_ID=test
   export AWS_SECRET_ACCESS_KEY=test
   export AWS_DEFAULT_REGION=us-east-1

   # 確認
   echo $AWS_ENDPOINT_URL
   ```

### ❌ LocalStackでS3操作が失敗する

**症状**:
```
An error occurred (NoSuchBucket) when calling the HeadBucket operation
```

**解決方法**:
```bash
# LocalStack再起動（データリセット）
docker-compose down
docker-compose up -d localstack

# 初期化待機
sleep 5

# バケット再作成
aws s3 mb s3://test-bucket --endpoint-url http://localhost:4566
```

### ❌ LocalStackのデータが消える

**原因**: LocalStackはデフォルトでデータを永続化しない

**解決方法**:
```yaml
# docker-compose.yml
services:
  localstack:
    volumes:
      - "./localstack-data:/tmp/localstack"
    environment:
      - DATA_DIR=/tmp/localstack/data
```

---

## AWS CLI関連

### ❌ AWS CLIコマンドが見つからない

**症状**:
```
aws: command not found
```

**解決方法**:
```bash
# インストール確認
which aws

# AWS CLI v2 インストール (Linux)
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# インストール確認
aws --version
```

### ❌ 認証情報が無効

**症状**:
```
Unable to locate credentials
```

**解決方法**:
```bash
# 認証情報設定
aws configure

# または環境変数で設定
export AWS_ACCESS_KEY_ID=your_access_key
export AWS_SECRET_ACCESS_KEY=your_secret_key
export AWS_DEFAULT_REGION=us-east-1

# 確認
aws sts get-caller-identity
```

### ❌ リージョンエラー

**症状**:
```
You must specify a region
```

**解決方法**:
```bash
# 環境変数で指定
export AWS_DEFAULT_REGION=us-east-1

# またはコマンドで指定
aws ec2 describe-instances --region us-east-1

# aws configureで設定
aws configure set region us-east-1
```

---

## Azure CLI関連

### ❌ Azure CLIコマンドが見つからない

**症状**:
```
az: command not found
```

**解決方法**:
```bash
# インストール (Linux)
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# インストール確認
az --version
```

### ❌ ログインが必要

**症状**:
```
Please run 'az login' to setup account
```

**解決方法**:
```bash
# インタラクティブログイン
az login

# サービスプリンシパルでログイン
az login --service-principal \
  --username <app-id> \
  --password <password-or-cert> \
  --tenant <tenant-id>

# ログイン確認
az account show
```

### ❌ サブスクリプションが正しくない

**症状**:
```
Subscription not found
```

**解決方法**:
```bash
# サブスクリプション一覧
az account list --output table

# サブスクリプション設定
az account set --subscription <subscription-id>

# 確認
az account show
```

### ❌ リソースグループが見つからない

**症状**:
```
ResourceGroupNotFound
```

**解決方法**:
```bash
# リソースグループ作成
az group create \
  --name my-resource-group \
  --location japaneast

# 確認
az group show --name my-resource-group
```

---

## テンプレート関連

### ❌ テンプレートファイルが見つからない

**症状**:
```
Template file not found: templates/aws/compute/xxx.yaml
```

**解決方法**:
```bash
# テンプレート一覧確認
find templates/ -name "*.yaml"

# パスの確認（相対パス）
ls -la templates/aws/compute/

# 正しいパス指定
./skills/provision/provision.sh <<< '{
  "template": "aws/compute/ec2",
  ...
}'
```

### ❌ YAMLシンタックスエラー

**症状**:
```
YAML syntax error
```

**解決方法**:
```bash
# オンラインバリデーター使用
# http://www.yamllint.com/

# インデント確認（スペース2個が標準）
cat templates/aws/compute/ec2.yaml | head -20

# タブ文字をスペースに変換
expand -t 2 template.yaml > template_fixed.yaml
```

### ❌ 必須パラメータが不足

**症状**:
```
Missing required parameter: bucket_name
```

**解決方法**:
```bash
# テンプレートの必須パラメータ確認
grep -A 5 "required: true" templates/aws/storage/s3.yaml

# パラメータ追加
INPUT_JSON='{
  "provider": "aws",
  "template": "aws/storage/s3",
  "params": {
    "bucket_name": "my-bucket",  # ← 追加
    "region": "us-east-1"
  }
}'
```

### ❌ パラメータバリデーションエラー

**症状**:
```
Validation failed: bucket_name must match pattern ^[a-z0-9-]+$
```

**解決方法**:
```bash
# バケット名ルール確認
# - 小文字と数字とハイフンのみ
# - 3-63文字
# - 大文字・アンダースコア不可

# 正しい例
bucket_name: "my-test-bucket-123"

# 間違った例
bucket_name: "My_Test_Bucket"  # 大文字・アンダースコア不可
```

---

## スキル実行関連

### ❌ スキルスクリプトが実行できない

**症状**:
```
Permission denied: ./skills/provision/provision.sh
```

**解決方法**:
```bash
# 実行権限付与
chmod +x skills/provision/provision.sh
chmod +x skills/*/. sh

# 確認
ls -la skills/provision/provision.sh
```

### ❌ JSONパースエラー

**症状**:
```
parse error: Invalid JSON
```

**解決方法**:
```bash
# JSON整形ツールで確認
echo '$INPUT_JSON' | jq .

# シングルクォートとダブルクォートの使い分け
# ✓ 正しい
INPUT_JSON='{"key": "value"}'

# ✗ 間違い
INPUT_JSON={"key": "value"}  # クォートなし
INPUT_JSON="{"key": "value"}"  # ネストしたクォート
```

### ❌ スキル実行がタイムアウト

**症状**:
```
Timeout after 120 seconds
```

**解決方法**:
```bash
# タイムアウト延長（スクリプト内）
timeout 300 aws ec2 run-instances ...

# 非同期実行
aws ec2 run-instances ... --no-wait

# ステータス確認
aws ec2 describe-instances --instance-ids $INSTANCE_ID
```

---

## 認証・権限関連

### ❌ 権限不足エラー (AWS)

**症状**:
```
AccessDenied: User is not authorized to perform: ec2:RunInstances
```

**解決方法**:
```bash
# 現在のユーザー確認
aws sts get-caller-identity

# 必要なIAMポリシー追加
# EC2の場合:
# - ec2:RunInstances
# - ec2:CreateTags
# - ec2:DescribeInstances

# IAMポリシー確認
aws iam get-user-policy --user-name your-user --policy-name your-policy
```

### ❌ 権限不足エラー (Azure)

**症状**:
```
AuthorizationFailed: does not have authorization to perform action
```

**解決方法**:
```bash
# 現在のユーザー/サービスプリンシパル確認
az account show

# 必要なロール割り当て
az role assignment create \
  --assignee <user-or-sp-id> \
  --role "Virtual Machine Contributor" \
  --scope /subscriptions/<subscription-id>

# ロール確認
az role assignment list --assignee <user-or-sp-id>
```

### ❌ MFA/2FAエラー

**症状**:
```
MultiFactorAuthentication required
```

**解決方法**:
```bash
# AWS: MFA付きの一時認証情報取得
aws sts get-session-token \
  --serial-number arn:aws:iam::123456789012:mfa/user \
  --token-code 123456

# Azure: デバイスコード認証
az login --use-device-code
```

---

## ネットワーク関連

### ❌ VPCクォータ超過

**症状**:
```
VpcLimitExceeded: maximum number of VPCs has been reached
```

**解決方法**:
```bash
# 既存VPC確認
aws ec2 describe-vpcs --region us-east-1

# 不要なVPC削除
aws ec2 delete-vpc --vpc-id vpc-xxxxx

# クォータ確認
aws service-quotas get-service-quota \
  --service-code vpc \
  --quota-code L-F678F1CE
```

### ❌ サブネットのIP枯渇

**症状**:
```
InsufficientFreeAddressesInSubnet
```

**解決方法**:
```bash
# サブネット確認
aws ec2 describe-subnets --subnet-ids subnet-xxxxx

# 利用可能IP数確認
# AvailableIpAddressCount を確認

# 解決策:
# 1. より大きなCIDRブロックのサブネット作成
# 2. 不要なENIの削除
# 3. 別のサブネット使用
```

### ❌ セキュリティグループルール上限

**症状**:
```
RulesPerSecurityGroupLimitExceeded
```

**解決方法**:
```bash
# セキュリティグループルール確認
aws ec2 describe-security-groups --group-ids sg-xxxxx

# ルール数カウント
# デフォルト上限: 60ルール/グループ

# 解決策:
# 1. ルールを統合（CIDRレンジを集約）
# 2. 複数のセキュリティグループに分割
# 3. クォータ引き上げリクエスト
```

---

## デバッグ Tips

### スキルのデバッグモード

```bash
# set -x でデバッグ出力有効化
bash -x ./skills/provision/provision.sh <<< '$INPUT_JSON'

# 詳細ログ
export DEBUG=1
./skills/provision/provision.sh <<< '$INPUT_JSON'
```

### CLI コマンドのドライラン

```bash
# AWS: --dry-run オプション
aws ec2 run-instances --dry-run ...

# Azure: --what-if オプション
az deployment group create --what-if ...

# テンプレートスクリプト: --validate-only
./scripts/execute-template.sh --validate-only ...
```

### ログ出力の分離

```bash
# 標準出力のみ（JSON結果）
./skills/provision/provision.sh <<< '$INPUT_JSON' 2>/dev/null

# エラー出力のみ
./skills/provision/provision.sh <<< '$INPUT_JSON' 1>/dev/null

# 両方をファイルに保存
./skills/provision/provision.sh <<< '$INPUT_JSON' > output.log 2>&1
```

---

## よくある質問 (FAQ)

### Q: LocalStackでAzureリソースはテストできますか？
A: いいえ。LocalStackはAWSサービスのエミュレーターです。Azureには類似のツールがありません。

### Q: 本番環境で誤って実行しないようにするには？
A:
```bash
# 環境変数でガード
if [ "$ENVIRONMENT" = "production" ]; then
  read -p "本番環境で実行します。続行しますか？ (yes/no) " confirm
  [ "$confirm" != "yes" ] && exit 1
fi
```

### Q: 複数のAWSアカウントを切り替えるには？
A:
```bash
# プロファイル使用
aws configure --profile account1
aws configure --profile account2

# 実行時に指定
aws s3 ls --profile account1
export AWS_PROFILE=account1
```

### Q: テンプレートのバージョン管理は？
A: Gitでテンプレートを管理し、タグを使用:
```bash
git tag -a template-v1.1.0 -m "S3テンプレート更新"
git push origin template-v1.1.0
```

---

## サポート

問題が解決しない場合:

1. **ログ確認**: 詳細なエラーメッセージを確認
2. **Issue作成**: GitHub Issuesで報告
3. **テスト実行**: `./tests/run-all-tests.sh` でシステム状態確認
4. **ドキュメント参照**:
   - [ARCHITECTURE.md](ARCHITECTURE.md)
   - [API_REFERENCE.md](API_REFERENCE.md)
   - [CLAUDE.md](../CLAUDE.md)
