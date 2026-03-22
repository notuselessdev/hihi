import AppKit
import SwiftUI

/// A transparent, click-through overlay window that spans the bottom of the primary display.
/// Used to render the animation without blocking user interaction.
final class OverlayWindow: NSWindow {
    /// Height of the overlay strip at the bottom of the screen.
    static let overlayHeight: CGFloat = 360

    init() {
        guard let screen = NSScreen.main else {
            super.init(
                contentRect: .zero,
                styleMask: .borderless,
                backing: .buffered,
                defer: false
            )
            return
        }

        let frame = NSRect(
            x: screen.frame.origin.x,
            y: screen.frame.origin.y,
            width: screen.frame.width,
            height: Self.overlayHeight
        )

        super.init(
            contentRect: frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )

        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        level = .screenSaver
        collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        ignoresMouseEvents = true
        isReleasedWhenClosed = false
    }

    /// Shows the overlay window (call before starting animation).
    func showOverlay() {
        orderFrontRegardless()
    }

    /// Hides the overlay window (call after animation completes).
    func hideOverlay() {
        orderOut(nil)
    }
}

/// Manages the lifecycle of the overlay window as a shared resource.
@MainActor
final class OverlayWindowController: ObservableObject {
    static let shared = OverlayWindowController()

    let window: OverlayWindow

    private init() {
        window = OverlayWindow()
    }

    func show() {
        window.showOverlay()
    }

    func hide() {
        window.hideOverlay()
    }
}
