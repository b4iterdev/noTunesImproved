import Combine
import Foundation

enum BlockingMode: String, CaseIterable, Identifiable {
    case always
    case headphoneTriggeredOnly

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .always:
            return "Always block"
        case .headphoneTriggeredOnly:
            return "Only after headphone activation"
        }
    }
}

final class AppPreferences: ObservableObject {
    static let defaultBlockedBundleIdentifiers: Set<String> = [
        "com.apple.Music",
        "com.apple.iTunes"
    ]

    static let defaultManualLaunchIdleThreshold: TimeInterval = 1.0

    private enum Key {
        static let blockingEnabled = "blockingEnabled"
        static let blockingMode = "blockingMode"
        static let blockedBundleIdentifiers = "blockedBundleIdentifiers"
        static let replacementEnabled = "replacementEnabled"
        static let replacementTarget = "replacementTarget"
        static let hideStatusIcon = "hideStatusIcon"
        static let manualLaunchIdleThreshold = "manualLaunchIdleThreshold"
    }

    private let defaults: UserDefaults
    private var isLoading = true

    @Published var blockingEnabled: Bool {
        didSet { save(blockingEnabled, forKey: Key.blockingEnabled) }
    }

    @Published var blockingMode: BlockingMode {
        didSet { save(blockingMode.rawValue, forKey: Key.blockingMode) }
    }

    @Published var blockedBundleIdentifiers: Set<String> {
        didSet { save(Array(blockedBundleIdentifiers).sorted(), forKey: Key.blockedBundleIdentifiers) }
    }

    @Published var replacementEnabled: Bool {
        didSet { save(replacementEnabled, forKey: Key.replacementEnabled) }
    }

    @Published var replacementTarget: String {
        didSet { save(replacementTarget, forKey: Key.replacementTarget) }
    }

    @Published var hideStatusIcon: Bool {
        didSet { save(hideStatusIcon, forKey: Key.hideStatusIcon) }
    }

    @Published var manualLaunchIdleThreshold: TimeInterval {
        didSet { save(manualLaunchIdleThreshold, forKey: Key.manualLaunchIdleThreshold) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        blockingEnabled = defaults.object(forKey: Key.blockingEnabled) as? Bool ?? true
        blockingMode = defaults.string(forKey: Key.blockingMode).flatMap(BlockingMode.init(rawValue:)) ?? .headphoneTriggeredOnly
        blockedBundleIdentifiers = Set(defaults.stringArray(forKey: Key.blockedBundleIdentifiers) ?? Array(Self.defaultBlockedBundleIdentifiers))
        replacementEnabled = defaults.object(forKey: Key.replacementEnabled) as? Bool ?? false
        replacementTarget = defaults.string(forKey: Key.replacementTarget) ?? ""
        hideStatusIcon = defaults.object(forKey: Key.hideStatusIcon) as? Bool ?? false
        manualLaunchIdleThreshold = defaults.object(forKey: Key.manualLaunchIdleThreshold) as? TimeInterval ?? Self.defaultManualLaunchIdleThreshold
        isLoading = false
    }

    func isBlocked(bundleIdentifier: String) -> Bool {
        blockedBundleIdentifiers.contains(bundleIdentifier)
    }

    func setBlocked(_ blocked: Bool, bundleIdentifier: String) {
        if blocked {
            blockedBundleIdentifiers.insert(bundleIdentifier)
        } else {
            blockedBundleIdentifiers.remove(bundleIdentifier)
        }
    }

    private func save(_ value: Any, forKey key: String) {
        guard !isLoading else { return }
        defaults.set(value, forKey: key)
    }
}
