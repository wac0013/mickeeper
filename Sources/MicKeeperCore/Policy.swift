import Foundation

public struct AudioInput: Equatable {
    public var uid: String
    public var name: String
    public var isBluetooth: Bool
    public var isBuiltIn: Bool

    public init(uid: String, name: String, isBluetooth: Bool = false, isBuiltIn: Bool = false) {
        self.uid = uid
        self.name = name
        self.isBluetooth = isBluetooth
        self.isBuiltIn = isBuiltIn
    }

    public var ref: DeviceRef { DeviceRef(uid: uid, name: name) }
}

public struct Outcome: Equatable {
    /// Dispositivo para o qual trocar; nil = manter o atual.
    public var switchTo: AudioInput?
    public var lastGoodUID: String?
}

public enum Policy {
    /// Elegível = pode ser a entrada padrão.
    /// - Bloqueado: nunca.
    /// - Bluetooth: só se o ranking estiver ligado e o dispositivo estiver nele
    ///   (microfone Bluetooth escolhido de propósito; o padrão é nunca cair em HFP).
    public static func isEligible(_ d: AudioInput, config: Config) -> Bool {
        if config.isBlocked(d.uid) { return false }
        if d.isBluetooth { return config.rankingEnabled && config.isRanked(d.uid) }
        return true
    }

    /// Decide qual deve ser a entrada padrão.
    /// 1. Ranking ligado: primeiro do ranking conectado e elegível.
    /// 2. Entrada atual, se elegível (troca legítima do usuário vira o novo "bom").
    /// 3. Último "bom" conectado e elegível.
    /// 4. Embutido, senão qualquer elegível. Sem candidato: não mexe.
    public static func decide(current: AudioInput?, available: [AudioInput], config: Config) -> Outcome {
        let candidates = available.filter { isEligible($0, config: config) }

        var target: AudioInput?
        if config.rankingEnabled {
            target = config.ranking.lazy
                .compactMap { r in candidates.first { $0.uid == r.uid } }
                .first
        }
        if target == nil, let cur = current, isEligible(cur, config: config) {
            target = cur
        }
        if target == nil, let good = config.lastGoodUID {
            target = candidates.first { $0.uid == good }
        }
        if target == nil {
            target = candidates.first { $0.isBuiltIn } ?? candidates.first
        }

        let change = (target != nil && target?.uid != current?.uid) ? target : nil
        return Outcome(switchTo: change, lastGoodUID: target?.uid ?? config.lastGoodUID)
    }
}
