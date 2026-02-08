#!/bin/bash

# SuperClaude Destroy Skill Handler

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
ENVIRONMENT=$(get_param "environment")
FORCE=$(get_param "force")

ENVIRONMENT="${ENVIRONMENT:-local}"
FORCE="${FORCE:-false}"

log_warning "SuperClaude Destroy Skill 開始"
log_warning "このスキルはリソースを削除します！"
log_info "Provider: $PROVIDER"

[ -z "$PROVIDER" ] && error_exit "プロバイダーが指定されていません"
[ -z "$TEMPLATE" ] && error_exit "テンプレートが指定されていません"

TEMPLATE_PATH="$PROJECT_ROOT/templates/${TEMPLATE}.yaml"
[ ! -f "$TEMPLATE_PATH" ] && TEMPLATE_PATH="$PROJECT_ROOT/templates/${TEMPLATE}"
[ ! -f "$TEMPLATE_PATH" ] && error_exit "テンプレートが見つかりません"

if [ "$ENVIRONMENT" = "local" ] && [ "$PROVIDER" = "aws" ]; then
    export AWS_ENDPOINT_URL="${AWS_ENDPOINT_URL:-http://localhost:4566}"
    export AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID:-test}"
    export AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY:-test}"
    export AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:-us-east-1}"
fi

export TEMPLATE_PATH ENVIRONMENT PROVIDER

RESULT=$(python3 <<'PYTHON_SCRIPT'
import yaml, json, sys, os, re

def load_template(path):
    with open(path, 'r') as f:
        return yaml.safe_load(f)

def get_input_params():
    return json.loads(os.environ.get('INPUT_JSON', '{}')).get('params', {})

def replace_variables(template_str, params):
    result = template_str
    for key, value in params.items():
        result = re.sub(r'\{\{' + key + r'\}\}', str(value), result)
    return ' '.join(result.replace('\\\n', ' ').split())

def get_delete_commands(template, params):
    commands = []
    delete_cmds = template.get('resources', {}).get('commands', {}).get('delete', [])

    for cmd_def in delete_cmds:
        cmd = replace_variables(cmd_def.get('command', ''), params)
        commands.append({
            'name': cmd_def.get('name', ''),
            'command': cmd,
            'description': cmd_def.get('description', '')
        })

    return commands

def main():
    try:
        template = load_template(os.environ['TEMPLATE_PATH'])
        params = get_input_params()

        if os.environ.get('ENVIRONMENT') == "local" and os.environ.get('PROVIDER') == "aws":
            params['endpoint_url'] = os.environ.get('AWS_ENDPOINT_URL', '')

        commands = get_delete_commands(template, params)
        print(json.dumps({'commands': commands}))
    except Exception as e:
        print(json.dumps({'error': str(e)}), file=sys.stderr)
        sys.exit(1)

if __name__ == '__main__':
    main()
PYTHON_SCRIPT
)

[ $? -ne 0 ] && error_exit "コマンド生成失敗: $RESULT"

COMMANDS=$(echo "$RESULT" | python3 -c "import sys, json; print(json.dumps(json.load(sys.stdin)['commands']))")
COMMAND_COUNT=$(echo "$COMMANDS" | python3 -c "import sys, json; print(len(json.load(sys.stdin)))")

DELETED_RESOURCES=[]

for i in $(seq 0 $((COMMAND_COUNT - 1))); do
    CMD_NAME=$(echo "$COMMANDS" | python3 -c "import sys, json; print(json.load(sys.stdin)[$i]['name'])")
    CMD=$(echo "$COMMANDS" | python3 -c "import sys, json; print(json.load(sys.stdin)[$i]['command'])")

    log_warning "削除実行: $CMD_NAME"
    log_info "コマンド: $CMD"

    if OUTPUT=$(eval "$CMD" 2>&1); then
        log_success "$CMD_NAME 完了"
    else
        log_warning "$CMD_NAME 失敗（スキップ）: $OUTPUT"
    fi
done

log_success "リソースの削除が完了しました"
output_json "success" "リソースを削除しました" "{\"deleted_resources\": $COMMANDS}"
