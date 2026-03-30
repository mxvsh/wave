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
                    Toggle("Hide pill when idle", isOn: $state.hideIdlePill)
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
