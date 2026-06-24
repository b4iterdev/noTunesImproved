import Foundation

@discardableResult
func check(_ condition: @autoclosure () -> Bool, _ message: String) -> Bool {
    if !condition() {
        print("FAIL: \(message)")
        exit(1)
    }
    return true
}

@main
struct LogicSmokeTests {
    static func main() {
        let now = Date(timeIntervalSince1970: 1_000)

        // Simulated system states injected into the classifier.
        let autoLaunchClassifier = LaunchTriggerClassifier(
            headphoneTriggerWindow: 8,
            idleTimeProvider: { 30 }   // high idle: no recent input -> looks like an auto-launch
        )
        let manualLaunchClassifier = LaunchTriggerClassifier(
            headphoneTriggerWindow: 8,
            idleTimeProvider: { 0.2 }  // low idle: user just clicked/typed -> looks like a manual launch
        )

        // --- Auto-launch path: within window AND user idle -> block ----------------
        check(
            autoLaunchClassifier.shouldBlock(
                blockingEnabled: true,
                blockingMode: .headphoneTriggeredOnly,
                lastHeadphoneActivationDate: now.addingTimeInterval(-4),
                launchDate: now
            ),
            "headphone-only mode should block auto-launches inside trigger window"
        )

        // --- Manual-launch path: within window BUT user was active -> allow --------
        check(
            !manualLaunchClassifier.shouldBlock(
                blockingEnabled: true,
                blockingMode: .headphoneTriggeredOnly,
                lastHeadphoneActivationDate: now.addingTimeInterval(-4),
                launchDate: now
            ),
            "headphone-only mode should allow manual launches inside trigger window when user was active"
        )

        // --- Outside window: never block (idle is irrelevant) ----------------------
        check(
            !autoLaunchClassifier.shouldBlock(
                blockingEnabled: true,
                blockingMode: .headphoneTriggeredOnly,
                lastHeadphoneActivationDate: now.addingTimeInterval(-12),
                launchDate: now
            ),
            "headphone-only mode should allow launches outside trigger window"
        )

        // --- Always mode: block without headphone trigger --------------------------
        check(
            autoLaunchClassifier.shouldBlock(
                blockingEnabled: true,
                blockingMode: .always,
                lastHeadphoneActivationDate: nil,
                launchDate: now
            ),
            "always mode should block without headphone trigger"
        )

        // --- Unknown idle (nil) falls back to conservative timing-only block ------
        let unknownIdleClassifier = LaunchTriggerClassifier(
            headphoneTriggerWindow: 8,
            idleTimeProvider: { nil }
        )
        check(
            unknownIdleClassifier.shouldBlock(
                blockingEnabled: true,
                blockingMode: .headphoneTriggeredOnly,
                lastHeadphoneActivationDate: now.addingTimeInterval(-4),
                launchDate: now
            ),
            "headphone-only mode should block inside window when idle time is unavailable"
        )

        // --- Disabled: never block ------------------------------------------------
        check(
            !autoLaunchClassifier.shouldBlock(
                blockingEnabled: false,
                blockingMode: .headphoneTriggeredOnly,
                lastHeadphoneActivationDate: now.addingTimeInterval(-4),
                launchDate: now
            ),
            "blocking should be disabled when blockingEnabled is false"
        )

        let suiteName = "LogicSmokeTests-\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            print("FAIL: could not create isolated defaults suite")
            exit(1)
        }
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let preferences = AppPreferences(defaults: defaults)
        check(preferences.blockingEnabled, "blocking should default to enabled")
        check(preferences.blockingMode == .headphoneTriggeredOnly, "blocking mode should default to headphone-triggered only")
        check(preferences.blockedBundleIdentifiers.contains("com.apple.Music"), "Music should be blocked by default")
        check(preferences.blockedBundleIdentifiers.contains("com.apple.iTunes"), "iTunes should be blocked by default")

        preferences.blockingMode = .always
        let reloadedPreferences = AppPreferences(defaults: defaults)
        check(reloadedPreferences.blockingMode == .always, "blocking mode should persist")

        print("PASS")
    }
}
