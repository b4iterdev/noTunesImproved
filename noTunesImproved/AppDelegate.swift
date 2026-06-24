import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let preferences = AppPreferences()
    private let audioDeviceMonitor = AudioDeviceMonitor()
    private let loginItemController = LoginItemController()
    private var configurationWindowController: ConfigurationWindowController?
    private var statusBarController: StatusBarController?
    private var launchBlocker: MusicLaunchBlocker?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        audioDeviceMonitor.start()

        let configurationWindowController = ConfigurationWindowController(preferences: preferences)
        self.configurationWindowController = configurationWindowController

        statusBarController = StatusBarController(
            preferences: preferences,
            configurationWindowController: configurationWindowController,
            loginItemController: loginItemController
        )

        let launchBlocker = MusicLaunchBlocker(
            preferences: preferences,
            audioDeviceMonitor: audioDeviceMonitor
        )
        self.launchBlocker = launchBlocker
        launchBlocker.start()
    }

    // ponytail: relaunch path is the only way to unhide a hidden menubar icon
    // (app is LSUIElement, so clicking it in Finder/Applications reopens the running instance)
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if preferences.hideStatusIcon {
            preferences.hideStatusIcon = false
        }
        return false
    }

    func applicationWillTerminate(_ notification: Notification) {
        launchBlocker?.stop()
        audioDeviceMonitor.stop()
    }
}
