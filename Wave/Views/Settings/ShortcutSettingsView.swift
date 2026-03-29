import SwiftUI

struct ShortcutSettingsView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var state = appState

        VStack(alignment: .leading, spacing: 20) {
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

                section("Shortcuts") {
                    shortcutRow("Dictation", keyCode: $state.hotkeyKeyCode, modifiers: $state.hotkeyModifiers) { isRecording in
                        if isRecording { appState.hotkeyService.stop() } else { appState.hotkeyService.start() }
                    } onChange: { appState.setupHotkey() }

                    shortcutRow("AI Mode", keyCode: $state.aiModeKeyCode, modifiers: $state.aiModeModifiers) { isRecording in
                        if isRecording { appState.aiHotkeyService.stop() } else { appState.aiHotkeyService.start() }
                    } onChange: { appState.setupHotkey() }
                }
            }
            .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    @ViewBuilder
    private func shortcutRow(
        _ label: String,
        keyCode: Binding<UInt16>,
        modifiers: Binding<UInt64>,
        onRecordingChanged: @escaping (Bool) -> Void,
        onChange: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.system(size: 13))
                .frame(width: 72, alignment: .leading)
            ShortcutRecorderView(
                keyCode: keyCode,
                modifiers: modifiers,
                onRecordingChanged: onRecordingChanged
            )
            .onChange(of: keyCode.wrappedValue) { onChange() }
            .onChange(of: modifiers.wrappedValue) { onChange() }
            Spacer()
        }
    }

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
}
