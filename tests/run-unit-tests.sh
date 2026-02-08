#!/bin/bash

# 単体テスト実行スクリプト

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "========================================"
echo "Running Unit Tests"
echo "========================================"
echo ""

TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# unit/ディレクトリ内のすべてのテストを実行
for test_file in "$SCRIPT_DIR"/unit/test-*.sh; do
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
echo "Unit Test Results"
echo "========================================"
echo "Total test files: $TOTAL_TESTS"
echo "Passed: $PASSED_TESTS"
echo "Failed: $FAILED_TESTS"
echo ""

if [ $FAILED_TESTS -eq 0 ]; then
    echo "✓ All unit tests passed!"
    exit 0
else
    echo "✗ Some unit tests failed"
    exit 1
fi
