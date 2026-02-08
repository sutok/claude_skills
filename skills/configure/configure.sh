#!/bin/bash

# SuperClaude Configure Skill Handler

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1" >&2; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1" >&2; }
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

error_exit() {
    log_error "$1"
    output_json "failed" "$1" "{}"
    exit 1
}

get_param() {
    local param_name="$1"
    local env_var_name=$(echo "$param_name" | tr '[:lower:]' '[:upper:]')
    [ -n "${!env_var_name}" ] && echo "${!env_var_name}" && return
    [ -n "$INPUT_JSON" ] && echo "$INPUT_JSON" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('$param_name', ''))"
}

PROVIDER=$(get_param "provider")
TEMPLATE=$(get_param "template")
ACTION=$(get_param "action")
ENVIRONMENT=$(get_param "environment")

ENVIRONMENT="${ENVIRONMENT:-local}"

log_info "SuperClaude Configure Skill 開始"
log_info "Provider: $PROVIDER, Action: $ACTION"

[ -z "$PROVIDER" ] && error_exit "プロバイダーが指定されていません"
[ -z "$TEMPLATE" ] && error_exit "テンプレートが指定されていません"
[ -z "$ACTION" ] && error_exit "アクションが指定されていません"

TEMPLATE_PATH="$PROJECT_ROOT/templates/${TEMPLATE}.yaml"
[ ! -f "$TEMPLATE_PATH" ] && TEMPLATE_PATH="$PROJECT_ROOT/templates/${TEMPLATE}"
[ ! -f "$TEMPLATE_PATH" ] && error_exit "テンプレートが見つかりません: $TEMPLATE"

if [ "$ENVIRONMENT" = "local" ] && [ "$PROVIDER" = "aws" ]; then
    export AWS_ENDPOINT_URL="${AWS_ENDPOINT_URL:-http://localhost:4566}"
    export AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID:-test}"
    export AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY:-test}"
    export AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:-us-east-1}"
fi

# コマンド生成と実行
export TEMPLATE_PATH ACTION ENVIRONMENT PROVIDER

RESULT=$(python3 <<'PYTHON_SCRIPT'
import yaml, json, sys, os, re

def load_template(path):
    with open(path, 'r', encoding='utf-8') as f:
        return yaml.safe_load(f)

def get_input_params():
    input_json = os.environ.get('INPUT_JSON', '{}')
    return json.loads(input_json).get('params', {})

def replace_variables(template_str, params):
    result = template_str
    for key, value in params.items():
        pattern = r'\{\{' + key + r'\}\}'
        result = re.sub(pattern, str(value), result)
    return ' '.join(result.replace('\\\n', ' ').split())

def get_configure_command(template, params, action):
    resources = template.get('resources', {}).get('commands', {})
    configure_commands = resources.get('configure', [])

    for cmd_def in configure_commands:
        if action in cmd_def.get('name', '').lower():
            return cmd_def

    return None

def main():
    try:
        template = load_template(os.environ['TEMPLATE_PATH'])
        params = get_input_params()
        action = os.environ.get('ACTION', '')

        if os.environ.get('ENVIRONMENT') == "local" and os.environ.get('PROVIDER') == "aws":
            params['endpoint_url'] = os.environ.get('AWS_ENDPOINT_URL', '')

        cmd_def = get_configure_command(template, params, action)
        if not cmd_def:
            raise Exception(f"アクション '{action}' に対応するコマンドが見つかりません")

        cmd = replace_variables(cmd_def.get('command', ''), params)

        print(json.dumps({
            'command': cmd,
            'description': cmd_def.get('description', ''),
            'action': action
        }))
    except Exception as e:
        print(json.dumps({'error': str(e)}), file=sys.stderr)
        sys.exit(1)

if __name__ == '__main__':
    main()
PYTHON_SCRIPT
)

[ $? -ne 0 ] && error_exit "コマンド生成失敗: $RESULT"

COMMAND=$(echo "$RESULT" | python3 -c "import sys, json; print(json.load(sys.stdin)['command'])")
DESCRIPTION=$(echo "$RESULT" | python3 -c "import sys, json; print(json.load(sys.stdin)['description'])")

log_info "実行中: $DESCRIPTION"
log_info "コマンド: $COMMAND"

if OUTPUT=$(eval "$COMMAND" 2>&1); then
    log_success "設定変更完了"
    output_json "success" "リソースの設定を変更しました" "{\"output\": $(echo "$OUTPUT" | python3 -c 'import sys,json; print(json.dumps(sys.stdin.read()))')}"
else
    error_exit "設定変更失敗: $OUTPUT"
fi
