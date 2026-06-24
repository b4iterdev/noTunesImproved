import SwiftUI

struct ConfigurationView: View {
    @ObservedObject var preferences: AppPreferences

    private let knownApps = [
        (name: "Apple Music", bundleIdentifier: "com.apple.Music"),
        (name: "iTunes", bundleIdentifier: "com.apple.iTunes")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            header

            Form {
                Section("Blocking") {
                    Toggle("Enable blocking", isOn: $preferences.blockingEnabled)

                    Picker("Mode", selection: $preferences.blockingMode) {
                        ForEach(BlockingMode.allCases) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }
                    .pickerStyle(.radioGroup)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Apps to block")
                            .font(.headline)

                        ForEach(knownApps, id: \.bundleIdentifier) { app in
                            Toggle(
                                app.name,
                                isOn: blockedBinding(for: app.bundleIdentifier)
                            )
                        }
                    }
                }

                Section("Replacement") {
                    Toggle("Open a replacement after blocking", isOn: $preferences.replacementEnabled)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Replacement target")
                            .font(.headline)

                        TextField("https://music.youtube.com or /Applications/Spotify.app", text: $preferences.replacementTarget)
                            .textFieldStyle(.roundedBorder)
                            .disabled(!preferences.replacementEnabled)

                        Text("Enter a website URL or an app/file path to open after a selected app is blocked.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Text("Headphone-triggered mode blocks selected apps only when they launch shortly after a likely headphone or Bluetooth audio device activation. macOS does not expose the exact launch cause, so the app combines the activation time with recent user-input activity to tell a system auto-launch apart from a manual launch.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(28)
        .frame(minWidth: 540, minHeight: 500)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("noTunes Improved")
                .font(.system(size: 28, weight: .bold, design: .rounded))

            Text("Keep Music out of the way, especially when headphones wake it up.")
                .foregroundStyle(.secondary)
        }
    }

    private func blockedBinding(for bundleIdentifier: String) -> Binding<Bool> {
        Binding(
            get: { preferences.blockedBundleIdentifiers.contains(bundleIdentifier) },
            set: { preferences.setBlocked($0, bundleIdentifier: bundleIdentifier) }
        )
    }
}

#Preview {
    ConfigurationView(preferences: AppPreferences())
}
