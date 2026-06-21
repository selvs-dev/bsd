#!/usr/bin/env bash
set -euo pipefail

WIN_USER="${WIN_USER:-selvino.junior@hotmail.com}"
WIN_IP="${WIN_IP:-192.168.68.111}"
TOKEN_FILE="${HOME}/.config/bsd/win-screenshot.token"

SERVER_TMP=$(mktemp /tmp/screenshot-server-XXXX.ps1)
START_TMP=$(mktemp /tmp/screenshot-start-XXXX.ps1)
STOP_TMP=$(mktemp /tmp/screenshot-stop-XXXX.ps1)
trap 'rm -f "$SERVER_TMP" "$START_TMP" "$STOP_TMP"' EXIT

# Gera token aleatório (ou reutiliza o existente)
if [[ -f "$TOKEN_FILE" ]]; then
  TOKEN=$(cat "$TOKEN_FILE")
  echo "Reutilizando token existente."
else
  TOKEN=$(openssl rand -hex 24)
  mkdir -p "$(dirname "$TOKEN_FILE")"
  echo "$TOKEN" > "$TOKEN_FILE"
  chmod 600 "$TOKEN_FILE"
  echo "Novo token gerado e salvo em $TOKEN_FILE"
fi

# Servidor HTTP com verificação de token
cat > "$SERVER_TMP" << 'PSEOF'
$token = "SCREENSHOT_TOKEN"
Add-Type -AssemblyName System.Windows.Forms, System.Drawing
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add('http://+:8765/')
$listener.Start()
while ($listener.IsListening) {
    $ctx = $listener.GetContext()
    $auth = $ctx.Request.Headers["Authorization"]
    if ($auth -ne "Bearer $token") {
        $ctx.Response.StatusCode = 401
        $ctx.Response.Close()
        continue
    }
    $screen = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
    $bmp = New-Object System.Drawing.Bitmap $screen.Width, $screen.Height
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.CopyFromScreen($screen.Location, [System.Drawing.Point]::Empty, $screen.Size)
    $ms = New-Object System.IO.MemoryStream
    $bmp.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
    $bytes = $ms.ToArray()
    $ctx.Response.ContentType = 'image/png'
    $ctx.Response.ContentLength64 = $bytes.Length
    $ctx.Response.OutputStream.Write($bytes, 0, $bytes.Length)
    $ctx.Response.Close()
}
PSEOF
sed -i "s/SCREENSHOT_TOKEN/$TOKEN/" "$SERVER_TMP"

# Script de start: cria scheduled task na sessão interativa e dispara
cat > "$START_TMP" << 'PSEOF'
$action = New-ScheduledTaskAction `
    -Execute 'powershell.exe' `
    -Argument '-WindowStyle Hidden -NonInteractive -File "C:\Users\Public\screenshot-server.ps1"'
$principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive
Register-ScheduledTask -TaskName "ScreenshotServer" -Action $action -Principal $principal -Force | Out-Null
Start-ScheduledTask -TaskName "ScreenshotServer"
Start-Sleep -Seconds 2
Write-Host "Servidor iniciado na porta 8765."
PSEOF

# Script de stop: mata o processo e remove a task
cat > "$STOP_TMP" << 'PSEOF'
$procs = Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" |
    Where-Object { $_.CommandLine -like '*screenshot-server*' }
if ($procs) {
    $procs | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
    Write-Host "Servidor encerrado."
} else {
    Write-Host "Servidor nao estava rodando."
}
Unregister-ScheduledTask -TaskName "ScreenshotServer" -Confirm:$false -ErrorAction SilentlyContinue
PSEOF

echo "Copiando scripts para Windows..."
scp "$SERVER_TMP" "${WIN_USER}@${WIN_IP}:C:/Users/Public/screenshot-server.ps1"
scp "$START_TMP"  "${WIN_USER}@${WIN_IP}:C:/Users/Public/screenshot-start.ps1"
scp "$STOP_TMP"   "${WIN_USER}@${WIN_IP}:C:/Users/Public/screenshot-stop.ps1"

echo ""
echo "Setup concluído! Token em: $TOKEN_FILE"
echo ""
echo "Use:"
echo "  bsd win-screenshot-start  → sobe o servidor no Windows"
echo "  bsd win-screenshot         → captura para o clipboard"
echo "  bsd win-screenshot-stop   → derruba o servidor"
