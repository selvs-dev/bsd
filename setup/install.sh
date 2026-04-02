#!/usr/bin/env bash
set -euo pipefail

REPO="https://github.com/selvs-dev/bsd.git"
INSTALL_DIR="$HOME/.bsd"

echo ""
echo "  Installing bySelvs Doctor (bsd)..."
echo ""

# Verificar dependências
if ! command -v git &>/dev/null; then
    echo "  [erro] git não encontrado. Instale o git e tente novamente."
    exit 1
fi

# Clonar ou atualizar
if [[ -d "$INSTALL_DIR/.git" ]]; then
    echo "  [info] Diretório $INSTALL_DIR já existe, atualizando..."
    git -C "$INSTALL_DIR" pull --ff-only
else
    echo "  [info] Clonando repositório em $INSTALL_DIR..."
    git clone --depth=1 "$REPO" "$INSTALL_DIR"
fi

chmod +x "$INSTALL_DIR/bsd"

echo ""
"$INSTALL_DIR/bsd" --install

echo ""
echo "  [ok] Instalação concluída!"
echo "  Reabra o terminal ou execute: source ~/.bashrc  (ou ~/.zshrc)"
echo ""
