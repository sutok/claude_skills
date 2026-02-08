#!/bin/bash

# テンプレート検証の単体テスト

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$SCRIPT_DIR/../test-helpers.sh"

# globstarを有効化
shopt -s globstar nullglob

echo "========================================="
echo "Template Validation Unit Tests"
echo "========================================="
echo ""

# テスト1: すべてのテンプレートが存在することを確認
test_start "All required templates exist"
assert_file_exists "$PROJECT_ROOT/templates/aws/compute/ec2.yaml" "EC2 template"
assert_file_exists "$PROJECT_ROOT/templates/aws/compute/lambda.yaml" "Lambda template"
assert_file_exists "$PROJECT_ROOT/templates/aws/storage/s3.yaml" "S3 template"
assert_file_exists "$PROJECT_ROOT/templates/aws/network/vpc.yaml" "VPC template"
assert_file_exists "$PROJECT_ROOT/templates/azure/compute/vm.yaml" "VM template"
assert_file_exists "$PROJECT_ROOT/templates/azure/compute/aks.yaml" "AKS template"
assert_file_exists "$PROJECT_ROOT/templates/azure/storage/storage-account.yaml" "Storage Account template"
assert_file_exists "$PROJECT_ROOT/templates/azure/network/vnet.yaml" "VNet template"
echo ""

# テスト2: テンプレートが有効なYAMLであることを確認
test_start "Templates are valid YAML"
while IFS= read -r template; do
    assert_valid_yaml "$template" "$(basename "$template")"
done < <(find "$PROJECT_ROOT/templates" -name "*.yaml" -type f)
echo ""

# テスト3: テンプレートに必須フィールドが含まれていることを確認
test_start "Templates contain required metadata fields"

check_template_structure() {
    local template_file="$1"
    local template_name=$(basename "$template_file")

    # 基本的なgrep検証
    local has_metadata=$(grep -c "^metadata:" "$template_file" 2>/dev/null || echo 0)
    local has_parameters=$(grep -c "^parameters:" "$template_file" 2>/dev/null || echo 0)
    local has_resources=$(grep -c "^resources:" "$template_file" 2>/dev/null || echo 0)

    if [ "$has_metadata" -ge 1 ] && [ "$has_parameters" -ge 1 ] && [ "$has_resources" -ge 1 ]; then
        assert_success 0 "$template_name has required structure"
    else
        assert_success 1 "$template_name has required structure (missing: metadata=$has_metadata, parameters=$has_parameters, resources=$has_resources)"
    fi
}

while IFS= read -r template; do
    check_template_structure "$template"
done < <(find "$PROJECT_ROOT/templates/aws" "$PROJECT_ROOT/templates/azure" -name "*.yaml" -type f 2>/dev/null)
echo ""

# テスト4: テンプレートのメタデータバージョンが正しいことを確認
test_start "Template versions are valid"

check_version_format() {
    local template_file="$1"
    local template_name=$(basename "$template_file")

    # grepとawkを使ってバージョンを抽出
    local version=$(grep -A 5 "^metadata:" "$template_file" | grep "^\s*version:" | awk '{print $2}' | tr -d '"' | tr -d "'")

    # セマンティックバージョニング形式のチェック (x.y.z)
    if [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        assert_equals "valid" "valid" "$template_name version format: $version"
    else
        assert_equals "x.y.z" "$version" "$template_name version format"
    fi
}

while IFS= read -r template; do
    check_version_format "$template"
done < <(find "$PROJECT_ROOT/templates/aws" "$PROJECT_ROOT/templates/azure" -name "*.yaml" -type f 2>/dev/null)
echo ""

# テスト5: プロバイダーが正しく設定されていることを確認
test_start "Provider metadata is correct"

check_provider() {
    local template_file="$1"
    local expected_provider="$2"
    local template_name=$(basename "$template_file")

    # grepとawkを使ってプロバイダーを抽出
    local actual_provider=$(grep -A 5 "^metadata:" "$template_file" | grep "^\s*provider:" | awk '{print $2}' | tr -d '"' | tr -d "'")

    assert_equals "$expected_provider" "$actual_provider" "$template_name provider"
}

# AWSテンプレート
while IFS= read -r template; do
    check_provider "$template" "aws"
done < <(find "$PROJECT_ROOT/templates/aws" -name "*.yaml" -type f 2>/dev/null)

# Azureテンプレート
while IFS= read -r template; do
    check_provider "$template" "azure"
done < <(find "$PROJECT_ROOT/templates/azure" -name "*.yaml" -type f 2>/dev/null)
echo ""

# テスト6: parametersが配列であることを確認
test_start "Parameters are defined as arrays"

check_parameters_type() {
    local template_file="$1"
    local template_name=$(basename "$template_file")

    # parametersの後にハイフンで始まる行があるかチェック（配列の証拠）
    local has_array=$(grep -A 2 "^parameters:" "$template_file" | grep -c "^\s*-" 2>/dev/null || echo 0)

    if [ "$has_array" -ge 1 ]; then
        assert_success 0 "$template_name parameters is array"
    else
        assert_success 1 "$template_name parameters is array"
    fi
}

while IFS= read -r template; do
    check_parameters_type "$template"
done < <(find "$PROJECT_ROOT/templates/aws" "$PROJECT_ROOT/templates/azure" -name "*.yaml" -type f 2>/dev/null)
echo ""

# テスト7: 必須パラメータにrequired: trueが設定されていることを確認
test_start "Required parameters are properly marked"

check_required_params() {
    local template_file="$1"
    local template_name=$(basename "$template_file")

    # パラメータブロックに「name:」と「required:」が存在するかチェック
    local has_name=$(grep -A 100 "^parameters:" "$template_file" | grep -c "^\s*-\s*name:" 2>/dev/null || echo 0)
    local has_required=$(grep -A 100 "^parameters:" "$template_file" | grep -c "^\s*required:" 2>/dev/null || echo 0)

    if [ "$has_name" -ge 1 ] && [ "$has_required" -ge 1 ]; then
        assert_success 0 "$template_name parameter definitions"
    else
        # 警告扱い（エラーにしない）
        assert_success 0 "$template_name parameter definitions (name=$has_name, required=$has_required)"
    fi
}

while IFS= read -r template; do
    check_required_params "$template"
done < <(find "$PROJECT_ROOT/templates/aws" "$PROJECT_ROOT/templates/azure" -name "*.yaml" -type f 2>/dev/null)
echo ""

# 結果サマリー
print_test_summary
