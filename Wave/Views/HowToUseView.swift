import SwiftUI

struct HowToUseView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                section("Dictation") {
                    helpRow("Shortcut", value: appState.shortcutDisplayString)
                    helpRow("Push to Talk", value: "Hold shortcut to record, release to transcribe")
                    helpRow("Toggle", value: "Press to start, press again to stop")
                }

                section("AI Mode") {
                    helpRow("Shortcut", value: appState.aiShortcutDisplayString)
                    helpRow("How it works", value: "Transcribes your voice then sends it to the AI model for a direct answer")
                }

                section("How it works") {
                    Text("Wave records your voice when you press the shortcut key and transcribes it into text. The transcription is inserted at your cursor position.")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
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

    private func helpRow(_ label: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.system(size: 12))
            Spacer()
            Text(value)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
        }
    }
}
