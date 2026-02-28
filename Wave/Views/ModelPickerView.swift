import SwiftUI
import UniformTypeIdentifiers

struct ModelPickerView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var modelManager = appState.modelManager

        VStack(alignment: .leading, spacing: 16) {
            Text("Models")
                .font(.title3.bold())

            ScrollView {
                VStack(spacing: 8) {
                    ForEach(WhisperModel.available) { model in
                        modelRow(model)
                    }
                }
            }
            .frame(maxHeight: 300)

            Divider()

            HStack {
                Text("Or locate a model file:")
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Choose File...") {
                    let panel = NSOpenPanel()
                    panel.allowedContentTypes = [.init(filenameExtension: "bin")!]
                    panel.canChooseDirectories = false
                    panel.allowsMultipleSelection = false
                    if panel.runModal() == .OK, let url = panel.url {
                        appState.modelManager.selectModelAtPath(url.path)
                        Task { await appState.loadSelectedModel() }
                    }
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
    }

    @ViewBuilder
    private func modelRow(_ model: WhisperModel) -> some View {
        let isDownloaded = appState.modelManager.isDownloaded(model)
        let isSelected = appState.modelManager.selectedModelPath == appState.modelManager.fileURL(for: model).path
        let isDownloading = appState.modelManager.downloadingModelId == model.id.uuidString

        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(model.name)
                        .font(.system(size: 13, weight: .medium))
                    Text(model.size)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                Text(model.type)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if isSelected {
                Label("Active", systemImage: "checkmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(.green)
            } else if isDownloaded {
                Button("Use") {
                    appState.modelManager.selectModel(model)
                    Task { await appState.loadSelectedModel() }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            } else if isDownloading {
                let progress = appState.modelManager.downloadProgress[model.id.uuidString] ?? 0
                HStack(spacing: 8) {
                    ProgressView(value: progress)
                        .frame(width: 60)
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 11).monospacedDigit())
                    Button(action: { appState.modelManager.cancelDownload() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            } else {
                Button("Download") {
                    appState.modelManager.download(model)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
    }
}
