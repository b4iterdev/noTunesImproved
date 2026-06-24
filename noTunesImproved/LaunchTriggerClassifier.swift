import Foundation

struct LaunchTriggerClassifier {
    let headphoneTriggerWindow: TimeInterval

    let idleTimeProvider: () -> Double?

    init(
        headphoneTriggerWindow: TimeInterval = 8,
        idleTimeProvider: @escaping () -> Double? = { UserActivityMonitor().secondsSinceLastInput() }
    ) {
        self.headphoneTriggerWindow = headphoneTriggerWindow
        self.idleTimeProvider = idleTimeProvider
    }

    func shouldBlock(
        blockingEnabled: Bool,
        blockingMode: BlockingMode,
        manualLaunchIdleThreshold: TimeInterval,
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

            if let idle = idleTimeProvider(), idle <= manualLaunchIdleThreshold {
                return false
            }
            return true
        }
    }
}
