import AppKit
import CoreAudio
import MicKeeperCore
import ServiceManagement

/// Item de menu com closure. O menu é reconstruído só quando abre (menuNeedsUpdate): custo zero parado.
final class ActionItem: NSMenuItem {
    private let handler: () -> Void

    init(_ title: String, key: String = "", checked: Bool = false, enabled: Bool = true,
         handler: @escaping () -> Void) {
        self.handler = handler
        super.init(title: title, action: #selector(fire), keyEquivalent: key)
        target = self
        state = checked ? .on : .off
        isEnabled = enabled
    }

    required init(coder: NSCoder) { fatalError("init(coder:) não é usado") }

    @objc private func fire() { handler() }
}

final class StatusController: NSObject, NSMenuDelegate {
    private let store: ConfigStore
    private let guardian: Guardian
    private let s = Strings()
    private var item: NSStatusItem?

    init(store: ConfigStore, guardian: Guardian) {
        self.store = store
        self.guardian = guardian
    }

    /// Cria/remove o ícone conforme a config e atualiza o indicador ligado/desligado.
    func refresh() {
        guard store.config.showIcon else {
            if let item { NSStatusBar.system.removeStatusItem(item) }
            item = nil
            return
        }
        if item == nil {
            let created = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
            let menu = Self.makeMenu()
            menu.delegate = self
            created.menu = menu
            item = created
        }
        updateIcon()
    }

    private func updateIcon() {
        let on = store.config.enabled
        let label = on ? s.protected : s.paused
        let image = NSImage(systemSymbolName: on ? "mic.fill" : "mic.slash", accessibilityDescription: label)
        image?.isTemplate = true
        item?.button?.image = image
        item?.button?.appearsDisabled = !on
        item?.button?.toolTip = "MicKeeper — \(label)"
    }

    private static func makeMenu() -> NSMenu {
        let menu = NSMenu()
        menu.autoenablesItems = false
        return menu
    }

    // MARK: - Menu

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        let config = store.config
        let devices = CoreAudioDevices.inputs()
        let currentID = CoreAudioDevices.defaultInputID()
        let currentName = devices.first { $0.id == currentID }?.info.name

        let header = NSMenuItem(
            title: "\(config.enabled ? "●" : "○") \(config.enabled ? s.protected : s.paused) — \(s.micLine(currentName))",
            action: nil, keyEquivalent: "")
        header.isEnabled = false
        menu.addItem(header)

        menu.addItem(ActionItem(s.protectionOn, key: "e", checked: config.enabled) { [self] in toggleProtection() })
        menu.addItem(.separator())

        menu.addItem(devicesItem(devices, currentID: currentID, config: config))
        menu.addItem(rankingItem(devices, config: config))
        menu.addItem(blockedItem(devices, config: config))
        menu.addItem(.separator())

        menu.addItem(loginItem())
        menu.addItem(ActionItem(s.showIcon, checked: config.showIcon) { [self] in
            store.update { $0.showIcon.toggle() }
            refresh()
        })
        menu.addItem(.separator())

        menu.addItem(ActionItem(s.about) { [self] in showAbout() })
        menu.addItem(ActionItem(s.quit, key: "q") { NSApp.terminate(nil) })
    }

    private func devicesItem(_ devices: [Device], currentID: AudioDeviceID?, config: Config) -> NSMenuItem {
        let parent = NSMenuItem(title: s.devices, action: nil, keyEquivalent: "")
        let sub = Self.makeMenu()
        for d in devices {
            var tags: [String] = []
            if d.info.isBluetooth { tags.append(s.tagBluetooth) }
            if config.isBlocked(d.info.uid) { tags.append(s.tagBlocked) }
            let suffix = tags.isEmpty ? "" : "  · " + tags.joined(separator: ", ")

            let row = NSMenuItem(title: d.info.name + suffix, action: nil, keyEquivalent: "")
            row.state = d.id == currentID ? .on : .off
            let actions = Self.makeMenu()
            actions.addItem(ActionItem(s.useNow, enabled: Policy.isEligible(d.info, config: config)) { [self] in
                CoreAudioDevices.setDefaultInput(d.id)
                guardian.evaluate()
            })
            actions.addItem(ActionItem(s.blockAlways, checked: config.isBlocked(d.info.uid)) { [self] in
                change { $0.toggleBlock(d.info.ref) }
            })
            actions.addItem(ActionItem(s.addToRanking, checked: config.isRanked(d.info.uid)) { [self] in
                change { $0.toggleRank(d.info.ref) }
            })
            row.submenu = actions
            sub.addItem(row)
        }
        if devices.isEmpty { sub.addItem(disabled(s.empty)) }
        parent.submenu = sub
        return parent
    }

