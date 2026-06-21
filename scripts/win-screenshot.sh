#!/usr/bin/env bash
set -euo pipefail

WIN_IP="${WIN_IP:-192.168.68.111}"
WIN_PORT="${WIN_PORT:-8765}"
TOKEN_FILE="${HOME}/.config/bsd/win-screenshot.token"
OUTFILE="${1:-}"

if [[ ! -f "$TOKEN_FILE" ]]; then
  echo "Token não encontrado. Execute: bsd win-screenshot-setup" >&2
  exit 1
fi

TOKEN=$(cat "$TOKEN_FILE")
url="http://$WIN_IP:$WIN_PORT/"

if [[ -n "$OUTFILE" ]]; then
  curl -sf --max-time 5 -H "Authorization: Bearer $TOKEN" "$url" -o "$OUTFILE" \
    || { echo "Erro: servidor não disponível. Rode: bsd win-screenshot-start" >&2; exit 1; }
  echo "Screenshot salvo em: $OUTFILE"
else
  curl -sf --max-time 5 -H "Authorization: Bearer $TOKEN" "$url" \
    | wl-copy --type image/png \
    || { echo "Erro: servidor não disponível. Rode: bsd win-screenshot-start" >&2; exit 1; }
  echo "Screenshot no clipboard!"
fi
