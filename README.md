# SuperClaude

Azure/AWS環境をCLI経由で管理するためのテンプレートベースのインフラ管理システム

## 概要

SuperClaudeは、Claude Skillsと統合されたテンプレートシステムを使用して、AzureおよびAWS環境の構成管理を自動化します。LocalStackを使用したローカル開発により、本番環境に影響を与えることなくAWSワークフローをテストできます。

## 主な機能

- **テンプレートベース**: 再利用可能なインフラ構成テンプレート
- **マルチクラウド対応**: AzureとAWSの両方をサポート
- **ローカル開発**: LocalStackによるAWSのローカルエミュレーション
- **Claude Skills統合**: 自動化されたワークフロー実行
- **CLI中心**: Azure CLIとAWS CLIを活用

## プロジェクト構造

```
superclaude/
├── templates/          # インフラテンプレート
│   ├── azure/         # Azureリソーステンプレート
│   ├── aws/           # AWSリソーステンプレート
│   └── shared/        # 共有スキーマと検証ルール
├── skills/            # Claude Skillsの実装
│   ├── provision/     # リソースプロビジョニング
│   ├── configure/     # 設定変更
│   ├── query/         # リソース情報取得
│   ├── destroy/       # リソース削除
│   └── validate/      # 設定検証
├── scripts/           # ユーティリティスクリプト
├── tests/             # テストスイート
└── docs/              # ドキュメント

```

## セットアップ

### 前提条件

- Docker (LocalStack用)
- Azure CLI 2.x以上
- AWS CLI 2.x以上
- jq (JSON処理用)
- yq (YAML処理用)

### LocalStackのセットアップ

```bash
# docker-composeを使用してLocalStackを起動
docker-compose up -d

# または直接Dockerで起動
docker run -d \
  --name localstack \
  -p 4566:4566 \
  -e SERVICES=s3,ec2,lambda,dynamodb,cloudformation,iam \
  localstack/localstack
```

### 環境変数の設定

```bash
# LocalStack用のAWS設定
export AWS_ENDPOINT_URL=http://localhost:4566
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1
```

## 使い方

詳細な使用方法とガイドラインは[CLAUDE.md](./CLAUDE.md)を参照してください。

## ライセンス

MIT

## 貢献

プルリクエストを歓迎します。
