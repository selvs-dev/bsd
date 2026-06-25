#!/usr/bin/env bash
set -euo pipefail

SOURCE=$(wpctl status | grep "\*.*PCM2902" | grep -oP '\d+(?=\.)' | head -1)
SOURCE="${SOURCE:-@DEFAULT_AUDIO_SOURCE@}"

FILE="/tmp/bsd-mic-test.wav"

echo "Gravando 4 segundos... fale agora"
pw-record --target "$SOURCE" "$FILE" &
REC_PID=$!
sleep 4
kill $REC_PID 2>/dev/null
wait $REC_PID 2>/dev/null || true
sleep 0.4

echo "Reproduzindo..."
pw-play "$FILE"
