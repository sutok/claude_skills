# テンプレート

このディレクトリには、AzureとAWSのインフラリソースを管理するためのテンプレートが含まれています。

## 構造

- `azure/` - Azureリソーステンプレート
  - `compute/` - VM, AKSなどのコンピュートリソース
  - `storage/` - ストレージアカウント、Blob等
  - `network/` - VNet, サブネット、NSG等

- `aws/` - AWSリソーステンプレート
  - `compute/` - EC2, Lambda等
  - `storage/` - S3, EBS等
  - `network/` - VPC, サブネット、セキュリティグループ等

- `shared/` - 共有リソース
  - `schemas/` - テンプレート検証用のJSONスキーマ

## テンプレート形式

各テンプレートはYAML形式で以下の構造を持ちます：

```yaml
metadata:
  name: template-name
  description: テンプレートの説明
  version: 1.0.0
  provider: azure|aws

parameters:
  - name: parameter-name
    type: string|number|boolean|array|object
    description: パラメータの説明
    required: true|false
    default: デフォルト値（オプション）
    validation:
      pattern: 正規表現（文字列の場合）
      min: 最小値（数値の場合）
      max: 最大値（数値の場合）

resources:
  # CLI コマンドテンプレートまたはリソース定義

outputs:
  - name: output-name
    description: 出力の説明
    value: 出力値の取得方法

validation:
  pre_checks:
    - 実行前チェック

  post_checks:
    - 実行後チェック
```

## 使用例

テンプレートは、Claude Skillsまたは直接スクリプトから呼び出されます：

```bash
# テンプレートの実行例
./scripts/execute-template.sh \
  --provider aws \
  --template templates/aws/storage/s3.yaml \
  --params params.json \
  --environment local
```
