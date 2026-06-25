#!/usr/bin/env bash
set -euo pipefail

wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle

MUTED=$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@ | grep -o 'MUTED' || true)

if [[ -n "$MUTED" ]]; then
  echo "Microfone: MUTADO"
else
  echo "Microfone: ATIVO"
fi
