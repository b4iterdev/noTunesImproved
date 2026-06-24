import AppKit

final class StatusBarController: NSObject {
    private let preferences: AppPreferences
    private let configurationWindowController: ConfigurationWindowController
    private let statusItem: NSStatusItem

    init(
        preferences: AppPreferences,
        configurationWindowController: ConfigurationWindowController
    ) {
        self.preferences = preferences
        self.configurationWindowController = configurationWindowController
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()
        configureButton()
        rebuildMenu()
    }

    private func configureButton() {
        guard let button = statusItem.button else { return }
        button.image = NSImage(systemSymbolName: "headphones", accessibilityDescription: "noTunes Improved")
        button.image?.isTemplate = true
        button.toolTip = "noTunes Improved"
    }

    private func rebuildMenu() {
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

        statusItem.menu = menu
    }

    @objc private func toggleBlocking() {
        preferences.blockingEnabled.toggle()
        rebuildMenu()
    }

    @objc private func toggleMode() {
        preferences.blockingMode = preferences.blockingMode == .always ? .headphoneTriggeredOnly : .always
        rebuildMenu()
    }

    @objc private func openConfiguration() {
        configurationWindowController.show()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
