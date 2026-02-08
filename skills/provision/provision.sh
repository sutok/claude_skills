#!/bin/bash

# SuperClaude Provision Skill Handler
# 新しいクラウドリソースをプロビジョニングします

set -e

# スクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# カラー出力
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ログ関数
log_info() { echo -e "${BLUE}[INFO]${NC} $1" >&2; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1" >&2; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1" >&2; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

# JSON 出力関数
output_json() {
    local status="$1"
    local message="$2"
    local data="$3"

    cat <<EOF
{
  "status": "$status",
  "message": "$message",
  "data": $data,
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
}

# エラーハンドリング
error_exit() {
    log_error "$1"
    output_json "failed" "$1" "{}"
    exit 1
}

# 入力パラメータを環境変数またはJSONから取得
get_param() {
    local param_name="$1"
    local env_var_name=$(echo "$param_name" | tr '[:lower:]' '[:upper:]')

    # 環境変数をチェック
    if [ -n "${!env_var_name}" ]; then
        echo "${!env_var_name}"
        return
    fi

    # INPUT_JSON から取得
    if [ -n "$INPUT_JSON" ]; then
        echo "$INPUT_JSON" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('$param_name', ''))"
    fi
}

# パラメータ取得
PROVIDER=$(get_param "provider")
RESOURCE_TYPE=$(get_param "resource_type")
TEMPLATE=$(get_param "template")
ENVIRONMENT=$(get_param "environment")
DRY_RUN=$(get_param "dry_run")
WAIT_FOR_COMPLETION=$(get_param "wait_for_completion")

# デフォルト値
ENVIRONMENT="${ENVIRONMENT:-local}"
DRY_RUN="${DRY_RUN:-false}"
WAIT_FOR_COMPLETION="${WAIT_FOR_COMPLETION:-true}"

log_info "SuperClaude Provision Skill 開始"
log_info "Provider: $PROVIDER"
log_info "Resource Type: $RESOURCE_TYPE"
log_info "Template: $TEMPLATE"
log_info "Environment: $ENVIRONMENT"

# 必須パラメータチェック
[ -z "$PROVIDER" ] && error_exit "プロバイダーが指定されていません"
[ -z "$TEMPLATE" ] && error_exit "テンプレートが指定されていません"

# テンプレートパスを解決
TEMPLATE_PATH="$PROJECT_ROOT/templates/${TEMPLATE}.yaml"
if [ ! -f "$TEMPLATE_PATH" ]; then
    # .yamlなしでも試す
    TEMPLATE_PATH="$PROJECT_ROOT/templates/${TEMPLATE}"
    if [ ! -f "$TEMPLATE_PATH" ]; then
        error_exit "テンプレートファイルが見つかりません: $TEMPLATE"
    fi
fi

log_info "テンプレートを読み込んでいます: $TEMPLATE_PATH"

# Python でテンプレートを処理
RESULT=$(python3 <<PYTHON_SCRIPT
import yaml
import json
import sys
import os
import re
from datetime import datetime

def load_template(template_path):
    """テンプレートファイルを読み込む"""
    with open(template_path, 'r', encoding='utf-8') as f:
        return yaml.safe_load(f)

def get_input_params():
    """入力パラメータを取得"""
    input_json = os.environ.get('INPUT_JSON', '{}')
    params = json.loads(input_json).get('params', {})
    return params

def replace_variables(template_str, params):
    """テンプレート変数を置換（簡易実装）"""
    result = template_str

    # {{variable}} 形式の変数を置換
    for key, value in params.items():
        pattern = r'\{\{' + key + r'\}\}'

        if isinstance(value, bool):
            value_str = 'true' if value else 'false'
        elif isinstance(value, (list, dict)):
            value_str = json.dumps(value)
        else:
            value_str = str(value)

        result = re.sub(pattern, value_str, result)

    # 条件式の処理（簡易実装）
    # {{#if variable}}...{{/if}} を処理
    for key, value in params.items():
        # 真の場合
        if_pattern = r'\{\{#if ' + key + r'\}\}(.*?)\{\{/if\}\}'
        if value:
            result = re.sub(if_pattern, r'\1', result, flags=re.DOTALL)
        else:
            result = re.sub(if_pattern, '', result, flags=re.DOTALL)

    # 残っている条件ブロックを削除
    result = re.sub(r'\{\{#if .*?\}\}.*?\{\{/if\}\}', '', result, flags=re.DOTALL)

    # 空のパラメータを削除（空行のクリーンアップ）
    lines = result.split('\\n')
    cleaned_lines = [line for line in lines if line.strip() and not re.match(r'^\s*\\\\$', line)]

    return '\\n'.join(cleaned_lines)

def generate_commands(template, params, action='create'):
    """CLIコマンドを生成"""
    commands = []

    resources = template.get('resources', {})
    command_list = resources.get('commands', {}).get(action, [])

    for cmd_def in command_list:
        cmd_name = cmd_def.get('name', 'unknown')
        cmd_template = cmd_def.get('command', '')

        # 変数を置換
        cmd = replace_variables(cmd_template, params)

        # 複数行を単一行に（継続行を処理）
        cmd = cmd.replace('\\\n', ' ')
        cmd = ' '.join(cmd.split())

        commands.append({
            'name': cmd_name,
            'command': cmd,
            'description': cmd_def.get('description', '')
        })

    return commands

def main():
    try:
        template_path = "${TEMPLATE_PATH}"
        environment = "${ENVIRONMENT}"
        dry_run = "${DRY_RUN}" == "true"

        # テンプレート読み込み
        template = load_template(template_path)

        # パラメータ取得
        params = get_input_params()

        # 環境設定を追加
        if environment == "local" and "${PROVIDER}" == "aws":
            params['endpoint_url'] = os.environ.get('AWS_ENDPOINT_URL', 'http://localhost:4566')

        # コマンド生成
        commands = generate_commands(template, params, action='create')

        result = {
            'template_metadata': template.get('metadata', {}),
            'commands': commands,
            'params': params,
            'dry_run': dry_run
        }

        print(json.dumps(result, indent=2, ensure_ascii=False))

    except Exception as e:
        error = {
            'error': str(e),
            'type': type(e).__name__
        }
        print(json.dumps(error, indent=2), file=sys.stderr)
        sys.exit(1)

if __name__ == '__main__':
    main()
PYTHON_SCRIPT
)

# Python スクリプトの実行結果をチェック
if [ $? -ne 0 ]; then
    error_exit "テンプレート処理中にエラーが発生しました: $RESULT"
fi

log_info "コマンド生成完了"

# 生成されたコマンドを取得
COMMANDS=$(echo "$RESULT" | python3 -c "import sys, json; data=json.load(sys.stdin); print(json.dumps(data.get('commands', [])))")
DRY_RUN_FLAG=$(echo "$RESULT" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('dry_run', False))")

# 環境設定
if [ "$ENVIRONMENT" = "local" ] && [ "$PROVIDER" = "aws" ]; then
    export AWS_ENDPOINT_URL="${AWS_ENDPOINT_URL:-http://localhost:4566}"
    export AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID:-test}"
    export AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY:-test}"
    export AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:-us-east-1}"
    log_info "LocalStack環境設定を適用しました"