    private func rankingItem(_ devices: [Device], config: Config) -> NSMenuItem {
        let parent = NSMenuItem(title: s.ranking, action: nil, keyEquivalent: "")
        let sub = Self.makeMenu()
        sub.addItem(ActionItem(s.useRanking, checked: config.rankingEnabled) { [self] in
            change { $0.rankingEnabled.toggle() }
        })
        sub.addItem(.separator())
        for (i, ref) in config.ranking.enumerated() {
            let connected = devices.contains { $0.info.uid == ref.uid }
            let row = NSMenuItem(
                title: "\(i + 1). \(ref.name)" + (connected ? "" : "  · \(s.tagOffline)"),
                action: nil, keyEquivalent: "")
            let actions = Self.makeMenu()
            actions.addItem(ActionItem(s.moveUp, enabled: i > 0) { [self] in
                change { $0.moveRank(uid: ref.uid, by: -1) }
            })
            actions.addItem(ActionItem(s.moveDown, enabled: i < config.ranking.count - 1) { [self] in
                change { $0.moveRank(uid: ref.uid, by: 1) }
            })
            actions.addItem(ActionItem(s.remove) { [self] in change { $0.toggleRank(ref) } })
            row.submenu = actions
            sub.addItem(row)
        }
        if config.ranking.isEmpty { sub.addItem(disabled(s.empty)) }
        parent.submenu = sub
        return parent
    }

    private func blockedItem(_ devices: [Device], config: Config) -> NSMenuItem {
        let parent = NSMenuItem(title: s.blocked, action: nil, keyEquivalent: "")
        let sub = Self.makeMenu()
        for ref in config.blocklist {
            let connected = devices.contains { $0.info.uid == ref.uid }
            let row = NSMenuItem(title: ref.name + (connected ? "" : "  · \(s.tagOffline)"), action: nil, keyEquivalent: "")
            let actions = Self.makeMenu()
            actions.addItem(ActionItem(s.unblock) { [self] in change { $0.toggleBlock(ref) } })
            row.submenu = actions
            sub.addItem(row)
        }
        if config.blocklist.isEmpty { sub.addItem(disabled(s.empty)) }
        parent.submenu = sub
        return parent
    }

    private func loginItem() -> NSMenuItem {
        let service = SMAppService.mainApp
        let needsApproval = service.status == .requiresApproval
        let row = ActionItem(needsApproval ? s.launchNeedsApproval : s.launchAtLogin,
                             checked: service.status == .enabled) { [self] in
            if needsApproval {
                SMAppService.openSystemSettingsLoginItems()
                return
            }
            do {
                if service.status == .enabled { try service.unregister() } else { try service.register() }
            } catch {
                showAlert(s.loginError(error.localizedDescription))
            }
        }
        if needsApproval { row.state = .mixed }
        return row
    }

    // MARK: - Ações

    private func change(_ mutation: (inout Config) -> Void) {
        store.update(mutation)
        guardian.evaluate()
    }

    private func toggleProtection() {
        store.update { $0.enabled.toggle() }
        if store.config.enabled { guardian.start() } else { guardian.stop() }
        updateIcon()
    }

    private func disabled(_ title: String) -> NSMenuItem {
        let row = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        row.isEnabled = false
        return row
    }

    private func showAbout() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.orderFrontStandardAboutPanel(options: [.credits: NSAttributedString(string: s.aboutCredits)])
    }

    private func showAlert(_ text: String) {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = text
        alert.runModal()
    }
}
