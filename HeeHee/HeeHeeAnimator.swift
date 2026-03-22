import AppKit
import AVFoundation
import Combine

/// Plays the hee-hee video across the overlay window and triggers audio at random points.
@MainActor
final class HeeHeeAnimator: ObservableObject {

    static let shared = HeeHeeAnimator()

    // MARK: - Configuration

    /// Display size for the video in the overlay (square video, fit to overlay height).
    private static let videoDisplaySize = NSSize(width: 280, height: 280)

    // MARK: - State

    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var videoHostView: NSView?
    private var heeHeeTimer: Timer?
    private var hooooTimer: Timer?
    private var speechBubble: SpeechBubbleView?
    private var bubbleTrackingTimer: Timer?
    private var onComplete: (() -> Void)?
    private var endObserver: Any?
    @Published private(set) var isAnimating = false
    private var lastWentRight: Bool? = nil

    private init() {}

    // MARK: - Public API

    func startAnimation(completion: (() -> Void)? = nil) {
        guard !isAnimating else { return }
        isAnimating = true
        onComplete = completion

        guard let videoURL = Bundle.main.url(forResource: "hee-hee", withExtension: "mov") else {
            stopAnimation()
            return
        }

        let controller = OverlayWindowController.shared
        controller.show()

        let goingRight: Bool
        if let last = lastWentRight {
            goingRight = !last
        } else {
            goingRight = Bool.random()
        }
        lastWentRight = goingRight
        let screenWidth = controller.window.frame.width
        let size = Self.videoDisplaySize

        let startX: CGFloat = goingRight ? -size.width : screenWidth
        let endX: CGFloat = goingRight ? screenWidth : -size.width

        let playerItem = AVPlayerItem(url: videoURL)
        let avPlayer = AVPlayer(playerItem: playerItem)
        avPlayer.isMuted = true
        player = avPlayer

        // Loop the video
        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { [weak avPlayer] _ in
            avPlayer?.seek(to: .zero)
            avPlayer?.play()
        }

        // Host view for the AVPlayerLayer
        let hostView = NSView(frame: NSRect(x: startX, y: -35, width: size.width, height: size.height))
        hostView.wantsLayer = true

        let layer = AVPlayerLayer(player: avPlayer)
        layer.frame = hostView.bounds
        layer.videoGravity = .resizeAspect
        layer.backgroundColor = NSColor.clear.cgColor
        hostView.layer?.addSublayer(layer)

        // Flip horizontally when going left to right so the character faces the correct direction
        if goingRight {
            layer.transform = CATransform3DMakeScale(-1, 1, 1)
        }

        controller.window.contentView?.addSubview(hostView)
        videoHostView = hostView
        playerLayer = layer
        avPlayer.play()

        // Schedule audio at random points during the slide
        let duration = Double.random(in: 5...8)
        let heeHeeDelay = Double.random(in: 0.5...(duration * 0.5))
        let hooooDelay = Double.random(in: (duration * 0.5)...(duration - 1.0))

        heeHeeTimer = Timer.scheduledTimer(withTimeInterval: heeHeeDelay, repeats: false) { [weak self] _ in
            Task { @MainActor in
                HeeHeeAudioPlayer.shared.playHeeHee()
                if PreferencesManager.shared.speechBubbleEnabled {
                    self?.showSpeechBubble(text: "hee-hee!")
                }
            }
        }

        hooooTimer = Timer.scheduledTimer(withTimeInterval: hooooDelay, repeats: false) { [weak self] _ in
            Task { @MainActor in
                HeeHeeAudioPlayer.shared.playHoooo()
                if PreferencesManager.shared.speechBubbleEnabled {
                    self?.showSpeechBubble(text: "hoooo!")
                }
            }
        }

        // Slide across the screen
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = duration
            context.timingFunction = CAMediaTimingFunction(name: .linear)
            hostView.animator().frame.origin.x = endX
        }, completionHandler: { [weak self] in
            Task { @MainActor in
                self?.stopAnimation()
            }
        })
    }

    func stopAnimation() {
        heeHeeTimer?.invalidate()
        heeHeeTimer = nil
        hooooTimer?.invalidate()
        hooooTimer = nil
        bubbleTrackingTimer?.invalidate()
        bubbleTrackingTimer = nil

        if let observer = endObserver {
            NotificationCenter.default.removeObserver(observer)
            endObserver = nil
        }

        player?.pause()
        player = nil
        playerLayer?.removeFromSuperlayer()
        playerLayer = nil

        speechBubble?.removeFromSuperview()
        speechBubble = nil
        videoHostView?.removeFromSuperview()
        videoHostView = nil

        isAnimating = false
        OverlayWindowController.shared.hide()

        let callback = onComplete
        onComplete = nil
        callback?()
    }

    // MARK: - Speech Bubble

    private func showSpeechBubble(text: String) {
        // Remove any existing bubble first
        speechBubble?.removeFromSuperview()
        speechBubble = nil
        bubbleTrackingTimer?.invalidate()
        bubbleTrackingTimer = nil

        guard let hostView = videoHostView else { return }

        let bubble = SpeechBubbleView.create(text: text)
        bubble.alphaValue = 1.0

        // Position bubble above the character's current location
        positionBubble(bubble, above: hostView)

        OverlayWindowController.shared.window.contentView?.addSubview(bubble)
        speechBubble = bubble

        // Track the character so the bubble follows along
        bubbleTrackingTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, let bubble = self.speechBubble, let hostView = self.videoHostView else { return }
                self.positionBubble(bubble, above: hostView)
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            self?.bubbleTrackingTimer?.invalidate()
            self?.bubbleTrackingTimer = nil
            guard let bubble = self?.speechBubble else { return }
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.8
                bubble.animator().alphaValue = 0.0
            }, completionHandler: { [weak self] in
                self?.speechBubble?.removeFromSuperview()
                self?.speechBubble = nil
            })
        }
    }

    private func positionBubble(_ bubble: SpeechBubbleView, above hostView: NSView) {
        let spriteX: CGFloat
        if let presentationLayer = hostView.layer?.presentation() {
            spriteX = presentationLayer.frame.origin.x
        } else {
            spriteX = hostView.frame.origin.x
        }
        let bubbleX = spriteX + Self.videoDisplaySize.width / 2 - bubble.frame.width / 2
        let bubbleY = hostView.frame.origin.y + Self.videoDisplaySize.height + 5
        bubble.frame.origin = NSPoint(x: bubbleX, y: bubbleY)
    }
}
