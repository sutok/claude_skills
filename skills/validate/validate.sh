#!/bin/bash

# SuperClaude Validate Skill Handler

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1" >&2; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1" >&2; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1" >&2; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

output_json() {
    cat <<EOF
{
  "status": "$1",
  "message": "$2",
  "data": $3,
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
}

get_param() {
    local param_name="$1"
    local env_var_name=$(echo "$param_name" | tr '[:lower:]' '[:upper:]')
    [ -n "${!env_var_name}" ] && echo "${!env_var_name}" && return
    [ -n "$INPUT_JSON" ] && echo "$INPUT_JSON" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('$param_name', ''))"
}

TEMPLATE=$(get_param "template")
VALIDATION_LEVEL=$(get_param "validation_level")
CHECK_SECURITY=$(get_param "check_security")

VALIDATION_LEVEL="${VALIDATION_LEVEL:-standard}"
CHECK_SECURITY="${CHECK_SECURITY:-false}"

log_info "SuperClaude Validate Skill 開始"
log_info "Template: $TEMPLATE"
log_info "Validation Level: $VALIDATION_LEVEL"

[ -z "$TEMPLATE" ] && {
    output_json "failed" "テンプレートが指定されていません" '{"is_valid": false}'
    exit 1
}

TEMPLATE_PATH="$PROJECT_ROOT/templates/${TEMPLATE}.yaml"
[ ! -f "$TEMPLATE_PATH" ] && TEMPLATE_PATH="$PROJECT_ROOT/templates/${TEMPLATE}"
[ ! -f "$TEMPLATE_PATH" ] && {
    output_json "failed" "テンプレートファイルが見つかりません: $TEMPLATE" '{"is_valid": false}'
    exit 1
}

export TEMPLATE_PATH VALIDATION_LEVEL CHECK_SECURITY

