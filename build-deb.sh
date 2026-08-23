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
echo "==> Construindo $DEB..."
cp -a "$SCRIPT_DIR/DEBIAN" "$BUILD_DIR/"
cp -a "$SCRIPT_DIR/src/." "$BUILD_DIR/"
chmod 755 "$BUILD_DIR/DEBIAN/"* 2>/dev/null || true
find "$BUILD_DIR/usr/bin" -type f -exec chmod 755 {} \; 2>/dev/null || true
find "$BUILD_DIR/usr/local/bin" -type f -exec chmod 755 {} \; 2>/dev/null || true
dpkg-deb --build --root-owner-group "$BUILD_DIR" "$DEB"
echo "==> $DEB gerado."
