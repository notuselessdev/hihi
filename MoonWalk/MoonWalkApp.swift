import SwiftUI

@main
struct MoonWalkApp: App {
    @ObservedObject private var animator = MoonwalkAnimator.shared
    @ObservedObject private var launchAtLogin = LaunchAtLoginManager.shared

    init() {
        MoonwalkTimer.shared.start()
    }

    var body: some Scene {
        MenuBarExtra("MoonWalk", systemImage: "figure.walk") {
            Button("Moonwalk Now") {
                MoonwalkTimer.shared.reset()
                MoonwalkAnimator.shared.startMoonwalk()
            }
            .disabled(animator.isAnimating)
            .keyboardShortcut("m", modifiers: [.command, .shift])

            Divider()

            Toggle("Launch at Login", isOn: $launchAtLogin.isEnabled)

            Divider()

            Button("Preferences...") {
                PreferencesWindowController.shared.showWindow()
            }
            .keyboardShortcut(",", modifiers: .command)

            Divider()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: .command)
        }
    }
}

// MARK: - Preferences Window

@MainActor
final class PreferencesWindowController {
    static let shared = PreferencesWindowController()

    private var window: NSWindow?

    private init() {}

    func showWindow() {
        if let existing = window, existing.isVisible {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let preferencesView = PreferencesView()
        let hostingView = NSHostingView(rootView: preferencesView)
        hostingView.frame = NSRect(x: 0, y: 0, width: 380, height: 360)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 360),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "MoonWalk Preferences"
        window.contentView = hostingView
        window.center()
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        self.window = window
    }
}

struct PreferencesView: View {
    @ObservedObject private var prefs = PreferencesManager.shared
    @ObservedObject private var launchAtLogin = LaunchAtLoginManager.shared

    var body: some View {
        Form {
            Section("Timer") {
                HStack {
                    Text("Min interval:")
                    Slider(value: $prefs.minIntervalMinutes, in: 1...60, step: 1) {
                        Text("Min")
                    }
                    Text("\(Int(prefs.minIntervalMinutes)) min")
                        .frame(width: 50, alignment: .trailing)
                }
                .onChange(of: prefs.minIntervalMinutes) { newValue in
                    if prefs.maxIntervalMinutes < newValue {
                        prefs.maxIntervalMinutes = newValue
                    }
                }

                HStack {
                    Text("Max interval:")
                    Slider(value: $prefs.maxIntervalMinutes, in: 1...60, step: 1) {
                        Text("Max")
                    }
                    Text("\(Int(prefs.maxIntervalMinutes)) min")
                        .frame(width: 50, alignment: .trailing)
                }
                .onChange(of: prefs.maxIntervalMinutes) { newValue in
                    if prefs.minIntervalMinutes > newValue {
                        prefs.minIntervalMinutes = newValue
                    }
                }
            }

            Section("Effects") {
                Toggle("Enable sound", isOn: $prefs.soundEnabled)
                Toggle("Enable speech bubble", isOn: $prefs.speechBubbleEnabled)
            }

            Section("General") {
                Toggle("Launch at Login", isOn: $launchAtLogin.isEnabled)
            }
        }
        .formStyle(.grouped)
        .frame(width: 380, height: 380)
    }
}
