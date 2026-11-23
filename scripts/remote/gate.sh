#!/bin/bash
# Roda NO MAC, como `command=` da chave SSH do servidor de desenvolvimento.
# É o único comando que essa chave pode executar; tudo fica em ~/.mickeeper-ci.
# (bash 3.2 do macOS: sem recursos do bash 4+.)
set -euo pipefail

ROOT="$HOME/.mickeeper-ci"
SRC="$ROOT/src"
export PATH="/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin:/usr/local/bin"

read -r -a args <<< "${SSH_ORIGINAL_COMMAND:-}"
action="${args[0]:-}"

case "$action" in
  status)
    echo "arch: $(uname -m)  macOS: $(sw_vers -productVersion)"
    swift --version 2>&1 | head -1
    ;;
  put) # stdin: tar do projeto; substitui $SRC (bsdtar recusa caminhos absolutos e ..)
    rm -rf "$SRC"
    mkdir -p "$SRC"
    tar -x -f - -C "$SRC"
    ;;
  test)
    cd "$SRC"
    exec swift test
    ;;
  bundle) # bundle [versão]
    version="${args[1]:-$(tr -d '[:space:]' < "$SRC/VERSION")}"
    re='^[0-9A-Za-z.+-]+$'
    [[ $version =~ $re ]] || { echo "versão inválida" >&2; exit 2; }
    cd "$SRC"
    exec scripts/bundle.sh "$version"
    ;;
  get) # stdout: tar de build/
    tar -c -f - -C "$SRC/build" .
    ;;
  *)
    echo "ação não permitida: use status | put | test | bundle [versão] | get" >&2
    exit 2
    ;;
esac
