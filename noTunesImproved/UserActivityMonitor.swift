import CoreGraphics
import Foundation

/// Reports how recently the user interacted with the system (keyboard/mouse/trackpad).
///
/// macOS exposes no public API that says *why* an app launched, so this is used to
/// distinguish a manual launch (the user just clicked/typed → low idle) from a
/// system-triggered auto-launch (no recent input → high idle). It is a read-only
/// query over existing aggregate event state; it does not install an event tap and
/// needs no Input Monitoring / Accessibility permission.
struct UserActivityMonitor {
    /// Seconds elapsed since the last combined-session input event.
    ///
    /// `combinedSessionState` covers keyboard, mouse, and trackpad events for the
    /// current session. Returns `nil` only if the underlying call cannot be serviced
    /// (e.g. restricted under sandbox); callers should treat `nil` as "unknown" and
    /// fall back to the existing timing heuristic rather than guessing.
    func secondsSinceLastInput() -> Double? {
        // kCGAnyInputEventType is `~0`, i.e. all bits set -> UInt32.max.
        guard let anyInputEventType = CGEventType(rawValue: UInt32.max) else { return nil }
        let seconds = CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: anyInputEventType)
        // A negative or non-finite result means the state source is unavailable.
        return seconds.isFinite && seconds >= 0 ? seconds : nil
    }
}
