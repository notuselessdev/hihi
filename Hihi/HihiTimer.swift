import AppKit

/// Manages automatic moonwalk triggering at random intervals between 5 and 30 minutes.
/// Pauses when the app is deactivated and resumes when reactivated.
@MainActor
final class HihiTimer {

    static let shared = HihiTimer()

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

    /// Resets the timer (e.g., after a manual moonwalk trigger).
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
        guard !HihiAnimator.shared.isAnimating else {
            // If already animating, reschedule
            scheduleNext()
            return
        }
        HihiAnimator.shared.startAnimation {
            Task { @MainActor in
                HihiTimer.shared.scheduleNext()
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
