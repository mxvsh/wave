import SwiftUI
import Combine

struct SettingsPageView: View {
    @Environment(AppState.self) private var appState
    @State private var showProviderPicker = false
    @State private var micGranted = PermissionService.isMicrophoneAuthorized()
    @State private var accessibilityGranted = PermissionService.isAccessibilityGranted()

    var body: some View {
        @Bindable var state = appState

        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Shortcut
                section("Shortcut") {
                    ShortcutRecorderView(
                        keyCode: $state.hotkeyKeyCode,
                        modifiers: $state.hotkeyModifiers,
                        onRecordingChanged: { isRecording in
                            if isRecording {
                                appState.hotkeyService.stop()
                            } else {
                                appState.hotkeyService.start()
                            }
                        }
                    )
                    .onChange(of: appState.hotkeyKeyCode) { appState.setupHotkey() }
                    .onChange(of: appState.hotkeyModifiers) { appState.setupHotkey() }
                }

                // Mode
                section("Mode") {
                    Picker("", selection: $state.dictationMode) {
                        ForEach(DictationMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                    .onChange(of: appState.dictationMode) { appState.setupHotkey() }
                }

                // Transcription
                section("Transcription") {
                    Toggle("Include punctuation", isOn: $state.includePunctuation)
                        .font(.system(size: 13))
                    Toggle("Mute system audio while dictating", isOn: $state.muteSystemAudio)
                        .font(.system(size: 13))
                }

                // Models
                section("Models") {
                    modelRow(
                        icon: "waveform",
                        label: "Audio",
                        value: audioModelLabel,
                        action: { showProviderPicker = true }
                    )
                    modelRow(
                        icon: "brain",
                        label: "LLM",
                        value: "Coming soon",
                        action: nil
                    )
                }

                // Permissions
                if !micGranted || !accessibilityGranted {
                    section("Permissions") {
                        if !micGranted {
                            permissionRow(
                                icon: "mic.fill",
                                label: "Microphone",
                                detail: "Required to record speech",
                                action: {
                                    Task { await PermissionService.requestMicrophoneAccess() }
                                    NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone")!)
                                }
                            )
                        }
                        if !accessibilityGranted {
                            permissionRow(
                                icon: "hand.raised.fill",
                                label: "Accessibility",
                                detail: "Required for global shortcut",
                                action: {
                                    PermissionService.requestAccessibility()
                                    NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
                                }
                            )
                        }
                    }
                }
            }
            .padding(16)
        }
        .onReceive(Timer.publish(every: 1.5, on: .main, in: .common).autoconnect()) { _ in
            micGranted = PermissionService.isMicrophoneAuthorized()
            accessibilityGranted = PermissionService.isAccessibilityGranted()
        }
        .sheet(isPresented: $showProviderPicker) {
            ProviderPickerView()
                .environment(appState)
                .frame(width: 420)
        }
    }

    // MARK: - Audio model label

    private var audioModelLabel: String {
        switch appState.transcriptionProvider {
        case .local:
            if let path = appState.modelManager.selectedModelPath {
                return "Local \u{00B7} \(URL(fileURLWithPath: path).deletingPathExtension().lastPathComponent)"
            }
            return "No model selected"
        case .groq:
            return "Groq \u{00B7} \(appState.groqModel)"
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            content()
        }
    }

    @ViewBuilder
    private func modelRow(icon: String, label: String, value: String, action: (() -> Void)?) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .frame(width: 16)
            Text(label)
                .font(.system(size: 13, weight: .medium))
            Spacer()
            Text(value)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .lineLimit(1)
            if let action {
                Button("Change\u{2026}") { action() }
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 6))
                    .buttonStyle(.plain)
            }
        }
        .padding(10)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
        .opacity(action == nil ? 0.5 : 1)
    }

    @ViewBuilder
    private func permissionRow(icon: String, label: String, detail: String, action: @escaping () -> Void) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(.orange)
                .frame(width: 16)
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(size: 13, weight: .medium))
                Text(detail)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("Allow") { action() }
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 6))
                .buttonStyle(.plain)
        }
        .padding(10)
        .background(.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(.orange.opacity(0.2), lineWidth: 1))
    }
}
