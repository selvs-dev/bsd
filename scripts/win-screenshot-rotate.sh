#!/usr/bin/env bash
set -euo pipefail

TOKEN_FILE="${HOME}/.config/bsd/win-screenshot.token"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Rotacionando token..."
rm -f "$TOKEN_FILE"

echo "Reinstalando servidor com novo token..."
bash "$SCRIPT_DIR/win-screenshot-setup.sh"

echo "Reiniciando servidor no Windows..."
bash "$SCRIPT_DIR/win-screenshot-stop.sh"  2>/dev/null || true
bash "$SCRIPT_DIR/win-screenshot-start.sh"
