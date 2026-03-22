import AppKit

/// A comic-style speech bubble that displays text and fades out.
final class SpeechBubbleView: NSView {

    private static let bubbleSize = NSSize(width: 90, height: 45)
    private static let tailHeight: CGFloat = 10

    private let text: String

    override var isFlipped: Bool { false }

    init(frame frameRect: NSRect, text: String) {
        self.text = text
        super.init(frame: frameRect)
        wantsLayer = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let bounds = self.bounds
        let tailHeight = Self.tailHeight
        let bubbleRect = NSRect(x: 2, y: tailHeight, width: bounds.width - 4, height: bounds.height - tailHeight - 2)

        // Draw bubble background
        NSColor.white.setFill()
        let bubble = NSBezierPath(roundedRect: bubbleRect, xRadius: 10, yRadius: 10)
        bubble.fill()

        // Draw bubble border
        NSColor.black.setStroke()
        bubble.lineWidth = 2
        bubble.stroke()

        // Draw tail (triangle pointing down-center)
        let tail = NSBezierPath()
        let cx = bounds.width / 2
        tail.move(to: NSPoint(x: cx - 6, y: tailHeight))
        tail.line(to: NSPoint(x: cx, y: 0))
        tail.line(to: NSPoint(x: cx + 6, y: tailHeight))
        tail.close()

        NSColor.white.setFill()
        tail.fill()

        NSColor.black.setStroke()
        tail.lineWidth = 2
        tail.stroke()

        // Cover the tail-bubble seam with white
        let seam = NSBezierPath(rect: NSRect(x: cx - 7, y: tailHeight, width: 14, height: 4))
        NSColor.white.setFill()
        seam.fill()

        // Draw text
        let nsText = text as NSString
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 14),
            .foregroundColor: NSColor.black,
        ]
        let textSize = nsText.size(withAttributes: attrs)
        let textOrigin = NSPoint(
            x: bubbleRect.midX - textSize.width / 2,
            y: bubbleRect.midY - textSize.height / 2
        )
        nsText.draw(at: textOrigin, withAttributes: attrs)
    }

    /// Creates a speech bubble view sized appropriately.
    static func create(text: String = "hee-hee!") -> SpeechBubbleView {
        let totalHeight = bubbleSize.height + tailHeight
        let view = SpeechBubbleView(frame: NSRect(x: 0, y: 0, width: bubbleSize.width, height: totalHeight), text: text)
        return view
    }
}
