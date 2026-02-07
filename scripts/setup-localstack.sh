#!/bin/bash

# LocalStack セットアップスクリプト

set -e

echo "🚀 LocalStackのセットアップを開始します..."

# LocalStackが起動しているか確認
if ! docker ps | grep -q superclaude-localstack; then
    echo "📦 LocalStackを起動します..."
    docker-compose up -d localstack

    # LocalStackの起動を待つ
    echo "⏳ LocalStackの起動を待っています..."
    timeout 60 bash -c 'until curl -s http://localhost:4566/_localstack/health | grep -q "\"s3\": \"available\""; do sleep 2; done'

    echo "✅ LocalStackが起動しました"
else
    echo "✅ LocalStackは既に起動しています"
fi

# AWS CLI設定の確認
echo "🔧 AWS CLI設定を確認します..."
if [ -z "$AWS_ENDPOINT_URL" ]; then
    echo "⚠️  AWS_ENDPOINT_URLが設定されていません"
    echo "次のコマンドを実行してください："
    echo "  export AWS_ENDPOINT_URL=http://localhost:4566"
    echo "  export AWS_ACCESS_KEY_ID=test"
    echo "  export AWS_SECRET_ACCESS_KEY=test"
    echo "  export AWS_DEFAULT_REGION=us-east-1"
else
    echo "✅ AWS CLI設定が完了しています"
fi

# LocalStackの動作確認
echo "🧪 LocalStackの動作を確認します..."
AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test aws --endpoint-url=http://localhost:4566 s3 ls > /dev/null 2>&1 && \
    echo "✅ LocalStackは正常に動作しています" || \
    echo "❌ LocalStackの動作確認に失敗しました"

echo ""
echo "🎉 セットアップが完了しました！"
echo ""
echo "次のステップ："
echo "1. 環境変数を設定: source .env"
echo "2. テンプレートを作成: templates/ ディレクトリ"
echo "3. スキルを実装: skills/ ディレクトリ"
