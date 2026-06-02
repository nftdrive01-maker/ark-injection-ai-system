#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
WORKSPACE_ROOT="$(cd "$REPO_ROOT/.." && pwd)"
ENV_EXAMPLE_PATH="$REPO_ROOT/.env.example"
ENV_PATH="$REPO_ROOT/.env"
WORKSPACE_FILE_PATH="$WORKSPACE_ROOT/ark-injection-ai-system.code-workspace"

CHAT_BACKEND="chatgpt"
SKIP_GOOGLE_WORKSPACE_MCP=0
SKIP_ESTAT_MCP=0
FORCE_ENV=0
FORCE_WORKSPACE_FILE=0
START_STACK=0
DRY_RUN=0

REPO_NAMES=(
  "amica"
  "injection-tool"
  "mcp-server"
  "google-workspace-mcp"
  "estat-mcp"
  "piper"
  "Style-Bert-VITS2"
)

REPO_PATHS=(
  "amica"
  "injection-tool"
  "mcp-server"
  "google-workspace-mcp"
  "estat-mcp"
  "piper"
  "sbv2/Style-Bert-VITS2"
)

REPO_URLS=(
  "https://github.com/nftdrive01-maker/amica-nftdrive.git"
  "https://github.com/nftdrive01-maker/ark-injection-tool.git"
  "https://github.com/nftdrive01-maker/ark-mcp-server.git"
  "https://github.com/nftdrive01-maker/google_workspace_mcp-nftdrive.git"
  "https://github.com/nftdrive01-maker/estat-mcp-nftdrive.git"
  "https://github.com/nftdrive01-maker/piper-nftdrive.git"
  "https://github.com/nftdrive01-maker/Style-Bert-VITS2-nftdrive.git"
)

usage() {
  cat <<'EOF'
Usage: bash ./scripts/setup-workspace.sh [options]

Options:
  -ChatBackend <chatgpt|ollama>
  -SkipGoogleWorkspaceMcp
  -SkipEstatMcp
  -ForceEnv
  -ForceWorkspaceFile
  -StartStack
  -DryRun
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -ChatBackend)
      if [[ $# -lt 2 ]]; then
        echo "Missing value for -ChatBackend" >&2
        exit 1
      fi
      CHAT_BACKEND="$2"
      shift 2
      ;;
    -SkipGoogleWorkspaceMcp)
      SKIP_GOOGLE_WORKSPACE_MCP=1
      shift
      ;;
    -SkipEstatMcp)
      SKIP_ESTAT_MCP=1
      shift
      ;;
    -ForceEnv)
      FORCE_ENV=1
      shift
      ;;
    -ForceWorkspaceFile)
      FORCE_WORKSPACE_FILE=1
      shift
      ;;
    -StartStack)
      START_STACK=1
      shift
      ;;
    -DryRun)
      DRY_RUN=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ "$CHAT_BACKEND" != "chatgpt" && "$CHAT_BACKEND" != "ollama" ]]; then
  echo "-ChatBackend must be chatgpt or ollama" >&2
  exit 1
fi

run_cmd() {
  if [[ $DRY_RUN -eq 1 ]]; then
    printf 'DRY RUN:'
    printf ' %q' "$@"
    printf '\n'
    return 0
  fi

  "$@"
}

ensure_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Required command not found: $1" >&2
    exit 1
  fi
}

set_env_value() {
  local file_path="$1"
  local key="$2"
  local value="$3"
  local temp_file
  temp_file="$(mktemp)"

  awk -v key="$key" -v value="$value" '
    BEGIN { updated = 0 }
    index($0, key "=") == 1 {
      print key "=" value
      updated = 1
      next
    }
    { print }
    END {
      if (updated == 0) {
        print key "=" value
      }
    }
  ' "$file_path" > "$temp_file"

  if [[ $DRY_RUN -eq 1 ]]; then
    echo "DRY RUN: set $key=$value in $file_path"
    rm -f "$temp_file"
    return 0
  fi

  mv "$temp_file" "$file_path"
}

ensure_repository_present() {
  local name="$1"
  local relative_path="$2"
  local url="$3"
  local target_path="$WORKSPACE_ROOT/$relative_path"
  local target_parent
  target_parent="$(dirname "$target_path")"

  if [[ -d "$target_path/.git" ]]; then
    echo "Skip existing repository: $name"
    return 0
  fi

  if [[ -e "$target_path" && ! -d "$target_path" ]]; then
    echo "Target path exists and is not a directory: $target_path" >&2
    exit 1
  fi

  if [[ -d "$target_path" ]]; then
    if [[ -n "$(find "$target_path" -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null)" ]]; then
      echo "Target path exists and is not an empty git repository: $target_path" >&2
      exit 1
    fi
  else
    run_cmd mkdir -p "$target_parent"
  fi

  echo "Cloning $name into $target_path"
  run_cmd git clone "$url" "$target_path"
}

