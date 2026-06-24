import AppKit
import Combine

final class StatusBarController: NSObject, NSMenuDelegate {
    private let preferences: AppPreferences
    private let configurationWindowController: ConfigurationWindowController
    private let loginItemController: LoginItemController
    private var statusItem: NSStatusItem?
    private var launchAtLoginMenuItem: NSMenuItem?
    private var cancellables = Set<AnyCancellable>()

    init(
        preferences: AppPreferences,
        configurationWindowController: ConfigurationWindowController,
        loginItemController: LoginItemController
    ) {
        self.preferences = preferences
        self.configurationWindowController = configurationWindowController
        self.loginItemController = loginItemController
        super.init()
        if !preferences.hideStatusIcon {
            showStatusItem()
        }
        preferences.$hideStatusIcon
            .receive(on: DispatchQueue.main)
            .sink { [weak self] hidden in
                if hidden {
                    self?.hideStatusItem()
                } else {
                    self?.showStatusItem()
                }
            }
            .store(in: &cancellables)
    }

    private func showStatusItem() {
        guard statusItem == nil else { return }
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        configureButton(for: item)
        item.menu = makeMenu()
        item.menu?.delegate = self
        statusItem = item
    }

    private func hideStatusItem() {
        guard let item = statusItem else { return }
        NSStatusBar.system.removeStatusItem(item)
        statusItem = nil
    }

    private func configureButton(for item: NSStatusItem) {
        guard let button = item.button else { return }
        button.image = NSImage(systemSymbolName: "music.note", accessibilityDescription: "noTunes Improved")
        button.image?.isTemplate = true
        button.toolTip = "noTunes Improved"
    }

    private func makeMenu() -> NSMenu {
        let menu = NSMenu()

        let enabledItem = NSMenuItem(
            title: preferences.blockingEnabled ? "Disable Blocking" : "Enable Blocking",
            action: #selector(toggleBlocking),
            keyEquivalent: ""
        )
        enabledItem.target = self
        menu.addItem(enabledItem)

        let modeItem = NSMenuItem(
            title: "Mode: \(preferences.blockingMode.displayName)",
            action: #selector(toggleMode),
            keyEquivalent: ""
        )
        modeItem.target = self
        menu.addItem(modeItem)

        menu.addItem(.separator())

        let launchAtLoginItem = NSMenuItem(
            title: "Launch at Login",
            action: #selector(toggleLaunchAtLogin),
            keyEquivalent: ""
        )
        launchAtLoginItem.target = self
        launchAtLoginItem.state = loginItemController.isEnabled ? .on : .off
        launchAtLoginMenuItem = launchAtLoginItem
        menu.addItem(launchAtLoginItem)

        let configurationItem = NSMenuItem(
            title: "Configuration…",
            action: #selector(openConfiguration),
            keyEquivalent: ","
        )
        configurationItem.target = self
        menu.addItem(configurationItem)

        menu.addItem(.separator())

        let hideItem = NSMenuItem(
            title: "Hide from Menubar",
            action: #selector(hideFromMenubar),
            keyEquivalent: ""
        )
        hideItem.target = self
        menu.addItem(hideItem)

        let quitItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        return menu
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        launchAtLoginMenuItem?.state = loginItemController.isEnabled ? .on : .off
    }

    @objc private func toggleBlocking() {
        preferences.blockingEnabled.toggle()
        rebuildMenuTitles()
    }

    @objc private func toggleMode() {
        preferences.blockingMode = preferences.blockingMode == .always ? .headphoneTriggeredOnly : .always
        rebuildMenuTitles()
    }

    @objc private func toggleLaunchAtLogin() {
        let newValue = !loginItemController.isEnabled
        if !loginItemController.setEnabled(newValue) {
            let alert = NSAlert()
            alert.alertStyle = .warning
            alert.messageText = "Could not \(newValue ? "enable" : "disable") Launch at Login"
            alert.informativeText = "macOS requires Ventura (13.0) or later for this feature."
            alert.runModal()
        }
    }

    @objc private func openConfiguration() {
        configurationWindowController.show()
    }

    @objc private func hideFromMenubar() {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = "Hide from Menubar?"
        alert.informativeText = "The menubar icon will be hidden. Launch the app again from Applications to show it."
        alert.addButton(withTitle: "Hide")
        alert.addButton(withTitle: "Cancel")
        if alert.runModal() == .alertFirstButtonReturn {
            preferences.hideStatusIcon = true
        }
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    private func rebuildMenuTitles() {
        guard let menu = statusItem?.menu else { return }
        if menu.items.count >= 2 {
            menu.items[0].title = preferences.blockingEnabled ? "Disable Blocking" : "Enable Blocking"
            menu.items[1].title = "Mode: \(preferences.blockingMode.displayName)"
        }
    }
}
