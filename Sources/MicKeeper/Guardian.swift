import CoreAudio
import Foundation
import MicKeeperCore

/// Reage a mudanças do CoreAudio e mantém a entrada padrão conforme a política.
/// Desligado = listeners removidos (custo zero). Sem timers nem polling.
final class Guardian {
    private let store: ConfigStore
    private var listener: AudioObjectPropertyListenerBlock?
    private var recentSwitches: [CFAbsoluteTime] = []

    init(store: ConfigStore) {
        self.store = store
    }

    func start() {
        guard listener == nil else { return }
        let block: AudioObjectPropertyListenerBlock = { [weak self] _, _ in self?.evaluate() }
        listener = block
        for var addr in [CoreAudioDevices.defaultInputAddress, CoreAudioDevices.deviceListAddress] {
            AudioObjectAddPropertyListenerBlock(AudioObjectID(kAudioObjectSystemObject), &addr, .main, block)
        }
        evaluate()
    }

    func stop() {
        guard let block = listener else { return }
        for var addr in [CoreAudioDevices.defaultInputAddress, CoreAudioDevices.deviceListAddress] {
            AudioObjectRemovePropertyListenerBlock(AudioObjectID(kAudioObjectSystemObject), &addr, .main, block)
        }
        listener = nil
    }

    /// Idempotente e barato: se a entrada já está correta, não faz nada.
    func evaluate() {
        let config = store.config
        guard config.enabled else { return }

        let devices = CoreAudioDevices.inputs()
        let currentID = CoreAudioDevices.defaultInputID()
        let current = devices.first { $0.id == currentID }?.info

        let outcome = Policy.decide(current: current, available: devices.map(\.info), config: config)
        store.update { $0.lastGoodUID = outcome.lastGoodUID }

        guard let target = outcome.switchTo,
              let device = devices.first(where: { $0.info.uid == target.uid }),
              allowSwitch() else { return }
        CoreAudioDevices.setDefaultInput(device.id)
    }

    /// Trava contra briga com o sistema: no máximo 6 trocas em 10 s.
    private func allowSwitch() -> Bool {
        let now = CFAbsoluteTimeGetCurrent()
        recentSwitches.removeAll { now - $0 > 10 }
        guard recentSwitches.count < 6 else { return false }
        recentSwitches.append(now)
        return true
    }
}
