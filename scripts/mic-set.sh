#!/usr/bin/env bash
set -euo pipefail

mapfile -t SOURCE_LINES < <(wpctl status 2>/dev/null | awk '
  /^Audio/ { in_audio=1 }
  in_audio && /Sources:/ { in_sources=1; next }
  in_sources && /Filters:/ { exit }
  in_sources && /[0-9]+\./ { print }
')

if [[ ${#SOURCE_LINES[@]} -eq 0 ]]; then
  echo "Nenhuma fonte de áudio encontrada."
  exit 1
fi

IDS=()
NAMES=()
DEFAULTS=()

for line in "${SOURCE_LINES[@]}"; do
  id=$(echo "$line" | grep -oP '\d+(?=\.)')
  name=$(echo "$line" | grep -oP '(?<=\d\. ).+' | sed 's/\s*\[vol:.*//; s/\s*$//')
  is_default=$([[ "$line" =~ \* ]] && echo true || echo false)
  IDS+=("$id")
  NAMES+=("$name")
  DEFAULTS+=("$is_default")
done

echo "Fontes de microfone disponíveis:"
for i in "${!IDS[@]}"; do
  marker=$([[ "${DEFAULTS[$i]}" == true ]] && echo " *" || echo "")
  echo "  [$((i+1))] ${NAMES[$i]}$marker"
done
echo ""
read -rp "Selecione [1-${#IDS[@]}]: " choice

idx=$((choice - 1))
if [[ $idx -lt 0 || $idx -ge ${#IDS[@]} ]]; then
  echo "Opção inválida."; exit 1
fi

node_name=$(wpctl inspect "${IDS[$idx]}" 2>/dev/null | grep -oP '(?<=node\.name = ")[^"]+')
pw-metadata 0 default.audio.source "{\"name\":\"$node_name\"}"
echo "Fonte definida: ${NAMES[$idx]}"
