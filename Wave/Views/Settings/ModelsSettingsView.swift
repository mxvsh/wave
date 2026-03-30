import SwiftUI

struct ModelsSettingsView: View {
    @Environment(AppState.self) private var appState
    @State private var showProviderPicker = false
    @State private var showLLMPicker = false
    @State private var isEditingKey = false

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
                        action: (appState.transcriptionProvider == .groq && !appState.groqAPIKey.isEmpty) ? { showLLMPicker = true } : nil
                    )
                }

                section("Groq") {
                    Toggle("Use Groq API", isOn: Binding(
                        get: { appState.transcriptionProvider == .groq },
                        set: { appState.transcriptionProvider = $0 ? .groq : .local }
                    ))
                    .font(.system(size: 13))

                    if appState.transcriptionProvider == .groq {
                        if !appState.groqAPIKey.isEmpty && !isEditingKey {
                            HStack(spacing: 6) {
                                Text(maskedAPIKey)
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Button("Edit") { isEditingKey = true }
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 6))
                                    .buttonStyle(.plain)
                            }
                        } else {
                            HStack(spacing: 6) {
                                TextField("API Key (gsk_...)", text: Binding(
                                    get: { appState.groqAPIKey },
                                    set: { appState.groqAPIKey = $0 }
                                ))
                                .textFieldStyle(.roundedBorder)
                                .font(.system(size: 12, design: .monospaced))
                                Button("Save") {
                                    Task {
                                        await appState.verifyAndFetchGroqModels()
                                        if appState.groqAPIStatus == .operational {
                                            isEditingKey = false
                                        }
                                    }
                                }
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.brand.opacity(0.15), in: RoundedRectangle(cornerRadius: 7))
                                .foregroundStyle(Color.brand)
                                .buttonStyle(.plain)
                                .disabled(appState.groqAPIKey.isEmpty || appState.groqAPIStatus == .checking)
                            }
                        }

                        groqStatusView
                    }
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

    private var maskedAPIKey: String {
        let key = appState.groqAPIKey
        guard key.count > 10 else { return key }
        let prefix = String(key.prefix(6))
        let suffix = String(key.suffix(4))
        return "\(prefix)...\(suffix)"
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
