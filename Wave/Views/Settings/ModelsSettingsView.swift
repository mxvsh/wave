import SwiftUI

struct ModelsSettingsView: View {
    @Environment(AppState.self) private var appState
    @State private var showProviderPicker = false
    @State private var showLLMPicker = false

    var body: some View {
        @Bindable var state = appState

        VStack(alignment: .leading, spacing: 20) {
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
                        value: aiModelLabel,
                        action: { showLLMPicker = true }
                    )
                }

                section("LLM System Prompt") {
                    TextEditor(text: $state.llmSystemPrompt)
                        .font(.system(size: 12))
                        .frame(minHeight: 80, maxHeight: 120)
                        .scrollContentBackground(.hidden)
                        .padding(8)
                        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
                    Text("Instructions for the AI when using AI Mode shortcut.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .sheet(isPresented: $showProviderPicker) {
            ProviderPickerView()
                .environment(appState)
                .frame(width: 420)
        }
        .sheet(isPresented: $showLLMPicker) {
            LLMPickerView()
                .environment(appState)
                .frame(width: 520)
        }
    }

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

    private var aiModelLabel: String {
        llmModels.first(where: { $0.id == appState.aiModel })?.name ?? appState.aiModel
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
}