fi

# コマンド実行
EXECUTED_COMMANDS=[]
RESOURCE_OUTPUT="{}"

if [ "$DRY_RUN" = "true" ]; then
    log_warning "DRY-RUN モード: コマンドは実行されません"
    echo "$RESULT" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for cmd in data.get('commands', []):
    print(f\"[DRY-RUN] {cmd['name']}: {cmd['command']}\")
"
    output_json "success" "ドライラン完了（コマンド実行なし）" "$RESULT"
else
    log_info "コマンドを実行しています..."

    # コマンドを順次実行
    COMMAND_COUNT=$(echo "$COMMANDS" | python3 -c "import sys, json; print(len(json.load(sys.stdin)))")

    for i in $(seq 0 $((COMMAND_COUNT - 1))); do
        CMD_NAME=$(echo "$COMMANDS" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data[$i]['name'])")
        CMD=$(echo "$COMMANDS" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data[$i]['command'])")

        log_info "実行中: $CMD_NAME"
        log_info "コマンド: $CMD"

        # コマンド実行
        if OUTPUT=$(eval "$CMD" 2>&1); then
            log_success "$CMD_NAME 完了"
            RESOURCE_OUTPUT="$OUTPUT"
        else
            error_exit "$CMD_NAME 失敗: $OUTPUT"
        fi
    done

    log_success "すべてのコマンドが正常に実行されました"

    # 結果を出力
    FINAL_OUTPUT=$(cat <<EOF
{
  "resource_details": $RESOURCE_OUTPUT,
  "commands_executed": $COMMANDS,
  "environment": "$ENVIRONMENT",
  "provider": "$PROVIDER"
}
EOF
)

    output_json "success" "リソースのプロビジョニングが完了しました" "$FINAL_OUTPUT"
fi
