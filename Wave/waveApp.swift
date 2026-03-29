import SwiftUI

@main
struct WaveApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var appState = AppState()
    @Environment(\.openWindow) private var openWindow

    var body: some Scene {
        Window("Wave", id: "main") {
            HomeView()
                .environment(appState)
        }
        .defaultSize(width: 520, height: 440)
        .windowResizability(.contentSize)
        .defaultPosition(.center)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandGroup(replacing: .undoRedo) {}
            CommandGroup(replacing: .textFormatting) {}
            CommandGroup(replacing: .toolbar) {}
            CommandGroup(replacing: .windowSize) {}
            CommandGroup(replacing: .windowArrangement) {}
            CommandGroup(replacing: .help) {}
        }

        MenuBarExtra {
            switch appState.status {
            case .idle:
                if appState.isReady {
                    Label("Ready", systemImage: "checkmark.circle")
                } else {
                    Label("Not configured", systemImage: "exclamationmark.triangle")
                }
            case .recording:
                Label("Recording...", systemImage: "mic.fill")
            case .transcribing:
                Label("Transcribing...", systemImage: "brain")
            case .error(let msg):
                Label(msg, systemImage: "exclamationmark.triangle")
            }

            Divider()

            Button("Check for Updates...") {
                UpdaterService.shared.checkForUpdates()
            }
            .disabled(!UpdaterService.shared.isAvailable)

            Divider()

            Button("Settings...") {
                openWindow(id: "main")
                NSApp.activate(ignoringOtherApps: true)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    NSApp.activate(ignoringOtherApps: true)
                }
            }
            .keyboardShortcut(",", modifiers: .command)

            Divider()

            Button("Quit Wave") {
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: .command)
        } label: {
            Image("MenuBarIcon")
                .renderingMode(.template)
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        guard enforceSingleInstance() else { return }

        NSApp.setActivationPolicy(.regular)
        Task { @MainActor in
            UpdaterService.shared.start()
        }
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        // SwiftUI CommandGroup replacements leave empty menu headers on newer macOS.
        // Remove them directly via AppKit every time the app activates.
        guard let mainMenu = NSApp.mainMenu else { return }
        let remove = ["Format", "View", "File", "Edit", "Window", "Help"]
        for title in remove {
            if let item = mainMenu.items.first(where: { $0.title == title }) {
                mainMenu.removeItem(item)
            }
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    @discardableResult
    private func enforceSingleInstance() -> Bool {
        guard let bundleID = Bundle.main.bundleIdentifier else { return true }

        let running = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
        guard running.count > 1 else { return true }

        let currentPID = ProcessInfo.processInfo.processIdentifier
        if let existing = running.first(where: { $0.processIdentifier != currentPID }) {
            existing.activate(options: [.activateAllWindows])
        }

        DispatchQueue.main.async {
            NSApp.terminate(nil)
        }
        return false
    }
}
