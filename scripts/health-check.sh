#!/usr/bin/env bash
set -euo pipefail

WIN_ID=$(DISPLAY=:0 xwininfo -root -tree 2>/dev/null | grep -i "FreeRDP" | awk '{print $1}' | head -1)

if [[ -z "$WIN_ID" ]]; then
  echo "Janela FreeRDP não encontrada. Conecte via RDP primeiro."
  exit 1
fi

DISPLAY=:0 python3 -c "
from Xlib import display, X
from Xlib.protocol import event

d = display.Display(':0')
root = d.screen().root
win = d.create_resource_object('window', $WIN_ID)
NET_ACTIVE_WINDOW = d.intern_atom('_NET_ACTIVE_WINDOW')
ev = event.ClientMessage(window=win, client_type=NET_ACTIVE_WINDOW, data=(32, [2, X.CurrentTime, 0, 0, 0]))
root.send_event(ev, event_mask=X.SubstructureRedirectMask | X.SubstructureNotifyMask)
d.flush()
"

sleep 0.5
ydotool type "ctcDoctor health-check"
ydotool key 28:1 28:0
