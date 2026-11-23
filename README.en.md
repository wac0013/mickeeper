<p align="center">
  <img src="assets/icon.svg" alt="MicKeeper" width="128" height="128">
</p>

<h1 align="center">MicKeeper</h1>

<p align="center">
  Keeps the Mac's default microphone off Bluetooth devices, preserving audio quality.
</p>

<p align="center">
  <b>English</b> · <a href="README.md">Português (BR)</a>
</p>

<p align="center">
  <a href="https://github.com/wac0013/mickeeper/actions/workflows/ci.yml"><img alt="CI" src="https://img.shields.io/github/actions/workflow/status/wac0013/mickeeper/ci.yml?branch=main&label=CI&logo=githubactions&logoColor=white"></a>
  <a href="https://github.com/wac0013/mickeeper/actions/workflows/release.yml"><img alt="Release pipeline" src="https://img.shields.io/github/actions/workflow/status/wac0013/mickeeper/release.yml?label=release&logo=githubactions&logoColor=white"></a>
  <a href="https://github.com/wac0013/mickeeper/releases/latest"><img alt="Version" src="https://img.shields.io/github/v/release/wac0013/mickeeper?label=version&logo=github&color=6366F1"></a>
  <a href="https://github.com/wac0013/mickeeper/releases"><img alt="Downloads" src="https://img.shields.io/github/downloads/wac0013/mickeeper/total?label=downloads&logo=github"></a>
  <a href="https://github.com/wac0013/homebrew-tap"><img alt="Homebrew" src="https://img.shields.io/badge/homebrew-wac0013%2Ftap-FBB040?logo=homebrew&logoColor=white"></a>
</p>
<p align="center">
  <img alt="macOS 13+" src="https://img.shields.io/badge/macOS-13%2B-000000?logo=apple&logoColor=white">
  <img alt="Architecture" src="https://img.shields.io/badge/arch-arm64%20%7C%20x86__64-555">
  <img alt="Swift 5.9" src="https://img.shields.io/badge/Swift-5.9-F05138?logo=swift&logoColor=white">
  <img alt="No dependencies" src="https://img.shields.io/badge/dependencies-0-brightgreen">
  <img alt="No telemetry" src="https://img.shields.io/badge/telemetry-none-brightgreen">
  <img alt="No network" src="https://img.shields.io/badge/network-unused-brightgreen">
</p>
<p align="center">
  <a href="LICENSE"><img alt="MIT license" src="https://img.shields.io/github/license/wac0013/mickeeper?color=blue"></a>
  <img alt="Status" src="https://img.shields.io/badge/status-beta-orange">
  <a href="https://github.com/wac0013/mickeeper/commits/main"><img alt="Last commit" src="https://img.shields.io/github/last-commit/wac0013/mickeeper"></a>
  <a href="https://github.com/wac0013/mickeeper/issues"><img alt="Issues" src="https://img.shields.io/github/issues/wac0013/mickeeper"></a>
  <img alt="Code size" src="https://img.shields.io/github/languages/code-size/wac0013/mickeeper">
</p>

---

The problem: when AirPods or a headset connect, macOS may switch the default microphone to the Bluetooth device. That forces the low-quality HFP profile and degrades the audio, output included.

## Install

```bash
brew install wac0013/tap/mickeeper
```

Requires macOS 13+ (Intel and Apple Silicon). The app is ad-hoc signed (not notarized); the cask clears the quarantine flag on install.

Upgrade: `brew update && brew upgrade --cask mickeeper`

Manual install: download the `.zip` from [Releases](https://github.com/wac0013/mickeeper/releases), move it to `/Applications` and run `xattr -dr com.apple.quarantine /Applications/MicKeeper.app`.

## How it works

It listens to CoreAudio for changes to the default input and to the device list (no polling, no timers). When the input becomes a device that isn't allowed, it switches back to one that is:

1. **Ranking** (optional): the first connected device in the ranking.
2. The current input, if allowed (manually switching to a USB mic, for example, makes it the new "last good" device).
3. The **last good** device, if connected.
4. The built-in microphone.

Permission rules:

- **Blocked** devices can never be the default input (blocking wins over the ranking).
- **Bluetooth** is blocked by default. It is only allowed when the **ranking is on** and the device is in it (a Bluetooth mic you chose on purpose).
- With the ranking on, it is strict: if a higher-ranked device connects, the input moves to it.
- The audio output is never changed.

## Menu

- State (protected/paused) and current microphone; `mic.fill` (active) / `mic.slash` (paused) icon
- **Protection on** (⌘E) — turning it off removes the listeners (zero cost)
- **Input devices** → use now / always block / add to ranking
- **Ranking** → use ranking, order (up/down), remove
- **Blocked** → unblock
- **Launch at login** (via `SMAppService`; if approval is needed, it opens System Settings)
- **Show menu bar icon** — to bring back a hidden icon, open the app again (`open -a MicKeeper`)

The interface follows the system language: Brazilian Portuguese if the system is in Portuguese, English otherwise.

## Privacy

- No network, no telemetry, no auto-update.
- It doesn't capture audio or ask for microphone permission: it only reads and sets the default device.
- Settings live in local `UserDefaults` (`io.github.wac0013.mickeeper`): state, ranking, blocklist and the UID of the last good device. Device names are never logged or sent anywhere.

## Development

```bash
swift test              # policy, config and strings (macOS)
scripts/bundle.sh       # builds build/MicKeeper.app and the .zip
```

Icon: `assets/icon.svg` is the source. To regenerate `Resources/AppIcon.icns` (any OS): `npm i --no-save @resvg/resvg-js && node scripts/make-icon.mjs`.

Developing on Linux (remote build on a Mac over restricted SSH): see [scripts/remote](scripts/remote). On the Mac: `scripts/remote/mac-setup.sh "<public key>" "<server IP>"`; on the server: `scripts/remote/mac.sh test|bundle`.

Release: `git tag vX.Y.Z && git push --tags` → the workflow tests, publishes the `.zip` and updates the cask in [`wac0013/homebrew-tap`](https://github.com/wac0013/homebrew-tap) (needs the `TAP_TOKEN` secret).

## License

[MIT](LICENSE)
