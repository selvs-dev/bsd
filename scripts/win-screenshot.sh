#!/usr/bin/env bash
set -euo pipefail

WIN_IP="${WIN_IP:-192.168.68.111}"
WIN_PORT="${WIN_PORT:-8765}"
TOKEN_FILE="${HOME}/.config/bsd/win-screenshot.token"

if [[ ! -f "$TOKEN_FILE" ]]; then
  echo "Token não encontrado. Execute: bsd win-screenshot-setup" >&2
  exit 1
fi

TOKEN=$(cat "$TOKEN_FILE")
BASE_URL="http://$WIN_IP:$WIN_PORT"

LIST_MONITORS=false
MONITOR_IDX=""
OUTFILE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --monitors|-l)
      LIST_MONITORS=true
      shift
      ;;
    --monitor=*)
      MONITOR_IDX="${1#--monitor=}"
      shift
      ;;
    -m)
      MONITOR_IDX="$2"
      shift 2
      ;;
    *)
      OUTFILE="$1"
      shift
      ;;
  esac
done

curl_err() {
  echo "Erro: servidor não disponível. Rode: bsd win-screenshot-start" >&2
  exit 1
}

if $LIST_MONITORS; then
  curl -sf --max-time 5 -H "Authorization: Bearer $TOKEN" "$BASE_URL/monitors" \
    | python3 -c "
import json, sys
monitors = json.load(sys.stdin)
if not isinstance(monitors, list):
    monitors = [monitors]
for m in monitors:
    primary = ' (primary)' if m.get('primary') else ''
    print(f\"  [{m['index']}] {m['width']}x{m['height']}  {m['name']}{primary}\")
" || curl_err
  exit 0
fi

URL="$BASE_URL/"
if [[ -n "$MONITOR_IDX" ]]; then
  URL="${URL}?monitor=${MONITOR_IDX}"
fi

if [[ -n "$OUTFILE" ]]; then
  curl -sf --max-time 5 -H "Authorization: Bearer $TOKEN" "$URL" -o "$OUTFILE" \
    || curl_err
  echo "Screenshot salvo em: $OUTFILE"
else
  curl -sf --max-time 5 -H "Authorization: Bearer $TOKEN" "$URL" \
    | wl-copy --type image/png \
    || curl_err
  echo "Screenshot no clipboard!"
fi
