#!/bin/bash

# SuperClaude Skills デモスクリプト
# すべてのスキルの基本的な使用方法を示します

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# カラー出力
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}SuperClaude Skills デモ${NC}"
echo -e "${BLUE}========================================${NC}"
echo

# 1. Validate Skill のデモ
echo -e "${GREEN}[1/5] Validate Skill - テンプレート検証${NC}"
echo "AWS EC2 テンプレートを検証します..."
echo

export INPUT_JSON='{
  "template": "aws/compute/ec2",
  "validation_level": "standard",
  "check_security": false
}'

if "$PROJECT_ROOT/skills/validate/validate.sh" 2>&1 | tail -20; then
    echo -e "${GREEN}✓ 検証成功${NC}"
else
    echo -e "${YELLOW}⚠ 検証に問題がありました${NC}"
fi

echo
echo "---"
echo

# 2. Provision Skill のデモ (dry-run)
echo -e "${GREEN}[2/5] Provision Skill - リソース作成 (Dry Run)${NC}"
echo "EC2 インスタンス作成コマンドを生成します (実行はしません)..."
echo

export INPUT_JSON='{
  "provider": "aws",
  "resource_type": "compute",
  "template": "aws/compute/ec2",
  "environment": "local",
  "dry_run": true,
  "params": {
    "instance_name": "demo-instance",
    "ami_id": "ami-0c55b159cbfafe1f0",
    "instance_type": "t2.micro",
    "region": "us-east-1"
  }
}'

if "$PROJECT_ROOT/skills/provision/provision.sh" 2>&1 | tail -20; then
    echo -e "${GREEN}✓ コマンド生成成功${NC}"
else
    echo -e "${YELLOW}⚠ エラーが発生しました${NC}"
fi

echo
echo "---"
echo

# 3. Query Skill のデモ
echo -e "${GREEN}[3/5] Query Skill - リソース情報取得${NC}"
echo "注意: 実際のリソースが存在しないためエラーになります（正常な動作）"
echo

export INPUT_JSON='{
  "provider": "aws",
  "template": "aws/compute/ec2",
  "query_type": "show",
  "environment": "local",
  "params": {
    "instance_name": "demo-instance",
    "region": "us-east-1"
  }
}'

if "$PROJECT_ROOT/skills/query/query.sh" 2>&1 | tail -20; then
    echo -e "${GREEN}✓ クエリ生成成功${NC}"
else
    echo -e "${YELLOW}⚠ リソースが存在しません（想定内）${NC}"
fi

echo
echo "---"
echo

# 4. Configure Skill のデモ
echo -e "${GREEN}[4/5] Configure Skill - リソース設定変更${NC}"
echo "VM 起動コマンドを生成します..."
echo

export INPUT_JSON='{
  "provider": "azure",
  "template": "azure/compute/vm",
  "action": "start",
  "environment": "prod",
  "params": {
    "vm_name": "demo-vm",
    "resource_group": "demo-rg"
  }
}'

if "$PROJECT_ROOT/skills/configure/configure.sh" 2>&1 | tail -20; then
    echo -e "${GREEN}✓ コマンド生成成功${NC}"
else
    echo -e "${YELLOW}⚠ エラーが発生しました（想定内）${NC}"
fi

echo
echo "---"
echo

# 5. Destroy Skill のデモ
echo -e "${GREEN}[5/5] Destroy Skill - リソース削除${NC}"
echo "削除コマンドを生成します..."
echo

export INPUT_JSON='{
  "provider": "aws",
  "template": "aws/compute/ec2",
  "environment": "local",
  "params": {
    "instance_name": "demo-instance",
    "region": "us-east-1"
  }
}'

if "$PROJECT_ROOT/skills/destroy/destroy.sh" 2>&1 | tail -20; then
    echo -e "${GREEN}✓ コマンド生成成功${NC}"
else
    echo -e "${YELLOW}⚠ エラーが発生しました（想定内）${NC}"
fi

echo
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}デモ完了！${NC}"
echo -e "${BLUE}========================================${NC}"
echo
echo "詳細は skills/SKILLS_GUIDE.md を参照してください"
echo
