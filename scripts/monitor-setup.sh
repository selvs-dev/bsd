#!/usr/bin/env bash
set -euo pipefail

echo "=== Setup: Display Virtual para notebook via Sunshine ==="
echo ""

# 1. Grupo video (necessário para abrir /dev/dri/card*)
echo "[1/4] Verificando grupo video..."
if groups | grep -qw "video"; then
  echo "      OK: usuário já está no grupo video."
else
  echo "      Adicionando ao grupo video..."
  sudo usermod -aG video "$USER"
  echo "      OK: adicionado. ATENÇÃO: faça logout e login para ter efeito."
fi

# 2. Carrega o módulo evdi
echo "[2/4] Verificando módulo evdi..."
if lsmod | grep -q "^evdi"; then
  echo "      OK: evdi já está carregado."
else
  echo "      Carregando evdi..."
  sudo modprobe evdi && echo "      OK: evdi carregado." || { echo "      ERRO: sudo apt install evdi-dkms"; exit 1; }
fi

# 3. Cria dispositivo evdi (se ainda não existir)
echo "[3/4] Verificando dispositivo evdi..."
EVDI_DEVICES=$(ls /sys/devices/evdi/ 2>/dev/null | grep -c "^evdi\." || true)

if [[ "$EVDI_DEVICES" -gt 0 ]]; then
  echo "      OK: $EVDI_DEVICES dispositivo(s) evdi já existem."
else
  echo "      Criando dispositivo evdi..."
  echo 1 | sudo tee /sys/devices/evdi/add > /dev/null
  sleep 1
  echo "      OK: dispositivo criado."
fi

# 4. Testa se o daemon consegue abrir o device
echo "[4/4] Testando acesso ao dispositivo evdi..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if python3 -c "
import ctypes, sys
lib = ctypes.CDLL('/usr/lib/libevdi.so.1')
lib.evdi_check_device.restype = ctypes.c_int
lib.evdi_open.restype = ctypes.c_void_p
for i in range(0, 16):
    if lib.evdi_check_device(ctypes.c_int(i)) == 1:
        h = lib.evdi_open(ctypes.c_int(i))
        if h:
            lib.evdi_close(ctypes.c_void_p(h))
            print(f'OK: card{i} acessível')
            sys.exit(0)
        else:
            print(f'ERRO: card{i} encontrado mas sem permissão de acesso')
            sys.exit(1)
print('ERRO: nenhum dispositivo evdi disponível')
sys.exit(1)
" 2>&1; then
  echo ""
  echo "Setup completo. Use 'bsd monitor-on' para iniciar o monitor virtual."
else
  echo ""
  echo "ATENÇÃO: faça logout e login para o grupo video ter efeito, depois rode monitor-setup novamente."
fi
