#!/bin/bash
# Roda NO MAC (uma vez, e de novo ao trocar de Mac). Autoriza a chave do servidor de desenvolvimento
# com restrições: só do IP informado, sem forwarding/pty, e só executando ~/.mickeeper-ci/gate.sh.
# Uso: scripts/remote/mac-setup.sh "<chave pública ssh-ed25519>" "<IP do servidor>"
set -euo pipefail

PUBKEY="${1:?uso: mac-setup.sh \"<chave pública>\" \"<IP do servidor>\"}"
FROM="${2:?uso: mac-setup.sh \"<chave pública>\" \"<IP do servidor>\"}"

set -- $PUBKEY
[[ ${1:-} == ssh-ed25519 && -n ${2:-} ]] || { echo "chave inválida (esperado ssh-ed25519 AAAA...)" >&2; exit 1; }
KEY="$1 $2"
ip_re='^[0-9]{1,3}(\.[0-9]{1,3}){3}$'
[[ $FROM =~ $ip_re ]] || { echo "IP inválido: $FROM" >&2; exit 1; }

ROOT="$HOME/.mickeeper-ci"
HERE="$(cd "$(dirname "$0")" && pwd)"
mkdir -p "$ROOT" "$HOME/.ssh"
chmod 700 "$ROOT" "$HOME/.ssh"
install -m 700 "$HERE/gate.sh" "$ROOT/gate.sh"

AK="$HOME/.ssh/authorized_keys"
touch "$AK"
chmod 600 "$AK"
# Idempotente: troca a linha anterior marcada com mickeeper-ci.
{ grep -v ' mickeeper-ci$' "$AK" || true; } > "$AK.tmp"
echo "from=\"$FROM\",command=\"$ROOT/gate.sh\",restrict $KEY mickeeper-ci" >> "$AK.tmp"
chmod 600 "$AK.tmp"
mv "$AK.tmp" "$AK"

echo "OK: chave autorizada (somente de $FROM, somente $ROOT/gate.sh)."
nc -z 127.0.0.1 22 2>/dev/null \
  || echo "AVISO: SSH desligado. Ative em Ajustes do Sistema > Geral > Compartilhamento > Sessão remota."
xcrun --find swift >/dev/null 2>&1 \
  || echo "AVISO: sem toolchain Swift. Rode: xcode-select --install"
