#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PKG_NAME="agenda-tarsila"
VERSION="${1:-4.0.0}"
DEB="${PKG_NAME}_${VERSION}_all.deb"
BUILD_DIR="$(mktemp -d)"
cleanup() { rm -rf "$BUILD_DIR"; }
trap cleanup EXIT
echo "==> Construindo $DEB..."
cp -a "$SCRIPT_DIR/DEBIAN" "$BUILD_DIR/"
cp -a "$SCRIPT_DIR/src/." "$BUILD_DIR/"
chmod 755 "$BUILD_DIR/DEBIAN/"* 2>/dev/null || true
find "$BUILD_DIR/usr/bin" -type f -exec chmod 755 {} \; 2>/dev/null || true
dpkg-deb --build --root-owner-group "$BUILD_DIR" "$DEB"
echo "==> $DEB gerado."
