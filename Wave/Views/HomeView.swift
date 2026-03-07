import SwiftUI

struct HomeView: View {
    @Environment(AppState.self) private var appState
    @State private var showModelPicker = false
    @State private var newVocabTerm = ""

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
                    modifiers: $state.hotkeyModifiers
                )
                .onChange(of: appState.hotkeyKeyCode) { appState.setupHotkey() }
                .onChange(of: appState.hotkeyModifiers) { appState.setupHotkey() }
            }

            // Transcription section
            VStack(alignment: .leading, spacing: 8) {
                Text("Transcription")
                    .font(.headline)
                Toggle("Include punctuation", isOn: $state.includePunctuation)
            }

            // Vocabulary section
            VStack(alignment: .leading, spacing: 8) {
                Text("Vocabulary")
                    .font(.headline)
                Text("Terms listed here are hinted to the model before each transcription, improving accuracy for technical names and jargon.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                if !appState.customVocabulary.isEmpty {
                    ScrollView {
                        VStack(spacing: 4) {
                            ForEach(appState.customVocabulary, id: \.self) { term in
                                HStack {
                                    Text(term)
                                        .font(.system(size: 13))
                                    Spacer()
                                    Button {
                                        appState.customVocabulary.removeAll { $0 == term }
                                    } label: {
                                        Image(systemName: "minus.circle.fill")
                                            .foregroundStyle(.secondary)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(Color(.controlBackgroundColor))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                        }
                    }
                    .frame(maxHeight: 120)
                }

                HStack {
                    TextField("Add term…", text: $newVocabTerm)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit { addVocabTerm() }
                    Button("Add") { addVocabTerm() }
                        .disabled(newVocabTerm.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }

            // Model section
            VStack(alignment: .leading, spacing: 8) {
                Text("Model")
                    .font(.headline)
                HStack {
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
                    Spacer()
                    Button("Change...") { showModelPicker = true }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
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
        .background(WindowConfigurator().frame(width: 0, height: 0))
        .sheet(isPresented: $showModelPicker) {
            ModelPickerView()
                .environment(appState)
                .frame(width: 420, height: 420)
        }
        .sheet(isPresented: Binding(
            get: { appState.showOnboarding },
            set: { appState.showOnboarding = $0 }
        )) {
            OnboardingView()
                .environment(appState)
        }
    }

    private var statusColor: Color {
        switch appState.status {
        case .idle: return appState.isModelLoaded ? .green : .orange
        case .recording: return .red
        case .transcribing: return .blue
        case .error: return .red
        }
    }

    private var statusText: String {
        switch appState.status {
        case .idle: return appState.isModelLoaded ? "Ready" : "No model loaded"
        case .recording: return "Recording..."
        case .transcribing: return "Transcribing..."
        case .error(let msg): return msg
        }
    }

    private func addVocabTerm() {
        let term = newVocabTerm.trimmingCharacters(in: .whitespaces)
        guard !term.isEmpty, !appState.customVocabulary.contains(term) else { return }
        appState.customVocabulary.append(term)
        newVocabTerm = ""
    }
}
