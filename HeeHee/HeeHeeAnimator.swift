import AppKit
import AVFoundation
import Combine
import CoreImage

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
    private lazy var chromakeyFilterData: CIFilter = Self.chromakeyFilter(fromHue: 0.25, toHue: 0.45)
    private lazy var videoAsset: AVAsset? = Bundle.main.url(forResource: "hee-hee", withExtension: "mp4")
        .map { AVAsset(url: $0) }

    private init() {}

    // MARK: - Public API

    func startAnimation(completion: (() -> Void)? = nil) {
        guard !isAnimating else { return }
        isAnimating = true
        onComplete = completion

        guard let asset = videoAsset else {
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

        // Set up AVPlayer with chromakey composition to remove green screen
        let playerItem = AVPlayerItem(asset: asset)
        playerItem.videoComposition = makeChromakeyComposition(for: asset)

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
        let hostView = NSView(frame: NSRect(x: startX, y: -20, width: size.width, height: size.height))
        hostView.wantsLayer = true

        let layer = AVPlayerLayer(player: avPlayer)
        layer.frame = hostView.bounds
        layer.videoGravity = .resizeAspect
        layer.backgroundColor = NSColor.clear.cgColor
        hostView.layer?.addSublayer(layer)

        // Flip horizontally when going left to right so the character faces the correct direction
        if goingRight {
            hostView.layer?.transform = CATransform3DMakeScale(-1, 1, 1)
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

    // MARK: - Chromakey

    /// Creates an AVVideoComposition that removes green screen pixels in realtime.
    private func makeChromakeyComposition(for asset: AVAsset) -> AVVideoComposition {
        let filter = chromakeyFilterData
        let composition = AVMutableVideoComposition(asset: asset) { request in
            let source = request.sourceImage.clampedToExtent()

            filter.setValue(source, forKey: kCIInputImageKey)

            if let output = filter.outputImage?.cropped(to: request.sourceImage.extent) {
                request.finish(with: output, context: nil)
            } else {
                request.finish(with: source, context: nil)
            }
        }
        composition.renderSize = CGSize(width: 720, height: 720)
        return composition
    }

    /// Builds a CIColorCube filter that maps a hue range to transparent.
    private static func chromakeyFilter(fromHue: CGFloat, toHue: CGFloat) -> CIFilter {
        let cubeSize = 64
        let cubeDataSize = cubeSize * cubeSize * cubeSize * 4
        var cubeData = [Float](repeating: 0, count: cubeDataSize)

        var offset = 0
        for z in 0..<cubeSize {
            let blue = CGFloat(z) / CGFloat(cubeSize - 1)
            for y in 0..<cubeSize {
                let green = CGFloat(y) / CGFloat(cubeSize - 1)
                for x in 0..<cubeSize {
                    let red = CGFloat(x) / CGFloat(cubeSize - 1)

                    let hue = getHue(red: red, green: green, blue: blue)
                    let alpha: Float = (hue >= fromHue && hue <= toHue) ? 0.0 : 1.0

                    cubeData[offset]     = Float(red) * alpha    // premultiplied
                    cubeData[offset + 1] = Float(green) * alpha
                    cubeData[offset + 2] = Float(blue) * alpha
                    cubeData[offset + 3] = alpha
                    offset += 4
                }
            }
        }

        let data = Data(bytes: cubeData, count: cubeDataSize * MemoryLayout<Float>.size)

        let filter = CIFilter(name: "CIColorCube")!
        filter.setValue(cubeSize, forKey: "inputCubeDimension")
        filter.setValue(data, forKey: "inputCubeData")
        return filter
    }

    /// Converts RGB to hue (0.0–1.0).
    private static func getHue(red: CGFloat, green: CGFloat, blue: CGFloat) -> CGFloat {
        let maxVal = max(red, green, blue)
        let minVal = min(red, green, blue)
        let delta = maxVal - minVal

        guard delta > 0.001 else { return 0 }

        var hue: CGFloat
        if maxVal == red {
            hue = (green - blue) / delta
        } else if maxVal == green {
            hue = 2.0 + (blue - red) / delta
        } else {
            hue = 4.0 + (red - green) / delta
        }

        hue /= 6.0
        if hue < 0 { hue += 1.0 }
        return hue
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