ensure_env_file() {
  if [[ -f "$ENV_PATH" && $FORCE_ENV -ne 1 ]]; then
    echo "Skip existing .env file. Use -ForceEnv to overwrite from .env.example."
    return 0
  fi

  if [[ $DRY_RUN -eq 1 ]]; then
    echo "DRY RUN: copy $ENV_EXAMPLE_PATH -> $ENV_PATH"
  else
    cp "$ENV_EXAMPLE_PATH" "$ENV_PATH"
  fi

  set_env_value "$ENV_PATH" "AMICA_CHATBOT_BACKEND" "$CHAT_BACKEND"

  if [[ "$CHAT_BACKEND" == "chatgpt" ]]; then
    set_env_value "$ENV_PATH" "AMICA_OPENAI_URL" "https://api.openai.com"
    set_env_value "$ENV_PATH" "AMICA_OPENAI_MODEL" "gpt-4o-mini"
  else
    set_env_value "$ENV_PATH" "AMICA_OLLAMA_URL" "http://host.docker.internal:11434"
    set_env_value "$ENV_PATH" "INJECTION_OLLAMA_URL" "http://host.docker.internal:11434"
    set_env_value "$ENV_PATH" "AMICA_OLLAMA_MODEL" "qwen2.5:7b"
  fi
}

ensure_workspace_file() {
  local paths=("ark-injection-ai-system")
  local i

  if [[ -f "$WORKSPACE_FILE_PATH" && $FORCE_WORKSPACE_FILE -ne 1 ]]; then
    echo "Skip existing .code-workspace file. Use -ForceWorkspaceFile to overwrite."
    return 0
  fi

  for ((i = 0; i < ${#REPO_NAMES[@]}; i++)); do
    case "${REPO_NAMES[$i]}" in
      google-workspace-mcp)
        [[ $SKIP_GOOGLE_WORKSPACE_MCP -eq 1 ]] && continue
        ;;
      estat-mcp)
        [[ $SKIP_ESTAT_MCP -eq 1 ]] && continue
        ;;
    esac
    paths+=("${REPO_PATHS[$i]}")
  done

  if [[ $DRY_RUN -eq 1 ]]; then
    echo "DRY RUN: write workspace file $WORKSPACE_FILE_PATH"
    return 0
  fi

  {
    printf '{\n'
    printf '  "folders": [\n'
    local idx
    for ((idx = 0; idx < ${#paths[@]}; idx++)); do
      printf '    {"path": "%s"}' "${paths[$idx]}"
      if (( idx + 1 < ${#paths[@]} )); then
        printf ','
      fi
      printf '\n'
    done
    printf '  ],\n'
    printf '  "settings": {\n'
    printf '    "files.exclude": {\n'
    printf '      "**/.git": true,\n'
    printf '      "**/__pycache__": true,\n'
    printf '      "**/.pytest_cache": true\n'
    printf '    }\n'
    printf '  }\n'
    printf '}\n'
  } > "$WORKSPACE_FILE_PATH"
}

start_stack() {
  local compose_files=( -f "$REPO_ROOT/docker-compose.yml" -f "$REPO_ROOT/docker-compose.dev.yml" )
  local services=( amica injection-tool mcp-server sbv2 )
  echo
  echo "Starting development stack via docker compose up -d --build"
  echo "Optional MCP services remain stopped unless you start them explicitly."
  run_cmd docker compose "${compose_files[@]}" up -d --build "${services[@]}"
}

ensure_command git
if [[ $START_STACK -eq 1 ]]; then
  ensure_command docker
fi

echo "Workspace root: $WORKSPACE_ROOT"
echo "Current ark-injection-ai-system root: $REPO_ROOT"
echo "Selected chat backend: $CHAT_BACKEND"

if [[ $SKIP_GOOGLE_WORKSPACE_MCP -eq 1 || $SKIP_ESTAT_MCP -eq 1 ]]; then
  skipped_names=()
  [[ $SKIP_GOOGLE_WORKSPACE_MCP -eq 1 ]] && skipped_names+=("google-workspace-mcp")
  [[ $SKIP_ESTAT_MCP -eq 1 ]] && skipped_names+=("estat-mcp")
  echo "Skipped repositories: ${skipped_names[*]}"
  echo "These repositories are omitted from clone targets and the generated .code-workspace file."
fi

for ((i = 0; i < ${#REPO_NAMES[@]}; i++)); do
  case "${REPO_NAMES[$i]}" in
    google-workspace-mcp)
      [[ $SKIP_GOOGLE_WORKSPACE_MCP -eq 1 ]] && continue
      ;;
    estat-mcp)
      [[ $SKIP_ESTAT_MCP -eq 1 ]] && continue
      ;;
  esac
  ensure_repository_present "${REPO_NAMES[$i]}" "${REPO_PATHS[$i]}" "${REPO_URLS[$i]}"
done

ensure_env_file
ensure_workspace_file

echo
echo "Workspace bootstrap completed."
echo "- .env path: $ENV_PATH"
echo "- workspace file: $WORKSPACE_FILE_PATH"
echo "- Voice models, avatar assets, and character models are not downloaded by this script."
echo "- Review .env and set secrets before public use."

if [[ $START_STACK -eq 1 ]]; then
  start_stack
fi