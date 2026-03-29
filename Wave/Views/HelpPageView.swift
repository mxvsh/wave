import SwiftUI

struct HelpPageView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                section("Keyboard Shortcut") {
                    helpRow("Current shortcut", value: appState.shortcutDisplayString)
                    helpRow("Push to Talk", value: "Hold shortcut to record, release to transcribe")
                    helpRow("Toggle", value: "Press to start, press again to stop")
                }

                section("How it works") {
                    Text("Wave records your voice when you press the shortcut key and transcribes it into text. The transcription is inserted at your cursor position.")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }

                section("About") {
                    if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                        helpRow("Version", value: version)
                    }
                    HStack {
                        Text("Source")
                            .font(.system(size: 12))
                        Spacer()
                        Link("GitHub", destination: URL(string: "https://github.com/AeroWang/Wave")!)
                            .font(.system(size: 12))
                    }
                    HStack {
                        Text("Community")
                            .font(.system(size: 12))
                        Spacer()
                        Link("Discord", destination: URL(string: "https://discord.com/invite/3kUSy2d")!)
                            .font(.system(size: 12))
                    }
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
