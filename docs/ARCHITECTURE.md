# SuperClaude アーキテクチャ

## 概要

SuperClaudeは、テンプレートベースのインフラ管理システムで、Claude SkillsとCLIツールを統合してAzureとAWSのリソース管理を自動化します。

## システムアーキテクチャ

```
┌─────────────────────────────────────────────────────────────────┐
│                          Claude Code                             │
│                    (自然言語インターフェース)                      │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Claude Skills Layer                         │
│  ┌─────────┐  ┌─────────┐  ┌──────┐  ┌─────────┐  ┌─────────┐ │
│  │Provision│  │Configure│  │Query │  │ Destroy │  │Validate │ │
│  └────┬────┘  └────┬────┘  └──┬───┘  └────┬────┘  └────┬────┘ │
└───────┼────────────┼──────────┼───────────┼────────────┼───────┘
        │            │          │           │            │
        └────────────┴──────────┴───────────┴────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Template Engine                               │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ execute-template.sh                                       │   │
│  │  - テンプレート読み込み                                    │   │
│  │  - パラメータ検証                                          │   │
│  │  - 変数置換 (Handlebars風)                                │   │
│  │  - コマンド生成                                            │   │
│  └──────────────────────────────────────────────────────────┘   │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Templates Repository                          │
│  ┌─────────────┐              ┌─────────────┐                   │
│  │    AWS      │              │   Azure     │                   │
│  ├─────────────┤              ├─────────────┤                   │
│  │ • EC2       │              │ • VM        │                   │
│  │ • Lambda    │              │ • AKS       │                   │
│  │ • VPC       │              │ • VNet      │                   │
│  │ • S3        │              │ • Storage   │                   │
│  └─────────────┘              └─────────────┘                   │
└────────────────────────┬────────────────────────────────────────┘
                         │
         ┌───────────────┴───────────────┐
         ▼                               ▼
┌─────────────────┐            ┌─────────────────┐
│   AWS CLI       │            │   Azure CLI     │
│                 │            │                 │
│ ┌─────────────┐ │            │ ┌─────────────┐ │
│ │ Production  │ │            │ │ Production  │ │
│ └─────────────┘ │            │ └─────────────┘ │
│ ┌─────────────┐ │            │                 │
│ │ LocalStack  │ │            │                 │
│ │ (Dev/Test)  │ │            │                 │
│ └─────────────┘ │            │                 │
└─────────────────┘            └─────────────────┘
```

## コンポーネント詳細

### 1. Claude Code層
- **役割**: ユーザーからの自然言語リクエストを受け付け
- **機能**:
  - リクエストの解釈
  - 適切なSkillの選択
  - パラメータ抽出

### 2. Skills層
各Skillは独立したスクリプトとして実装：

#### Provision (`skills/provision/`)
- **目的**: 新規リソースの作成
- **入力**: provider, template, params, environment
- **出力**: リソース作成結果（JSON）
- **例**: EC2インスタンス起動、S3バケット作成

#### Configure (`skills/configure/`)
- **目的**: 既存リソースの設定変更
- **入力**: provider, template, action, params
- **出力**: 設定変更結果（JSON）
- **例**: VMの起動/停止、スケーリング設定変更

#### Query (`skills/query/`)
- **目的**: リソース情報の取得
- **入力**: provider, template, query_type, params
- **出力**: リソース情報（JSON）
- **例**: インスタンス一覧、ステータス確認

#### Destroy (`skills/destroy/`)
- **目的**: リソースの削除
- **入力**: provider, template, params
- **出力**: 削除結果（JSON）
- **例**: VMの削除、バケットの削除

#### Validate (`skills/validate/`)
- **目的**: テンプレート/パラメータの検証
- **入力**: template, params, validation_level
- **出力**: 検証結果（JSON）
- **例**: 構文チェック、パラメータ妥当性確認

### 3. Template Engine
**実装**: `scripts/execute-template.sh`

**処理フロー**:
```
1. テンプレート読み込み (YAML)
   ↓
2. スキーマ検証
   ↓
3. パラメータバリデーション
   ↓
4. 変数置換
   {{param}} → actual_value
   {{#if condition}}...{{/if}}
   ↓
5. CLI コマンド生成
   ↓
6. 環境判定 (local/prod)
   ↓
7. コマンド実行
   ↓
8. 結果整形・返却
```

### 4. Templates
**構造**:
```yaml
metadata:
  name: リソース名
  description: 説明
  version: セマンティックバージョン
  provider: aws|azure
  category: compute|storage|network

parameters:
  - name: パラメータ名
    type: string|number|boolean|array|object
    required: true|false
    default: デフォルト値
    validation: 検証ルール

resources:
  commands:
    create: [...作成コマンド]
    delete: [...削除コマンド]
    query: [...クエリコマンド]
    configure: [...設定変更コマンド]

outputs:
  - name: 出力名
    description: 説明
    value: JSONPath式

validation:
  pre_checks: [...事前チェック]
  post_checks: [...事後チェック]
```

