import SwiftUI
import Combine

struct HomeView: View {
    @Environment(AppState.self) private var appState
    @State private var showModelPicker = false
    @State private var showDictionaryEditor = false
    @State private var micGranted = PermissionService.isMicrophoneAuthorized()
    @State private var accessibilityGranted = PermissionService.isAccessibilityGranted()

    var body: some View {
        @Bindable var state = appState

        VStack(alignment: .leading, spacing: 20) {
            // Mode section
            VStack(alignment: .leading, spacing: 8) {
                Text("Mode")
                    .font(.headline)
                Picker("", selection: $state.dictationMode) {
                    ForEach(DictationMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .labelsHidden()
                .pickerStyle(.segmented)
                .onChange(of: appState.dictationMode) {
                    appState.setupHotkey()
                }
            }

            // Shortcut section
            VStack(alignment: .leading, spacing: 8) {
                Text("Shortcut")
                    .font(.headline)
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

            // Transcription section
            VStack(alignment: .leading, spacing: 8) {
                Text("Transcription")
                    .font(.headline)
                Toggle("Include punctuation", isOn: $state.includePunctuation)
                Toggle("Mute system audio while dictating", isOn: $state.muteSystemAudio)
            }

            // Dictionary section
            VStack(alignment: .leading, spacing: 8) {
                Text("Dictionary")
                    .font(.headline)
                HStack {
                    let count = appState.customVocabulary.count
                    Text(count == 0 ? "No terms" : "\(count) term\(count == 1 ? "" : "s")")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Manage...") { showDictionaryEditor = true }
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
                        .buttonStyle(.plain)
                }
            }

            // Model section
            VStack(alignment: .leading, spacing: 8) {
                Text("Model")
                    .font(.headline)
                HStack {
                    switch appState.transcriptionProvider {
                    case .local:
                        if let path = appState.modelManager.selectedModelPath {
                            let name = URL(fileURLWithPath: path).lastPathComponent
                            Label(name, systemImage: "brain")
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        } else {
                            Text("No model selected")
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                        }
                    case .groq:
                        Label(appState.groqModel, systemImage: "cloud")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Spacer()
                    Button("Change...") { showModelPicker = true }
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
                        .buttonStyle(.plain)
                }
            }

            // Permissions section — only shown when something is missing
            if !micGranted || !accessibilityGranted {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Permissions")
                        .font(.headline)

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

            Divider()

            // Status
            HStack {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                Text(statusText)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
        .padding(.top, 36) // space below traffic lights
        .frame(width: 380)
        .onReceive(Timer.publish(every: 1.5, on: .main, in: .common).autoconnect()) { _ in
            micGranted = PermissionService.isMicrophoneAuthorized()
            accessibilityGranted = PermissionService.isAccessibilityGranted()
        }
        .background(WindowConfigurator().frame(width: 0, height: 0))
        .sheet(isPresented: $showModelPicker) {
            ProviderPickerView()
                .environment(appState)
                .frame(width: 420)
        }
        .sheet(isPresented: $showDictionaryEditor) {
            DictionaryEditorView()
                .environment(appState)
                .frame(width: 360, height: 300)
        }
        .sheet(isPresented: Binding(
            get: { appState.showOnboarding },
            set: { appState.showOnboarding = $0 }
        )) {
            OnboardingView()
                .environment(appState)
        }
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
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
                .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(.orange.opacity(0.2), lineWidth: 1))
    }

    private var statusColor: Color {
        switch appState.status {
        case .idle: return appState.isReady ? .green : .orange
        case .recording: return .red
        case .transcribing: return .blue
        case .error: return .red
        }
    }

    private var statusText: String {
        switch appState.status {
        case .idle:
            if appState.isReady { return "Ready" }
            return appState.transcriptionProvider == .groq ? "Groq API key required" : "No model loaded"
        case .recording: return "Recording..."
        case .transcribing: return "Transcribing..."
        case .error(let msg): return msg
        }
    }

}
