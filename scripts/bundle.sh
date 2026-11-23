#!/usr/bin/env bash
# Gera build/MicKeeper.app (universal, assinatura ad-hoc) e build/MicKeeper-<versão>.zip.
# Uso: scripts/bundle.sh [versão]   (padrão: arquivo VERSION)
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION="${1:-$(tr -d '[:space:]' < VERSION)}"
APP="build/MicKeeper.app"

swift build -c release --arch arm64 --arch x86_64
BIN="$(swift build -c release --arch arm64 --arch x86_64 --show-bin-path)/MicKeeper"

rm -rf build
mkdir -p "$APP/Contents/MacOS"
cp "$BIN" "$APP/Contents/MacOS/MicKeeper"
sed "s/__VERSION__/$VERSION/g" Resources/Info.plist > "$APP/Contents/Info.plist"

codesign --force --deep --sign - "$APP"
ditto -c -k --keepParent "$APP" "build/MicKeeper-$VERSION.zip"
(cd build && shasum -a 256 "MicKeeper-$VERSION.zip" | tee "MicKeeper-$VERSION.zip.sha256")