## データフロー

### Provision操作の例

```
1. ユーザーリクエスト
   "LocalStackにS3バケットを作成してください"

2. Claude Code解釈
   → Skill: provision
   → Template: aws/storage/s3
   → Environment: local

3. Skillが入力JSON生成
   {
     "provider": "aws",
     "template": "aws/storage/s3",
     "environment": "local",
     "params": {
       "bucket_name": "test-bucket-12345",
       "region": "us-east-1"
     }
   }

4. Template Engineが処理
   a. s3.yamlを読み込み
   b. parametersを検証
   c. resourcesのcreateコマンドを取得
   d. 変数置換:
      aws s3 mb s3://{{bucket_name}}
      → aws s3 mb s3://test-bucket-12345
   e. endpoint_url追加（local環境）
      → aws s3 mb s3://test-bucket-12345 \
          --endpoint-url http://localhost:4566

5. CLI実行
   AWS CLI → LocalStack

6. 結果返却
   {
     "status": "success",
     "message": "S3バケット作成完了",
     "data": {
       "bucket_name": "test-bucket-12345",
       "location": "/test-bucket-12345"
     }
   }
```

## 環境管理

### Local環境 (LocalStack)
- **目的**: 開発・テスト
- **対象**: AWS リソースのみ
- **設定**:
  ```bash
  export AWS_ENDPOINT_URL=http://localhost:4566
  export AWS_ACCESS_KEY_ID=test
  export AWS_SECRET_ACCESS_KEY=test
  ```
- **利点**:
  - コスト無料
  - 高速なイテレーション
  - 安全な実験環境

### Production環境
- **AWS**: 実際のAWSアカウント
- **Azure**: 実際のAzureサブスクリプション
- **認証**:
  - AWS: ~/.aws/credentials または環境変数
  - Azure: az login

## セキュリティアーキテクチャ

### 認証情報管理
```
┌─────────────────┐
│  環境変数        │  ← 優先度1
└─────────────────┘
┌─────────────────┐
│  ~/.aws/config  │  ← 優先度2 (AWS)
│  az login       │  ← 優先度2 (Azure)
└─────────────────┘
```

### 権限モデル
- **最小権限の原則**: 必要な権限のみ付与
- **テンプレート検証**: 実行前に権限チェック
- **Dry-runモード**: 実際の変更前に確認

## スケーラビリティ

### 横方向拡張
- 新しいテンプレート追加が容易
- プロバイダー追加可能（GCP等）
- Skill拡張（backup, monitor等）

### 縦方向拡張
- 並列実行対応（複数リソース同時作成）
- バッチ処理対応
- ステート管理追加可能

## 拡張ポイント

### 1. 新しいクラウドプロバイダー追加
```
templates/
├── gcp/
│   ├── compute/
│   │   └── gce.yaml
│   └── storage/
│       └── gcs.yaml
```

### 2. カスタムSkill追加
```
skills/
└── backup/
    ├── backup.sh
    └── skill.yaml
```

### 3. ステート管理
```
state/
├── resources.json
└── deployments/
    └── deployment-123.json
```

### 4. CI/CD統合
```yaml
# .github/workflows/deploy.yml
- name: Deploy Infrastructure
  run: |
    INPUT_JSON='...' ./skills/provision/provision.sh
```

## パフォーマンス考慮事項

### キャッシング
- テンプレートの解析結果キャッシュ
- CLIレスポンスのキャッシュ（query操作）

### 並列化
- 依存関係のないリソースは並列作成
- 複数環境への同時デプロイ

### 最適化
- 不要なAPI呼び出しの削減
- バッチAPI使用（対応している場合）

## モニタリング・ログ

### ログレベル
- ERROR: 実行失敗
- WARN: 警告（継続可能）
- INFO: 実行情報
- DEBUG: 詳細ログ

### ログ出力先
- STDOUT: 構造化されたJSON結果
- STDERR: エラーメッセージ、ログ

## 今後の拡張計画

1. **Terraform/OpenTofu統合**
   - 既存IaCツールとの連携
   - ステートファイル管理

2. **ステート管理システム**
   - リソース追跡
   - 依存関係管理
   - ロールバック機能

3. **コスト見積もり**
   - 事前コスト計算
   - 予算アラート

4. **コンプライアンスチェック**
   - ポリシー検証
   - セキュリティスキャン

5. **GitOps統合**
   - Git-driven deployments
   - 自動同期

6. **WebUI/API**
   - REST API エンドポイント
   - Webベース管理画面
