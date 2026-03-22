import AppKit

/// Manages automatic animation triggering at random intervals.
/// Pauses when the app is deactivated and resumes when reactivated.
@MainActor
final class HeeHeeTimer {

    static let shared = HeeHeeTimer()

    private var minInterval: TimeInterval {
        PreferencesManager.shared.minIntervalMinutes * 60
    }
    private var maxInterval: TimeInterval {
        PreferencesManager.shared.maxIntervalMinutes * 60
    }

    private var timer: Timer?
    private var isPaused = false

    private init() {
        // Observe app activation state
        NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.resume()
            }
        }

        NotificationCenter.default.addObserver(
            forName: NSApplication.didResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.pause()
            }
        }
    }

    // MARK: - Public API

    /// Starts the random timer. Call once at app launch.
    func start() {
        scheduleNext()
    }

    /// Resets the timer (e.g., after a manual trigger).
    func reset() {
        timer?.invalidate()
        timer = nil
        scheduleNext()
    }

    // MARK: - Private

    private func scheduleNext() {
        timer?.invalidate()
        let interval = TimeInterval.random(in: minInterval...maxInterval)
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.fire()
            }
        }
    }

    private func fire() {
        guard !HeeHeeAnimator.shared.isAnimating else {
            // If already animating, reschedule
            scheduleNext()
            return
        }
        HeeHeeAnimator.shared.startAnimation {
            Task { @MainActor in
                HeeHeeTimer.shared.scheduleNext()
            }
        }
    }

    private func pause() {
        isPaused = true
        timer?.invalidate()
        timer = nil
    }

    private func resume() {
        guard isPaused else { return }
        isPaused = false
        scheduleNext()
    }
}
