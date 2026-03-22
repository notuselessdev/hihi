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
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                NSApp.activate(ignoringOtherApps: true)
            }
            .keyboardShortcut(",", modifiers: .command)

            Divider()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: .command)
        }

        Settings {
            PreferencesView()
        }
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

            Section("Sound") {
                Toggle("Enable \"hihi\" sound", isOn: $prefs.soundEnabled)
            }

            Section("General") {
                Toggle("Launch at Login", isOn: $launchAtLogin.isEnabled)
            }
        }
        .formStyle(.grouped)
        .frame(width: 380, height: 260)
    }
}
