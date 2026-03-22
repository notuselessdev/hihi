import AVFoundation
import CoreAudio

/// Plays moonwalk audio clips (hee-hee and hoooo), respecting system volume and mute state.
@MainActor
final class HihiAudioPlayer {

    static let shared = HihiAudioPlayer()

    private var players: [AVAudioPlayer] = []

    private init() {}

    /// Plays the hee-hee sound once.
    func playHeeHee() {
        playSound(resource: "hee-hee", ext: "mp3")
    }

    /// Plays the hoooo sound once.
    func playHoooo() {
        playSound(resource: "hoooo", ext: "mp3")
    }

    private func playSound(resource: String, ext: String) {
        guard PreferencesManager.shared.soundEnabled else { return }
        guard !isSystemMuted() else { return }

        guard let url = Bundle.main.url(forResource: resource, withExtension: ext) else { return }

        do {
            let audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer.volume = 1.0
            audioPlayer.play()
            players.removeAll { !$0.isPlaying }
            players.append(audioPlayer)
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
