#!/bin/bash

# SuperClaude Query Skill Handler
# クラウドリソースの情報を取得します

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# カラー出力
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1" >&2; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1" >&2; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

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

error_exit() {
    log_error "$1"
    output_json "failed" "$1" "{}"
    exit 1
}

get_param() {
    local param_name="$1"
    local env_var_name=$(echo "$param_name" | tr '[:lower:]' '[:upper:]')
    if [ -n "${!env_var_name}" ]; then
        echo "${!env_var_name}"
        return
    fi
    if [ -n "$INPUT_JSON" ]; then
        echo "$INPUT_JSON" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('$param_name', ''))"
    fi
}

PROVIDER=$(get_param "provider")
TEMPLATE=$(get_param "template")
QUERY_TYPE=$(get_param "query_type")
ENVIRONMENT=$(get_param "environment")
OUTPUT_FORMAT=$(get_param "output_format")

ENVIRONMENT="${ENVIRONMENT:-local}"
QUERY_TYPE="${QUERY_TYPE:-show}"
OUTPUT_FORMAT="${OUTPUT_FORMAT:-json}"

log_info "SuperClaude Query Skill 開始"
log_info "Provider: $PROVIDER"
log_info "Template: $TEMPLATE"
log_info "Query Type: $QUERY_TYPE"

[ -z "$PROVIDER" ] && error_exit "プロバイダーが指定されていません"
[ -z "$TEMPLATE" ] && error_exit "テンプレートが指定されていません"

TEMPLATE_PATH="$PROJECT_ROOT/templates/${TEMPLATE}.yaml"
if [ ! -f "$TEMPLATE_PATH" ]; then
    TEMPLATE_PATH="$PROJECT_ROOT/templates/${TEMPLATE}"
    [ ! -f "$TEMPLATE_PATH" ] && error_exit "テンプレートファイルが見つかりません: $TEMPLATE"
fi

# 環境設定
if [ "$ENVIRONMENT" = "local" ] && [ "$PROVIDER" = "aws" ]; then
    export AWS_ENDPOINT_URL="${AWS_ENDPOINT_URL:-http://localhost:4566}"
    export AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID:-test}"
    export AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY:-test}"
    export AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:-us-east-1}"
fi

# Python でクエリ実行
RESULT=$(python3 <<'PYTHON_SCRIPT'
import yaml
import json
import sys
import os
import re
import subprocess

def load_template(template_path):
    with open(template_path, 'r', encoding='utf-8') as f:
        return yaml.safe_load(f)

def get_input_params():
    input_json = os.environ.get('INPUT_JSON', '{}')
    params = json.loads(input_json).get('params', {})
    return params

def replace_variables(template_str, params):
    result = template_str
    for key, value in params.items():
        pattern = r'\{\{' + key + r'\}\}'
        if isinstance(value, bool):
            value_str = 'true' if value else 'false'
        elif isinstance(value, (list, dict)):
            value_str = json.dumps(value)
        else:
            value_str = str(value)
        result = re.sub(pattern, value_str, result)

    for key, value in params.items():
        if_pattern = r'\{\{#if ' + key + r'\}\}(.*?)\{\{/if\}\}'
        if value:
            result = re.sub(if_pattern, r'\1', result, flags=re.DOTALL)
        else:
            result = re.sub(if_pattern, '', result, flags=re.DOTALL)

    result = re.sub(r'\{\{#if .*?\}\}.*?\{\{/if\}\}', '', result, flags=re.DOTALL)
    lines = result.split('\n')
    cleaned_lines = [line for line in lines if line.strip()]
    return '\n'.join(cleaned_lines)

def get_query_command(template, params, query_type):
    resources = template.get('resources', {})
    commands = resources.get('commands', {})

    query_commands = commands.get('query', [])

    # query_type に応じて適切なコマンドを選択
    for cmd_def in query_commands:
        cmd_name = cmd_def.get('name', '')
        if query_type == 'show' and 'show' in cmd_name:
            return cmd_def
        elif query_type == 'list' and 'list' in cmd_name:
            return cmd_def
        elif query_type == 'status' and 'status' in cmd_name:
            return cmd_def
        elif query_type == 'ip' and 'ip' in cmd_name:
            return cmd_def

    # デフォルトは最初のコマンド
    return query_commands[0] if query_commands else None

def main():
    try:
        template_path = os.environ.get('TEMPLATE_PATH', '')
        query_type = os.environ.get('QUERY_TYPE', 'show')
        environment = os.environ.get('ENVIRONMENT', 'local')
        provider = os.environ.get('PROVIDER', '')

        template = load_template(template_path)
        params = get_input_params()

        if environment == "local" and provider == "aws":
            params['endpoint_url'] = os.environ.get('AWS_ENDPOINT_URL', 'http://localhost:4566')

        cmd_def = get_query_command(template, params, query_type)
        if not cmd_def:
            raise Exception(f"クエリタイプ '{query_type}' に対応するコマンドが見つかりません")

        cmd_template = cmd_def.get('command', '')
        cmd = replace_variables(cmd_template, params)
        cmd = cmd.replace('\\\n', ' ')
        cmd = ' '.join(cmd.split())

        print(json.dumps({
            'command': cmd,
            'description': cmd_def.get('description', ''),
            'query_type': query_type
        }, indent=2))

    except Exception as e:
        print(json.dumps({'error': str(e), 'type': type(e).__name__}, indent=2), file=sys.stderr)
        sys.exit(1)

if __name__ == '__main__':
    main()
PYTHON_SCRIPT
)

if [ $? -ne 0 ]; then
    error_exit "コマンド生成中にエラーが発生しました: $RESULT"
fi

COMMAND=$(echo "$RESULT" | python3 -c "import sys, json; print(json.load(sys.stdin)['command'])")
DESCRIPTION=$(echo "$RESULT" | python3 -c "import sys, json; print(json.load(sys.stdin)['description'])")

log_info "実行中: $DESCRIPTION"
log_info "コマンド: $COMMAND"

if QUERY_OUTPUT=$(eval "$COMMAND" 2>&1); then
    log_success "クエリ実行完了"

    FINAL_OUTPUT=$(cat <<EOF
{
  "resource_info": $QUERY_OUTPUT,
  "query_executed": "$COMMAND",
  "query_type": "$QUERY_TYPE"
}
EOF
)
    output_json "success" "リソース情報の取得が完了しました" "$FINAL_OUTPUT"
else
    error_exit "クエリ実行失敗: $QUERY_OUTPUT"
fi

export TEMPLATE_PATH
export QUERY_TYPE
export ENVIRONMENT
export PROVIDER
