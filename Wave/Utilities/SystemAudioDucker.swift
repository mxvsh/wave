import CoreAudio

/// Saves and restores the default output device's mute state around a dictation session.
/// Uses CoreAudio's `kAudioDevicePropertyMute` rather than changing volume so the
/// user's volume setting is never touched.
enum SystemAudioDucker {
    private static var savedMuteState: Bool = false

    /// Snapshot the current mute state, then mute system output.
    static func duck() {
        savedMuteState = isMuted()
        setMuted(true)
    }

    /// Restore the mute state captured at the last `duck()` call.
    static func restore() {
        setMuted(savedMuteState)
    }

    // MARK: - Private

    private static func isMuted() -> Bool {
        guard let device = defaultOutputDevice() else { return false }
        var mute: UInt32 = 0
        var size = UInt32(MemoryLayout<UInt32>.size)
        var address = mutePropertyAddress()
        let status = AudioObjectGetPropertyData(device, &address, 0, nil, &size, &mute)
        return status == noErr && mute != 0
    }

    private static func setMuted(_ muted: Bool) {
        guard let device = defaultOutputDevice() else { return }
        var mute = UInt32(muted ? 1 : 0)
        var address = mutePropertyAddress()
        // Silently ignore devices that don't support the mute property (e.g. some BT sinks)
        AudioObjectSetPropertyData(device, &address, 0, nil, UInt32(MemoryLayout<UInt32>.size), &mute)
    }

    private static func defaultOutputDevice() -> AudioDeviceID? {
        var device = AudioDeviceID(kAudioObjectUnknown)
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, &device
        )
        return (status == noErr && device != kAudioObjectUnknown) ? device : nil
    }

    private static func mutePropertyAddress() -> AudioObjectPropertyAddress {
        AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
    }
}
