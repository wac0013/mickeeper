import Foundation

/// Textos da interface. PT-BR se o idioma preferido do sistema for português; inglês caso contrário.
/// Sem arquivos de recurso: mantém o app pequeno e o bundle simples.
public struct Strings {
    public let pt: Bool

    public init(languages: [String] = Locale.preferredLanguages) {
        pt = languages.first?.lowercased().hasPrefix("pt") ?? false
    }

    private func t(_ pt: String, _ en: String) -> String { self.pt ? pt : en }

    public var protected: String { t("Protegido", "Protected") }
    public var paused: String { t("Pausado", "Paused") }
    public func micLine(_ name: String?) -> String {
        t("Microfone: ", "Microphone: ") + (name ?? t("nenhum", "none"))
    }
    public var protectionOn: String { t("Proteção ativa", "Protection on") }
    public var devices: String { t("Dispositivos de entrada", "Input devices") }
    public var useNow: String { t("Usar agora", "Use now") }
    public var blockAlways: String { t("Bloquear sempre", "Always block") }
    public var addToRanking: String { t("Incluir no ranking", "Add to ranking") }
    public var ranking: String { t("Ranking", "Ranking") }
    public var useRanking: String { t("Usar ranking", "Use ranking") }
    public var moveUp: String { t("Subir", "Move up") }
    public var moveDown: String { t("Descer", "Move down") }
    public var remove: String { t("Remover", "Remove") }
    public var blocked: String { t("Bloqueados", "Blocked") }
    public var unblock: String { t("Desbloquear", "Unblock") }
    public var empty: String { t("(vazio)", "(empty)") }
    public var tagBluetooth: String { "Bluetooth" }
    public var tagBlocked: String { t("bloqueado", "blocked") }
    public var tagOffline: String { t("desconectado", "disconnected") }
    public var launchAtLogin: String { t("Iniciar com o sistema", "Launch at login") }
    public var launchNeedsApproval: String {
        t("Iniciar com o sistema (aprovar em Ajustes…)", "Launch at login (approve in Settings…)")
    }
    public var showIcon: String { t("Mostrar ícone na barra", "Show menu bar icon") }
    public var about: String { t("Sobre o MicKeeper", "About MicKeeper") }
    public var quit: String { t("Sair do MicKeeper", "Quit MicKeeper") }
    public func loginError(_ detail: String) -> String {
        t("Não foi possível alterar o item de login: ", "Could not change the login item: ") + detail
    }
    public var aboutCredits: String {
        t("Mantém o microfone padrão fora de dispositivos Bluetooth para preservar a qualidade do áudio.\nSem rede, sem telemetria: tudo fica nesta máquina.",
          "Keeps the default microphone off Bluetooth devices to preserve audio quality.\nNo network, no telemetry: everything stays on this machine.")
    }
}
