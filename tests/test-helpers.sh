#!/bin/bash

# テストヘルパー関数
# すべてのテストスクリプトで共通して使用する関数を定義

# カラー定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# テスト統計
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# テスト開始
test_start() {
    local test_name="$1"
    echo -e "${BLUE}▶ Testing:${NC} $test_name"
    TESTS_RUN=$((TESTS_RUN + 1))
}

# アサーション: 等しい
assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-Assertion failed}"

    if [ "$expected" = "$actual" ]; then
        echo -e "  ${GREEN}✓${NC} $message"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "  ${RED}✗${NC} $message"
        echo -e "    Expected: ${GREEN}$expected${NC}"
        echo -e "    Actual:   ${RED}$actual${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# アサーション: 含む
assert_contains() {
    local haystack="$1"
    local needle="$2"
    local message="${3:-Should contain}"

    if [[ "$haystack" == *"$needle"* ]]; then
        echo -e "  ${GREEN}✓${NC} $message"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "  ${RED}✗${NC} $message"
        echo -e "    Text:     $haystack"
        echo -e "    Expected: $needle"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# アサーション: 真
assert_true() {
    local condition="$1"
    local message="${2:-Should be true}"

    if [ "$condition" -eq 0 ]; then
        echo -e "  ${GREEN}✓${NC} $message"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "  ${RED}✗${NC} $message"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# アサーション: ファイル存在
assert_file_exists() {
    local file_path="$1"
    local message="${2:-File should exist}"

    if [ -f "$file_path" ]; then
        echo -e "  ${GREEN}✓${NC} $message: $file_path"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "  ${RED}✗${NC} $message: $file_path"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# アサーション: JSONが有効
assert_valid_json() {
    local json_string="$1"
    local message="${2:-Should be valid JSON}"

    if echo "$json_string" | jq empty 2>/dev/null; then
        echo -e "  ${GREEN}✓${NC} $message"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "  ${RED}✗${NC} $message"
        echo -e "    Invalid JSON: $json_string"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# アサーション: YAMLが有効
assert_valid_yaml() {
    local yaml_file="$1"
    local message="${2:-Should be valid YAML}"

    # 基本的なYAML構文チェック（コロン、ハイフンの存在）
    if grep -q "^[a-zA-Z_].*:" "$yaml_file" 2>/dev/null; then
        echo -e "  ${GREEN}✓${NC} $message"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "  ${RED}✗${NC} $message: $yaml_file"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# アサーション: コマンド成功
assert_success() {
    local exit_code=$1
    local message="${2:-Command should succeed}"

    if [ $exit_code -eq 0 ]; then
        echo -e "  ${GREEN}✓${NC} $message"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "  ${RED}✗${NC} $message (exit code: $exit_code)"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# アサーション: コマンド失敗
assert_failure() {
    local exit_code=$1
    local message="${2:-Command should fail}"

    if [ $exit_code -ne 0 ]; then
        echo -e "  ${GREEN}✓${NC} $message"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "  ${RED}✗${NC} $message (exit code: $exit_code)"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# テスト結果サマリー表示
print_test_summary() {
    echo ""
    echo "=================================="
    echo "Test Summary"
    echo "=================================="
    echo -e "Total:  $TESTS_RUN"
    echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"

    if [ $TESTS_FAILED -gt 0 ]; then
        echo -e "${RED}Failed: $TESTS_FAILED${NC}"
        echo ""
        return 1
    else
        echo -e "${GREEN}All tests passed!${NC}"
        echo ""
        return 0
    fi
}

# モックデータ生成
generate_mock_ec2_response() {
    cat <<EOF
{
  "Reservations": [{
    "Instances": [{
      "InstanceId": "i-1234567890abcdef0",
      "State": {"Name": "running"},
      "PublicIpAddress": "203.0.113.1",
      "PrivateIpAddress": "10.0.1.5"
    }]
  }]
}
EOF
}

generate_mock_s3_response() {
    cat <<EOF
{
  "Location": "/test-bucket"
}
EOF
}

# 一時ディレクトリ作成
create_temp_dir() {
    mktemp -d -t superclaude-test.XXXXXX
}

# クリーンアップ
cleanup_temp_dir() {
    local temp_dir="$1"
    if [ -n "$temp_dir" ] && [ -d "$temp_dir" ]; then
        rm -rf "$temp_dir"
    fi
}

export -f test_start
export -f assert_equals
export -f assert_contains
export -f assert_true
export -f assert_file_exists
export -f assert_valid_json
export -f assert_valid_yaml
export -f assert_success
export -f assert_failure
export -f print_test_summary
export -f generate_mock_ec2_response
export -f generate_mock_s3_response
export -f create_temp_dir
export -f cleanup_temp_dir
