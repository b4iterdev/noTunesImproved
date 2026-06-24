import AppKit
import Foundation

final class MusicLaunchBlocker {
    private let preferences: AppPreferences
    private let audioDeviceMonitor: AudioDeviceMonitor
    private let classifier: LaunchTriggerClassifier
    private let replacementLauncher: ReplacementLauncher
    private var observer: NSObjectProtocol?

    init(
        preferences: AppPreferences,
        audioDeviceMonitor: AudioDeviceMonitor,
        classifier: LaunchTriggerClassifier = LaunchTriggerClassifier(),
        replacementLauncher: ReplacementLauncher = ReplacementLauncher()
    ) {
        self.preferences = preferences
        self.audioDeviceMonitor = audioDeviceMonitor
        self.classifier = classifier
        self.replacementLauncher = replacementLauncher
    }

    func start() {
        guard observer == nil else { return }

        terminateRunningBlockedAppsIfNeeded()

        observer = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.willLaunchApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleWillLaunch(notification: notification)
        }
    }

    func stop() {
        guard let observer else { return }
        NSWorkspace.shared.notificationCenter.removeObserver(observer)
        self.observer = nil
    }

    private func terminateRunningBlockedAppsIfNeeded() {
        guard preferences.blockingEnabled else { return }

        let shouldSweep = classifier.shouldBlock(
            blockingEnabled: preferences.blockingEnabled,
            blockingMode: preferences.blockingMode,
            manualLaunchIdleThreshold: preferences.manualLaunchIdleThreshold,
            lastHeadphoneActivationDate: audioDeviceMonitor.lastHeadphoneActivationDate
        )

        guard shouldSweep else { return }

        for application in NSWorkspace.shared.runningApplications {
            guard let bundleIdentifier = application.bundleIdentifier else { continue }
            terminate(application: application, bundleIdentifier: bundleIdentifier)
        }
    }

    private func handleWillLaunch(notification: Notification) {
        guard
            let application = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
            let bundleIdentifier = application.bundleIdentifier
        else {
            return
        }

        terminate(application: application, bundleIdentifier: bundleIdentifier)
    }

    private func terminate(application: NSRunningApplication, bundleIdentifier: String) {
        guard preferences.isBlocked(bundleIdentifier: bundleIdentifier) else { return }

        let shouldBlock = classifier.shouldBlock(
            blockingEnabled: preferences.blockingEnabled,
            blockingMode: preferences.blockingMode,
            manualLaunchIdleThreshold: preferences.manualLaunchIdleThreshold,
            lastHeadphoneActivationDate: audioDeviceMonitor.lastHeadphoneActivationDate
        )

        guard shouldBlock else { return }

        application.forceTerminate()
        replacementLauncher.launchIfConfigured(preferences: preferences)
    }
}
