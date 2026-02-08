#!/bin/bash

# 統合テスト実行スクリプト

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "========================================"
echo "Running Integration Tests"
echo "========================================"
echo ""

# LocalStackが起動しているか確認
if ! curl -s http://localhost:4566/_localstack/health > /dev/null 2>&1; then
    echo "❌ LocalStack is not running!"
    echo ""
    echo "Please start LocalStack with:"
    echo "  docker-compose up -d localstack"
    echo ""
    exit 1
fi

echo "✓ LocalStack is running"
echo ""

TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# integration/ディレクトリ内のすべてのテストを実行
for test_file in "$SCRIPT_DIR"/integration/test-*.sh; do
    if [ -f "$test_file" ]; then
        echo "Running $(basename "$test_file")..."
        echo ""

        if bash "$test_file"; then
            PASSED_TESTS=$((PASSED_TESTS + 1))
        else
            FAILED_TESTS=$((FAILED_TESTS + 1))
        fi

        TOTAL_TESTS=$((TOTAL_TESTS + 1))
        echo ""
    fi
done

# 最終結果
echo "========================================"
echo "Integration Test Results"
echo "========================================"
echo "Total test files: $TOTAL_TESTS"
echo "Passed: $PASSED_TESTS"
echo "Failed: $FAILED_TESTS"
echo ""

if [ $FAILED_TESTS -eq 0 ]; then
    echo "✓ All integration tests passed!"
    exit 0
else
    echo "✗ Some integration tests failed"
    exit 1
fi
