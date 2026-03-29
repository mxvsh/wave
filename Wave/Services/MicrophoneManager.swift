import Foundation
import CoreAudio

struct AudioInputDevice: Identifiable, Hashable {
    let id: AudioDeviceID
    let name: String
    let uid: String
}

@Observable
final class MicrophoneManager {
    var devices: [AudioInputDevice] = []

    init() { refresh() }

    func refresh() {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var dataSize: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(
            AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &dataSize
        ) == noErr else { return }

        let count = Int(dataSize) / MemoryLayout<AudioDeviceID>.size
        var ids = [AudioDeviceID](repeating: 0, count: count)
        guard AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &dataSize, &ids
        ) == noErr else { return }

        devices = ids.compactMap { deviceID -> AudioInputDevice? in
            guard hasInputChannels(deviceID),
                  let name = propertyString(deviceID, selector: kAudioObjectPropertyName),
                  let uid = propertyString(deviceID, selector: kAudioDevicePropertyDeviceUID)
            else { return nil }
            return AudioInputDevice(id: deviceID, name: name, uid: uid)
        }
    }

    func setDefaultInput(_ deviceID: AudioDeviceID) {
        var id = deviceID
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        AudioObjectSetPropertyData(
            AudioObjectID(kAudioObjectSystemObject), &address,
            0, nil, UInt32(MemoryLayout<AudioDeviceID>.size), &id
        )
    }

    func applySelection(uid: String) {
        guard !uid.isEmpty,
              let device = devices.first(where: { $0.uid == uid })
        else { return }
        setDefaultInput(device.id)
    }

    // MARK: - Private

    private func hasInputChannels(_ id: AudioDeviceID) -> Bool {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreamConfiguration,
            mScope: kAudioDevicePropertyScopeInput,
            mElement: kAudioObjectPropertyElementMain
        )
        var size: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(id, &address, 0, nil, &size) == noErr, size > 0 else { return false }

        let bufferList = UnsafeMutablePointer<AudioBufferList>.allocate(capacity: Int(size))
        defer { bufferList.deallocate() }
        guard AudioObjectGetPropertyData(id, &address, 0, nil, &size, bufferList) == noErr else { return false }

        let channels = (0..<Int(bufferList.pointee.mNumberBuffers)).reduce(0) {
            $0 + Int(UnsafeMutableAudioBufferListPointer(bufferList)[$1].mNumberChannels)
        }
        return channels > 0
    }

    private func propertyString(_ id: AudioDeviceID, selector: AudioObjectPropertySelector) -> String? {
        var address = AudioObjectPropertyAddress(
            mSelector: selector,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var value: CFString = "" as CFString
        var size = UInt32(MemoryLayout<CFString>.size)
        guard AudioObjectGetPropertyData(id, &address, 0, nil, &size, &value) == noErr else { return nil }
        return value as String
    }
}
