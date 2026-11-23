import AppKit
import MicKeeperCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let store = ConfigStore()
    private lazy var guardian = Guardian(store: store)
    private lazy var status = StatusController(store: store, guardian: guardian)

    func applicationDidFinishLaunching(_ notification: Notification) {
        if store.config.enabled { guardian.start() }
        status.refresh()
    }

    /// Reabrir o app (Finder, `open -a MicKeeper`) traz o ícone de volta se estiver oculto.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        store.update { $0.showIcon = true }
        status.refresh()
        return false
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
