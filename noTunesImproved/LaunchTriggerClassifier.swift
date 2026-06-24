import Foundation

struct LaunchTriggerClassifier {
    /// Block launches that occur within this interval after a headphone activation.
    let headphoneTriggerWindow: TimeInterval

    /// Within the trigger window, a launch is treated as *manual* (allowed) if the
    /// user interacted with the system within this many seconds. A higher value is
    /// more lenient toward slow manual launches but more likely to let an auto-launch
    /// through while the user happens to be active in another app.
    let manualLaunchIdleThreshold: TimeInterval

    /// Returns seconds since the last user input, or `nil` if unavailable. Injected
    /// so tests can simulate auto-launch (high idle) vs manual launch (low idle).
    let idleTimeProvider: () -> Double?

    init(
        headphoneTriggerWindow: TimeInterval = 8,
        manualLaunchIdleThreshold: TimeInterval = 1.0,
        idleTimeProvider: @escaping () -> Double? = { UserActivityMonitor().secondsSinceLastInput() }
    ) {
        self.headphoneTriggerWindow = headphoneTriggerWindow
        self.manualLaunchIdleThreshold = manualLaunchIdleThreshold
        self.idleTimeProvider = idleTimeProvider
    }

    func shouldBlock(
        blockingEnabled: Bool,
        blockingMode: BlockingMode,
        lastHeadphoneActivationDate: Date?,
        launchDate: Date = Date()
    ) -> Bool {
        guard blockingEnabled else { return false }

        switch blockingMode {
        case .always:
            return true
        case .headphoneTriggeredOnly:
            guard let lastHeadphoneActivationDate else { return false }
            let elapsed = launchDate.timeIntervalSince(lastHeadphoneActivationDate)
            guard elapsed >= 0 && elapsed <= headphoneTriggerWindow else { return false }

            // We are inside the headphone trigger window. macOS gives no launch-reason
            // API, so disambiguate using HID idle time: if the user just interacted
            // with the system, treat this as a manual launch and allow it. If idle time
            // is unavailable, fall back to the conservative timing-only behavior (block).
            if let idle = idleTimeProvider(), idle <= manualLaunchIdleThreshold {
                return false
            }
            return true
        }
    }
}
