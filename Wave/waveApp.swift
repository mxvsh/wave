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
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultPosition(.center)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandGroup(replacing: .undoRedo) {}
            CommandGroup(replacing: .pasteboard) {}
            CommandGroup(replacing: .textEditing) {}
            CommandGroup(replacing: .textFormatting) {}
            CommandGroup(replacing: .toolbar) {}
            CommandGroup(replacing: .sidebar) {}
            CommandGroup(replacing: .windowSize) {}
            CommandGroup(replacing: .windowArrangement) {}
            CommandGroup(replacing: .help) {}
        }

        MenuBarExtra {
            switch appState.status {
            case .idle:
                if appState.isModelLoaded {
                    Label("Ready", systemImage: "checkmark.circle")
                } else {
                    Label("No model loaded", systemImage: "exclamationmark.triangle")
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
                // Show the window immediately (it already exists, just hidden)
                let win = NSApp.windows.first(where: { !($0 is NSPanel) })
                win?.makeKeyAndOrderFront(nil)
                if win == nil { openWindow(id: "main") }
                NSApp.activate(ignoringOtherApps: true)
                // Re-activate after the menu finishes closing (~menu animation duration)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    NSApp.activate(ignoringOtherApps: true)
                    NSApp.windows.first(where: { !($0 is NSPanel) })?.makeKeyAndOrderFront(nil)
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