RESULT=$(python3 <<'PYTHON_SCRIPT'
import yaml
import json
import sys
import os
import re
from typing import List, Dict, Any

class TemplateValidator:
    def __init__(self, template_path, validation_level='standard', check_security=False):
        self.template_path = template_path
        self.validation_level = validation_level
        self.check_security = check_security
        self.errors = []
        self.warnings = []
        self.suggestions = []

    def validate(self):
        """テンプレート検証を実行"""
        try:
            # YAMLファイルの読み込み
            with open(self.template_path, 'r', encoding='utf-8') as f:
                self.template = yaml.safe_load(f)

            # 基本検証
            self._validate_structure()

            if self.validation_level in ['standard', 'strict']:
                self._validate_parameters()
                self._validate_resources()

            if self.validation_level == 'strict' or self.check_security:
                self._validate_security()

            return {
                'is_valid': len(self.errors) == 0,
                'errors': self.errors,
                'warnings': self.warnings,
                'suggestions': self.suggestions,
                'validation_level': self.validation_level
            }

        except yaml.YAMLError as e:
            return {
                'is_valid': False,
                'errors': [f'YAML構文エラー: {str(e)}'],
                'warnings': [],
                'suggestions': []
            }
        except Exception as e:
            return {
                'is_valid': False,
                'errors': [f'検証エラー: {str(e)}'],
                'warnings': [],
                'suggestions': []
            }

    def _validate_structure(self):
        """テンプレート構造を検証"""
        required_fields = ['metadata', 'parameters', 'resources']

        for field in required_fields:
            if field not in self.template:
                self.errors.append(f'必須フィールド "{field}" が見つかりません')

        # メタデータ検証
        if 'metadata' in self.template:
            metadata = self.template['metadata']
            if 'name' not in metadata:
                self.errors.append('metadata.name が必要です')
            if 'version' not in metadata:
                self.warnings.append('metadata.version の指定を推奨します')
            if 'provider' not in metadata:
                self.warnings.append('metadata.provider の指定を推奨します')

    def _validate_parameters(self):
        """パラメータ定義を検証"""
        if 'parameters' not in self.template:
            return

        params = self.template['parameters']
        if not isinstance(params, list):
            self.errors.append('parameters はリスト形式である必要があります')
            return

        for i, param in enumerate(params):
            if not isinstance(param, dict):
                self.errors.append(f'パラメータ {i} が辞書形式ではありません')
                continue

            # 必須フィールドチェック
            if 'name' not in param:
                self.errors.append(f'パラメータ {i} に name が指定されていません')

            if 'type' not in param:
                self.errors.append(f'パラメータ "{param.get("name", i)}" に type が指定されていません')

            if 'description' not in param:
                self.warnings.append(f'パラメータ "{param.get("name", i)}" に description がありません')

            # 型チェック
            valid_types = ['string', 'number', 'boolean', 'array', 'object']
            param_type = param.get('type')
            if param_type and param_type not in valid_types:
                self.errors.append(f'パラメータ "{param.get("name")}" の型 "{param_type}" は無効です')

    def _validate_resources(self):
        """リソース定義を検証"""
        if 'resources' not in self.template:
            return

        resources = self.template['resources']
        if 'commands' not in resources:
            self.warnings.append('resources.commands が定義されていません')
            return

        commands = resources['commands']
        expected_actions = ['create', 'delete', 'query', 'configure']

        for action in expected_actions:
            if action not in commands:
                if action in ['create', 'delete']:
                    self.warnings.append(f'アクション "{action}" が定義されていません')

    def _validate_security(self):
        """セキュリティチェック"""
        # パスワードやシークレットがデフォルト値に含まれていないかチェック
        if 'parameters' in self.template:
            for param in self.template['parameters']:
                param_name = param.get('name', '').lower()

                if any(word in param_name for word in ['password', 'secret', 'key', 'token']):
                    if 'default' in param:
                        self.errors.append(
                            f'セキュリティリスク: パラメータ "{param.get("name")}" に'
                            'デフォルト値を設定しないでください'
                        )

                    if param.get('required') == False:
                        self.warnings.append(
                            f'セキュリティ警告: 認証情報パラメータ "{param.get("name")}" は'
                            'required=true にすることを推奨します'
                        )

        # コマンドに平文のパスワードが含まれていないかチェック
        if 'resources' in self.template:
            commands = self.template.get('resources', {}).get('commands', {})
            for action, cmd_list in commands.items():
                if isinstance(cmd_list, list):
                    for cmd in cmd_list:
                        cmd_str = cmd.get('command', '')
                        if any(word in cmd_str.lower() for word in ['password=', 'secret=', 'token=']):
                            self.suggestions.append(
                                f'セキュリティ提案: {action} コマンドで認証情報を環境変数経由で渡すことを検討してください'
                            )

def main():
    try:
        template_path = os.environ.get('TEMPLATE_PATH', '')
        validation_level = os.environ.get('VALIDATION_LEVEL', 'standard')
        check_security = os.environ.get('CHECK_SECURITY', 'false').lower() == 'true'

        validator = TemplateValidator(template_path, validation_level, check_security)
        result = validator.validate()

        print(json.dumps(result, indent=2, ensure_ascii=False))

    except Exception as e:
        print(json.dumps({
            'is_valid': False,
            'errors': [str(e)],
            'warnings': [],
            'suggestions': []
        }, indent=2), file=sys.stderr)
        sys.exit(1)

if __name__ == '__main__':
    main()
PYTHON_SCRIPT
)

if [ $? -eq 0 ]; then
    IS_VALID=$(echo "$RESULT" | python3 -c "import sys, json; print(json.load(sys.stdin)['is_valid'])")

    if [ "$IS_VALID" = "True" ]; then
        log_success "テンプレート検証成功"
        output_json "success" "テンプレートは有効です" "$RESULT"
    else
        log_error "テンプレート検証失敗"
        output_json "failed" "テンプレートに問題があります" "$RESULT"
        exit 1
    fi
else
    log_error "検証処理中にエラーが発生しました"
    output_json "failed" "検証処理エラー" "$RESULT"
    exit 1
fi
