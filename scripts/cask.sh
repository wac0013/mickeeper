#!/usr/bin/env bash
# Imprime o cask do Homebrew. Uso: scripts/cask.sh <versão> <sha256>
set -euo pipefail
VERSION="$1"
SHA="$2"

cat <<EOF
cask "mickeeper" do
  version "$VERSION"
  sha256 "$SHA"

  url "https://github.com/wac0013/mickeeper/releases/download/v#{version}/MicKeeper-#{version}.zip"
  name "MicKeeper"
  desc "Menu bar app that keeps Bluetooth devices from hijacking the default microphone"
  homepage "https://github.com/wac0013/mickeeper"

  depends_on macos: ">= :ventura"

  app "MicKeeper.app"

  # App com assinatura ad-hoc (sem notarização): remove a quarentena para o Gatekeeper não bloquear.
  postflight do
    system_command "/usr/bin/xattr",
                   args: ["-dr", "com.apple.quarantine", "#{appdir}/MicKeeper.app"]
  end

  uninstall quit: "io.github.wac0013.mickeeper"

  zap trash: "~/Library/Preferences/io.github.wac0013.mickeeper.plist"
end
EOF
