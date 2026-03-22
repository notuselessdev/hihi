import Foundation
import Combine

/// Manages user preferences backed by UserDefaults.
class PreferencesManager: ObservableObject {

    static let shared = PreferencesManager()

    private static let minIntervalKey = "minIntervalMinutes"
    private static let maxIntervalKey = "maxIntervalMinutes"
    private static let soundEnabledKey = "soundEnabled"
    private static let speechBubbleEnabledKey = "speechBubbleEnabled"

    @Published var minIntervalMinutes: Double {
        didSet { UserDefaults.standard.set(minIntervalMinutes, forKey: Self.minIntervalKey) }
    }

    @Published var maxIntervalMinutes: Double {
        didSet { UserDefaults.standard.set(maxIntervalMinutes, forKey: Self.maxIntervalKey) }
    }

    @Published var soundEnabled: Bool {
        didSet { UserDefaults.standard.set(soundEnabled, forKey: Self.soundEnabledKey) }
    }

    @Published var speechBubbleEnabled: Bool {
        didSet { UserDefaults.standard.set(speechBubbleEnabled, forKey: Self.speechBubbleEnabledKey) }
    }

    private init() {
        let defaults = UserDefaults.standard

        // Register defaults
        defaults.register(defaults: [
            Self.minIntervalKey: 5.0,
            Self.maxIntervalKey: 15.0,
            Self.soundEnabledKey: true,
            Self.speechBubbleEnabledKey: true,
        ])

        self.minIntervalMinutes = defaults.double(forKey: Self.minIntervalKey)
        self.maxIntervalMinutes = defaults.double(forKey: Self.maxIntervalKey)
        self.soundEnabled = defaults.bool(forKey: Self.soundEnabledKey)
        self.speechBubbleEnabled = defaults.bool(forKey: Self.speechBubbleEnabledKey)
    }
}
