#!/usr/bin/env bash
set -euo pipefail

INSTALL_DIR="$HOME/.bsd"
removed=0

echo ""
echo "  Uninstalling bySelvs Doctor (bsd)..."
echo ""

for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
    if [[ -f "$rc" ]] && grep -qF 'bsd' "$rc"; then
        sed -i '/# bsd - adicionado por --install/d' "$rc"
        sed -i '/export PATH=.*\.bsd/d' "$rc"
        sed -i '/export PATH=.*\/bsd/d' "$rc"
        echo "  [ok]  Entradas removidas de $rc"
        removed=1
    fi
done

if [[ -d "$INSTALL_DIR" ]]; then
    rm -rf "$INSTALL_DIR"
    echo "  [ok]  Diretório $INSTALL_DIR removido"
    removed=1
fi

if [[ $removed -eq 1 ]]; then
    echo ""
    echo "  Desinstalação concluída. Reabra o terminal para aplicar."
else
    echo "  [aviso]  Nada encontrado para remover."
fi
echo ""
