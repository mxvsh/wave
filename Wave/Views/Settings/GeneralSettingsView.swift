import SwiftUI
import Combine

struct GeneralSettingsView: View {
    @Environment(AppState.self) private var appState
    @State private var micGranted = PermissionService.isMicrophoneAuthorized()
    @State private var accessibilityGranted = PermissionService.isAccessibilityGranted()

    var body: some View {
        @Bindable var state = appState

        VStack(alignment: .leading, spacing: 20) {
                // Transcription
                section("Transcription") {
                    Toggle("Include punctuation", isOn: $state.includePunctuation)
                        .font(.system(size: 13))
                    Toggle("Mute system audio while dictating", isOn: $state.muteSystemAudio)
                        .font(.system(size: 13))
                    Picker("Language", selection: $state.transcriptionLanguage) {
                        ForEach(Self.languages, id: \.code) { lang in
                            Text(lang.label).tag(lang.code)
                        }
                    }
                    .font(.system(size: 13))
                }

                // Microphone
                section("Microphone") {
                    Picker("Input", selection: Binding(
                        get: { appState.selectedMicUID },
                        set: { appState.selectedMicUID = $0 }
                    )) {
                        Text("System Default").tag("")
                        ForEach(appState.microphoneManager.devices) { device in
                            Text(device.name).tag(device.uid)
                        }
                    }
                    .labelsHidden()
                    .onAppear { appState.microphoneManager.refresh() }
                }

                // Groq
                section("Groq") {
                    Toggle("Use Groq API", isOn: Binding(
                        get: { appState.transcriptionProvider == .groq },
                        set: { appState.transcriptionProvider = $0 ? .groq : .local }
                    ))
                    .font(.system(size: 13))

                    if appState.transcriptionProvider == .groq {
                        HStack(spacing: 6) {
                            TextField("API Key (gsk_...)", text: Binding(
                                get: { appState.groqAPIKey },
                                set: { appState.groqAPIKey = $0 }
                            ))
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 12, design: .monospaced))
                            Button("Save") {
                                Task { await appState.verifyAndFetchGroqModels() }
                            }
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(.blue.opacity(0.15), in: RoundedRectangle(cornerRadius: 7))
                            .foregroundStyle(.blue)
                            .buttonStyle(.plain)
                            .disabled(appState.groqAPIKey.isEmpty || appState.groqAPIStatus == .checking)
                        }

                        groqStatusView
                    }
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
        .onReceive(Timer.publish(every: 1.5, on: .main, in: .common).autoconnect()) { _ in
            micGranted = PermissionService.isMicrophoneAuthorized()
            accessibilityGranted = PermissionService.isAccessibilityGranted()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    // MARK: - Groq status

    @ViewBuilder
    private var groqStatusView: some View {
        switch appState.groqAPIStatus {
        case .unknown:
            EmptyView()
        case .checking:
            HStack(spacing: 5) {
                ProgressView().scaleEffect(0.6).frame(width: 8, height: 8)
                Text("Verifying...")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
        case .operational:
            HStack(spacing: 5) {
                Circle().fill(.green).frame(width: 6, height: 6)
                Text("Operational")
                    .font(.system(size: 11))
                    .foregroundStyle(.green)
            }
        case .error(let msg):
            HStack(spacing: 5) {
                Circle().fill(.red).frame(width: 6, height: 6)
                Text(msg)
                    .font(.system(size: 11))
                    .foregroundStyle(.red)
            }
        }
    }

    // MARK: - Language list

    static let languages: [(code: String, label: String)] = [
        ("auto", "Auto Detect"),
        ("en", "English"),
        ("es", "Spanish"),
        ("fr", "French"),
        ("de", "German"),
        ("it", "Italian"),
        ("pt", "Portuguese"),
        ("nl", "Dutch"),
        ("pl", "Polish"),
        ("ru", "Russian"),
        ("ja", "Japanese"),
        ("zh", "Chinese"),
        ("ko", "Korean"),
        ("ar", "Arabic"),
        ("hi", "Hindi"),
        ("tr", "Turkish"),
        ("sv", "Swedish"),
        ("da", "Danish"),
        ("fi", "Finnish"),
        ("no", "Norwegian"),
    ]

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
