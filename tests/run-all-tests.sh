#!/bin/bash

# すべてのテストを実行するスクリプト

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "========================================"
echo "SuperClaude Test Suite"
echo "========================================"
echo ""

UNIT_PASSED=0
INTEGRATION_PASSED=0

# 単体テスト実行
echo "1. Running Unit Tests..."
echo "----------------------------------------"
if bash "$SCRIPT_DIR/run-unit-tests.sh"; then
    UNIT_PASSED=1
    echo "✓ Unit tests completed successfully"
else
    echo "✗ Unit tests failed"
fi
echo ""
echo ""

# 統合テスト実行
echo "2. Running Integration Tests..."
echo "----------------------------------------"
if bash "$SCRIPT_DIR/run-integration-tests.sh"; then
    INTEGRATION_PASSED=1
    echo "✓ Integration tests completed successfully"
else
    echo "✗ Integration tests failed"
fi
echo ""
echo ""

# 最終サマリー
echo "========================================"
echo "Final Test Summary"
echo "========================================"
if [ $UNIT_PASSED -eq 1 ] && [ $INTEGRATION_PASSED -eq 1 ]; then
    echo "✓✓ All tests passed! ✓✓"
    echo ""
    exit 0
elif [ $UNIT_PASSED -eq 1 ]; then
    echo "✓ Unit tests passed"
    echo "✗ Integration tests failed"
    echo ""
    exit 1
elif [ $INTEGRATION_PASSED -eq 1 ]; then
    echo "✗ Unit tests failed"
    echo "✓ Integration tests passed"
    echo ""
    exit 1
else
    echo "✗✗ All tests failed ✗✗"
    echo ""
    exit 1
fi
