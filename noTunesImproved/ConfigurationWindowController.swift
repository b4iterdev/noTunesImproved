import AppKit
import SwiftUI

final class ConfigurationWindowController {
    private let preferences: AppPreferences
    private var window: NSWindow?

    init(preferences: AppPreferences) {
        self.preferences = preferences
    }

    func show() {
        let window = existingOrNewWindow()
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func existingOrNewWindow() -> NSWindow {
        if let window {
            return window
        }

        let contentView = ConfigurationView(preferences: preferences)
        let hostingController = NSHostingController(rootView: contentView)
        let window = NSWindow(contentViewController: hostingController)
        window.title = "noTunes Improved Configuration"
        window.setContentSize(NSSize(width: 600, height: 540))
        window.minSize = NSSize(width: 560, height: 500)
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.isReleasedWhenClosed = false
        self.window = window
        return window
    }
}
