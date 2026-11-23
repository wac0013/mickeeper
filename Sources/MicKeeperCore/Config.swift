import Foundation

/// Referência estável a um dispositivo: o UID identifica, o nome é só para exibir
/// (permite listar itens que não estão conectados no momento).
public struct DeviceRef: Codable, Hashable {
    public var uid: String
    public var name: String
    public init(uid: String, name: String) {
        self.uid = uid
        self.name = name
    }
}

/// Configuração persistida localmente (UserDefaults). Nada sai da máquina.
public struct Config: Codable, Equatable {
    public var enabled = true
    public var showIcon = true
    public var rankingEnabled = false
    /// Ordem de preferência: o primeiro conectado vence.
    public var ranking: [DeviceRef] = []
    /// Dispositivos que nunca podem ser a entrada padrão.
    public var blocklist: [DeviceRef] = []
    /// Último dispositivo "bom" visto como entrada padrão.
    public var lastGoodUID: String?

    public init() {}

    // Tolerante a campos novos/ausentes entre versões.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        enabled = try c.decodeIfPresent(Bool.self, forKey: .enabled) ?? true
        showIcon = try c.decodeIfPresent(Bool.self, forKey: .showIcon) ?? true
        rankingEnabled = try c.decodeIfPresent(Bool.self, forKey: .rankingEnabled) ?? false
        ranking = try c.decodeIfPresent([DeviceRef].self, forKey: .ranking) ?? []
        blocklist = try c.decodeIfPresent([DeviceRef].self, forKey: .blocklist) ?? []
        lastGoodUID = try c.decodeIfPresent(String.self, forKey: .lastGoodUID)
    }

    public func isBlocked(_ uid: String) -> Bool { blocklist.contains { $0.uid == uid } }
    public func isRanked(_ uid: String) -> Bool { ranking.contains { $0.uid == uid } }

    /// Bloquear remove do ranking (o bloqueio sempre vence).
    public mutating func toggleBlock(_ ref: DeviceRef) {
        if isBlocked(ref.uid) {
            blocklist.removeAll { $0.uid == ref.uid }
        } else {
            blocklist.append(ref)
            ranking.removeAll { $0.uid == ref.uid }
        }
    }

    /// Entrar no ranking remove do bloqueio.
    public mutating func toggleRank(_ ref: DeviceRef) {
        if isRanked(ref.uid) {
            ranking.removeAll { $0.uid == ref.uid }
        } else {
            ranking.append(ref)
            blocklist.removeAll { $0.uid == ref.uid }
        }
    }

    public mutating func moveRank(uid: String, by delta: Int) {
        guard let i = ranking.firstIndex(where: { $0.uid == uid }) else { return }
        let j = i + delta
        guard ranking.indices.contains(j) else { return }
        ranking.swapAt(i, j)
    }
}

public final class ConfigStore {
    private let defaults: UserDefaults
    private let key = "config.v1"
    public private(set) var config: Config

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: key),
           let saved = try? JSONDecoder().decode(Config.self, from: data) {
            config = saved
        } else {
            config = Config()
        }
    }

    /// Só grava se algo mudou.
    public func update(_ change: (inout Config) -> Void) {
        var next = config
        change(&next)
        guard next != config else { return }
        config = next
        if let data = try? JSONEncoder().encode(next) {
            defaults.set(data, forKey: key)
        }
    }
}
