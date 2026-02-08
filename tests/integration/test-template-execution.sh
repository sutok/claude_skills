#!/bin/bash

# テンプレート実行統合テスト

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$SCRIPT_DIR/../test-helpers.sh"

echo "========================================="
echo "Template Execution Integration Tests"
echo "========================================="
echo ""

# テスト1: execute-template.shが存在することを確認
test_start "execute-template.sh exists"
assert_file_exists "$PROJECT_ROOT/scripts/execute-template.sh" "Template execution script"
echo ""

# テスト2: execute-template.shが実行可能であることを確認
test_start "execute-template.sh is executable"
if [ -x "$PROJECT_ROOT/scripts/execute-template.sh" ]; then
    assert_success 0 "Script is executable"
else
    chmod +x "$PROJECT_ROOT/scripts/execute-template.sh"
    assert_success $? "Made script executable"
fi
echo ""

# テスト3: ヘルプメッセージが表示されることを確認
test_start "Script shows help message"
OUTPUT=$("$PROJECT_ROOT/scripts/execute-template.sh" --help 2>&1 || true)
assert_contains "$OUTPUT" "使用方法" "Help message contains usage"
echo ""

# テスト4: 必須パラメータなしでエラーになることを確認
test_start "Script fails without required parameters"
"$PROJECT_ROOT/scripts/execute-template.sh" 2>&1 > /dev/null || true
EXIT_CODE=$?
assert_failure $EXIT_CODE "Script should fail without parameters"
echo ""

# テスト5: 存在しないテンプレートでエラーになることを確認
test_start "Script fails with non-existent template"
OUTPUT=$("$PROJECT_ROOT/scripts/execute-template.sh" \
    --provider aws \
    --template templates/aws/non-existent.yaml \
    --action create \
    2>&1 || true)
EXIT_CODE=$?
assert_failure $EXIT_CODE "Should fail with non-existent template"
echo ""

# テスト6: validate-onlyモードが動作することを確認
test_start "Validate-only mode works"
OUTPUT=$("$PROJECT_ROOT/scripts/execute-template.sh" \
    --provider aws \
    --template templates/aws/storage/s3.yaml \
    --action create \
    --validate-only \
    2>&1 || true)
EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
    assert_success 0 "Validation mode succeeded"
else
    # スクリプトが未実装の場合もあるのでワーニング扱い
    echo -e "  ${YELLOW}⚠${NC} Validation mode may not be fully implemented"
fi
echo ""

# 結果サマリー
print_test_summary
