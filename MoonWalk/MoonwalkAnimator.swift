import AppKit

/// Generates moonwalk sprite frames programmatically and animates them across the overlay window.
@MainActor
final class MoonwalkAnimator {

    static let shared = MoonwalkAnimator()

    // MARK: - Sprite Configuration

    private static let spriteSize = NSSize(width: 80, height: 150)
    private static let frameCount = 4
    private static let framesPerSecond: Double = 8

    // MARK: - State

    private let spriteFrames: [NSImage]
    private var spriteView: NSImageView?
    private var frameTimer: Timer?
    private var currentFrame = 0
    private(set) var isAnimating = false
    private var hihiTimer: Timer?
    private var speechBubble: SpeechBubbleView?

    private init() {
        spriteFrames = Self.generateFrames()
    }

    // MARK: - Public API

    func startMoonwalk() {
        guard !isAnimating else { return }
        isAnimating = true

        let controller = OverlayWindowController.shared
        controller.show()

        let goingRight = Bool.random()
        let screenWidth = controller.window.frame.width
        let size = Self.spriteSize

        // Position sprite just off-screen on the starting side
        let startX: CGFloat = goingRight ? -size.width : screenWidth
        let endX: CGFloat = goingRight ? screenWidth : -size.width

        let imageView = NSImageView(frame: NSRect(x: startX, y: 10, width: size.width, height: size.height))
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.image = spriteFrames[0]
        imageView.wantsLayer = true

        // Moonwalk faces left by default; flip when going right
        if goingRight {
            imageView.layer?.transform = CATransform3DMakeScale(-1, 1, 1)
        }

        controller.window.contentView?.addSubview(imageView)
        spriteView = imageView

        // Start frame-by-frame animation
        currentFrame = 0
        frameTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / Self.framesPerSecond, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.advanceFrame()
            }
        }

        // Schedule "hihi" audio at a random point during the moonwalk
        let duration = Double.random(in: 5...8)
        let hihiDelay = Double.random(in: 0.5...(duration - 1.0))
        hihiTimer = Timer.scheduledTimer(withTimeInterval: hihiDelay, repeats: false) { [weak self] _ in
            Task { @MainActor in
                HihiAudioPlayer.shared.play()
                self?.showSpeechBubble()
            }
        }

        // Slide across the screen over 5-8 seconds
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = duration
            context.timingFunction = CAMediaTimingFunction(name: .linear)
            imageView.animator().frame.origin.x = endX
        }, completionHandler: { [weak self] in
            Task { @MainActor in
                self?.stopMoonwalk()
            }
        })
    }

    func stopMoonwalk() {
        frameTimer?.invalidate()
        frameTimer = nil
        hihiTimer?.invalidate()
        hihiTimer = nil
        speechBubble?.removeFromSuperview()
        speechBubble = nil
        spriteView?.removeFromSuperview()
        spriteView = nil
        currentFrame = 0
        isAnimating = false
        OverlayWindowController.shared.hide()
    }

    // MARK: - Speech Bubble

    private func showSpeechBubble() {
        guard let spriteView = spriteView else { return }

        // Get the sprite's current on-screen position from the presentation layer
        let spriteX: CGFloat
        if let presentationLayer = spriteView.layer?.presentation() {
            spriteX = presentationLayer.frame.origin.x
        } else {
            spriteX = spriteView.frame.origin.x
        }

        let bubble = SpeechBubbleView.create()
        let bubbleX = spriteX + Self.spriteSize.width / 2 - bubble.frame.width / 2
        let bubbleY = spriteView.frame.origin.y + Self.spriteSize.height + 5
        bubble.frame.origin = NSPoint(x: bubbleX, y: bubbleY)
        bubble.alphaValue = 1.0

        OverlayWindowController.shared.window.contentView?.addSubview(bubble)
        speechBubble = bubble

        // Fade out after 1.5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let bubble = self?.speechBubble else { return }
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.5
                bubble.animator().alphaValue = 0.0
            }, completionHandler: { [weak self] in
                self?.speechBubble?.removeFromSuperview()
                self?.speechBubble = nil
            })
        }
    }

    // MARK: - Frame Animation

    private func advanceFrame() {
        currentFrame = (currentFrame + 1) % spriteFrames.count
        spriteView?.image = spriteFrames[currentFrame]
    }

    // MARK: - Sprite Generation

    /// Generates moonwalk animation frames as a simple silhouette figure with hat.
    /// Each frame varies the leg positions to simulate the moonwalk slide.
    private static func generateFrames() -> [NSImage] {
        (0..<frameCount).map { drawFrame(index: $0) }
    }

    private static func drawFrame(index: Int) -> NSImage {
        let size = spriteSize
        let image = NSImage(size: size)
        image.lockFocus()

        let color = NSColor.black
        color.setFill()
        color.setStroke()

        let cx: CGFloat = size.width / 2  // center x

        // --- Hat (fedora) ---
        let hatBrim = NSBezierPath(ovalIn: NSRect(x: cx - 22, y: 128, width: 44, height: 10))
        hatBrim.fill()
        let hatTop = NSBezierPath(roundedRect: NSRect(x: cx - 14, y: 133, width: 28, height: 14), xRadius: 6, yRadius: 6)
        hatTop.fill()

        // --- Head ---
        let head = NSBezierPath(ovalIn: NSRect(x: cx - 12, y: 110, width: 24, height: 24))
        head.fill()

        // --- Body (torso) ---
        let torso = NSBezierPath()
        torso.lineWidth = 4
        torso.move(to: NSPoint(x: cx, y: 110))
        torso.line(to: NSPoint(x: cx, y: 60))
        torso.stroke()

        // --- Arms (slight swing) ---
        let armSwing: CGFloat = index % 2 == 0 ? 5 : -5
        let arms = NSBezierPath()
        arms.lineWidth = 3
        // Left arm
        arms.move(to: NSPoint(x: cx, y: 100))
        arms.line(to: NSPoint(x: cx - 20 + armSwing, y: 75))
        // Right arm
        arms.move(to: NSPoint(x: cx, y: 100))
        arms.line(to: NSPoint(x: cx + 20 - armSwing, y: 75))
        arms.stroke()

        // --- Legs (moonwalk cycle) ---
        // 4 frames: alternating which foot is flat vs on toes
        let legs = NSBezierPath()
        legs.lineWidth = 4

        switch index {
        case 0:
            // Left leg: back, flat foot; Right leg: forward, on toes
            // Left leg
            legs.move(to: NSPoint(x: cx, y: 60))
            legs.line(to: NSPoint(x: cx - 15, y: 30))
            legs.line(to: NSPoint(x: cx - 20, y: 8))
            // Left foot (flat)
            legs.move(to: NSPoint(x: cx - 28, y: 8))
            legs.line(to: NSPoint(x: cx - 12, y: 8))

            // Right leg
            legs.move(to: NSPoint(x: cx, y: 60))
            legs.line(to: NSPoint(x: cx + 12, y: 32))
            legs.line(to: NSPoint(x: cx + 10, y: 14))
            // Right foot (on toes)
            legs.move(to: NSPoint(x: cx + 6, y: 14))
            legs.line(to: NSPoint(x: cx + 14, y: 8))

        case 1:
            // Transition: legs closer together
            // Left leg
            legs.move(to: NSPoint(x: cx, y: 60))
            legs.line(to: NSPoint(x: cx - 8, y: 30))
            legs.line(to: NSPoint(x: cx - 10, y: 8))
            // Left foot
            legs.move(to: NSPoint(x: cx - 18, y: 8))
            legs.line(to: NSPoint(x: cx - 4, y: 8))

            // Right leg
            legs.move(to: NSPoint(x: cx, y: 60))
            legs.line(to: NSPoint(x: cx + 8, y: 30))
            legs.line(to: NSPoint(x: cx + 6, y: 12))
            // Right foot (going flat)
            legs.move(to: NSPoint(x: cx, y: 8))
            legs.line(to: NSPoint(x: cx + 14, y: 8))

        case 2:
            // Right leg: back, flat foot; Left leg: forward, on toes
            // Right leg
            legs.move(to: NSPoint(x: cx, y: 60))
            legs.line(to: NSPoint(x: cx + 15, y: 30))
            legs.line(to: NSPoint(x: cx + 20, y: 8))
            // Right foot (flat)
            legs.move(to: NSPoint(x: cx + 12, y: 8))
            legs.line(to: NSPoint(x: cx + 28, y: 8))

            // Left leg
            legs.move(to: NSPoint(x: cx, y: 60))
            legs.line(to: NSPoint(x: cx - 12, y: 32))
            legs.line(to: NSPoint(x: cx - 10, y: 14))
            // Left foot (on toes)
            legs.move(to: NSPoint(x: cx - 14, y: 14))
            legs.line(to: NSPoint(x: cx - 6, y: 8))

        default:
            // Transition: legs closer together (mirrored)
            // Right leg
            legs.move(to: NSPoint(x: cx, y: 60))
            legs.line(to: NSPoint(x: cx + 8, y: 30))
            legs.line(to: NSPoint(x: cx + 10, y: 8))
            // Right foot
            legs.move(to: NSPoint(x: cx + 4, y: 8))
            legs.line(to: NSPoint(x: cx + 18, y: 8))

            // Left leg
            legs.move(to: NSPoint(x: cx, y: 60))
            legs.line(to: NSPoint(x: cx - 8, y: 30))
            legs.line(to: NSPoint(x: cx - 6, y: 12))
            // Left foot (going flat)
            legs.move(to: NSPoint(x: cx - 14, y: 8))
            legs.line(to: NSPoint(x: cx, y: 8))
        }

        legs.stroke()

        image.unlockFocus()
        return image
    }
}
