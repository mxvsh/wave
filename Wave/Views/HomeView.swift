import SwiftUI
import Combine

struct HomeView: View {
    @Environment(AppState.self) private var appState
    @State private var showModelPicker = false
    @State private var showDictionaryEditor = false
    @State private var micGranted = PermissionService.isMicrophoneAuthorized()
    @State private var accessibilityGranted = PermissionService.isAccessibilityGranted()
    @State private var groqAPIKeyDraft = ""
    @State private var isEditingGroqAPIKey = false
    @FocusState private var isGroqAPIKeyFieldFocused: Bool

    var body: some View {
        @Bindable var state = appState

        VStack(alignment: .leading, spacing: 18) {
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
                            _ = appState.hotkeyService.start()
                        }
                    }
                )
                .onChange(of: appState.hotkeyKeyCode) { appState.setupHotkey() }
                .onChange(of: appState.hotkeyModifiers) { appState.setupHotkey() }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Transcription")
                    .font(.headline)
                Toggle("Include punctuation", isOn: $state.includePunctuation)
                Toggle("Mute system audio while dictating", isOn: $state.muteSystemAudio)
            }

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

            VStack(alignment: .leading, spacing: 8) {
                Text("Provider")
                    .font(.headline)
                Picker("", selection: $state.transcriptionProvider) {
                    ForEach(TranscriptionProvider.allCases, id: \.self) { provider in
                        Text(provider.rawValue).tag(provider)
                    }
                }
                .labelsHidden()
                .pickerStyle(.segmented)
                .disabled(appState.status != .idle)
            }

            providerSettings

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

            testCard

            Divider()

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
        .padding(.top, 36)
        .frame(width: 380)
        .onReceive(Timer.publish(every: 1.5, on: .main, in: .common).autoconnect()) { _ in
            micGranted = PermissionService.isMicrophoneAuthorized()
            accessibilityGranted = PermissionService.isAccessibilityGranted()
        }
        .background(WindowConfigurator().frame(width: 0, height: 0))
        .sheet(isPresented: $showModelPicker) {
            ModelPickerView()
                .environment(appState)
                .frame(width: 420, height: 420)
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
        .onAppear {
            groqAPIKeyDraft = appState.groqAPIKey
            isEditingGroqAPIKey = appState.groqAPIKey.isEmpty
        }
        .onChange(of: appState.transcriptionProvider) {
            if appState.transcriptionProvider == .localWhisper {
                Task { await appState.loadSelectedModel() }
            } else {
                appState.status = .idle
            }
        }
        .onChange(of: appState.groqAPIKey) {
            if !isEditingGroqAPIKey {
                groqAPIKeyDraft = appState.groqAPIKey
            }
        }
        .onChange(of: groqAPIKeyDraft) {
            guard isEditingGroqAPIKey || appState.groqAPIKey.isEmpty else { return }
            appState.groqAPIKey = trimmedGroqAPIKeyDraft
        }
        .onChange(of: isGroqAPIKeyFieldFocused) {
            if !isGroqAPIKeyFieldFocused && !appState.groqAPIKey.isEmpty {
                isEditingGroqAPIKey = false
            }
        }
    }

    @ViewBuilder
    private var providerSettings: some View {
        switch appState.transcriptionProvider {
        case .localWhisper:
            settingsCard {
                HStack(spacing: 10) {
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
                    Spacer(minLength: 8)
                    if appState.modelManager.selectedModelPath != nil {
                        Button("Clear") {
                            Task { await appState.clearSelectedModel() }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    Button("Change...") { showModelPicker = true }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                }
            }
        case .groqAPI:
            settingsCard(spacing: 12) {
                if isEditingGroqAPIKey || appState.groqAPIKey.isEmpty {
                    TextField("Right click to paste, then Return", text: $groqAPIKeyDraft)
                        .textFieldStyle(.roundedBorder)
                        .focused($isGroqAPIKeyFieldFocused)
                        .onSubmit { finishGroqAPIKeyEditing() }
                } else {
                    HStack(spacing: 10) {
                        Text(maskedGroqAPIKey)
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button("Edit") {
                            isEditingGroqAPIKey = true
                            groqAPIKeyDraft = appState.groqAPIKey
                            isGroqAPIKeyFieldFocused = true
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        Button("Clear") {
                            clearGroqAPIKey()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }

                Picker("Hosted model", selection: Binding(
                    get: { appState.groqModel },
                    set: { appState.groqModel = $0 }
                )) {
                    ForEach(GroqWhisperModel.allCases) { model in
                        Text(model.displayName).tag(model)
                    }
                }
                .pickerStyle(.menu)
            }
        }
    }

    private var testCard: some View {
        settingsCard(spacing: 10) {
            HStack(spacing: 12) {
                Button {
                    Task {
                        if appState.status == .recording {
                            await appState.stopDictationForTest()
                        } else if appState.status == .idle {
                            await appState.startDictation()
                        }
                    }
                } label: {
                    Label(testButtonTitle, systemImage: testButtonSymbol)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(appState.status == .transcribing)

                if appState.status == .recording {
                    Label("Listening", systemImage: "waveform")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.red)
                } else if appState.status == .transcribing {
                    HStack(spacing: 6) {
                        ProgressView()
                            .controlSize(.small)
                        Text("Transcribing")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if let transcript = appState.lastTranscription, !transcript.isEmpty {
                Text(transcript)
                    .font(.system(size: 13))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
            }

            if !appState.isHotkeyAvailable {
                Text("Accessibility is off for the shortcut.")
                    .font(.system(size: 11))
                    .foregroundStyle(.orange)
            }
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
        case .idle: return appState.isReadyToDictate ? .green : .orange
        case .recording: return .red
        case .transcribing: return .blue
        case .error: return .red
        }
    }

    private var statusText: String {
        switch appState.status {
        case .idle: return appState.readyStatusText
        case .recording: return "Recording..."
        case .transcribing: return "Transcribing..."
        case .error(let msg): return msg
        }
    }

    private var testButtonTitle: String {
        switch appState.status {
        case .recording:
            return "Stop Test"
        case .transcribing:
            return "Transcribing"
        default:
            return "Test Dictation"
        }
    }

    private var testButtonSymbol: String {
        switch appState.status {
        case .recording:
            return "stop.fill"
        default:
            return "mic.fill"
        }
    }

    private var maskedGroqAPIKey: String {
        let key = appState.groqAPIKey
        guard key.count > 10 else { return key }
        return "\(key.prefix(6))...\(key.suffix(4))"
    }

    private var trimmedGroqAPIKeyDraft: String {
        groqAPIKeyDraft.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func finishGroqAPIKeyEditing() {
        appState.groqAPIKey = trimmedGroqAPIKeyDraft
        isEditingGroqAPIKey = appState.groqAPIKey.isEmpty
        isGroqAPIKeyFieldFocused = false
    }

    private func clearGroqAPIKey() {
        groqAPIKeyDraft = ""
        appState.groqAPIKey = ""
        isEditingGroqAPIKey = true
        isGroqAPIKeyFieldFocused = true
    }

    @ViewBuilder
    private func settingsCard(spacing: CGFloat = 8, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: spacing) {
            content()
        }
        .padding(12)
        .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 14))
    }
}
