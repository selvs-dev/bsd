#!/usr/bin/env bash
# Alterna o layout da sessão GNOME, inclusive no Wayland. Execute sem sudo.
set -euo pipefail

schema=org.gnome.desktop.input-sources

usage() {
    cat <<'EOF'
Uso: teclado.sh [alternar|abnt2|intl|status]

  alternar  Alterna entre ABNT2 e US internacional (padrão).
  abnt2     Seleciona português brasileiro para o teclado do notebook.
  intl      Seleciona US internacional com teclas mortas para acentuação.
  status    Mostra o layout configurado sem alterá-lo.

A seleção é global para os teclados da sessão GNOME e substitui a lista
de fontes de entrada por um único layout. Execute como seu usuário, sem sudo.
EOF
}

case "${1:-alternar}" in
    -h|--help) usage; exit 0 ;;
    alternar|abnt2|br|intl|us|status) ;;
    *) usage >&2; exit 2 ;;
esac

command -v gsettings >/dev/null || {
    echo 'Erro: este script precisa do gsettings do GNOME.' >&2
    exit 1
}
current=$(gsettings get "$schema" sources)
case "$current" in
    "[('xkb', 'br')]") current_mode=abnt2 ;;
    "[('xkb', 'us+intl')]") current_mode=intl ;;
    *) current_mode=outro ;;
esac

mode=${1:-alternar}
if [[ "$mode" == status ]]; then
    printf 'Layout configurado: %s\nFontes: %s\n' "$current_mode" "$current"
    exit 0
fi
if [[ "$mode" == alternar ]]; then
    if [[ "$current_mode" == abnt2 ]]; then mode=intl; else mode=abnt2; fi
fi
case "$mode" in
    abnt2|br) target="[('xkb', 'br')]"; label='Português brasileiro — ABNT2' ;;
    intl|us) target="[('xkb', 'us+intl')]"; label='Inglês (US) internacional — Logitech Pebble Keys 2' ;;
esac

[[ $(gsettings writable "$schema" sources) == true ]] || {
    echo 'Erro: a sessão não permite alterar os layouts.' >&2
    exit 1
}
gsettings set "$schema" sources "$target"
[[ $(gsettings get "$schema" sources) == "$target" ]] || {
    echo 'Erro: não foi possível confirmar o layout selecionado.' >&2
    exit 1
}
printf 'Teclado: %s\n' "$label"
