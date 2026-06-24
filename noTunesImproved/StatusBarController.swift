import AppKit

final class StatusBarController: NSObject, NSMenuDelegate {
    private let preferences: AppPreferences
    private let configurationWindowController: ConfigurationWindowController
    private let loginItemController: LoginItemController
    private let statusItem: NSStatusItem
    private var launchAtLoginMenuItem: NSMenuItem?

    init(
        preferences: AppPreferences,
        configurationWindowController: ConfigurationWindowController,
        loginItemController: LoginItemController
    ) {
        self.preferences = preferences
        self.configurationWindowController = configurationWindowController
        self.loginItemController = loginItemController
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()
        configureButton()
        statusItem.menu = makeMenu()
        statusItem.menu?.delegate = self
    }

    private func configureButton() {
        guard let button = statusItem.button else { return }
        button.image = NSImage(systemSymbolName: "headphones", accessibilityDescription: "noTunes Improved")
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

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    private func rebuildMenuTitles() {
        guard let menu = statusItem.menu else { return }
        if menu.items.count >= 2 {
            menu.items[0].title = preferences.blockingEnabled ? "Disable Blocking" : "Enable Blocking"
            menu.items[1].title = "Mode: \(preferences.blockingMode.displayName)"
        }
    }
}
