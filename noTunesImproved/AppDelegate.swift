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

    func applicationWillTerminate(_ notification: Notification) {
        launchBlocker?.stop()
        audioDeviceMonitor.stop()
    }
}
