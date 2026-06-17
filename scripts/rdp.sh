#!/usr/bin/env bash
set -euo pipefail

USER_RDP="MicrosoftAccount\\selvino.junior@hotmail.com"
PASS_RDP="admin"
HOST_RDP="192.168.100.194:3389"

USE_RDESKTOP=false
PAIR=""

for arg in "$@"; do
  if [[ "$arg" == "--rd" ]]; then
    USE_RDESKTOP=true
  elif [[ "$arg" =~ ^[0-9]+(,[0-9]+)*$ ]]; then
    PAIR="$arg"
  fi
done

if $USE_RDESKTOP; then
  nohup rdesktop \
    -u "selvino.junior@hotmail.com" \
    -p "$PASS_RDP" \
    -d "MicrosoftAccount" \
    -r sound:local:alsa \
    -r clipboard:PRIMARYCLIPBOARD \
    -k pt \
    "$HOST_RDP" \
    </dev/null >/tmp/rdp_0.log 2>&1 &
  echo "RDP (rdesktop) iniciado em background (PID: $!). Log: /tmp/rdp_0.log"
  exit 0
fi

if [[ -z "$PAIR" ]]; then
  echo "Monitores detectados:"
  while read -r line; do
    id=$(echo "$line" | awk '{print $1}' | tr -d ':')
    name=$(echo "$line" | awk '{print $NF}')
    res=$(echo "$line" | grep -oP '\d+/\d+x\d+/\d+' | head -1)
    w=$(echo "$res" | grep -oP '^\d+')
    h=$(echo "$res" | grep -oP 'x\d+' | tr -d 'x')
    if (( w > h )); then orient="paisagem"; elif (( h > w )); then orient="retrato"; else orient="quadrado"; fi
    echo "  [$id] $name  ${w}x${h}  ($orient)"
  done < <(xrandr --listmonitors 2>/dev/null | grep -v '^Monitors:')
  echo ""
  echo "Informe os monitores no formato xfreerdp (ex: 3,1 ou 1):"
  echo "  (ou passe como parâmetro: ./rdp.sh 3,1)"
  read -rp "Monitores: " LAYOUT_CHOICE

  if [[ "$LAYOUT_CHOICE" =~ ^[0-9]+(,[0-9]+)*$ ]]; then
    PAIR="$LAYOUT_CHOICE"
  else
    echo "Opção inválida: '$LAYOUT_CHOICE'. Use um número/par (ex: 3,1)."
    exit 1
  fi
fi

nohup xfreerdp \
/u:"$USER_RDP" \
/p:"$PASS_RDP" \
/v:"$HOST_RDP" \
/cert:tofu \
/sec:rdp \
/multimon:force \
/monitors:"$PAIR" \
/dynamic-resolution \
/clipboard \
/audio-mode:0 \
/sound:sys:pulse \
/microphone:sys:pulse \
-decorations \
</dev/null >/tmp/rdp_0.log 2>&1 &

echo "RDP iniciado em background (PID: $!). Log: /tmp/rdp_0.log"
