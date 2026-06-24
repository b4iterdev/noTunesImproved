import AppKit
import Foundation

struct ReplacementLauncher {
    func launchIfConfigured(preferences: AppPreferences) {
        guard preferences.replacementEnabled else { return }

        let target = preferences.replacementTarget.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !target.isEmpty else { return }

        if let url = URL(string: target), url.scheme != nil {
            NSWorkspace.shared.open(url)
            return
        }

        let fileURL = URL(fileURLWithPath: target)
        NSWorkspace.shared.open(fileURL)
    }
}
