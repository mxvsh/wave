import SwiftUI

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                section("Wave") {
                    Text("Wave is a macOS app that turns your voice into text, anywhere you type. Press a shortcut, speak, and your words appear at the cursor — no setup, no interruptions.")
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
                    HStack {
                        Text("Feedback")
                            .font(.system(size: 12))
                        Spacer()
                        Link("@monawwarx", destination: URL(string: "https://x.com/monawwarx")!)
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
