import AVFoundation
import CoreAudio

/// Plays the "hihi" audio clip, respecting system volume and mute state.
@MainActor
final class HihiAudioPlayer {

    static let shared = HihiAudioPlayer()

    private var player: AVAudioPlayer?

    private init() {}

    /// Plays the hihi sound once. Does nothing if the system is muted.
    func play() {
        guard PreferencesManager.shared.soundEnabled else { return }
        guard !isSystemMuted() else { return }

        guard let url = Bundle.main.url(forResource: "hihi", withExtension: "m4a") else { return }

        do {
            let audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer.volume = 1.0  // Use full volume — AVAudioPlayer respects system volume automatically
            audioPlayer.play()
            player = audioPlayer  // Retain until playback finishes
        } catch {
            // Silently fail — audio is a nice-to-have
        }
    }

    /// Checks if the default output device is muted (volume == 0 or mute flag set).
    private func isSystemMuted() -> Bool {
        var defaultDeviceID = AudioDeviceID(0)
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)

        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0, nil,
            &size,
            &defaultDeviceID
        )
        guard status == noErr else { return false }

        // Check mute flag
        var muted: UInt32 = 0
        size = UInt32(MemoryLayout<UInt32>.size)
        var muteAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )

        let muteStatus = AudioObjectGetPropertyData(defaultDeviceID, &muteAddress, 0, nil, &size, &muted)
        if muteStatus == noErr && muted == 1 {
            return true
        }

        // Check if volume is effectively zero
        var volume: Float32 = 0
        size = UInt32(MemoryLayout<Float32>.size)
        var volumeAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwareServiceDeviceProperty_VirtualMainVolume,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )

        let volStatus = AudioObjectGetPropertyData(defaultDeviceID, &volumeAddress, 0, nil, &size, &volume)
        if volStatus == noErr && volume < 0.001 {
            return true
        }

        return false
    }
}
