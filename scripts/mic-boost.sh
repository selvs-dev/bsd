#!/usr/bin/env bash
set -euo pipefail

CURRENT=$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@ | grep -oP '[\d.]+')
CURRENT_PCT=$(echo "$CURRENT * 100 / 1" | bc)

SOURCE_NAME=$(wpctl status 2>/dev/null | awk '
  /^Audio/ { in_audio=1 }
  in_audio && /Sources:/ { in_sources=1; next }
  in_sources && /Filters:/ { exit }
  in_sources && /\*/ && /[0-9]+\./ { print }
' | grep -oP '(?<=\d\. ).+' | sed 's/\s*\[vol:.*//; s/\s*$//')
SOURCE_NAME="${SOURCE_NAME:-desconhecido}"

echo "Fonte atual: $SOURCE_NAME"
echo "Boost atual: ${CURRENT_PCT}%"
echo ""
read -rp "Novo boost (%): " INPUT

if [[ ! "$INPUT" =~ ^[0-9]+$ ]]; then
  echo "Valor inválido."; exit 1
fi

wpctl set-volume @DEFAULT_AUDIO_SOURCE@ "${INPUT}%"
echo "Boost definido: ${INPUT}%"
