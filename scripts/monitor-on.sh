#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Carregando módulo evdi..."
sudo modprobe evdi

echo "Criando dispositivo evdi (se necessário)..."
EVDI_DEVICES=$(ls /sys/devices/evdi/ 2>/dev/null | grep -c "^evdi\." || true)
if [[ "$EVDI_DEVICES" -eq 0 ]]; then
  echo 1 | sudo tee /sys/devices/evdi/add > /dev/null
  sleep 1
fi

echo "Iniciando daemon de display virtual..."
python3 "$SCRIPT_DIR/evdi-daemon.py" </dev/null >/tmp/evdi-daemon.log 2>&1 &
EVDI_PID=$!
echo "$EVDI_PID" > /tmp/evdi-daemon.pid
echo "  evdi-daemon PID: $EVDI_PID — log: /tmp/evdi-daemon.log"
sleep 2

echo "Iniciando Sunshine..."
flatpak run dev.lizardbyte.app.Sunshine </dev/null >/tmp/sunshine.log 2>&1 &
echo "  Sunshine PID: $! — log: /tmp/sunshine.log"

echo ""
echo "Monitor virtual ativo. Acesse https://localhost:47990"
echo "Abra o Moonlight no notebook para conectar."
