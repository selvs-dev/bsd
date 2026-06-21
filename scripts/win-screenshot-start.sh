#!/usr/bin/env bash
set -euo pipefail

WIN_USER="${WIN_USER:-selvino.junior@hotmail.com}"
WIN_IP="${WIN_IP:-192.168.68.111}"

ssh "${WIN_USER}@${WIN_IP}" powershell -File 'C:\Users\Public\screenshot-start.ps1'
