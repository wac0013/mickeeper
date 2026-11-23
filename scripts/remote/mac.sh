#!/usr/bin/env bash
# Roda NO SERVIDOR LINUX: envia o projeto ao Mac e executa test/bundle lá.
# Uso: scripts/remote/mac.sh status | test | bundle [versão]
# Host SSH: alias `macbuild` em ~/.ssh/config (ou MAC_HOST=...). Artefatos do bundle vão para ./build.
set -euo pipefail
cd "$(dirname "$0")/../.."

HOST="${MAC_HOST:-macbuild}"
action="${1:-}"

push() {
  tar -c -f - --exclude=./.git --exclude=./.build --exclude=./build --exclude=./.ia . | ssh "$HOST" put
}

case "$action" in
  status) ssh "$HOST" status ;;
  test)   push; ssh "$HOST" test ;;
  bundle)
    push
    ssh "$HOST" bundle ${2:+"$2"}
    rm -rf build && mkdir build
    ssh "$HOST" get | tar -x -f - -C build
    ls -1 build
    ;;
  *) echo "uso: $0 status | test | bundle [versão]" >&2; exit 2 ;;
esac
