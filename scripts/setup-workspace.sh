#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
POWERSHELL_SCRIPT="$SCRIPT_DIR/setup-workspace.ps1"

if ! command -v pwsh >/dev/null 2>&1; then
  echo "pwsh is required to run setup-workspace in WSL/Linux." >&2
  echo "Install PowerShell 7, then run: ./scripts/setup-workspace.sh ..." >&2
  exit 1
fi

exec pwsh -NoLogo -NoProfile -File "$POWERSHELL_SCRIPT" "$@"