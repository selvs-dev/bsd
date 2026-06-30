#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

ok() { echo -e "${GREEN}✓ $1${NC}"; }
fail() { echo -e "${RED}✗ $1${NC}"; echo -e "${YELLOW}  → $2${NC}"; }

echo ""
echo "=== Environment Check ==="
echo ""

# Java
if command -v java &>/dev/null; then
    ok "Java: $(java -version 2>&1 | head -1)"
else
    fail "Java não encontrado" "sdk install java 25-open"
fi

# Node
if command -v node &>/dev/null; then
    ok "Node: $(node --version)"
else
    fail "Node não encontrado" "nvm install --lts"
fi

# npm
if command -v npm &>/dev/null; then
    ok "npm: $(npm --version)"
else
    fail "npm não encontrado" "nvm install --lts"
fi

# Python
if command -v python3 &>/dev/null; then
    ok "Python: $(python3 --version)"
else
    fail "Python não encontrado" "sudo apt install -y python3"
fi

# pip
if command -v pip3 &>/dev/null; then
    ok "pip: $(pip3 --version | awk '{print $1, $2}')"
else
    fail "pip não encontrado" "sudo apt install -y python3-pip"
fi

# nvm
if [ -d "$HOME/.nvm" ]; then
    ok "nvm: $(. "$HOME/.nvm/nvm.sh" && nvm --version)"
else
    fail "nvm não encontrado" "curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash"
fi

# sdkman
if [ -d "$HOME/.sdkman" ]; then
    ok "sdkman: instalado"
else
    fail "sdkman não encontrado" "curl -s https://get.sdkman.io | bash"
fi

# Claude Code
if command -v claude &>/dev/null; then
    ok "Claude Code: $(claude --version 2>/dev/null || echo 'instalado')"
else
    fail "Claude Code não encontrado" "npm install -g @anthropic-ai/claude-code"
fi

# git
if command -v git &>/dev/null; then
    ok "git: $(git --version)"
else
    fail "git não encontrado" "sudo apt install -y git"
fi

# curl
if command -v curl &>/dev/null; then
    ok "curl: $(curl --version | head -1)"
else
    fail "curl não encontrado" "sudo apt install -y curl"
fi

echo ""