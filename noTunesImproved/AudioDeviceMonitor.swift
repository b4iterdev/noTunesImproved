import Combine
import CoreAudio
import Foundation

final class AudioDeviceMonitor: ObservableObject {
    @Published private(set) var lastHeadphoneActivationDate: Date?
    @Published private(set) var currentOutputDeviceName: String = "Unknown Output"

    private let headphoneNameTokens = [
        "airpods",
        "beats",
        "headphone",
        "headphones",
        "earbud",
        "earbuds",
        "buds"
    ]

    private var defaultOutputAddress = AudioObjectPropertyAddress(
        mSelector: kAudioHardwarePropertyDefaultOutputDevice,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMain
    )
    private var defaultOutputListenerBlock: AudioObjectPropertyListenerBlock?
    private var isMonitoring = false

    func start() {
        guard !isMonitoring else { return }
        isMonitoring = true
        refreshDefaultOutputDevice(markActivation: false)

        let listenerBlock: AudioObjectPropertyListenerBlock = { [weak self] _, _ in
            self?.refreshDefaultOutputDevice(markActivation: true)
        }
        defaultOutputListenerBlock = listenerBlock

        AudioObjectAddPropertyListenerBlock(
            AudioObjectID(kAudioObjectSystemObject),
            &defaultOutputAddress,
            DispatchQueue.main,
            listenerBlock
        )
    }

    func stop() {
        guard isMonitoring else { return }
        isMonitoring = false

        if let defaultOutputListenerBlock {
            AudioObjectRemovePropertyListenerBlock(
                AudioObjectID(kAudioObjectSystemObject),
                &defaultOutputAddress,
                DispatchQueue.main,
                defaultOutputListenerBlock
            )
            self.defaultOutputListenerBlock = nil
        }
    }

    func refreshDefaultOutputDevice(markActivation: Bool = true) {
        guard let deviceID = defaultOutputDeviceID() else { return }

        let deviceName = outputDeviceName(deviceID: deviceID) ?? "Unknown Output"
        currentOutputDeviceName = deviceName

        if markActivation, isLikelyHeadphone(deviceID: deviceID, name: deviceName) {
            lastHeadphoneActivationDate = Date()
        }
    }

    private func defaultOutputDeviceID() -> AudioDeviceID? {
        var deviceID = AudioDeviceID(0)
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &defaultOutputAddress,
            0,
            nil,
            &size,
            &deviceID
        )
        return status == noErr ? deviceID : nil
    }

    private func outputDeviceName(deviceID: AudioDeviceID) -> String? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioObjectPropertyName,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var name: CFString = "" as CFString
        var size = UInt32(MemoryLayout<CFString>.size)
        let status = AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, &name)
        return status == noErr ? name as String : nil
    }

    private func isLikelyHeadphone(deviceID: AudioDeviceID, name: String) -> Bool {
        let normalizedName = name.lowercased()
        if headphoneNameTokens.contains(where: normalizedName.contains) {
            return true
        }

        guard let transportType = outputDeviceTransportType(deviceID: deviceID) else {
            return false
        }

        return transportType == kAudioDeviceTransportTypeBluetooth
    }

    private func outputDeviceTransportType(deviceID: AudioDeviceID) -> UInt32? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyTransportType,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var transportType: UInt32 = 0
        var size = UInt32(MemoryLayout<UInt32>.size)
        let status = AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, &transportType)
        return status == noErr ? transportType : nil
    }
}
