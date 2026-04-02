#!/usr/bin/env bash
set -euo pipefail

USER_RDP="Docker"
PASS_RDP="admin"
HOST_RDP="127.0.0.1"

ARG="${1:-}"

if [[ "$ARG" =~ ^[0-9]+(,[0-9]+)*$ ]]; then
  PAIR="$ARG"
elif [[ "${ARG^^}" =~ ^[ABC]$ ]]; then
  case "${ARG^^}" in
    A) PAIR="3,1" ;;
    B) PAIR="1" ;;
    C) PAIR="3" ;;
  esac
else
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
  echo "Escolha o layout de monitores:"
  echo "  (ou passe como parâmetro: ./rdp.sh A  |  ./rdp.sh 3,1)"
  echo ""
  echo "  A) 2 monitores - Centro Direita    [monitors: 3,1]"
  echo "       [     ] [ ]"
  echo "    [ ] [ X ] [X]"
  echo "    [ ]"
  echo ""
  echo "  B) 1 monitor - Direita             [monitors: 1]"
  echo "       [     ] [ ]"
  echo "    [ ] [   ] [X]"
  echo "    [ ]"
  echo ""
  echo "  C) 1 monitor - Centro              [monitors: 3]"
  echo "       [     ] [ ]"
  echo "    [ ] [ X ] [ ]"
  echo "    [ ]"
  echo ""
  read -rp "Layout [A/B/C ou monitors: ex 3,1]: " LAYOUT_CHOICE

  if [[ "$LAYOUT_CHOICE" =~ ^[0-9]+(,[0-9]+)*$ ]]; then
    PAIR="$LAYOUT_CHOICE"
  else
    case "${LAYOUT_CHOICE^^}" in
      A) PAIR="3,1" ;;
      B) PAIR="1" ;;
      C) PAIR="3" ;;
      *)
        echo "Opção inválida: '$LAYOUT_CHOICE'. Use A, B, C ou um número/par (ex: 3,1)."
        exit 1
        ;;
    esac
  fi
fi

nohup xfreerdp3 \
/u:"$USER_RDP" \
/p:"$PASS_RDP" \
/v:"$HOST_RDP" \
/cert:tofu \
/multimon \
/monitors:"$PAIR" \
/dynamic-resolution \
/clipboard \
/audio-mode:0 \
/sound \
/microphone \
-decorations \
</dev/null >/tmp/rdp_0.log 2>&1 &

echo "RDP iniciado em background (PID: $!). Log: /tmp/rdp_0.log"



