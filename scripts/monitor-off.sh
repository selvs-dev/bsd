#!/usr/bin/env bash
set -euo pipefail

echo "Encerrando Sunshine..."
pkill -f "sunshine" 2>/dev/null && echo "  OK" || echo "  (não estava rodando)"

echo "Encerrando evdi-daemon..."
if [[ -f /tmp/evdi-daemon.pid ]]; then
  kill "$(cat /tmp/evdi-daemon.pid)" 2>/dev/null && echo "  OK" || echo "  (processo já encerrado)"
  rm -f /tmp/evdi-daemon.pid
else
  pkill -f "evdi-daemon.py" 2>/dev/null && echo "  OK" || echo "  (não estava rodando)"
fi

echo "Removendo módulo evdi..."
sudo modprobe -r evdi 2>/dev/null && echo "  OK" || echo "  (não estava carregado)"
