<p align="center">
  <img src="assets/icon.svg" alt="MicKeeper" width="128" height="128">
</p>

<h1 align="center">MicKeeper</h1>

<p align="center">
  Mantém o microfone padrão do Mac fora de dispositivos Bluetooth, preservando a qualidade do áudio.<br>
  <em>Keeps the Mac's default microphone off Bluetooth devices, preserving audio quality.</em>
</p>

<p align="center">
  <a href="README.en.md">English</a> · <b>Português (BR)</b>
</p>

<p align="center">
  <a href="https://github.com/wac0013/mickeeper/actions/workflows/ci.yml"><img alt="CI" src="https://img.shields.io/github/actions/workflow/status/wac0013/mickeeper/ci.yml?branch=main&label=CI&logo=githubactions&logoColor=white"></a>
  <a href="https://github.com/wac0013/mickeeper/actions/workflows/release.yml"><img alt="Release pipeline" src="https://img.shields.io/github/actions/workflow/status/wac0013/mickeeper/release.yml?label=release&logo=githubactions&logoColor=white"></a>
  <a href="https://github.com/wac0013/mickeeper/releases/latest"><img alt="Versão" src="https://img.shields.io/github/v/release/wac0013/mickeeper?label=vers%C3%A3o&logo=github&color=6366F1"></a>
  <a href="https://github.com/wac0013/mickeeper/releases"><img alt="Downloads" src="https://img.shields.io/github/downloads/wac0013/mickeeper/total?label=downloads&logo=github"></a>
  <a href="https://github.com/wac0013/homebrew-tap"><img alt="Homebrew" src="https://img.shields.io/badge/homebrew-wac0013%2Ftap-FBB040?logo=homebrew&logoColor=white"></a>
</p>
<p align="center">
  <img alt="macOS 13+" src="https://img.shields.io/badge/macOS-13%2B-000000?logo=apple&logoColor=white">
  <img alt="Arquitetura" src="https://img.shields.io/badge/arch-arm64%20%7C%20x86__64-555">
  <img alt="Swift 5.9" src="https://img.shields.io/badge/Swift-5.9-F05138?logo=swift&logoColor=white">
  <img alt="Sem dependências" src="https://img.shields.io/badge/depend%C3%AAncias-0-brightgreen">
  <img alt="Sem telemetria" src="https://img.shields.io/badge/telemetria-nenhuma-brightgreen">
  <img alt="Sem rede" src="https://img.shields.io/badge/rede-n%C3%A3o%20usa-brightgreen">
</p>
<p align="center">
  <a href="LICENSE"><img alt="Licença MIT" src="https://img.shields.io/github/license/wac0013/mickeeper?color=blue"></a>
  <img alt="Status" src="https://img.shields.io/badge/status-beta-orange">
  <a href="https://github.com/wac0013/mickeeper/commits/main"><img alt="Último commit" src="https://img.shields.io/github/last-commit/wac0013/mickeeper"></a>
  <a href="https://github.com/wac0013/mickeeper/issues"><img alt="Issues" src="https://img.shields.io/github/issues/wac0013/mickeeper"></a>
  <img alt="Tamanho do código" src="https://img.shields.io/github/languages/code-size/wac0013/mickeeper">
</p>

---

O problema: ao conectar AirPods ou um headset, o macOS pode trocar o microfone padrão para o Bluetooth. Isso força o perfil HFP e derruba a qualidade do áudio, inclusive da saída.

*The problem: when AirPods or a headset connect, macOS may switch the default microphone to the Bluetooth device. That forces the low-quality HFP profile and degrades output audio too.*

## Instalação / Install

```bash
brew install wac0013/tap/mickeeper
```

Requer macOS 13+ (Intel e Apple Silicon). O app tem assinatura ad-hoc (sem notarização); o cask remove a quarentena na instalação. / Requires macOS 13+. The app is ad-hoc signed (not notarized); the cask clears the quarantine flag on install.

Atualizar / upgrade: `brew update && brew upgrade --cask mickeeper`

Instalação manual: baixe o `.zip` em [Releases](https://github.com/wac0013/mickeeper/releases), mova para `/Applications` e rode `xattr -dr com.apple.quarantine /Applications/MicKeeper.app`.

## Como funciona

Escuta, via CoreAudio, mudanças da entrada padrão e da lista de dispositivos (sem polling, sem timers). Quando a entrada vira um dispositivo não permitido, volta para um permitido:

1. **Ranking** (opcional): o primeiro dispositivo do ranking que estiver conectado.
2. A entrada atual, se permitida (trocar manualmente para um USB, por exemplo, vira o novo "último bom").
3. O **último bom** conectado.
4. O microfone embutido.

Regras de permissão:

- **Bloqueados** nunca podem ser a entrada padrão (vence o ranking).
- **Bluetooth** é bloqueado por padrão. Só é permitido se o **ranking estiver ligado** e o dispositivo estiver nele (um microfone Bluetooth escolhido de propósito).
- Com o ranking ligado, ele é estrito: se um dispositivo melhor do ranking conectar, a entrada vai para ele.
- A saída de áudio nunca é alterada.

## Menu

- Estado (protegido/pausado) e microfone atual; ícone `mic.fill` (ativo) / `mic.slash` (pausado)
- **Proteção ativa** (⌘E) — desligar remove os listeners (custo zero)
- **Dispositivos de entrada** → usar agora / bloquear sempre / incluir no ranking
- **Ranking** → usar ranking, ordem (subir/descer), remover
- **Bloqueados** → desbloquear
- **Iniciar com o sistema** (via `SMAppService`; se pedir aprovação, abre os Ajustes)
- **Mostrar ícone na barra** — para reexibir um ícone oculto, abra o app de novo (`open -a MicKeeper`)

A interface segue o idioma do sistema: PT-BR se português, inglês caso contrário.

## Privacidade

- Sem rede, sem telemetria, sem auto-update.
- Não captura áudio nem pede permissão de microfone: só lê e define o dispositivo padrão.
- A configuração fica em `UserDefaults` local (`io.github.wac0013.mickeeper`): estado, ranking, bloqueados e UID do último dispositivo bom. Nomes de dispositivos não são logados nem enviados.

## Desenvolvimento

```bash
swift test              # política, config e textos (macOS)
scripts/bundle.sh       # gera build/MicKeeper.app e o .zip
```

Ícone: `assets/icon.svg` é a fonte. Para regenerar o `Resources/AppIcon.icns` (qualquer SO): `npm i --no-save @resvg/resvg-js && node scripts/make-icon.mjs`.

Dev em Linux (build remoto no Mac via SSH restrito): veja [scripts/remote](scripts/remote). No Mac: `scripts/remote/mac-setup.sh "<chave pública>" "<IP do servidor>"`; no servidor: `scripts/remote/mac.sh test|bundle`.

Release: `git tag vX.Y.Z && git push --tags` → o workflow testa, publica o `.zip` e atualiza o cask em [`wac0013/homebrew-tap`](https://github.com/wac0013/homebrew-tap) (requer o secret `TAP_TOKEN`).

## Licença

[MIT](LICENSE)
