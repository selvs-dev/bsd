#!/usr/bin/env bash
set -euo pipefail

SOURCE=$(pw-metadata 0 2>/dev/null | grep 'default.audio.source' | grep -oP '(?<="name":")[^"]+' | head -1)
SOURCE="${SOURCE:-@DEFAULT_AUDIO_SOURCE@}"

FILE="/tmp/bsd-mic-test-loop.wav"

echo "Loop de mic test iniciado. Ctrl+C para parar."
echo ""

trap 'echo ""; echo "Parado."; exit 0' INT

while true; do
  echo "--- Gravando 4s... fale agora ---"
  pw-record --target "$SOURCE" "$FILE" &
  REC_PID=$!
  sleep 4
  kill $REC_PID 2>/dev/null
  wait $REC_PID 2>/dev/null || true
  sleep 0.4
  echo "Reproduzindo..."
  pw-play "$FILE"
  echo ""
done
