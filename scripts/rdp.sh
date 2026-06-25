#!/usr/bin/env bash
set -euo pipefail

CONFIG_DIR="$HOME/.config/rdp"
mkdir -p "$CONFIG_DIR"

declare -A DEFAULT_USER DEFAULT_HOST DEFAULT_SEC DEFAULT_CERT
DEFAULT_USER[local]='MicrosoftAccount\selvino.junior@hotmail.com'
DEFAULT_USER[remote]='Administrator'
DEFAULT_HOST[local]='192.168.100.252:3389'
DEFAULT_HOST[remote]='54.233.120.172:3389'
DEFAULT_SEC[local]='rdp'
DEFAULT_SEC[remote]='nla'
DEFAULT_CERT[local]='tofu'
DEFAULT_CERT[remote]='ignore'
PROFILES=(local remote)

conf_get() {
  local conf="$CONFIG_DIR/$1.conf" key="$2"
  [[ -f "$conf" ]] && grep "^${key}=" "$conf" | head -1 | cut -d= -f2- | tr -d '"' || echo ""
}

PROFILE=""
PAIR=""
INTERACTIVE=false

for arg in "$@"; do
  case "$arg" in
    --config) INTERACTIVE=true ;;
    local|remote) PROFILE="$arg" ;;
    *) [[ "$arg" =~ ^[0-9]+(,[0-9]+)*$ ]] && PAIR="$arg" || true ;;
  esac
done

LAST_PROFILE_FILE="$CONFIG_DIR/last_profile"
LAST_PROFILE=$([[ -f "$LAST_PROFILE_FILE" ]] && cat "$LAST_PROFILE_FILE" || echo "")

# Seleção de perfil: obrigatório se não há último salvo ou se --config foi passado
if [[ -z "$PROFILE" ]]; then
  if $INTERACTIVE || [[ -z "$LAST_PROFILE" ]]; then
    echo "Selecione o perfil:"
    for i in "${!PROFILES[@]}"; do
      p="${PROFILES[$i]}"
      host=$(conf_get "$p" SAVED_HOST); host="${host:-${DEFAULT_HOST[$p]}}"
      user=$(conf_get "$p" SAVED_USER); user="${user:-${DEFAULT_USER[$p]}}"
      marker=$([[ "$p" == "$LAST_PROFILE" ]] && echo " *" || echo "")
      echo "  [$((i+1))] $p$marker  —  $user @ $host"
    done
    echo ""
    read -rp "Perfil [1-${#PROFILES[@]}]: " choice
    idx=$((choice - 1))
    if [[ $idx -lt 0 || $idx -ge ${#PROFILES[@]} ]]; then
      echo "Opção inválida."; exit 1
    fi
    PROFILE="${PROFILES[$idx]}"
  else
    PROFILE="$LAST_PROFILE"
  fi
fi

echo "$PROFILE" > "$LAST_PROFILE_FILE"

USER_RDP=$(conf_get "$PROFILE" SAVED_USER); USER_RDP="${USER_RDP:-${DEFAULT_USER[$PROFILE]}}"
HOST_RDP=$(conf_get "$PROFILE" SAVED_HOST); HOST_RDP="${HOST_RDP:-${DEFAULT_HOST[$PROFILE]}}"
SAVED_MONITORS=$(conf_get "$PROFILE" LAST_MONITORS)
SAVED_PASS_ENC=$(conf_get "$PROFILE" SAVED_PASS)
SEC_RDP="${DEFAULT_SEC[$PROFILE]}"
CERT_RDP="${DEFAULT_CERT[$PROFILE]}"

if $INTERACTIVE; then
  echo ""
  echo "Perfil: $PROFILE"

  read -rp "Usuário [$USER_RDP]: " input; [[ -n "$input" ]] && USER_RDP="$input"
  read -rp "Host    [$HOST_RDP]: " input; [[ -n "$input" ]] && HOST_RDP="$input"

  if [[ -z "$PAIR" ]]; then
    echo ""
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
    prompt="Monitores"
    [[ -n "$SAVED_MONITORS" ]] && prompt+=" [$SAVED_MONITORS]"
    read -rp "$prompt: " LAYOUT_CHOICE
    LAYOUT_CHOICE="${LAYOUT_CHOICE:-$SAVED_MONITORS}"
    if [[ ! "$LAYOUT_CHOICE" =~ ^[0-9]+(,[0-9]+)*$ ]]; then
      echo "Opção inválida: '$LAYOUT_CHOICE'."; exit 1
    fi
    PAIR="$LAYOUT_CHOICE"
  fi
else
  if [[ -z "$PAIR" ]]; then
    if [[ -z "$SAVED_MONITORS" ]]; then
      echo "Sem configuração salva. Execute com --config para configurar pela primeira vez."
      exit 1
    fi
    PAIR="$SAVED_MONITORS"
  fi
fi

if [[ "$SEC_RDP" == "nla" ]]; then
  if [[ -n "$SAVED_PASS_ENC" ]]; then
    read -rsp "Senha ($USER_RDP @ $HOST_RDP) [Enter para usar salva]: " PASS_RDP
    echo
    if [[ -z "$PASS_RDP" ]]; then
      PASS_RDP=$(echo "$SAVED_PASS_ENC" | base64 -d)
    else
      SAVED_PASS_ENC=$(echo -n "$PASS_RDP" | base64)
    fi
  else
    read -rsp "Senha ($USER_RDP @ $HOST_RDP): " PASS_RDP
    echo
    SAVED_PASS_ENC=$(echo -n "$PASS_RDP" | base64)
  fi
fi

cat > "$CONFIG_DIR/$PROFILE.conf" <<EOF
SAVED_USER="$USER_RDP"
SAVED_HOST="$HOST_RDP"
LAST_MONITORS="$PAIR"
SAVED_PASS="$SAVED_PASS_ENC"
EOF

XFREERDP_ARGS=(
  /u:"$USER_RDP"
  /v:"$HOST_RDP"
  /cert:"$CERT_RDP"
  /sec:"$SEC_RDP"
  /kbd:layout:0x00000416,lang:0x0416
  /multimon:force
  /monitors:"$PAIR"
  /dynamic-resolution
  /clipboard
  /audio-mode:0
  /sound:sys:pulse
  /microphone:sys:pulse
  -decorations
)

if [[ "$PROFILE" == "remote" ]]; then
  XFREERDP_ARGS+=(
    /network:wan
    /bpp:16
    -wallpaper
    -themes
    -fonts
    -menu-anims
  )
fi

if [[ "$SEC_RDP" == "nla" ]]; then
  XFREERDP_ARGS+=("/p:$PASS_RDP")
fi

xfreerdp "${XFREERDP_ARGS[@]}" >/tmp/rdp_0.log 2>&1 &
RDP_PID=$!
disown $RDP_PID

sleep 3
if ! kill -0 "$RDP_PID" 2>/dev/null; then
  echo ""
  echo "Falha ao conectar. Log:"
  echo "---"
  cat /tmp/rdp_0.log
  exit 1
fi

echo "RDP iniciado (PID: $RDP_PID) | perfil: $PROFILE | $USER_RDP @ $HOST_RDP | log: /tmp/rdp_0.log"
