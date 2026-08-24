#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PKG_NAME="agenda-tarsila"
# A versao vem do DEBIAN/control, que e a fonte unica. Escrita a mao aqui
# tambem, ela vira duas verdades que envelhecem separado: no
# tarsila-app-management as duas ja tinham divergido, e o pacote saia com um
# numero no nome e outro por dentro.
VERSION="${1:-$(sed -n 's/^Version: *//p' "$SCRIPT_DIR/DEBIAN/control" | head -1)}"
[ -n "$VERSION" ] || { echo "ERRO: sem Version: em DEBIAN/control" >&2; exit 1; }
DEB="${PKG_NAME}_${VERSION}_all.deb"
BUILD_DIR="$(mktemp -d)"
cleanup() { rm -rf "$BUILD_DIR"; }
trap cleanup EXIT
# Credencial do Google: fica FORA do Git (o .gitignore barra), e por isso
# precisa ser colocada a mao na maquina de build. Sem ela o pacote sai
# inteiro e funcional -- so que a Agenda vai pedir o arquivo na tela de
# login, em vez de ja vir com o cliente OAuth do produto.
#
# Isto e um aviso, nao um erro: build sem credencial e legitimo (em
# desenvolvimento, ou para quem vai usar o proprio cliente OAuth).
CRED="$SCRIPT_DIR/src/etc/agenda-tarsila/credentials.json"
if [ -f "$CRED" ]; then
  if grep -q '"installed"' "$CRED" 2>/dev/null; then
    echo "==> credentials.json encontrado (cliente 'App para desktop')."
  else
    echo "AVISO: $CRED nao parece um cliente OAuth do tipo 'App para desktop'." >&2
    echo "       A Agenda recusa cliente 'Aplicativo Web'. Veja o README.md." >&2
  fi
else
  echo "AVISO: sem src/etc/agenda-tarsila/credentials.json -- o pacote vai sair" >&2
  echo "       SEM o cliente OAuth, e cada usuario tera de fornecer o proprio." >&2
  echo "       Para embarcar, veja 'As credenciais do Google' no README.md." >&2
fi

echo "==> Construindo $DEB..."
cp -a "$SCRIPT_DIR/DEBIAN" "$BUILD_DIR/"
cp -a "$SCRIPT_DIR/src/." "$BUILD_DIR/"
chmod 755 "$BUILD_DIR/DEBIAN/"* 2>/dev/null || true
find "$BUILD_DIR/usr/bin" -type f -exec chmod 755 {} \; 2>/dev/null || true
find "$BUILD_DIR/usr/local/bin" -type f -exec chmod 755 {} \; 2>/dev/null || true
dpkg-deb --build --root-owner-group "$BUILD_DIR" "$DEB"
echo "==> $DEB gerado."
